FileRead, Dictionary, BWDict.txt
Dictionary := "`r`n" Dictionary "`r`n"

Title = Book Whomp
BorderColor = CC6B16
BackgroundColor = B25510

Scores := {}

W = 7
H = 7
MinWordLen := 4
Gui, Color, 512507
Loop %W%
{
	X := A_Index
	Loop %H%
	{
		Y := A_Index
		CX := ((X - 1) * 30) + 1			; The "X" position of the controls
		CY := ((Y - 1) * 30)				; The "Y" position of the outline
		CY2 := CY + floor((30 - 16) / 2)	; The "Y" position of the text
		CY3 := CY + 1						; The "Y" position of the background
		CID := X . "$" . Y					; The control ID of the text
		CID2 := X . "_" . Y					; The control ID of the outline
		CID3 := X . "#" . Y					; The control ID of the background
		%CID2% := RandomLetter()
		Gui, Add, progress, x%CX% y%CY3% w29 h29 v%CID3% Background%BorderColor%
		Gui, Font, s22, WebDings
		Gui, Add, Text, x%CX% y%CY% v%CID% BackgroundTrans c%BackgroundColor%, c
		Gui, Font, s12, Verdana
		Gui, Add, Text, x%CX% y%CY2% w29 v%CID2% BackgroundTrans Center cBlack, % %CID2%
	}
}
BoardW := W * 30 + 1
BoardH := H * 30 + 1
GuiH := BoardH + 21
GuiW := BoardW

Gui, Font, s8

EditW := BoardW*(3/4) - 1
Gui, Add, Edit, w%EditW% y%BoardH% h20 x1 vWord
Gui, Add, Button, % "w" BoardW/4 - 1 " x" EditW + 2 " h20 yp gEnter Default", Check

Gui, Font, s12

Gui, +ToolWindow +E0x40000
Gui, Show, w%GuiW% h%GuiH%, %Title%
OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x204, "WM_RBUTTONDOWN")
return

;#IfWinActive Book Whomp

Enter:
GuiControlGet, Word
Score(Word)
return

Score(Word)
{
	global Selected, MinWordLen, Dictionary, Scores, Title, Score
	
	if (StrLen(Selected) < MinWordLen)
	{
		ToolTip("Word too short")
		return
	}
	
	StringReplace, Selected, Selected, Q, QU, All
	
	if (LetterSort(Word) != LetterSort(Selected))
	{
		ToolTip("Mismatched")
		return
	}
	
	if (!InStr(Dictionary, "`r`n" Word "`r`n"))
	{
		ToolTip("Unknown")
		return
	}
	
	ScoreUnlimited(Word)
	return
}

ScoreUnlimited(Word) ; Keep score by averaging points per word
{
	global Selected, MinWordLen, Dictionary, Scores, Title, Score
	
	Clear(1)
	
	Points := Points(Word, 1)
	;MsgBox, % points
	Scores.Insert(Points)
	Average := Average(Scores)
	
	Score += Points
	
	ToolTip(Points " Points")
	
	Gui, Show,, %Title% - %Average% Points
	
	return
}

ScoreLimited(Word) ; So many turns per "round"
{
	global Words, Score
	Points := Points(Word, 1)
	;Scores.Insert(Points)
	Score += Points
	
	Words--
	If (Words <= 0)
	{
		EndLimited()
	}
	
	ToolTip(Points " Points")
	Gui, Show,, % Title " - " Score " - " Words " Word" (Words>1?"s":"") " Left"
	return
}

EndLimited()
{
	global Rounds, Scores, Score
	MsgBox, % Score
	Scores.Insert(Score)
	Rounds--
	if (Rounds <= 0)
		
	Gui, Show,, %Title%
}

Average(Score) ; Averages the values in an array
{
	Divisor := Score.MaxIndex()
	For key, Points in Score
		Average += Points
	return Floor(Average/Divisor)
}

WM_LBUTTONDOWN(wParam, lParam) ; Left click events
{
	global Selected
	X := lParam & 0xFFFF
	Y := lParam >> 16
	Cntrl := A_GuiControl
	If Cntrl not contains #
		return
	StringSplit, TP, Cntrl, #
	Letter := SetLetter(TP1, TP2) ; Get the letter name
	Select(TP1, TP2)
}

WM_RBUTTONDOWN(wParam, lParam) ; Right click events
{
	Clear()
	return false
}

Select(X, Y) ; Selects a tile
{
	global Selected, SelectedList
	Cntrl = %X%_%Y%
	if SelectedList
	{
		if (InStr(SelectedList, Cntrl) || !Adjacent(SelectedList, X, Y))
		{
			ToolTip("Failure")
			return
		}
		SetLetterColor(X, Y, "Red")
		SelectedList .= "," . Cntrl
	}
	else
	{
		SetLetterColor(X, Y, "Green")
		SelectedList := Cntrl
	}
	Letter := %Cntrl%
	Selected .= Letter
	return
}

Clear(Remove=0) ; Clear the tiles from the list
{
	global Selected, SelectedList
	Loop, Parse, SelectedList, `,
	{
		StringSplit, LP, A_LoopField, _ ; Letter Pos
		SetLetterColor(LP1, LP2, "Black")
		if Remove
			SetLetter(LP1, LP2, RandomLetter())
	}
	if (Remove || !SelectedList)
		GuiControl,, Word ; Clear edit box
	Selected :=
	SelectedList :=
}

Adjacent(SelectedList, X, Y)
{
	if (InStr(SelectedList, X-1 "_" Y-1)	; Diag
	|| InStr(SelectedList, X "_" Y-1)		; Up
	|| InStr(SelectedList, X+1 "_" Y-1)		; Diag
	|| InStr(SelectedList, X-1 "_" Y)		; Left
	|| InStr(SelectedList, X+1 "_" Y)		; Right
	|| InStr(SelectedList, X-1 "_" Y+1)		; Diag
	|| InStr(SelectedList, X "_" Y+1)		; Down
	|| InStr(SelectedList, X+1 "_" Y+1))	; Diag
		return true
	return false
}

RandomLetter() ; Psuedo random weighted letter generator
{
	static letters := "AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSTTTTTTUUUUVVWWXYYZ"
	Random, Rand, 1, 98
	return SubStr(letters, Rand, 1)
}

Points(String, Long=0) ; Gives you the string's point value
{
	global MinWordLen
	static Letters := {E:1,A:1,I:1,O:1,N:1,R:1,T:1,L:1,S:1,U:1,D:2,G:2,B:3,C:3,M:3,P:3,F:4,H:4,V:4,W:4,Y:4,K:5,J:8,X:8,Q:10,Z:10}
	Loop, Parse, String
	{
		Points += Letters[A_LoopField]
	}
	if (Long) ; Longer words score more points
	{
		if (Len := StrLen(String) - MinWordLen - 1 > 0)
			return floor(Points * (Len/3 + 1) * 10)
	}
	return Points * 10
}

AcessGlobal(name) ; Acesses a global value
{
	global
	x := %name%
	return x
}

SetLetterColor(X, Y, NewColor) ; Set the tile's color
{
	Gui, Font, c%NewColor%
	GuiControl, Font, %X%_%Y%
	SetLetter(X, Y, SetLetter(X, Y))
	return
}

SetLetter(X, Y, Letter="") ; Sets the tile's letter
{
	OldLetter := %X%_%Y%
	if !Letter
		return OldLetter
	StringUpper, Letter, Letter
	%X%_%Y% := Letter
	GuiControl,, %X%_%Y%, %Letter%
	return OldLetter
}

LetterSort(Word, Rand=0) ; Sorts the letters in the word
{
	Word := RegExReplace(Word, ".", "$0`,")
	if Rand
		Sort, Word, Random D`,
	else
		Sort, Word, D`,
	Word := RegExReplace(Word, ",", "")
	return Word
}

GenerateBoard(W, H) ; Clears the board and generates new tiles
{
	Loop %W%
	{
		X := A_Index
		Loop %H%
		{
			Y := A_Index
			SetLetterColor(X, Y, "Black")
			SetLetter(X, Y, RandomLetter())
		}
	}
	return
}

ToolTip(String) ; Temporary tooltip
{
	ToolTip, % String
	SetTimer, RemoveTip, -1000
	return
	
	RemoveTip:
	ToolTip
	return
}

GuiClose:
ExitApp
return
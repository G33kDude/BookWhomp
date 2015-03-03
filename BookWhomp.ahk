#NoEnv
SetBatchLines, -1

#Include GDI.ahk

Width := 7
Height := 7
TileWidth := 30
TileHeight := 30
BoardWidth := Width*TileWidth + 1
BoardHeight := Height*TileHeight + 1

Gui, New, +ToolWindow +E0x40000
Gui, Margin, 0, 0
Gui, Add, Progress, w%BoardWidth% h%BoardHeight% hWndBoardHwnd
Gui, Add, Edit, % "w" BoardWidth-50 " y+1"
Gui, Add, Button, x+0 yp-1 w50, Submit
Gui, Show

MyGdi := new GDI(BoardHwnd)
MyBoard := new Board(MyGdi, Width, Height, TileWidth, TileHeight)
MyBoard.Draw()

OnMessage(0xF, "WM_PAINT")
OnMessage(0x202, "WM_LBUTTONUP")
OnMessage(0x205, "WM_RBUTTONUP")
return

GuiClose:
ExitApp
return

WM_LBUTTONUP(wParam, lParam, Msg, hWnd)
{
	global MyBoard
	MyBoard.Select(MyBoard.CoordsToTilePos(MakePoints(lParam)*)*)
	MyBoard.Draw()
	;ToolTip, % Coords.x//q.tileWidth "," Coords.y//q.tileHeight
}

WM_RBUTTONUP(wParam, lParam, Msg, hWnd)
{
	global MyBoard
	MyBoard.Deselect()
}

WM_PAINT(wParam, lParam, Msg, hWnd)
{
	global MyBoard
	Sleep, -1
	MyBoard.MyGdi.BitBlt()
}

MakePoints(DWORD)
{
	return [SignWord(DWORD & 0xFFFF), SignWord(DWORD>>16 & 0xFFFF)]
}

SignWord(WORD)
{
	return WORD > 0x7FFF ? -(WORD ^ 0xFFFF) - 1 : WORD
}

class Board
{
	__New(MyGdi, Width, Height, TileWidth, TileHeight)
	{
		this.MyGdi := MyGdi
		this.Width := Width
		this.Height := Height
		this.TileWidth := TileWidth
		this.TileHeight := TileHeight
		
		this.Tiles := []
		this.SelectedTiles := []
		this.Grid := []
		Loop, %Width%
		{
			x := A_Index
			Loop, %Height%
			{
				y := A_Index
				Random, Rand, 65, 90
				MyTile := new Board.Tile(x, y, TileWidth-1, TileHeight-1, Chr(Rand))
				this.Grid[x, y] := MyTile
				this.Tiles.Insert(MyTile)
			}
		}
	}
	
	CoordsToTilePos(x, y)
	{
		return [x//this.TileWidth + 1, y//this.TileHeight + 1]
	}
	
	Select(x, y)
	{
		Tile := this.Grid[x, y]
		if this.IsSelecting()
		{
			if !this.IsSelectable(x, y)
				return ToolTip("Not adjacent")
			if this.SelectedTiles.HasKey(Tile)
				return ToolTip("Already selected")
			Tile.bg := 0x161FCC
			Tile.fg := 0x1012B2
		}
		else
		{
			Tile.fg := 0x10B244
			Tile.bg := 0x16CC49
		}
		
		this.SelectedTiles[Tile] := True
		this.Draw()
	}
	
	IsSelecting()
	{
		for Tile in this.SelectedTiles
			return True
		return False
	}
	
	IsSelectable(x, y)
	{
		for Tile in this.SelectedTiles
			if (Abs(Tile.x-x) < 2 && Abs(Tile.y-y) < 2)
				return True
		return False
	}
	
	Deselect()
	{
		for Tile in this.SelectedTiles
		{
			Tile.fg := Board.Tile.fg
			Tile.bg := Board.Tile.bg
		}
		Tiles := this.SelectedTiles
		this.SelectedTiles := []
		this.Draw()
		return Tiles
	}
	
	Draw()
	{
		this.MyGdi.FillRectangle(0, 0, this.Width*this.TileWidth+1, this.Height*this.TileHeight+1, 0x072551)
		for each, Tile in this.Tiles
			Tile.Draw(this.MyGdi, (tile.x-1)*this.TileWidth + 1, (tile.y-1)*this.TileHeight + 1)
		this.MyGdi.BitBlt()
	}
	
	class Tile
	{
		static bg := 0x166BCC, fg := 0x1055B2, Color := 0x000000
		
		
		__New(x, y, w, h, l)
		{
			this.x := x, this.y := y
			this.w := w, this.h := h
			this.Letter := l
		}
		
		Draw(MyGdi, xPos, yPos)
		{
			MyGdi.FillRectangle(xPos, yPos, this.w, this.h, this.fg)
			MyGdi.FillRectangle(xPos+2, yPos+2, this.w-4, this.h-4, this.bg)
			MyGdi.DrawText(xPos, yPos, this.w, this.h, this.Letter, this.Color, "Arial", 20, "CC")
		}
	}
}

ToolTip(Text, Time=1000)
{
	ToolTip, %Text%
	SetTimer, ClearTip, % -Abs(Time)
	return
	ClearTip:
	ToolTip
	return
}
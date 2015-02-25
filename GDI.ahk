class GDI
{
	__New(hWnd, CliWidth=0, CliHeight=0)
	{
		if !(CliWidth && CliHeight)
		{
			VarSetCapacity(Rect, 16, 0)
			DllCall("GetClientRect", "Ptr", hWnd, "Ptr", &Rect)
			CliWidth := NumGet(Rect, 8, "Int")
			CliHeight := NumGet(Rect, 12, "Int")
		}
		this.CliWidth := CliWidth
		this.CliHeight := CliHeight
		this.hWnd := hWnd
		this.hDC := DllCall("GetDC", "UPtr", hWnd, "UPtr")
		this.hMemDC := DllCall("CreateCompatibleDC", "UPtr", this.hDC, "UPtr")
		this.hBitmap := DllCall("CreateCompatibleBitmap", "UPtr", this.hDC, "Int", CliWidth, "Int", CliHeight, "UPtr")
		this.hOriginalBitmap := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", this.hBitmap)
	}
	
	__Delete()
	{
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", this.hOriginalBitmap)
		DllCall("DeleteObject", "UPtr", this.hBitmap)
		DllCall("DeleteObject", "UPtr", this.hMemDC)
		DllCall("ReleaseDC", "UPtr", this.hWnd, "UPtr", this.hDC)
	}
	
	BitBlt(x=0, y=0, w=0, h=0)
	{
		w := w ? w : this.CliWidth
		h := h ? h : this.CliHeight
		
		DllCall("BitBlt", "UPtr", this.hDC, "Int", x, "Int", y
		, "Int", w, "Int", h, "UPtr", this.hMemDC, "Int", 0, "Int", 0, "UInt", 0xCC0020) ;SRCCOPY
	}
	
	DrawLine(x, y, x2, y2, Color)
	{
		Pen := new GDI.Pen(Color)
		DllCall("MoveToEx", "UPtr", this.hMemDC, "Int", this.TranslateX(x), "Int", this.TranslateY(y), "UPtr", 0)
		hOriginalPen := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Pen.Handle, "UPtr")
		DllCall("LineTo", "UPtr", this.hMemDC, "Int", this.TranslateX(x2), "Int", this.TranslateY(y2))
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalPen, "UPtr")
	}
	
	SetPixel(x, y, Color, Fast=False)
	{
		x := this.TranslateX(x)
		y := this.TranslateY(y, this.Invert) ; Move up 1 px if inverted (drawing "up" instead of down)
		DllCall("SetPixel" (Fast?"V":""), "UPtr", this.hMemDC, "Int", x, "Int", y, "UInt", Color)
	}
	
	DrawText(x, y, w, h, Text, Color, Typeface, TextHeight, Align="LT", Weight=500, Style=0)
	{
		AlignH := {"L": 0x00, "C": 0x01, "R": 0x02}
		AlignV := {"C": 0x24, "B": 0x28, "T": 0x00}
		Align := StrSplit(Align)
		
		Font := new GDI.Font(Typeface, TextHeight, Weight, Style)
		
		; Transparent background, no color needed
		DllCall("SetBkMode", "UPtr", this.hMemDC, "Int", 1)
		;DllCall("SetBkColor", "UPtr", this.hMemDC, "UInt", 0xFFFFFF)
		
		DllCall("SetTextColor", "UPtr", this.hMemDC, "UInt", Color)
		hOriginalFont := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Font.Handle, "UPtr")
		
		x1 := this.TranslateX(x)
		y1 := this.TranslateY(y)
		x2 := this.TranslateX(x+w)
		y2 := this.TranslateY(y+h)
		if (y1 > y2) ; Fix the coordinates when inverted
			tmp := y1, y1 := y2, y2 := tmp
		
		; TODO: abstract RECTs
		VarSetCapacity(Rect, 16, 0)
		NumPut(x1, Rect, 0, "Int"), NumPut(y1, Rect, 4, "Int")
		NumPut(x2, Rect, 8, "Int"), NumPut(y2, Rect, 12, "Int")
		
		DllCall("DrawText", "UPtr", this.hMemDC, "Str", Text, "Int", -1, "UPtr", &Rect, "UInt", AlignH[Align[1]] | AlignV[Align[2]])
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalFont, "UPtr")
	}
	
	FillRectangle(x, y, w, h, Color, BorderColor=-1)
	{
		if (w == 1 && h == 1)
			return this.SetPixel(x, y, Color)
		
		Pen := new this.Pen(BorderColor < 0 ? Color : BorderColor)
		Brush := new this.Brush(Color)
		
		; Replace the original pen and brush with our own
		hOriginalPen := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Pen.Handle, "UPtr")
		hOriginalBrush := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Brush.Handle, "UPtr")
		
		x1 := this.TranslateX(x)
		x2 := this.TranslateX(x+w)
		y1 := this.TranslateY(y)
		y2 := this.TranslateY(y+h)
		
		DllCall("Rectangle", "UPtr", this.hMemDC
		, "Int", x1, "Int", y1
		, "Int", x2, "Int", y2)
		
		; Reselect the original pen and brush
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalPen, "UPtr")
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalBrush, "UPtr")
	}
	
	TranslateX(X)
	{
		return Floor(X)
	}
	
	TranslateY(Y, Offset=0)
	{
		if this.Invert
			return this.CliHeight - Floor(Y) - Offset
		return Floor(Y)
	}
	
	class Pen
	{
		__New(Color, Width=1, Style=0)
		{
			this.Handle := DllCall("CreatePen", "Int", Style, "Int", Width, "UInt", Color, "UPtr")
		}
		
		__Delete()
		{
			DllCall("DeleteObject", "UPtr", this.Handle)
		}
	}
	
	class Brush
	{
		__New(Color)
		{
			this.Handle := DllCall("CreateSolidBrush", "UInt", Color, "UPtr")
		}
		
		__Delete()
		{
			DllCall("DeleteObject", "UPtr", this.Handle)
		}
	}
	
	class Font
	{
		__New(Typeface, Height, Weight, Style)
		{
			this.Handle := DllCall("CreateFont"
			, "Int", Height ;height
			, "Int", 0 ;width
			, "Int", 0 ;angle of string (0.1 degrees)
			, "Int", 0 ;angle of each character (0.1 degrees)
			, "Int", Weight ;font weight
			, "UInt", Style&1 ;font italic
			, "UInt", Style&2 ;font underline
			, "UInt", Style&4 ;font strikeout
			, "UInt", 1 ;DEFAULT_CHARSET: character set
			, "UInt", 0 ;OUT_DEFAULT_PRECIS: output precision
			, "UInt", 0 ;CLIP_DEFAULT_PRECIS: clipping precision
			, "UInt", 0 ;DEFAULT_QUALITY: output quality
			, "UInt", 0 ;DEFAULT_PITCH | (FF_DONTCARE << 16): font pitch and family
			, "Str", Typeface ;typeface name
			, "UPtr")
		}
		
		__Delete()
		{
			DllCall("DeleteObject", "UPtr", this.Handle)
		}
	}
}
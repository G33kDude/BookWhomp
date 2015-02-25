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
Gui, Add, Edit, % "w" BoardWidth-50
Gui, Add, Button, x+0 yp-1 w50, Submit
Gui, Show

MyGdi := new GDI(BoardHwnd)
q := new Board(Width, Height, TileWidth, TileHeight)
q.Draw(MyGdi)
MyGdi.BitBlt()


class Board
{
	__New(Width, Height, TileWidth, TileHeight)
	{
		this.Width := Width
		this.Height := Height
		this.TileWidth := TileWidth
		this.TileHeight := TileHeight
		
		this.Tiles := []
		this.Grid := []
		Loop, %Width%
		{
			x := A_Index
			Loop, %Height%
			{
				y := A_Index
				Random, Rand, 97, 122
				MyTile := new Tile(x, y, TileWidth-1, TileHeight-1, Chr(Rand))
				this.Grid[x, y] := MyTile
				this.Tiles.Insert(MyTile)
			}
		}
	}
	
	Draw(MyGdi)
	{
		MyGdi.FillRectangle(0, 0, this.Width*this.TileWidth+1, this.Height*this.TileHeight+1, 0x072551)
		for each, Tile in this.Tiles
			Tile.Draw(MyGdi, (tile.x-1)*this.TileWidth + 1, (tile.y-1)*this.TileHeight + 1)
	}
}

class Tile
{
	__New(x, y, w, h, l)
	{
		this.x := x, this.y := y
		this.w := w, this.h := h
		this.bg := 0x1055B2
		this.fg := 0x166BCC
		this.Color := 0x000000
		this.letter := l
	}
	
	Draw(MyGdi, xPos, yPos)
	{
		MyGdi.FillRectangle(xPos, yPos, this.w, this.h, this.bg)
		MyGdi.FillRectangle(xPos+2, yPos+2, this.w-4, this.h-4, this.fg)
		MyGdi.DrawText(xPos, yPos, this.w, this.h, this.letter, 0, "Arial", 20, "CC")
	}
}

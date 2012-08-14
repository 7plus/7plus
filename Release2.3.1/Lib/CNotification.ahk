#include <CGUI>

Notify(Title, Text, Timeout = "", Icon = "", Action = "", Progress = "", Style = "")
{
	return new CNotificationWindow(Title, Text, Icon, Timeout, Action, Progress, Style)
}
Class CNotification
{
	static Windows := Array()
	static pToken :=  Gdip_Startup() ; Start gdi+
	;Default style used for a notification window. An instance can be supplied to the constructor to use a specific style
	Class Style
	{
		static BackgroundColor := "333333"

		static Radius := 9
		static Transparency := "220"
		Class Title
		{
			static FontSize := 8
			static FontWeight := 625
			static FontColor := "DDDDDD"
			static Font := "Arial"
		}
		Class Text
		{
			static FontSize := 8
			static FontColor := "DDDDDD"
			static FontWeight := 550
			static Font := "Arial"
		}

		Class Border
		{
			static Color := 0xAA000000
			static Width := 2
			static Radius := 13
			static Transpacency := 105
		}

		static ImageWidth := 32
		static ImageHeight := 32

		Class Progress
		{
			;Width := 350
			static Color := "Default"
			static BackgroundColor := "Default"
		}
		__new()
		{
			this.Title := new this.Title()
			this.Text := new this.Text()
			this.Border := new this.Border()
			this.Progress := new this.Progress()
		}
	}

	;Class used to describe a progress bar in a notification window. Can be passed to the constructor to show a progress bar
	Class CProgress
	{
		Min := 0
		Max := 100
		Value := 0
		__new(Min, Max, Value)
		{
			this.Min := Min
			this.Max := Max
			this.Value := Value
		}
	}
	RegisterNotificationWindow(NotificationWindow)
	{
		;msgbox % this.Windows.MaxIndex() ": " this.Windows[this.Windows.MaxIndex()].Y
		if(this.Windows.MaxIndex())
			Y := this.Windows[this.Windows.MaxIndex()].Y - NotificationWindow.WindowHeight
		else
		{
			SysGet, Mon, MonitorWorkArea, %mon%
			this.WorkspaceArea := {Left: MonLeft, Top : MonTop, Right : MonRight, Bottom : MonBottom}
			Y := this.WorkspaceArea.Bottom - NotificationWindow.WindowHeight
		}
		this.Windows.Insert(NotificationWindow)
		;msgbox % objmaxindex(this.Windows)
		NotificationWindow.OnClose.Handler := new Delegate(this, "OnClose")
		if(NotificationWindow.Timeout)
			SetTimer, CNotification_CloseTimer, -10
		return {X : this.WorkspaceArea.Right - NotificationWindow.WindowWidth, Y : Y}
	}
	OnClose(Sender)
	{
		for index, Window in this.Windows
		{
			if(Window = Sender)
			{
				this.Windows.Remove(Index)
				this.CalculateTargetPositions()
				SetTimer, CNotification_MoveWindows, -10
				return
			}
		}
	}
	CalculateTargetPositions()
	{
		Target := this.WorkspaceArea.Bottom
		Loop % this.Windows.MaxIndex()
		{
			;msgbox % "Window " A_Index ": " Target - this.Windows[A_Index].WindowHeight
			Target := this.Windows[A_Index].Target := Target - this.Windows[A_Index].WindowHeight
		}
	}
	MoveWindows()
	{
		Moved := false
		for index, Window in this.Windows
		{
			hwnd := Window.hwnd
			WinGetPos, , Y, , , ahk_id %hwnd%
			;Y := Window.Y
			if((Distance := Window.Target - Y) > 0)
			{
				Moved := true
				Delta := (Distance > 50 ? 5 : Round(5 - 5/Distance))
				Delta := Delta > Distance ? Distance : Delta
				WinMove, ahk_id %hwnd%, , , % Y + Delta
				;Window.Y := Y + (Distance > 50 ? 5 : Round(5 - 5/Distance))
			}
		}
		if(Moved)
			SetTimer, CNotification_MoveWindows, -10
	}
	CloseTimer()
	{
		StillWaiting := false
		for index, Window in this.Windows
		{
			if(Window.Timeout && A_TickCount > Window.CloseTime)
			{
				Window.Remove("Timeout")
				Window.Close()
				continue
			}
			if(Window.Timeout)
				StillWaiting := true
		}
		if(StillWaiting)
			SetTimer, CNotification_CloseTimer, -10
	}
}
CNotification_MoveWindows:
CNotification.MoveWindows()
return
CNotification_CloseTimer:
CNotification.CloseTimer()
return

Class CNotificationWindow Extends CGUI
{
	OnClick := new EventHandler()

	/*Creates a new notification. Parameters:
	Title: Title
	Text: Text. Supports links in markup language, see link control
	Icon: Path or icon handle
	Timeout: Empty for no timeout, otherwise timeout in ms.
	OnClick: function or delegate to handle clicks on the notification. It can optionally accept two arguments that indicate the clicked link, URLorID and Index.
	Progress: See CNotification.CProgress
	Style: See CNotification.CStyle
	*/

	__new(Title, Text, Icon = "", Timeout = "", OnClick = "", Progress = "", Style = "")
	{
		this.Timeout := Timeout * 1000
		this.CloseTime := A_TickCount + Timeout * 1000
		this.OnClick.Handler := OnClick
		this.AlwaysOnTop := true
		this.Border := false
		this.Caption := false
		this.ToolWindow := true
		;this.SysMenu := false
		if(!Style)
			Style := CNotification.Style

		this.WindowColor := Style.BackgroundColor
		this.Transparent := Style.Transparency

		;Background picture control to detect clicks on the GUI and render the border
		this.icoBackground := this.AddControl("Picture", "icoBackground", "x0 y0 w0 h0 0xE")
		
		;Offset from border
		Offset := Style.Border.Width > Style.Radius ? Style.Border.Width : Style.Radius
		if(Icon)
			this.icoIcon := this.AddControl("Picture", "icoIcon", "x" Offset " y" Offset " w" Style.ImageWidth " h" Style.ImageHeight " 0x40", Icon)
		;Revert to basic functions here so the font can be set before the control is added
		Gui, % this.GUINum ":Font", % "s" Style.Title.FontSize " w" Style.Title.FontWeight " c" Style.Title.FontColor, % Style.Title.Font
		this.txtTitle := this.AddControl("Text", "txtTitle", Icon ? "x+5" : "", Title)
		this.txtTitle.AutoSize()
		;Progress control
		if(Progress)
			this.prgProgress := this.AddControl("Progress", "prgProgress", "y+5 Range" Progress.Min "-" Progress.Max, Progress.Value)

		;Notification text is a link control
		Gui, % this.GUINum ":Font", % "s" Style.Text.FontSize " w" Style.Text.FontWeight " c" Style.Text.FontColor, % Style.Text.Font
		if(Text)
			this.lnkText := this.AddControl("Link", "lnkText", "y+5", Text)

		;Register and show window
		this.Position := CNotification.RegisterNotificationWindow(this)
		this.Show("NA")

		;Calculate width of progress bar
		w1 := this.HasKey("lnkText") ? this.lnkText.Width : 0
		w2 := this.txtTitle.Width
		width := w1 > w2 ? w1 : w2
		width := width > this.prgProgress.Width ? width : this.prgProgress.Width
		this.prgProgress.Width := width

		;Resize background picture control to fit whole window
		this.icoBackground.Size := {Width : this.Width, Height : this.Height}
		

		;Draw border:
		
		;Create background brush and pen for border
		pBrushBack := Gdip_BrushCreateSolid(0x00000000)
		pPen := Gdip_CreatePen(Style.Border.Color, Style.Border.Width)
		
		;Create bitmap and graphics
		pBitmap := Gdip_CreateBitmap(this.icoBackground.Width, this.icoBackground.Height)
		G := Gdip_GraphicsFromImage(pBitmap)
		
		;Draw background and border, taking into account the pen width
		Gdip_FillRectangle(G, pBrushBack, 0, 0, this.icoBackground.Width, this.icoBackground.Height)
		Gdip_DrawRoundedRectangle(G, pPen, Style.Border.Width/2, Style.Border.Width/2, this.icoBackground.Width - Style.Border.Width * 2, this.icoBackground.Height - Style.Border.Width * 2, Style.Radius)
		
		;Create HBITMAP and set it to the picture control
		hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
		SetImage(this.icoBackground.hwnd, hBitmap)
		
		;Cleanup
		Gdip_DeletePen(pPen)
		Gdip_DeleteBrush(pBrushBack)
		Gdip_DeleteGraphics(G)
		Gdip_DisposeImage(pBitmap)
		DeleteObject(hBitmap)


		;Set region for rounded windows
		if(Style.Radius)
			this.Region := "0-0 w" this.WindowWidth " h" this.WindowHeight " R" Style.Radius * 2 "-" Style.Radius * 2
		if(this.HasKey("icoIcon"))
			this.icoIcon.Redraw()
		if(this.HasKey("txtTitle"))
			this.txtTitle.Redraw()
		if(this.HasKey("lnkText"))
			this.lnkText.Redraw()
		if(this.HasKey("prgProgress"))
			this.prgProgress.Redraw()
		;Register handlers for all controls
		for index, control in this.Controls
			if(control.Type != "Progress" && control.Type != "Link")
				control.Click.Handler := new Delegate(this, "Click")
	}
	Click()
	{
		this.Close()
		this.OnClick.()
	}
	lnkText_Click(URLOrID, Index)
	{
		this.Close()
		this.OnClick.(URLOrID, Index)
	}
	__Set(Key, Value)
	{
		if(Key = "Progress" && this.HasKey("prgProgress"))
			this.prgProgress.Value := Value
		else if(Key = "Text")
		{
			this.lnkText.Text := Value
			this.lnkText.AutoSize()
		}
		else if(Key = "Title")
		{
			this.txtTitle.Text := Value
			this.txtTitle.AutoSize()
		}
		else
			Ignore := true
		if(!Ignore)
			return Value
	}
}
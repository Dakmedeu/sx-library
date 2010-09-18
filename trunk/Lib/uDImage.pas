// Build: 07/2000-09/2000 Author: Safranek David

unit uDImage;

interface

{$C PRELOAD}
{$R *.RES}
uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	ExtCtrls, StdCtrls,
	uGraph24;

type
	TMouseAction = (mwNone, mwScroll,
		mwScrollH, mwScrollHD, mwScrollHU, mwScrollHD2, mwScrollHU2,
		mwScrollV, mwScrollVD, mwScrollVU, mwScrollVD2, mwScrollVU2);
	TDImage = class(TWinControl)
	private
		{ Private declarations }
		FHotTrack: Boolean;

		FDrawFPS: Boolean;
		FWaitVBlank: Boolean;
		FOnFill: TNotifyEvent;
		FOnPaint: TNotifyEvent;
		FOnMouseEnter: TNotifyEvent;
		FOnMouseLeave: TNotifyEvent;
		MouseX, MouseY: Integer;
		BOfsX, BOfsY: Integer;
		HType, VType: Byte;
		NowMaxWidth, NowMaxHeight: Integer;
		SliderHX1,
		SliderHX2,
		SliderVY1,
		SliderVY2: Integer;
		LTickCount: LongWord;
		FCanvas: TCanvas;
		LCursor: TCursor;

		procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;

		procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
		procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
		procedure WMSize(var Message: TWMSize); message WM_SIZE;

		procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
		procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;

		procedure SetHotTrack(Value: Boolean);
	protected
		{ Protected declarations }
		procedure CreateParams(var Params: TCreateParams); override;

		procedure Paint; virtual;
		procedure PaintWindow(DC: HDC); override;
		property Canvas: TCanvas read FCanvas;
	public
		{ Public declarations }
		MouseL, MouseM, MouseR: Boolean;
		MouseAction: TMouseAction;
		MouseWhere: TMouseAction;
		MouseOn: Boolean;

		Bitmap: TBitmap;
		Bitmap24: TBitmap24;
		ScrollBarHWidth, ScrollBarHHeight,
		ScrollBarVWidth, ScrollBarVHeight: Integer;
		OfsX, OfsY: Integer;
		MaxOfsX, MaxOfsY: Integer;
		BitmapWidth, BitmapHeight: Integer;
		FramePerSec: Extended;
		FHandScroll: Boolean;
		procedure InitScrolls;

		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
		procedure DrawArrow(X1, Y1, X2, Y2: Integer; Down, Hot: Boolean;
			Orient: Integer);
		procedure OffsetRange(var NOfsX, NOfsY: Integer);
		procedure ScrollTo(NOfsX, NOfsY: Integer);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
			X, Y: Integer); override;
		procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
			X, Y: Integer); override;
{		function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
			MousePos: TPoint): Boolean; override;}
		function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
		function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
		procedure Fill; {virtual; }dynamic;
//		procedure Paint; //override;
		function MouseWh(const X, Y: Integer): TMouseAction;
	published
		{ Published declarations }
		property DrawFPS: Boolean read FDrawFPS write FDrawFPS;
		property HandScroll: Boolean read FHandScroll write FHandScroll;
		property HotTrack: Boolean read FHotTrack write SetHotTrack default False;
		property WaitVBlank: Boolean read FWaitVBlank write FWaitVBlank;
		property OnFill: TNotifyEvent read FOnFill write FOnFill;
		property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;

		property Align;
		property Anchors;
		property BiDiMode;
		property Constraints;
		property Ctl3D;
		property DragCursor;
		property DragKind;
		property DragMode;
		property Enabled;
		property ParentBiDiMode;
		property ParentCtl3D;
		property ParentShowHint;
		property PopupMenu;
		property ShowHint;
		property TabOrder;
		property TabStop default True;
		property Visible;
		property OnContextPopup;
		property OnDragDrop;
		property OnDragOver;
		property OnEndDock;
		property OnEndDrag;
		property OnEnter;
		property OnExit;
		property OnMouseDown;
		property OnMouseUp;
		property OnMouseMove;
		property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
		property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
		property OnMouseWheel;
		property OnMouseWheelDown;
		property OnMouseWheelUp;

		property OnKeyDown;
		property OnKeyPress;
		property OnKeyUp;
		property OnStartDock;
		property OnStartDrag;

		property OnDblClick;
	end;

procedure ZoomMake(
	BmpSource: TBitmap;
	VisX, VisY: Integer;
	AsWindow: Boolean; Zoom: Extended; XYConst: Boolean; QualityResize: Boolean;
	OX, OY: Integer;
	var SourceWidth, SourceHeight: Integer;
	var SX1, SY1, SXW, SYH: Integer;
	var DX1, DY1, DXW, DYH: Integer;
	var BmpSource2: TBitmap);

procedure Register;

implementation

uses
	Math,
	uAdd, uGraph;
const
	OfsS = 20; // ms; FPS = 1000 / OfsS; 25-30FPS for VR; 50 = TV
	ScrollEf = ef12;
	ScrollEf2 = ef12;

procedure TDImage.WMPaint(var Message: TWMPaint);
begin
	Paint;
//	DefaultHandler(Message);
	inherited;
end;

procedure TDImage.PaintWindow(DC: HDC);
begin
	FCanvas.Lock;
	try
		FCanvas.Handle := DC;
		try
			TControlCanvas(FCanvas).UpdateTextFlags;
			Paint;
		finally
			FCanvas.Handle := 0;
		end;
	finally
		FCanvas.Unlock;
	end;
end;

procedure TDImage.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
	DefaultHandler(Message);
end;

procedure TDImage.CMDialogKey(var Message: TCMDialogKey);
begin
	Beep;
{	with Message do
		if  (((CharCode = VK_RETURN) and FActive) or
			((CharCode = VK_ESCAPE) and FCancel)) and
			(KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
		begin
			Click;
			Result := 1;
		end else
			inherited;}
end;

procedure TDImage.CMMouseEnter(var Message: TMessage);
begin
	inherited;
	MouseOn := True;
	Fill;
	if Assigned(FOnMouseEnter) then FOnMouseEnter(Self);
end;

procedure TDImage.CMMouseLeave(var Message: TMessage);
begin
	inherited;
	MouseOn := False;
	MouseWhere := mwNone;
	Fill;
//	MouseL := False;
//	MouseM := False;
//	MouseR := False;
	if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);
end;

procedure TDImage.WMSize(var Message: TWMSize);
begin
	inherited;
end;

constructor TDImage.Create(AOwner: TComponent);
begin
	inherited Create(AOwner);
	FCanvas := TControlCanvas.Create;
	TControlCanvas(FCanvas).Control := Self;
	FHotTrack := True;

	Bitmap := TBitmap.Create;
	InitBitmap(Bitmap);
//	ControlStyle := [csDoubleClicks, csOpaque, csAcceptsControls, csMenuEvents, csDisplayDragImage, csReflector];
	ControlStyle := ControlStyle + [csOpaque, csMenuEvents, csDisplayDragImage, csReflector] - [csSetCaption];
	{	Width := 250;
	Height := 150;}
{	Bitmap.Width := Width;
	Bitmap.Height := Height;}
//	ParentColor := False;
//	TabStop := True;
end;

destructor TDImage.Destroy;
begin
	FCanvas.Free;
	Bitmap24.Free; Bitmap24 := nil;
	inherited Destroy;
end;

procedure TDImage.CreateParams(var Params: TCreateParams);
{const
	BorderStyles: array[TBorderStyle] of DWORD = (0, );}
begin
	inherited CreateParams(Params);
	LCursor := Cursor;
	with Params do
	begin
//		Style := Style or WS_BORDER;
		WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
//		ExStyle := ExStyle or WS_EX_CLIENTEDGE;
//		WindowClass.style := WindowClass.style or CS_KEYCVTWINDOW;
		Style := Style or BS_OWNERDRAW;
	end;
end;

function TDImage.MouseWh(const X, Y: Integer): TMouseAction;
begin
	Result := mwScroll;
	if VType <> 0 then
	if X + ScrollBarVWidth > Bitmap.Width  then
	begin // V
		if Y < ScrollBarHHeight then
			Result := mwScrollVD
		else if Y < SliderVY1 then
			Result := mwScrollVD2
		else if Y <= SliderVY2 then
			Result := mwScrollV
		else if Y < ScrollBarVHeight - ScrollBarHHeight then
			Result := mwScrollVU2
		else if Y < ScrollBarVHeight then
			Result := mwScrollVU;
	end;
	if HType <> 0 then
	if Y + ScrollBarHHeight > Bitmap.Height  then
	begin // H
		if X < ScrollBarVWidth then
			Result := mwScrollHD
		else if X < SliderHX1 then
			Result := mwScrollHD2
		else if X <= SliderHX2 then
			Result := mwScrollH
		else if X < ScrollBarHWidth - ScrollBarVWidth then
			Result := mwScrollHU2
		else if X < ScrollBarHWidth then
			Result := mwScrollHU;
	end;
end;

procedure TDImage.OffsetRange(var NOfsX, NOfsY: Integer);
begin
	if NOfsX > BitmapWidth - NowMaxWidth then
		NOfsX := BitmapWidth - NowMaxWidth;
	if NOfsX < 0 then
		NOfsX := 0;

	if NOfsY > BitmapHeight - NowMaxHeight then
		NOfsY := BitmapHeight - NowMaxHeight;
	if NOfsY < 0 then
		NOfsY := 0;
end;

procedure TDImage.ScrollTo(NOfsX, NOfsY: Integer);
begin
	OffsetRange(NOfsX, NOfsY);
	if (OfsX <> NOfsX) or (OfsY <> NOfsY) then
	begin
		OfsX := NOfsX;
		OfsY := NOfsY;
		Fill;
	end;
end;

procedure TDImage.MouseDown(Button: TMouseButton; Shift: TShiftState;
	X, Y: Integer);
const
	Speed1 = 65536 div 8; // Pixels / ms (x65536)
	StepInt = 500;
var
	Speed: Int64;
	TimeO, LastTickCount, FrameTickCount: LongWord;
	Cycle: Cardinal;
	NOfsX, NOfsY: Integer;
	MouseA: TMouseAction;
begin
	SetFocus;
	case Button of
	mbLeft:
	begin
		MouseL := True;
		MouseA := MouseWh(X, Y);
		case MouseA of
		mwScrollH:
		begin
			MouseAction := mwScrollH;
			MouseX := X;
			BOfsX := OfsX;
//			inherited MouseDown(Button, Shift, X, Y);
		end;
		mwScrollV:
		begin
			MouseAction := mwScrollV;
			MouseY := Y;
			BOfsY := OfsY;
//			inherited MouseDown(Button, Shift, X, Y);
		end;
		mwScrollHD, mwScrollHU,
		mwScrollVD, mwScrollVU,
		mwScrollHD2, mwScrollHU2,
		mwScrollVD2, mwScrollVU2:
		begin
			MouseAction := MouseA;
			LastTickCount := GetTickCount;
			case MouseA of
{     mwScrollHD, mwScrollHU,
			mwScrollVD, mwScrollVU: Speed := Speed1;}
			mwScrollHD2, mwScrollHU2: Speed := 64 * Int64(MaxOfsX);
			mwScrollVD2, mwScrollVU2: Speed := 64 * Int64(MaxOfsY);
			else Speed := Speed1;
			end;
			if Speed = 0 then Speed := 1;

			TimeO := 10; // ms
			NOfsX := RoundDiv64(65536 * Int64(OfsX), Speed);
			NOfsY := RoundDiv64(65536 * Int64(OfsY), Speed);
{     case MouseW of
			mwScrollHD, mwScrollHU,
			mwScrollHD2, mwScrollHU2:
			begin
			else
			begin
			end;}
//      MouseW := mdScrollB;
//			inherited MouseDown(Button, Shift, X, Y);
			Cycle := 0;
			FrameTickCount := 0;
			while MouseAction <> mwNone do
			begin
				case MouseA of
				mwScrollHD, mwScrollHD2: Dec(NOfsX, TimeO);
				mwScrollHU, mwScrollHU2: Inc(NOfsX, TimeO);
				mwScrollVD, mwScrollVD2: Dec(NOfsY, TimeO);
				mwScrollVU, mwScrollVU2: Inc(NOfsY, TimeO);
				end;
				ScrollTo(RoundDiv64(Int64(Speed) * Int64(NOfsX), 65536),
					RoundDiv64(Int64(Speed) * Int64(NOfsY), 65536));
//        Application.HandleMessage; no
				Application.ProcessMessages;
				TimeO := GetTickCount - LastTickCount;
				if TimeO < OfsS then
				begin
					Sleep(OfsS - TimeO);
					TimeO := OfsS;
				end;
				Inc(LastTickCount, TimeO);
				Inc(Cycle);
				if LastTickCount >= FrameTickCount then
				begin
					FramePerSec := 1000 * Cycle / (LastTickCount - FrameTickCount + StepInt);
					FrameTickCount := LastTickCount + StepInt;
					Cycle := 0;
				end;
			end;
			MouseAction := MouseA;
			MouseAction := mwNone;
			FramePerSec := 0;
		end;
		mwScroll:
		begin
			if ((MaxOfsX > 0) or (MaxOfsY > 0)) and (HandScroll or (ssShift in Shift)) then
			begin
				Screen.Cursor := 2;
				MouseAction := mwScroll;
				MouseX := OfsX + X;
				MouseY := OfsY + Y;
			end
			else
			begin
				MouseAction := mwNone;
//				inherited MouseDown(Button, Shift, X, Y);
			end;
		end;
		end;
	end;
	mbRight: MouseR := True;
	mbMiddle: MouseM := True;
	end;

	inherited MouseDown(Button, Shift, X, Y);
end;

procedure TDImage.MouseMove(Shift: TShiftState; X, Y: Integer);
var
	NOfsX, NOfsY: Integer;
	TickCount: LongWord;
	Sc: Boolean;
	MouseW: TMouseAction;
	Cur: TCursor;
begin
	MouseW := MouseWh(X, Y);
	case MouseW of
	mwScrollH, mwScrollV,
	mwScrollHD, mwScrollHU,
	mwScrollVD, mwScrollVU,
	mwScrollHD2, mwScrollHU2,
	mwScrollVD2, mwScrollVU2:
	begin
		Sc := False;
		if Cursor <> crArrow then
			Cursor := crArrow;
	end
	else
	begin
		Sc := (HandScroll or (ssShift in Shift)) and ((BitmapWidth - NowMaxWidth > 0) or (BitmapHeight - NowMaxHeight > 0));
		if Sc then
			Cur := 1 + SG(MouseL)
		else
			Cur := LCursor;
		if Cursor <> Cur then
			Cursor := Cur;
	end;
	end;

	if MouseWhere <> MouseW then
	begin
		MouseWhere := MouseW;
		Fill;
	end;

	NOfsX := OfsX;
	NOfsY := OfsY;
	case MouseAction of
	mwScroll:
	begin
		if Sc then
		begin
			NOfsX := MouseX - X;
			NOfsY := MouseY - Y;
		end;
	end;
	mwScrollH:
	begin
		NOfsX := BOfsX + RoundDiv64(BitmapWidth * Int64(X - MouseX), NowMaxWidth - 2 * ScrollBarHHeight);
		NOfsY := OfsY;
	end;
	mwScrollV:
	begin
		NOfsX := OfsX;
		NOfsY := BOfsY + RoundDiv64(BitmapHeight * Int64(Y - MouseY), NowMaxHeight - 2 * ScrollBarVWidth);
	end;
	end;
	TickCount := GetTickCount;
	if TickCount < LTickCount + OfsS then
	begin
		Sleep(LTickCount + OfsS - TickCount);
		TickCount := LTickCount + OfsS;
	end;
	LTickCount := TickCount;
	ScrollTo(NOfsX, NOfsY);
//  if (MouseW = mwNone){ or (MouseW = mwScroll)} then
	inherited MouseMove(Shift, X, Y);
end;

procedure TDImage.MouseUp(Button: TMouseButton; Shift: TShiftState;
	X, Y: Integer);
begin
	Screen.Cursor := crDefault;
	case Button of
	mbLeft:
	begin
		MouseL := False;
		case MouseAction of
		mwScrollHD, mwScrollHU,
		mwScrollVD, mwScrollVU,
		mwScrollHD2, mwScrollHU2,
		mwScrollVD2, mwScrollVU2:
		begin
			MouseAction := mwNone;
			Fill;
		end;
		mwScroll:
		begin
			MouseAction := mwNone;
			if (HandScroll or (ssShift in Shift)) and ((BitmapWidth - NowMaxWidth > 0) or (BitmapHeight - NowMaxHeight > 0)) then
				Cursor := 1
			else
				Cursor := LCursor;
		end
		else
		begin
			MouseAction := mwNone;
		end;
		end;
	end;
	mbRight: MouseR := False;
	mbMiddle: MouseM := False;
	end;
	inherited MouseUp(Button, Shift, X, Y);
end;
{
function TDImage.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
	MousePos: TPoint): Boolean;
begin
	Result := False;
	inherited DoMouseWheel(Shift, WheelDelta, MousePos);
	ScrollTo(OfsX, OfsY + WheelDelta);
end;}


function TDImage.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
	inherited DoMouseWheelDown(Shift, MousePos);
	ScrollTo(OfsX, OfsY + RoundDiv64(MaxOfsY, 32));
	Result := False;
end;

function TDImage.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
	inherited DoMouseWheelUp(Shift, MousePos);
	ScrollTo(OfsX, OfsY - RoundDiv64(MaxOfsY, 32));
	Result := False;
end;

procedure TDImage.InitScrolls;
begin
	ScrollBarVWidth := GetSystemMetrics(SM_CXVSCROLL);

	if BitmapWidth > Bitmap.Width then
		HType := 1
	else if BitmapWidth > Bitmap.Width - ScrollBarVWidth then
		HType := 2
	else
		HType := 0;

	ScrollBarHHeight := GetSystemMetrics(SM_CYHSCROLL);
	if BitmapHeight > Bitmap.Height then
	begin
		VType := 1;
		if HType = 2 then HType := 1;
	end
	else if BitmapHeight > Bitmap.Height - ScrollBarHHeight then
	begin
		case HType of
		0:
			VType := 0;
		2:
		begin
			VType := 0;
			HType := 0;
		end;
		else
			VType := 1;
		end;
	end
	else
	begin
		VType := 0;
		if HType = 2 then HType := 0;
	end;

	NowMaxWidth := Bitmap.Width - ScrollBarVWidth * VType;
	NowMaxHeight := Bitmap.Height - ScrollBarHHeight * HType;
	MaxOfsX := BitmapWidth - NowMaxWidth;
	MaxOfsY := BitmapHeight - NowMaxHeight;
	OffsetRange(OfsX, OfsY);
end;

procedure TDImage.DrawArrow(X1, Y1, X2, Y2: Integer; Down, Hot: Boolean;
	Orient: Integer);
var
	C1, C2: Integer;
	i: Integer;
	XM, HX1, HY1, HX2, HY2, H, Len: Integer;
begin
	if Down then
	begin
		C1 := 1;
		C2 := 2;
	end
	else
	begin
		C1 := 3;
		C2 := 0;
	end;
	Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(C1), DepthColor(C2), 1, ScrollEf);
	if FHotTrack and Hot then C1 := clHighlight else C1 := clBtnFace;
	Bar24(Bitmap24, clNone, X1 + 1 , Y1 + 1, X2 - 1, Y2 - 1, C1, ScrollEf);

	if Down then
	begin
		Inc(X1);
		Inc(X2);
		Inc(Y1);
		Inc(Y2);
	end;
	XM := X1 + X2;
	Len := X2 - X1 + 1;
	for i := 0 to Len div 3 - 1 do
	begin
		HX1 := (XM - 2 * i) div 2;
		HY1 := Y1 + i + (Len + 2) div 3;
		HX2 :=  (XM + 2 * i + 1) div 2;
		HY2 := Y1 + i + (Len + 2) div 3;
		case Orient of
		1:
		begin
			H := HX1;
			HX1 := (HY1 - Y1) + X1;
			HY1 := (H - X1) + Y1;
			H := HX2;
			HX2 := (HY2 - Y1) + X1;
			HY2 := (H - X1) + Y1;
		end;
		2:
		begin
			HY1 := Y2 - (HY1 - Y1);
			HY2 := Y2 - (HY2 - Y1);
		end;
		3:
		begin
			H := HX1;
			HX1 := X2 - (HY1 - Y1);
			HY1 := (H - X1) + Y1;
			H := HX2;
			HX2 := X2 - (HY2 - Y1);
			HY2 := (H - X1) + Y1;
		end;
		end;

		Lin24(Bitmap24, HX1, HY1, HX2, HY2, clBtnText, ef16);
	end;
end;

procedure TDImage.Fill;
var
	ScrollLen, ScrollLenS: Integer;
	X1, Y1, X2, Y2: Integer;
	C: TColor;
	SliderC1, SliderC2: TColor;
begin
	Bitmap.Width := Width;
	Bitmap.Height := Height;

	Bitmap24 := Conv24(Bitmap);
	try
		if Assigned(FOnFill) then FOnFill(Self);
		InitScrolls;

		SliderC1 := DarkerColor(clScrollBar);
		SliderC2 := LighterColor(clScrollBar);
		// H
		if (BitmapWidth > 0) and (HType = 1) then
		begin
			ScrollBarHWidth := NowMaxWidth;
			Y1 := Integer(Bitmap24.Height) - ScrollBarHHeight;
			Y2 := Bitmap24.Height - 1;

			X1 := 0;
			X2 := ScrollBarVWidth - 1;
	{   Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			Bar24(Bitmap24, clNone, X1 + 1 , Y1 + 1, X2 - 1, Y2 - 1, clBtnFace, ScrollEf);}
			DrawArrow(X1, Y1, X2, Y2, MouseAction = mwScrollHD, MouseWhere = mwScrollHD, 1);

			X1 := NowMaxWidth - ScrollBarVWidth;
			X2 := NowMaxWidth - 1;
	{   Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			Bar24(Bitmap24, clNone, X1 + 1 , Y1 + 1, X2 - 1, Y2 - 1, clBtnFace, ScrollEf);}
			DrawArrow(X1, Y1, X2, Y2, MouseAction = mwScrollHU, MouseWhere = mwScrollHU, 3);

			// TScrollBoxSlider
			ScrollLen := NowMaxWidth - 2 * ScrollBarVWidth;
			ScrollLenS := NowMaxWidth * ScrollLen div BitmapWidth;
			if ScrollLenS < ScrollBarHHeight div 2 then ScrollLenS := ScrollBarHHeight div 2;

			Y1 := Integer(Bitmap24.Height) - ScrollBarHHeight;
			Y2 := Bitmap24.Height - 1;
			X1 := ScrollBarVWidth + RoundDiv64(Int64(ScrollLen - ScrollLenS) * OfsX, BitmapWidth - NowMaxWidth);
			X2 := X1 + ScrollLenS - 1;
			SliderHX1 := X1;
			SliderHX2 := X2;

			Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			if FHotTrack and (MouseWhere = mwScrollH) then C := clHighlight else C := clBtnFace;
			Bar24(Bitmap24, clNone, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, C, ScrollEf);

			// =
			X1 := ScrollBarVWidth;
			X2 := SliderHX1 - 1;
			Y1 := Integer(Bitmap24.Height) - ScrollBarHHeight;
			Y2 := Bitmap24.Height - 1;

			if X2 >= X1 then
			begin
				if (MouseAction <> mwScrollHD2) then
					C := clScrollBar
				else
					C := clHighlight;
				Lin24(Bitmap24, X1, Y1, X2, Y1, SliderC1, ScrollEf2);
				Lin24(Bitmap24, X1, Y2, X2, Y2, SliderC2, ScrollEf2);
				Bar24(Bitmap24, clNone,
					X1, Y1 + 1,
					X2, Y2 - 1, C, ScrollEf2);
			end;

			X1 := SliderHX2 + 1;
			X2 := NowMaxWidth - ScrollBarVWidth - 1;
			Y1 := Integer(Bitmap24.Height) - ScrollBarHHeight;
			Y2 := Bitmap24.Height - 1;

			if X2 >= X1 then
			begin
				if (MouseAction <> mwScrollHU2) then
					C := clScrollBar
				else
					C := clHighlight;
				Lin24(Bitmap24, X1, Y1, X2, Y1, SliderC1, ScrollEf2);
				Lin24(Bitmap24, X1, Y2, X2, Y2, SliderC2, ScrollEf2);
				Bar24(Bitmap24, clNone,
					X1, Y1 + 1,
					X2, Y2 - 1, C, ScrollEf2);
			end;
		end
		else
			ScrollBarHWidth := 0;

		// V
		if (BitmapHeight > 0) and (VType = 1) then
		begin
			ScrollBarVHeight := NowMaxHeight;
			X1 := Integer(Bitmap24.Width) - ScrollBarVWidth;
			X2 := Bitmap24.Width - 1;

			Y1 := 0;
			Y2 := ScrollBarHHeight - 1;
	{   Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			Bar24(Bitmap24, clNone, X1 + 1 , Y1 + 1, X2 - 1, Y2 - 1, clBtnFace, ScrollEf);}
			DrawArrow(X1, Y1, X2, Y2, MouseAction = mwScrollVD, MouseWhere = mwScrollVD, 0);

			Y1 := NowMaxHeight - ScrollBarHHeight;
			Y2 := NowMaxHeight - 1;
	{   Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			Bar24(Bitmap24, clNone, X1 + 1 , Y1 + 1, X2 - 1, Y2 - 1, clBtnFace, ScrollEf);}
			DrawArrow(X1, Y1, X2, Y2, MouseAction = mwScrollVU, MouseWhere = mwScrollVU, 2);

			// TScrollBoxSlider
			ScrollLen := NowMaxHeight - 2 * ScrollBarHHeight;
			ScrollLenS := NowMaxHeight * ScrollLen div BitmapHeight;
			if ScrollLenS < ScrollBarVWidth div 2 then ScrollLenS := ScrollBarVWidth div 2;

			X1 := Integer(Bitmap24.Width) - ScrollBarVWidth;
			X2 := Bitmap24.Width - 1;
			Y1 := ScrollBarHHeight + (ScrollLen - ScrollLenS) * Int64(OfsY) div (BitmapHeight - NowMaxHeight);
			Y2 := Y1 + ScrollLenS - 1;
			SliderVY1 := Y1;
			SliderVY2 := Y2;

			Border24(Bitmap24, X1, Y1, X2, Y2, DepthColor(3), DepthColor(0), 1, ScrollEf);
			if FHotTrack and (MouseWhere = mwScrollV) then C := clHighlight else C := clBtnFace;
			Bar24(Bitmap24, clNone, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, C, ScrollEf);

			// ||
			Y1 := ScrollBarHHeight;
			Y2 := SliderVY1 - 1;
			X1 := Integer(Bitmap24.Width) - ScrollBarVWidth;
			X2 := Bitmap24.Width - 1;

			if Y2 >= Y1 then
			begin
				if (MouseAction <> mwScrollVD2) then
					C := clScrollBar
				else
					C := clHighlight;
				Lin24(Bitmap24, X1, Y1, X1, Y2, SliderC1, ScrollEf2);
				Lin24(Bitmap24, X2, Y1, X2, Y2, SliderC2, ScrollEf2);
				Bar24(Bitmap24, clNone,
					X1 + 1, Y1,
					X2 - 1, Y2, C, ScrollEf2);
			end;

			Y1 := SliderVY2 + 1;
			Y2 := NowMaxHeight - ScrollBarHHeight - 1;
			X1 := Integer(Bitmap24.Width) - ScrollBarVWidth;
			X2 := Bitmap24.Width - 1;

			if Y2 >= Y1 then
			begin
				if (MouseAction <> mwScrollVU2) then
					C := clScrollBar
				else
					C := clHighlight;
				Lin24(Bitmap24, X1, Y1, X1, Y2, SliderC1, ScrollEf2);
				Lin24(Bitmap24, X2, Y1, X2, Y2, SliderC2, ScrollEf2);
				Bar24(Bitmap24, clNone,
					X1 + 1, Y1,
					X2 - 1, Y2, C, ScrollEf2);
			end;
		end
		else
			ScrollBarVHeight := 0;

//    Pix24(Bitmap24.PData, Bitmap24.ByteX, MouseX, MouseY, clWhite, ef16);
		if FDrawFPS then
			if FramePerSec >= 0.1 then
			begin
				ShadowText(Bitmap.Canvas, 0, 0,
					Using('~### ##0.0', Round(10 * FramePerSec)),
					clWindowText, clNone);
			end;
	finally
		Bitmap24.Free; Bitmap24 := nil;
		Paint;
	end;
end;

procedure TDImage.Paint;
begin
	if Bitmap.Empty then
	begin
		FCanvas.Brush.Style := bsSolid;
		FCanvas.Brush.Color := clAppWorkSpace;
		PatBlt(
			FCanvas.Handle,
			0,
			0,
			Width,
			Height,
			PATCOPY
		 );
	end
	else
	begin
		SetStretchBltMode(FCanvas.Handle, STRETCH_DELETESCANS);
		if WaitVBlank then WaitRetrace;
		BitBlt(
			FCanvas.Handle,
			0, //Left,
			0, //Top,
			Width,
			Height,
			Bitmap.Canvas.Handle,
			0,
			0,
			SRCCOPY
		 );
	end;
	if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure ZoomMake(
	BmpSource: TBitmap;
	VisX, VisY: Integer;
	AsWindow: Boolean; Zoom: Extended; XYConst: Boolean; QualityResize: Boolean;
	OX, OY: Integer;
	var SourceWidth, SourceHeight: Integer;
	var SX1, SY1, SXW, SYH: Integer;
	var DX1, DY1, DXW, DYH: Integer;
	var BmpSource2: TBitmap);

var
	SX, SY: Integer;
	BmpDe, BS: TBitmap24;
	LastCursor: TCursor;
begin
	if AsWindow then
	begin
		if XYConst = False then
		begin
			SX := VisX;
			SY := VisY;
		end
		else
		begin
			if VisY * BmpSource.Width >=
				VisX * BmpSource.Height then
			begin
				SX := VisX;
				SY := RoundDiv(VisX * BmpSource.Height,
					BmpSource.Width);
			end
			else
			begin
				SX := RoundDiv(VisY * BmpSource.Width,
					BmpSource.Height);
				SY := VisY;
			end;
		end;

		SX1 := 0;
		SY1 := 0;
		SXW := BmpSource.Width;
		SYH := BmpSource.Height;

		DX1 := 0;
		DY1 := 0;
		DXW := SX;
		DYH := SY;
{   ZoomedWidth := BmpSource.Width;
		ZoomedHeight := BmpSource.Height;}

		SourceWidth := SX;
		SourceHeight := SY;
	end
	else
	begin
		SX := Round(Zoom * BmpSource.Width);
		SY := Round(Zoom * BmpSource.Height);

		SourceWidth := SX;
		SourceHeight := SY;

{   if SX > VisX then SX := VisX;
		if SY > VisY then SY := VisY;}
		if Zoom <= 1 then
		begin
			DX1 := 0;
			DY1 := 0;
		end
		else
		begin
			DX1 := -Round(Zoom * Frac(OX / Zoom));
			DY1 := -Round(Zoom * Frac(OY / Zoom));
		end;

		if Zoom <= 1 then
		begin
			SX1 := OX;
			SY1 := OY;
		end
		else
		begin
			SX1 := Trunc(OX / Zoom);
			SY1 := Trunc(OY / Zoom);
		end;
		SXW := Ceil(VisX / Zoom - DX1);
		SYH := Ceil(VisY / Zoom - DY1);
{   if (DX1 < 0) then
		begin
			Inc(SXW);
		end;
		if (DY1 < 0) then
		begin
			Inc(SYH);
		end;}


		DXW := Round(Zoom * SXW);
		DYH := Round(Zoom * SYH);
	end;

	if (SourceWidth < BmpSource.Width) or (SourceHeight < BmpSource.Height) then
	begin
		if not Assigned(BmpSource2) then
		begin
			BmpSource2 := TBitmap.Create;
			BmpSource2.PixelFormat := pf24bit;
		end;
		if (BmpSource2.Width <> SourceWidth)
		or (BmpSource2.Height <> SourceHeight) then
		begin
			BmpSource2.Width := SourceWidth;
			BmpSource2.Height := SourceHeight;
			if (QualityResize = False) {or (Zoom > 1)} then
			begin

				SetStretchBltMode(BmpSource2.Canvas.Handle, COLORONCOLOR);
				StretchBlt(BmpSource2.Canvas.Handle,
					0, 0,
					BmpSource2.Width, BmpSource2.Height,
					BmpSource.Canvas.Handle,
					0, 0,
					BmpSource.Width, BmpSource.Height,
					SRCCOPY);
	{     BmpSource2.Canvas.StretchDraw(Rect(0, 0,
					BmpSource2.Width, BmpSource2.Height), BmpSource);}
			end
			else
			begin
				LastCursor := Screen.Cursor;
				Screen.Cursor := crHourGlass;
				BmpDe := Conv24(BmpSource2);
				BS := Conv24(BmpSource);
				Resize24(BmpDe, BS,
					SourceWidth, SourceHeight, nil);
				BS.Free;
				BmpDe.Free;
				Screen.Cursor := LastCursor;
			end;
		end;
		SXW := DXW;
		SYH := DYH;
	end
	else
	begin
		if Assigned(BmpSource2) then
		begin
			BmpSource2.Free; BmpSource2 := nil;
		end;
	end;
end;

procedure TDImage.SetHotTrack(Value: Boolean);
begin
	if FHotTrack <> Value then
	begin
		FHotTrack := Value;
		Fill;
	end;
end;

procedure Register;
begin
	RegisterComponents('DComp', [TDImage]);
end;

initialization
	Screen.Cursors[1] := LoadCursor(HInstance, PChar('HANDPOINT'));
	Screen.Cursors[2] := LoadCursor(HInstance, PChar('HANDPOINTDOWN'));
end.
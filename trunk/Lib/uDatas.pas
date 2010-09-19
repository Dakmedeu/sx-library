//* File:     Lib\uData.pas
//* Created:  2006-12-26
//* Modified: 2006-12-26
//* Version:  X.X.35.X
//* Author:   Safranek David (Safrad)
//* E-Mail:   safrad at email.cz
//* Web:      http://safrad.webzdarma.cz

unit uDatas;

interface

uses uTypes, uData;

type
	TDatas = class(TData)
	private
		FIndex: SG;
		FItemAddr: Pointer;
		procedure SetIndex(const Value: SG);
	public
		constructor Create;
		procedure BeginUpdate;
		procedure EndUpdate;
		property ItemAddr: Pointer read FItemAddr write FItemAddr;
		property Index: SG read FIndex write SetIndex;
	end;

implementation

{ TDatas }

constructor TDatas.Create;
begin
	inherited;
	FIndex := 0;
end;

procedure TDatas.SetIndex(const Value: SG);
begin
	if FIndex <> Value then
	begin
		BeginUpdate;
		FIndex := Value;
		EndUpdate;
	end;
end;

procedure TDatas.BeginUpdate;
begin
	if (ItemAddr <> nil) and (ItemSize <> 0) then
		if (FIndex >= 0) and (FIndex < Count) then
			Move(ItemAddr^, Pointer(UG(GetFirst) + UG(FIndex) * ItemMemSize)^, ItemSize);
end;

procedure TDatas.EndUpdate;
begin
	if (ItemAddr <> nil) and (ItemSize <> 0) then
		if (FIndex >= 0) and (FIndex < Count) then
			Move(Pointer(UG(GetFirst) + UG(FIndex) * ItemMemSize)^, ItemAddr^, ItemSize)
		else
			FillChar(ItemAddr^, ItemSize, 0);
end;

end.


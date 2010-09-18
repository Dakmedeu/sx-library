unit uMapInfo;

interface

type
	TFlo = Single;
	TPoint = record
		X, Y: TFlo;
	end;

	TFieldM = record
		Point: TPoint;
		Kod: LongInt; { Decimal(7, 0)}
		Nazev: string[30];
		PSC: string[10];
		Typ: LongInt;{Decimal(3, 0)}
		Prior: LongInt; {Decimal(5, 0)}
		GNazev: string[30];
		Vojvod: string[5];
		Reserved: array[0..23] of Byte;
	end;

var
	FieldsM: array of TFieldM;
	FieldMCount: Integer;

	CharKind: array[Char] of (ckOthers, ckNum, ckDecimalSeparator, ckDelimeter);

procedure ReadMidMif(const MiName: string);
procedure WriteMid(const MiName: string);

implementation

uses
	SysUtils, Windows,
	uAdd, uFiles, uStrings;

const
	Delimiter = ',';

function GetNextFloat(Line: string; var InLineIndex: Integer): TFlo;
var
	NumStart: Integer;
	LastDecimalSeparator: Char;
begin
	while (InLineIndex <= Length(Line)) and (CharKind[Line[InLineIndex]] <> ckNum) do
		Inc(InLineIndex);
	NumStart := InLineIndex;
	Inc(InLineIndex);
	while (InLineIndex <= Length(Line)) and ((CharKind[Line[InLineIndex]] = ckNum) or
	(CharKind[Line[InLineIndex]] = ckDecimalSeparator)) do
		Inc(InLineIndex);

	LastDecimalSeparator := DecimalSeparator;
	DecimalSeparator := '.';
	Result := StrToFloat(Copy(Line, NumStart, InLineIndex - NumStart));
	DecimalSeparator := LastDecimalSeparator;
end;

procedure ReadMidMif(const MiName: string);
label LRetry;
var
	FIn: TFile;
	DBFileName: TFileName;
	Line: string;
	InLineIndex: Integer;
	NewSize: Integer;
	FileIndex: Integer;
	WhereMif: (wmNone, wmType, wmData);
	Po: Integer;
	FieldMIndex: Integer;
begin
	FIn := TFile.Create;
	FileIndex := 0;
	FieldMCount := 0; SetLength(FieldsM, 0);
	while FileIndex <= 1 do
	begin
		if FileIndex = 0 then
			DBFileName := DataDir + MiName + '.mif'
		else
			DBFileName := DataDir + MiName + '.mid';
		LRetry:
		if FIn.Open(DbFileName, fmReadOnly, FILE_FLAG_SEQUENTIAL_SCAN, False) then
		begin
			FieldMIndex := 0;
			WhereMif := wmNone;
			while not FIn.Eof do
			begin
				FIn.Readln(Line);
				InLineIndex := 1;
				if Line = '' then Continue;
				if Line[1] = ';' then Continue;
				if FileIndex and 1 = 0 then
				begin // MIF
					case WhereMif of
					wmNone:
					begin
						Po := Pos('Columns', Line);
						if Po = 1 then
						begin
							WhereMif := wmType;
{             InLineIndex := Po + 7;
							FormatCount := GetNextInt(Line, InLineIndex);
							SetLength(Formats, FormatCount);
							FormatIndex := 0;}
						end;
					end;
					wmType:
					begin
						if Pos('Data', Line) = 1 then
						begin
							WhereMif := wmData;
						end;
					end;
					wmData:
					begin
						Po := Pos('Point', Line);
						if Po <> 0 then
						begin
							NewSize := FieldMCount + 1;
							if AllocByEx(Length(FieldsM), NewSize, SizeOf(FieldsM[0])) then
								SetLength(FieldsM, NewSize);
							FieldsM[FieldMCount].Point.X := GetNextFloat(Line, InLineIndex);
							FieldsM[FieldMCount].Point.Y := GetNextFloat(Line, InLineIndex);

							Inc(FieldMCount);
						end;
					end;
					end;
				end
				else
				begin
					FieldsM[FieldMIndex].Kod := StrToInt(ReadToChar(Line, InLineIndex, Delimiter));

					FieldsM[FieldMIndex].Nazev := DelQuoteF(ReadToChar(Line, InLineIndex, Delimiter));

					FieldsM[FieldMIndex].PSC := DelCharsF(DelCharsF(DelQuoteF(ReadToChar(Line, InLineIndex, Delimiter)), '-'), ' ');
					if (Length(FieldsM[FieldMIndex].PSC) <> 0) then
						SetLength(FieldsM[FieldMIndex].PSC, 5);
					FieldsM[FieldMIndex].Typ := StrToInt(ReadToChar(Line, InLineIndex, Delimiter));
					FieldsM[FieldMIndex].Prior := StrToInt(ReadToChar(Line, InLineIndex, Delimiter));

					FieldsM[FieldMIndex].GNazev := DelQuoteF(ReadToChar(Line, InLineIndex, Delimiter));
					FieldsM[FieldMIndex].Vojvod := DelQuoteF(ReadToChar(Line, InLineIndex, Delimiter));


(*					s := ReadToChar(Line, InLineIndex, Delimiter);
					DelQuote(s);
					FieldsM[FieldMIndex].NazevCo := s;

					s := ReadToChar(Line, InLineIndex, Delimiter);
					DelQuote(s);
					FieldsM[FieldMIndex].NazevObc := s;
					ReadToChar(Line, InLineIndex, Delimiter);
					ReadToChar(Line, InLineIndex, Delimiter);
					ReadToChar(Line, InLineIndex, Delimiter);

					s := ReadToChar(Line, InLineIndex, Delimiter);
					DelQuote(s);
					FieldsM[FieldMIndex].PSC99 := s;*)

//          FieldsM[FieldMIndex].KodObc := StrToInt(ReadToChar(Line, InLineIndex, Delimiter));}
					Inc(FieldMIndex);
	//        Inc(LineIndex);
				end;
			end;
			FIn.Close;
		end;
		Inc(FileIndex);
	end;
	FIn.Free;
end;

procedure WriteMid(const MiName: string);
label LRetry;
var
	FIn: TFile;
	DBFileName: TFileName;
	FieldMIndex: Integer;
begin
	FIn := TFile.Create;
	DBFileName := DataDir + MiName + '.mid';
	LRetry:
	if FIn.Open(DbFileName, fmWriteOnly, FILE_FLAG_SEQUENTIAL_SCAN, False) then
	begin
		for FieldMIndex := 0 to FieldMCount - 1 do
		begin
			FIn.Writeln(
				IntToStr(FieldsM[FieldMIndex].Kod) + ',' +
				'"' + FieldsM[FieldMIndex].Nazev + '",' +
				'"' + FieldsM[FieldMIndex].PSC + '",' +
				IntToStr(FieldsM[FieldMIndex].Typ) + ',' +
				IntToStr(FieldsM[FieldMIndex].Prior) + ',' +
				'"' + FieldsM[FieldMIndex].GNazev + '",' +
				'"' + FieldsM[FieldMIndex].Vojvod + '"');
		end;
		FIn.Truncate;
		FIn.Close;
	end;
	FIn.Free;
end;

procedure FillData;
var c: Char;
begin
	for c := Low(c) to High(c) do
		case c of
		'0'..'9': CharKind[c] := ckNum;
		'.': CharKind[c] := ckDecimalSeparator;
		Delimiter: CharKind[c] := ckDelimeter;
		else CharKind[c] := ckOthers;
		end;
end;

initialization
	FillData;
end.
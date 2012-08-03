unit uBackup;

interface

uses SysUtils;

type
  TBackupFolder = (
  	bfSame, // *
    bfSub, // *
    bfSubEx, // preferred
    bfTemp); // preferred

// * Backuping 'data.txt' (delete mask '~data*.txt' can delete backups of i.e. 'data2.txt'

procedure BackupFile(const FileName: TFileName; const BackupFolder: TBackupFolder);

implementation

uses uFiles, uDelete;

procedure BackupFile(const FileName: TFileName; const BackupFolder: TBackupFolder);
var
  BackupPath: string;
  OriginalFileName: string;
	FileNameD: TFileName;
  DeleteOptions: TDeleteOptions;
begin
	if FileExists(FileName) = False then Exit;
  case BackupFolder of
  bfSame: BackupPath := DelFileName(FileName);
  bfSub: BackupPath := DelFileName(FileName) + '~backup\';
  bfSubEx: BackupPath := DelFileName(FileName) + '~backup\' + ExtractFileName(FileName) + '\';
  bfTemp: BackupPath := TempDir;
  end;
  OriginalFileName := ExtractFileName(FileName);
  if BackupFolder = bfSame then
	  OriginalFileName := '~' + OriginalFileName;

	if DirectoryExists(BackupPath) = False then
		CreateDirEx(BackupPath);
	FileNameD := BackupPath + OriginalFileName;
	if NewFileOrDirEx(string(FileNameD)) then
		uFiles.CopyFile(FileName, FileNameD, True);

  // Delete old
  if BackupFolder = bfSubEx then
    DeleteOptions.Mask := '*.*'
  else
    DeleteOptions.Mask := DelFileExt(OriginalFileName) + '*' + ExtractFileExt(OriginalFileName);
  DeleteOptions.MaxDirs := 100;
  DeleteOptions.SelectionType := stDifference;
  DeleteOptions.AcceptFiles := True;
  DeleteOptions.Test := False;
  SxDeleteDirs(BackupPath, DeleteOptions);
end;

end.

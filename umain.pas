unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, Forms, Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, Spin, ExtCtrls, IniPropStorage, Menus, DateUtils,
  LCLIntf, MMSystem, Windows, Clipbrd, LCLVersion, MD5;

type

  { TfMain }

  TfMain = class(TForm)
    chSound: TCheckBox;
    chTaskbarIcon: TCheckBox;
    chBuzz: TCheckBox;
    chIcons: TCheckBox;
    chTaskbarMessage: TCheckBox;
    chTaskbarIconAlarm: TCheckBox;
    chTaskbarTime: TCheckBox;
    chToolbar: TCheckBox;
    edFileOpen: TEdit;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    chFileOpen: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    laChecksum: TLabel;
    laComputer: TLabel;
    laFPC: TLabel;
    laLazarus: TLabel;
    chMessageTime: TCheckBox;
    laTarget: TLabel;
    laUsername: TLabel;
    laVersion: TLabel;
    lbApplication: TLabel;
    lvAlarms: TListView;
    meHistory: TMemo;
    miRemoveHours: TMenuItem;
    miAddHours: TMenuItem;
    mi2: TMenuItem;
    mi3: TMenuItem;
    miAdd: TMenuItem;
    miDelete: TMenuItem;
    miEdit: TMenuItem;
    miPurge: TMenuItem;
    miQuit: TMenuItem;
    miRestart: TMenuItem;
    miSetInactive: TMenuItem;
    miTest: TMenuItem;
    OpenDialog1: TOpenDialog;
    pcMain: TPageControl;
    pmAlarms: TPopupMenu;
    buFileSelect: TButton;
    seMessageTime: TSpinEdit;
    Shape1: TShape;
    chTaskbarShorttime: TCheckBox;
    chConfirmation: TCheckBox;
    Con: TSQLite3Connection;
    seHoursIncrement: TSpinEdit;
    sql: TSQLQuery;
    Tr: TSQLTransaction;
    sbMain: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    tbAdd: TToolButton;
    tbEdit: TToolButton;
    tbInactive: TToolButton;
    tbMain: TToolBar;
    tbPurge: TToolButton;
    tbRemove: TToolButton;
    tbRestart: TToolButton;
    tbTest: TToolButton;
    Timer1: TTimer;
    procedure chIconsChange(Sender: TObject);
    procedure chMessageTimeChange(Sender: TObject);
    procedure chTaskbarTimeChange(Sender: TObject);
    procedure chToolbarChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure laChecksumClick(Sender: TObject);
    procedure lvAlarmsAdvancedCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: boolean);
    procedure lvAlarmsDblClick(Sender: TObject);
    procedure lvAlarmsSelectItem(Sender: TObject; Item: TListItem;
      Selected: boolean);
    procedure miAddHoursClick(Sender: TObject);
    procedure miQuitClick(Sender: TObject);
    procedure miRemoveHoursClick(Sender: TObject);
    procedure pmAlarmsPopup(Sender: TObject);
    procedure buFileSelectClick(Sender: TObject);
    procedure tbAddClick(Sender: TObject);
    procedure tbEditClick(Sender: TObject);
    procedure tbInactiveClick(Sender: TObject);
    procedure tbPurgeClick(Sender: TObject);
    procedure tbRemoveClick(Sender: TObject);
    procedure tbRestartClick(Sender: TObject);
    procedure tbTestClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

procedure BuzzForm(f: TForm);

var
  fMain: TfMain;

implementation

{$R *.lfm}

uses uNew, uMessage;

  { TfMain }
var
  LockLaunching: boolean;
  CurrentUser, CurrentComputer: string;

function SecondsToTimeHMS(s: integer; b: boolean): string;
var
  h, m: integer;
begin
  h := 0;
  m := 0;
  if s > 60 * 60 then
  begin
    h := s div 60 div 60;
    s := s - h * 60 * 60;
  end;
  if s > 60 then
  begin
    m := s div 60;
    s := s - m * 60;
  end;
  if b then
  begin
    if h > 0 then
      Result := Format('%dh', [h])
    else if m > 0 then
      Result := Format('%dm', [m])
    else
      Result := Format('%ds', [s]);
  end
  else
    Result := Format('%.2d:%.2d:%.2d', [h, m, s]);
end;

procedure BuzzForm(f: TForm);
var
  rS: TResourceStream;
  i, j, x, y: integer;
  dx, dy: integer;
begin
  // Project - Project Options... - Resources - Add...
  // PlaySound('Buzz.wav', 0, SND_ASYNC);
  rS := TResourceStream.Create(HINSTANCE, 'Buzz', Windows.RT_RCDATA);
  try
    MMSystem.PlaySound(PChar(rS.Memory), 0, SND_MEMORY or SND_ASYNC);
  finally
    rS.Free;
  end;

  Randomize;
  dx := 10;
  dy := 10;
  x := f.Left;
  y := f.Top;
  for i := 1 to 5 do
    for j := 1 to 5 do
    begin
      f.Left := x + Round(dx - Random * dx);
      f.Top := y + round(dy - random * dy);
    end;
  f.Left := x;
  f.Top := y;
end;

procedure PlayInternalSound;
var
  rS: TResourceStream;
begin
  // Project - Project Options... - Resources - Add...
  // PlaySound('Buzz.wav', 0, SND_ASYNC);
  rS := TResourceStream.Create(HINSTANCE, 'RTWARNING2', Windows.RT_RCDATA);
  try
    MMSystem.PlaySound(PChar(rS.Memory), 0, SND_MEMORY or SND_ASYNC);
  finally
    rS.Free;
  end;
end;

function ShowTheMessage(ATitle, AMessage: string; ADelay: integer;
  Instant: boolean): integer;
begin
  if LockLaunching then
  begin
    Result := -1;
    Exit;
  end
  else if Instant then
    Result := 1
  else
  begin
    LockLaunching := True;
    Application.CreateForm(TfMessage, fMessage);
    with fMessage do
    begin
      try
        //Name := 'MessageForm';
        Caption := ATitle;
        Position := poMainFormCenter;
        FormStyle := fsStayOnTop;
        Interval := ADelay;
        Label1.Caption := AMessage;
        Timer1.Enabled := True;
        ShowModal;
        //if fMain.BuzzMessageWindow.Checked then BuzzForm(MessageForm);
      finally
        Result := LaunchAlarm;
        Free;
      end;
    end;
    LockLaunching := False;
  end;
end;

function GetUserFromWindows: string;
var
  UserName: string;
  UserNameLen: dWord;
begin
  UserNameLen := 255;
  SetLength(UserName, UserNameLen);
  if GetUserName(PChar(UserName), UserNameLen) then
    Result := Copy(UserName, 1, UserNameLen - 1)
  else
    Result := 'Unknown';
end;

function GetComputerNetName: string;
var
  buffer: array[0..255] of char;
  Size: dWord;
begin
  Size := 256;
  if GetComputerName(Buffer, Size) then
    Result := Buffer
  else
    Result := 'Undetected';
end;

procedure TfMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := False;
  miQuitClick(Sender);
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  FileDate: integer;
  s, strExeVersion, AppDir: string;
begin
  AppDir := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
  Con.DatabaseName := AppDir + 'alarmer.sqlite';
  IniPropStorage1.IniFileName := AppDir + 'alarmer.ini';

  try
    {$IfDef Win32}
    sqlite3conn.SQLiteLibraryName := AppDir + 'x32-sqlite3.dll';
    {$EndIf}
    {$IFDEF Win64}
    sqlite3conn.SQLiteLibraryName := AppDir + 'x64-sqlite3.dll';
    {$ENDIF}
    Con.Connected := True;
  except
    {$IfDef Windows}
    MessageDlg('Library sqlite3.dll not found!', mtError, [mbOK], 0);
    {$Else}
    MessageDlg('Library libsqlite3.so not found!'#13#13 +
      'Type this in Terminal:'#13 + 'sudo apt-get install libsqlite3-dev',
      mtError, [mbOK], 0);
    {$EndIf}
    Application.Terminate;
  end;
  sql.PacketRecords := -1;

  laChecksum.Caption :=
    'Checksum: ' + MD5.MD5Print(MD5File(Application.ExeName));
  laUsername.Caption := 'Username: ' + CurrentUser;
  laComputer.Caption := 'Computer: ' + GetComputerNetName;
  FileDate := FileAge(Application.ExeName);
  if FileDate > -1 then
    strExeVersion := FormatDateTime('yyyymmdd-hhnn', FileDateToDateTime(FileDate))
  else
    strExeVersion := 'undetected';
  laVersion.Caption := 'Exe Version: ' + strExeVersion;

  laLazarus.Caption := 'Lazarus: ' + lcl_version;
  laFPC.Caption := 'FPC: ' + {$I %FPCVersion%};
  laTarget.Caption := 'Target: ' + {$I %FPCTarget%};

  chIconsChange(Sender);
  pcMain.ActivePageIndex := 0;
end;

procedure TfMain.FormShow(Sender: TObject);
var
  Node1: TListItem;
  Length: integer;
begin
  if chConfirmation.Checked then
    if MessageDlg('Load list of alarms?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  Timer1.Enabled := False;
  //Computer := GetEnvironmentVariable('Computername');

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Select * From Usage Where StopTime Is Null');
  sql.SQL.Add('And Computer=:Computer Order By Id Limit 1;');
  sql.ParamByName('Computer').AsString := CurrentComputer;
  sql.Open;
  if sql.RecordCount = 1 then
    if MessageDlg('Alarmer seems to be already open.'#13 +
      'If is not, select YES to continue...', mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes then
    begin
      sql.Close;
      Application.Terminate;
    end;

  sql.Close;
  sql.SQL.Clear;
  //sql.SQL.Add('Update Usage Set StopTime=:Now Where StopTime Is Null;');
  //sql.ParamByName('Now').AsDateTime := Now();
  sql.SQL.Add('Delete From Usage;');
  sql.ExecSQL;
  Tr.Commit;

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Insert Into Usage(StartTime,Computer,Forced)');
  sql.SQL.Add('Values (:Now,:Computer,0);');
  sql.ParamByName('Now').AsDateTime := Now();
  sql.ParamByName('Computer').AsString := CurrentComputer;
  sql.ExecSQL;
  Tr.Commit;

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Select * From Events /*Where Active = -1*/ Order By StopTime;');
  sql.Open;
  while not sql.EOF do
  begin
    Node1 := lvAlarms.Items.Add;
    Node1.Caption := IntToStr(lvAlarms.Items.Count);
    Node1.ImageIndex := sql.FieldByName('Id').AsInteger;
    if sql.FieldByName('Active').AsBoolean = True then
      Node1.SubItems.Add('Yes')
    else
      Node1.SubItems.Add('No');
    Node1.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss',
      sql.FieldByName('StartTime').AsDateTime));
    Node1.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss',
      sql.FieldByName('StopTime').AsDateTime));
    Length := DateUtils.SecondsBetween(sql.FieldByName('StopTime').AsDateTime,
      sql.FieldByName('StartTime').AsDateTime);
    Node1.SubItems.Add(Format('%d', [Length]));
    //Node1.SubItems.Add(Remaining);
    Node1.SubItems.Add(SecondsToTimeHMS(
      SecondsBetween(sql.FieldByName('StopTime').AsDateTime, Now()), False));
    Node1.SubItems.Add(sql.FieldByName('Message').AsString);
    sql.Next;
  end;
  Timer1.Enabled := True;
end;

procedure TfMain.laChecksumClick(Sender: TObject);
begin
  Clipboard.AsText := Copy(laChecksum.Caption, Pos(': ', laChecksum.Caption), 999) +
    ' *' + ExtractFileName(Application.ExeName);
end;

procedure TfMain.tbAddClick(Sender: TObject);
var
  Node1: TListItem;
  StartTime, StopTime: TDateTime;
  Interval, IdAlarm: integer;
begin
  fNew.Caption := 'New alarm';
  fNew.Timer1.Enabled := True;
  fNew.Timer1Timer(Sender);
  if fNew.Execute then
  begin
    StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', fNew.edStartTime.Text);
    Interval := fNew.seHours.Value * 60 * 60 + fNew.seMinutes.Value *
      60 + fNew.seSeconds.Value;
    StopTime := IncSecond(StartTime, Interval);

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Insert Into Events (Active,StartTime,StopTime,Message)');
    sql.SQL.Add('Values (:Active,:StartTime,:StopTime,:Message)');
    sql.ParamByName('Active').AsBoolean := True;
    sql.ParamByName('StartTime').AsDateTime := StartTime;
    sql.ParamByName('StopTime').AsDateTime := StopTime;
    sql.ParamByName('Message').AsString := fNew.meMessage.Text;
    sql.ExecSQL;
    Tr.Commit;
    sql.Close;

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Select Id From Events Where Active=:Active And');
    sql.SQL.Add('StartTime=:StartTime And StopTime=:StopTime And Message=:Message');
    sql.SQL.Add('Order By Id Desc Limit 1;');
    sql.ParamByName('Active').AsBoolean := True;
    sql.ParamByName('StartTime').AsDateTime := StartTime;
    sql.ParamByName('StopTime').AsDateTime := StopTime;
    sql.ParamByName('Message').AsString := fNew.meMessage.Text;
    sql.Open;
    IdAlarm := sql.FieldByName('Id').AsInteger;
    sql.Close;

    Node1 := lvAlarms.Items.Add;
    Node1.ImageIndex := 0;
    Node1.Caption := IntToStr(lvAlarms.Items.Count);
    Node1.ImageIndex := IdAlarm;
    Node1.SubItems.Add('Yes');
    Node1.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime));
    Node1.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime));
    Node1.SubItems.Add(Format('%d', [Round(Interval)]));
    Node1.SubItems.Add(SecondsToTimeHMS(Interval, False));
    Node1.SubItems.Add(fNew.meMessage.Text);
  end;
end;

procedure TfMain.lvAlarmsAdvancedCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: boolean);
begin
  Item.Caption := IntToStr(Item.Index + 1);
  if Item.SubItems[0] = 'No' then
    Sender.Canvas.Font.Color := clRed
  else
    Sender.Canvas.Font.Color := clDefault;
end;

procedure TfMain.chTaskbarTimeChange(Sender: TObject);
begin
  chTaskbarMessage.Enabled := chTaskbarTime.Checked;
  chTaskbarIcon.Enabled := chTaskbarTime.Checked;
  chTaskbarShorttime.Enabled := chTaskbarTime.Checked;
  chTaskbarIconAlarm.Enabled := chTaskbarTime.Checked;
end;

procedure TfMain.chIconsChange(Sender: TObject);
begin
  if chIcons.Checked then
    pcMain.Images := ImageList1
  else
    pcMain.Images := nil;
end;

procedure TfMain.chMessageTimeChange(Sender: TObject);
begin
  seMessageTime.Enabled := chMessageTime.Checked;
end;

procedure TfMain.chToolbarChange(Sender: TObject);
begin
  tbMain.Visible := chToolbar.Checked;
end;

procedure TfMain.lvAlarmsDblClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  if lvAlarms.Selected = nil then
    Exit;
  fNew.Caption := 'Edit alarm';
  fNew.Timer1.Enabled := False;
  fNew.edStartTime.Text := lvAlarms.Selected.SubItems[1];
  Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
  H := Interval div 60 div 60;
  N := (Interval - H * 60 * 60) div 60;
  S := (Interval - H * 60 * 60 - N * 60);
  fNew.seHours.Value := H;
  fNew.seMinutes.Value := N;
  fNew.seSeconds.Value := S;
  fNew.meMessage.Text := lvAlarms.Selected.SubItems[5];
  fNew.seHoursChange(Sender);
  if fNew.Execute then
    with lvAlarms.Selected do
    begin
      StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', fNew.edStartTime.Text);
      Interval := fNew.seHours.Value * 60 * 60 + fNew.seMinutes.Value *
        60 + fNew.seSeconds.Value;
      StopTime := IncSecond(StartTime, Interval);
      SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
      SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
      SubItems[3] := IntToStr(Round(Interval));
      SubItems[4] := SecondsToTimeHMS(Interval, False);
      SubItems[5] := fNew.meMessage.Text;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add(
        'Update Events Set StopTime=:StopTime,Message=:Message Where Id=:Id');
      sql.ParamByName('StopTime').AsDateTime := StopTime;
      sql.ParamByName('Message').AsString := fNew.meMessage.Text;
      sql.ParamByName('Id').AsInteger := fMain.lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
end;

procedure TfMain.lvAlarmsSelectItem(Sender: TObject; Item: TListItem;
  Selected: boolean);
begin
  //PopupMenu1Popup(Sender);
  if lvAlarms.Selected <> nil then
    if lvAlarms.Selected.SubItems[0] = 'No' then
      miSetInactive.Caption := 'Activate'
    else
      miSetInactive.Caption := 'Deactivate';
  tbInactive.Caption := miSetInactive.Caption;
  tbEdit.Enabled := lvAlarms.Selected <> nil;
  tbRestart.Enabled := lvAlarms.Selected <> nil;
  tbTest.Enabled := lvAlarms.Selected <> nil;
  tbInactive.Enabled := lvAlarms.Selected <> nil;
  tbRemove.Enabled := lvAlarms.Selected <> nil;
end;

procedure TfMain.miAddHoursClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  with lvAlarms.Selected do
  begin
    StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', lvAlarms.Selected.SubItems[1]);
    Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
    H := Interval div 60 div 60;
    N := (Interval - H * 60 * 60) div 60;
    S := (Interval - H * 60 * 60 - N * 60);
    Interval := (H + seHoursIncrement.Value) * 60 * 60 + N * 60 + S;
    StopTime := IncSecond(StartTime, Interval);
    SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
    SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
    SubItems[3] := IntToStr(Round(Interval));
    SubItems[4] := SecondsToTimeHMS(Interval, False);
    //SubItems[5] := fNew.meMessage.Text;

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Update Events Set StopTime=:StopTime Where Id=:Id');
    sql.ParamByName('StopTime').AsDateTime := StopTime;
    sql.ParamByName('Id').AsInteger := fMain.lvAlarms.Selected.ImageIndex;
    sql.ExecSQL;
    Tr.Commit;
    sql.Close;
  end;
end;

procedure TfMain.miQuitClick(Sender: TObject);
begin
  if chConfirmation.Checked then
    if MessageDlg('Quit Alarmer?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Update Usage Set StopTime=:Now,Forced=-1');
  sql.SQL.Add('Where StopTime Is Null And Computer=:Computer;');
  sql.ParamByName('Now').AsDateTime := Now();
  sql.ParamByName('Computer').AsString := CurrentComputer;
  //GetEnvironmentVariable('Computername');
  sql.ExecSQL;
  Tr.Commit;
  sql.Close;

  Application.Terminate;
end;

procedure TfMain.miRemoveHoursClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  with lvAlarms.Selected do
  begin
    StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', lvAlarms.Selected.SubItems[1]);
    Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
    H := Interval div 60 div 60;
    N := (Interval - H * 60 * 60) div 60;
    S := (Interval - H * 60 * 60 - N * 60);
    Interval := (H - seHoursIncrement.Value) * 60 * 60 + N * 60 + S;
    StopTime := IncSecond(StartTime, Interval);
    //if Interval > seHoursIncrement.Value then
    if StopTime > Now() then
    begin
      SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
      SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
      SubItems[3] := IntToStr(Round(Interval));
      SubItems[4] := SecondsToTimeHMS(Interval, False);
      //SubItems[5] := fNew.meMessage.Text;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add('Update Events Set StopTime=:StopTime Where Id=:Id');
      sql.ParamByName('StopTime').AsDateTime := StopTime;
      sql.ParamByName('Id').AsInteger := fMain.lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
  end;
end;

procedure TfMain.pmAlarmsPopup(Sender: TObject);
begin
  if lvAlarms.ItemIndex <> -1 then
    if lvAlarms.Items[lvAlarms.ItemIndex].SubItems[0] = 'No' then
      miSetInactive.Caption := 'Activate'
    else
      miSetInactive.Caption := 'Deactivate';
  tbInactive.Caption := miSetInactive.Caption;

  miSetInactive.Enabled := (lvAlarms.ItemIndex <> -1) and fMain.Visible;
  miDelete.Enabled := (lvAlarms.ItemIndex <> -1) and fMain.Visible;
  miEdit.Enabled := (lvAlarms.ItemIndex <> -1) and fMain.Visible;
  miRemoveHours.Caption := Format('-%d hours', [seHoursIncrement.Value]);
  miAddHours.Caption := Format('+%d hours', [seHoursIncrement.Value]);
  miAdd.Enabled := fMain.Visible;
  miTest.Enabled := (lvAlarms.ItemIndex <> -1) and fMain.Visible;
end;

procedure TfMain.buFileSelectClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    if ExtractFilePath(ParamStr(0)) = ExtractFilePath(OpenDialog1.FileName) then
      edFileOpen.Text := ExtractFileName(OpenDialog1.FileName)
    else
      edFileOpen.Text := OpenDialog1.FileName;
end;

procedure TfMain.tbEditClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  if lvAlarms.Selected = nil then
    Exit;
  fNew.Caption := 'Edit alarm';
  fNew.Timer1.Enabled := False;
  fNew.edStartTime.Text := lvAlarms.Selected.SubItems[1];
  Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
  H := Interval div 60 div 60;
  N := (Interval - H * 60 * 60) div 60;
  S := (Interval - H * 60 * 60 - N * 60);
  fNew.seHours.Value := H;
  fNew.seMinutes.Value := N;
  fNew.seSeconds.Value := S;
  fNew.meMessage.Text := lvAlarms.Selected.SubItems[5];
  fNew.seHoursChange(Sender);
  if fNew.Execute then
    with lvAlarms.Selected do
    begin
      StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', fNew.edStartTime.Text);
      Interval := fNew.seHours.Value * 60 * 60 + fNew.seMinutes.Value *
        60 + fNew.seSeconds.Value;
      StopTime := IncSecond(StartTime, Interval);
      SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
      SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
      SubItems[3] := IntToStr(Round(Interval));
      SubItems[4] := SecondsToTimeHMS(Interval, False);
      SubItems[5] := fNew.meMessage.Text;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add(
        'Update Events Set StopTime=:StopTime,Message=:Message Where Id=:Id');
      sql.ParamByName('StopTime').AsDateTime := StopTime;
      sql.ParamByName('Message').AsString := fNew.meMessage.Text;
      sql.ParamByName('Id').AsInteger := fMain.lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
end;

procedure TfMain.tbInactiveClick(Sender: TObject);
begin
  if lvAlarms.ItemIndex <> -1 then
    if lvAlarms.Selected.SubItems[0] = 'No' then
    begin
      lvAlarms.Selected.SubItems[0] := 'Yes';
      miSetInactive.Caption := 'Set inactive';
      tbInactive.Caption := miSetInactive.Caption;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add('Update Events Set Active=:Active Where Id=:Id');
      sql.ParamByName('Active').AsBoolean := True;
      sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end
    else
    begin
      lvAlarms.Selected.SubItems[0] := 'No';
      miSetInactive.Caption := 'Activate';
      tbInactive.Caption := miSetInactive.Caption;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add('Update Events Set Active=:Active Where Id=:Id');
      sql.ParamByName('Active').AsBoolean := False;
      sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
end;

procedure TfMain.tbPurgeClick(Sender: TObject);
begin
  if MessageDlg('Remove from database all inactive alarms?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Delete From Events Where Active=0;');
    sql.ExecSQL;
    Tr.Commit;
    sql.Close;
  end;
end;

procedure TfMain.tbRemoveClick(Sender: TObject);
var
  i, Pos: integer;
begin
  if MessageDlg('Delete alarm completly?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Pos := lvAlarms.ItemIndex;

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Delete From Events Where Id=:Id');
    sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
    sql.ExecSQL;
    Tr.Commit;
    sql.Close;

    lvAlarms.Selected.Delete;
    for i := 1 to lvAlarms.Items.Count do
      lvAlarms.Items[i - 1].Caption := IntToStr(i);
    if Pos = lvAlarms.Items.Count then
      Dec(Pos);
    if Pos < lvAlarms.Items.Count then
      lvAlarms.ItemIndex := Pos;
    pmAlarmsPopup(Sender);
  end;
end;

procedure TfMain.tbRestartClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Length: integer;
begin
  if lvAlarms.ItemIndex <> -1 then
  begin
    StartTime := Now();

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Select StartTime,StopTime From Events Where Id=:Id');
    sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
    sql.Open;
    Length := SecondsBetween(sql.FieldByName('StartTime').AsDateTime,
      sql.FieldByName('StopTime').AsDateTime);
    StopTime := DateUtils.IncSecond(StartTime, Length);

    lvAlarms.Selected.SubItems[0] := 'Yes';
    lvAlarms.Selected.SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
    lvAlarms.Selected.SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
    miSetInactive.Caption := 'Set inactive';
    tbInactive.Caption := miSetInactive.Caption;

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Update Events Set Active=:Active,');
    sql.SQL.Add('StartTime=:StartTime,StopTime=:StopTime Where Id=:Id');
    sql.ParamByName('Active').AsBoolean := True;
    sql.ParamByName('StartTime').AsDateTime := StartTime;
    sql.ParamByName('StopTime').AsDateTime := StopTime;
    sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
    sql.ExecSQL;
    Tr.Commit;
    sql.Close;
  end;
end;

procedure TfMain.tbTestClick(Sender: TObject);
var
  str: string;
begin
  if lvAlarms.Selected.SubItems[5] <> '' then
  begin
    case ShowTheMessage('Alarmer', lvAlarms.Selected.SubItems[5],
        seMessageTime.Value * 1000, not chMessageTime.Checked) of
      0:
      begin
        sql.Close;
        sql.SQL.Clear;
        sql.SQL.Add('Update Events Set Active=0 Where Id=:Id;');
        sql.ParamByName('Id').AsInteger := lvAlarms.Selected.ImageIndex;
        sql.ExecSQL;
        Tr.Commit;
        sql.Close;
      end;
      1:
      begin
        if chSound.Checked then
          PlayInternalSound;
        str := ExtractFilePath(Application.ExeName) + edFileOpen.Text;
        if chFileOpen.Checked and FileExists(str) then
          LCLIntf.OpenURL(str);
      end;
    end;
  end;
end;

procedure TfMain.Timer1Timer(Sender: TObject);
var
  i, Interval, Minimum, ActiveAlarms, InactiveAlarms: integer;
  CurrentTime, AlarmTime: TDateTime;
  str, Messsage: string;
  AnAlarmIsPassed: boolean;
  bmp: Graphics.TBitmap;
begin
  CurrentTime := Now();
  Minimum := 0;
  AnAlarmIsPassed := False;
  ActiveAlarms := 0;
  InactiveAlarms := 0;

  for i := 1 to lvAlarms.Items.Count do
  begin
    if lvAlarms.Items[i - 1].SubItems[0] = 'Yes' then
    begin
      AlarmTime := ScanDateTime('yyyy-mm-dd hh:nn:ss',
        lvAlarms.Items[i - 1].SubItems[2]);
      if CurrentTime >= AlarmTime then
      begin
        lvAlarms.Items[i - 1].SubItems[4] := SecondsToTimeHMS(0, False);
        lvAlarms.Items[i - 1].SubItems[0] := 'No';
        if lvAlarms.Items[i - 1].SubItems[5] <> '' then
          case ShowTheMessage('Alarmer', lvAlarms.Items[i - 1].SubItems[5],
              seMessageTime.Value * 1000, not chMessageTime.Checked) of
            -1: Exit;
            0:
            begin
              sql.Close;
              sql.SQL.Clear;
              sql.SQL.Add('Update Events Set Active=0 Where Id=:Id;');
              sql.ParamByName('Id').AsInteger := lvAlarms.Items[i - 1].ImageIndex;
              sql.ExecSQL;
              Tr.Commit;
              sql.Close;
            end;
            1:
            begin
              if chSound.Checked then
                PlayInternalSound;
              str := ExtractFilePath(Application.ExeName) + edFileOpen.Text;
              if chFileOpen.Checked and FileExists(str) then
                LCLIntf.OpenURL(str);
            end;
          end;
      end
      else
      begin
        Interval := SecondsBetween(CurrentTime, AlarmTime);
        if Minimum = 0 then
        begin
          Minimum := Interval;
          Messsage := lvAlarms.Items[i - 1].SubItems[5];
        end
        else if Minimum >= Interval then
        begin
          Minimum := Interval;
          Messsage := lvAlarms.Items[i - 1].SubItems[5];
        end;
        lvAlarms.Items[i - 1].SubItems[4] := SecondsToTimeHMS(Interval, False);
      end;
    end
    else if not AnAlarmIsPassed then
      AnAlarmIsPassed := True;
    if lvAlarms.Items[i - 1].SubItems[0] = 'Yes' then
      Inc(ActiveAlarms)
    else
      Inc(InactiveAlarms);
  end;

  if chTaskbarTime.Checked then
  begin
    if chTaskbarMessage.Checked then
    begin
      Application.Title := SecondsToTimeHMS(Minimum, chTaskbarShorttime.Checked) +
        ' - ' + Messsage;
      fMain.Caption := SecondsToTimeHMS(Minimum, chTaskbarShorttime.Checked) +
        ' - ' + Messsage;
    end
    else
    begin
      Application.Title := 'Alarmer ' + SecondsToTimeHMS(Minimum,
        chTaskbarShorttime.Checked) + '';
      fMain.Caption := 'Alarmer ' + SecondsToTimeHMS(Minimum,
        chTaskbarShorttime.Checked) + '';
      //TrayIcon1.Hint:= 'Alarmer '+ SecondsToTimeHMS(Minimum)+ '';
    end;
  end
  else
  begin
    Application.Title := 'Alarmer';
    fMain.Caption := 'Alarmer';
    //TrayIcon1.Hint:= 'Alarmer';
  end;

  if chTaskbarIconAlarm.Checked then
  begin
    bmp := Graphics.TBitmap.Create;
    try
      bmp.SetSize(32, 32);
      //ImageList2.GetBitmap(0, bmp);
      bmp.Canvas.Brush.Style := bsSolid;
      if AnAlarmIsPassed then
        bmp.Canvas.Brush.Color := clRed
      else
        bmp.Canvas.Brush.Color := clGray;
      bmp.Canvas.Pen.Color := bmp.Canvas.Brush.Color;
      bmp.Canvas.Rectangle(0, 0, bmp.Width, bmp.Height);
      //bmp.TransparentColor := clWhite;
      //bmp.Canvas.TextOut(1, 1, 'next');
      //bmp.Canvas.TextOut(1, 16, SecondsToTimeHMS(Minimum, chTaskbarShorttime.Checked));
      Messsage := SecondsToTimeHMS(Minimum, chTaskbarShorttime.Checked);
      bmp.Canvas.TextOut((bmp.Width - bmp.Canvas.TextWidth(Messsage)) div
        2, (bmp.Height - bmp.Canvas.TextHeight(Messsage)) div 2, Messsage);
      Application.Icon.Assign(bmp);
    finally
      bmp.Free;
    end;
  end
  else
  if chTaskbarIcon.Checked and AnAlarmIsPassed then
  begin
    bmp := Graphics.TBitmap.Create;
    try
      ImageList2.GetBitmap(1, bmp);
      Application.Icon.Assign(bmp);
    finally
      bmp.Free;
    end;
  end
  else
  begin
    bmp := Graphics.TBitmap.Create;
    try
      ImageList2.GetBitmap(0, bmp);
      Application.Icon.Assign(bmp);
    finally
      bmp.Free;
    end;
  end;
  sbMain.Panels[0].Text := Format('%d active alarms', [ActiveAlarms]);
  sbMain.Panels[1].Text := Format('%d inactive alarms', [InactiveAlarms]);
end;

initialization
  LockLaunching := False;
  CurrentUser := GetUserFromWindows;
  CurrentComputer := GetComputerNetName;

end.

unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, Forms, Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, Spin, ExtCtrls, IniPropStorage, Menus, DateUtils, LCLIntf;

type

  { TMainForm }

  TMainForm = class(TForm)
    ChangeApplicationIconIfAnAlarmIsPassed: TCheckBox;
    DisplayIconsOnTabs: TCheckBox;
    DisplayMessageOfNextAlarmInTaskbar: TCheckBox;
    DisplayNextAlarmAsTaskbarIcon: TCheckBox;
    DisplayRemainingTimeOfNextAlarmInTaskbar: TCheckBox;
    DisplayToolbar: TCheckBox;
    FileToOpenInAlarm: TEdit;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    laFileToOpenOnAlarm: TLabel;
    laSecondsToDisplayMessage: TLabel;
    lvAlarms: TListView;
    meHistory: TMemo;
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
    PageControl1: TPageControl;
    pmAlarms: TPopupMenu;
    SelectFile: TButton;
    seSecondsToDisplayMessage: TSpinEdit;
    Shape1: TShape;
    ShortTimeFormat: TCheckBox;
    ShowConfirmationDialogs: TCheckBox;
    Con: TSQLite3Connection;
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
    procedure DisplayIconsOnTabsChange(Sender: TObject);
    procedure DisplayRemainingTimeOfNextAlarmInTaskbarChange(Sender: TObject);
    procedure DisplayToolbarChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lvAlarmsAdvancedCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
      var DefaultDraw: boolean);
    procedure lvAlarmsDblClick(Sender: TObject);
    procedure lvAlarmsSelectItem(Sender: TObject; Item: TListItem;
      Selected: boolean);
    procedure miQuitClick(Sender: TObject);
    procedure pmAlarmsPopup(Sender: TObject);
    procedure SelectFileClick(Sender: TObject);
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

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses uNew, uMessage;

  { TMainForm }
var
  LockLaunching: boolean;

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

function ShowTheMessage(ATitle, AMessage: string; ADelay: integer): integer;
begin
  if LockLaunching then
  begin
    Result := -1;
    Exit;
  end
  else
  begin
    LockLaunching := True;
    Application.CreateForm(TMessageForm, MessageForm);
    with MessageForm do
    begin
      try
        Caption := ATitle;
        Position := poMainFormCenter;
        FormStyle := fsStayOnTop;
        Interval := ADelay;
        Label1.Caption := AMessage;
        Timer1.Enabled := True;
        ShowModal;
      finally
        Result := LaunchAlarm;
        Free;
      end;
    end;
    LockLaunching := False;
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := False;
  miQuitClick(Sender);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  AppDir: string;
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

  DisplayIconsOnTabsChange(Sender);
  PageControl1.ActivePageIndex := 0;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  Node1: TListItem;
  Length: integer;
  Computer: string;
begin
  if ShowConfirmationDialogs.Checked then
    if MessageDlg('Load list of alarms?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  Timer1.Enabled := False;
  Computer := GetEnvironmentVariable('Computername');

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Select * From Usage Where StopTime Is Null');
  sql.SQL.Add('And Computer=:Computer Order By Id Limit 1;');
  sql.ParamByName('Computer').AsString := Computer;
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
  sql.ParamByName('Computer').AsString := Computer;
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

procedure TMainForm.tbAddClick(Sender: TObject);
var
  Node1: TListItem;
  StartTime, StopTime: TDateTime;
  Interval, IdAlarm: integer;
begin
  NewAlarmForm.Caption := 'New alarm';
  NewAlarmForm.Timer1.Enabled := True;
  NewAlarmForm.Timer1Timer(Sender);
  if NewAlarmForm.Execute then
  begin
    StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', NewAlarmForm.edStartTime.Text);
    Interval := NewAlarmForm.seHours.Value * 60 * 60 +
      NewAlarmForm.seMinutes.Value * 60 + NewAlarmForm.seSeconds.Value;
    StopTime := IncSecond(StartTime, Interval);

    sql.Close;
    sql.SQL.Clear;
    sql.SQL.Add('Insert Into Events (Active,StartTime,StopTime,Message)');
    sql.SQL.Add('Values (:Active,:StartTime,:StopTime,:Message)');
    sql.ParamByName('Active').AsBoolean := True;
    sql.ParamByName('StartTime').AsDateTime := StartTime;
    sql.ParamByName('StopTime').AsDateTime := StopTime;
    sql.ParamByName('Message').AsString := NewAlarmForm.meMessage.Text;
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
    sql.ParamByName('Message').AsString := NewAlarmForm.meMessage.Text;
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
    Node1.SubItems.Add(NewAlarmForm.meMessage.Text);
  end;
end;

procedure TMainForm.lvAlarmsAdvancedCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; Stage: TCustomDrawStage;
  var DefaultDraw: boolean);
begin
  Item.Caption := IntToStr(Item.Index + 1);
  if Item.SubItems[0] = 'No' then
    Sender.Canvas.Font.Color := clRed
  else
    Sender.Canvas.Font.Color := clDefault;
end;

procedure TMainForm.DisplayRemainingTimeOfNextAlarmInTaskbarChange(Sender: TObject);
begin
  DisplayMessageOfNextAlarmInTaskbar.Enabled :=
    DisplayRemainingTimeOfNextAlarmInTaskbar.Checked;
  ChangeApplicationIconIfAnAlarmIsPassed.Enabled :=
    DisplayRemainingTimeOfNextAlarmInTaskbar.Checked;
  ShortTimeFormat.Enabled :=
    DisplayRemainingTimeOfNextAlarmInTaskbar.Checked;
end;

procedure TMainForm.DisplayIconsOnTabsChange(Sender: TObject);
begin
  if DisplayIconsOnTabs.Checked then
    PageControl1.Images := ImageList1
  else
    PageControl1.Images := nil;
end;

procedure TMainForm.DisplayToolbarChange(Sender: TObject);
begin
  tbMain.Visible := DisplayToolbar.Checked;
end;

procedure TMainForm.lvAlarmsDblClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  if lvAlarms.Selected = nil then
    Exit;
  NewAlarmForm.Caption := 'Edit alarm';
  NewAlarmForm.Timer1.Enabled := False;
  NewAlarmForm.edStartTime.Text := lvAlarms.Selected.SubItems[1];
  Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
  H := Interval div 60 div 60;
  N := (Interval - H * 60 * 60) div 60;
  S := (Interval - H * 60 * 60 - N * 60);
  NewAlarmForm.seHours.Value := H;
  NewAlarmForm.seMinutes.Value := N;
  NewAlarmForm.seSeconds.Value := S;
  NewAlarmForm.meMessage.Text := lvAlarms.Selected.SubItems[5];
  NewAlarmForm.seHoursChange(Sender);
  if NewAlarmForm.Execute then
    with lvAlarms.Selected do
    begin
      StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', NewAlarmForm.edStartTime.Text);
      Interval := NewAlarmForm.seHours.Value * 60 * 60 +
        NewAlarmForm.seMinutes.Value * 60 + NewAlarmForm.seSeconds.Value;
      StopTime := IncSecond(StartTime, Interval);
      SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
      SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
      SubItems[3] := IntToStr(Round(Interval));
      SubItems[4] := SecondsToTimeHMS(Interval, False);
      SubItems[5] := NewAlarmForm.meMessage.Text;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add(
        'Update Events Set StopTime=:StopTime,Message=:Message Where Id=:Id');
      sql.ParamByName('StopTime').AsDateTime := StopTime;
      sql.ParamByName('Message').AsString := NewAlarmForm.meMessage.Text;
      sql.ParamByName('Id').AsInteger := MainForm.lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
end;

procedure TMainForm.lvAlarmsSelectItem(Sender: TObject; Item: TListItem;
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

procedure TMainForm.miQuitClick(Sender: TObject);
begin
  if ShowConfirmationDialogs.Checked then
    if MessageDlg('Quit Alarmer?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;

  sql.Close;
  sql.SQL.Clear;
  sql.SQL.Add('Update Usage Set StopTime=:Now,Forced=-1');
  sql.SQL.Add('Where StopTime Is Null And Computer=:Computer;');
  sql.ParamByName('Now').AsDateTime := Now();
  sql.ParamByName('Computer').AsString := GetEnvironmentVariable('Computername');
  sql.ExecSQL;
  Tr.Commit;
  sql.Close;

  Application.Terminate;
end;

procedure TMainForm.pmAlarmsPopup(Sender: TObject);
begin
  if lvAlarms.ItemIndex <> -1 then
    if lvAlarms.Items[lvAlarms.ItemIndex].SubItems[0] = 'No' then
      miSetInactive.Caption := 'Activate'
    else
      miSetInactive.Caption := 'Deactivate';
  tbInactive.Caption := miSetInactive.Caption;

  miSetInactive.Enabled := (lvAlarms.ItemIndex <> -1) and MainForm.Visible;
  miDelete.Enabled := (lvAlarms.ItemIndex <> -1) and MainForm.Visible;
  miEdit.Enabled := (lvAlarms.ItemIndex <> -1) and MainForm.Visible;
  miAdd.Enabled := MainForm.Visible;
  miTest.Enabled := (lvAlarms.ItemIndex <> -1) and MainForm.Visible;
end;

procedure TMainForm.SelectFileClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    if ExtractFilePath(ParamStr(0)) = ExtractFilePath(OpenDialog1.FileName) then
      FileToOpenInAlarm.Text := ExtractFileName(OpenDialog1.FileName)
    else
      FileToOpenInAlarm.Text := OpenDialog1.FileName;
end;

procedure TMainForm.tbEditClick(Sender: TObject);
var
  StartTime, StopTime: TDateTime;
  Interval, H, N, S: integer;
begin
  if lvAlarms.Selected = nil then
    Exit;
  NewAlarmForm.Caption := 'Edit alarm';
  NewAlarmForm.Timer1.Enabled := False;
  NewAlarmForm.edStartTime.Text := lvAlarms.Selected.SubItems[1];
  Interval := StrToInt(lvAlarms.Selected.SubItems[3]);
  H := Interval div 60 div 60;
  N := (Interval - H * 60 * 60) div 60;
  S := (Interval - H * 60 * 60 - N * 60);
  NewAlarmForm.seHours.Value := H;
  NewAlarmForm.seMinutes.Value := N;
  NewAlarmForm.seSeconds.Value := S;
  NewAlarmForm.meMessage.Text := lvAlarms.Selected.SubItems[5];
  NewAlarmForm.seHoursChange(Sender);
  if NewAlarmForm.Execute then
    with lvAlarms.Selected do
    begin
      StartTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', NewAlarmForm.edStartTime.Text);
      Interval := NewAlarmForm.seHours.Value * 60 * 60 +
        NewAlarmForm.seMinutes.Value * 60 + NewAlarmForm.seSeconds.Value;
      StopTime := IncSecond(StartTime, Interval);
      SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StartTime);
      SubItems[2] := FormatDateTime('yyyy-mm-dd hh:nn:ss', StopTime);
      SubItems[3] := IntToStr(Round(Interval));
      SubItems[4] := SecondsToTimeHMS(Interval, False);
      SubItems[5] := NewAlarmForm.meMessage.Text;

      sql.Close;
      sql.SQL.Clear;
      sql.SQL.Add(
        'Update Events Set StopTime=:StopTime,Message=:Message Where Id=:Id');
      sql.ParamByName('StopTime').AsDateTime := StopTime;
      sql.ParamByName('Message').AsString := NewAlarmForm.meMessage.Text;
      sql.ParamByName('Id').AsInteger := MainForm.lvAlarms.Selected.ImageIndex;
      sql.ExecSQL;
      Tr.Commit;
      sql.Close;
    end;
end;

procedure TMainForm.tbInactiveClick(Sender: TObject);
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

procedure TMainForm.tbPurgeClick(Sender: TObject);
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

procedure TMainForm.tbRemoveClick(Sender: TObject);
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

procedure TMainForm.tbRestartClick(Sender: TObject);
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

procedure TMainForm.tbTestClick(Sender: TObject);
begin
  if lvAlarms.Selected.SubItems[5] <> '' then
  begin
    case ShowTheMessage('Alarmer', lvAlarms.Selected.SubItems[5],
        seSecondsToDisplayMessage.Value * 1000) of
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
        if FileExists(ExtractFilePath(Application.ExeName) + FileToOpenInAlarm.Text) then
          LCLIntf.OpenURL(ExtractFilePath(Application.ExeName) + FileToOpenInAlarm.Text);
    end;
  end;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  i, Interval, Minimum, ActiveAlarms, InactiveAlarms: integer;
  CurrentTime, AlarmTime: TDateTime;
  Messsage: string;
  AnAlarmIsPassed: boolean;
  bmp: TBitmap;
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
              seSecondsToDisplayMessage.Value * 1000) of
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
            1: if FileExists(ExtractFilePath(Application.ExeName) +
                FileToOpenInAlarm.Text) then
                OpenURL(ExtractFilePath(Application.ExeName) +
                  FileToOpenInAlarm.Text);
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

  if DisplayRemainingTimeOfNextAlarmInTaskbar.Checked then
  begin
    if DisplayMessageOfNextAlarmInTaskbar.Checked then
    begin
      Application.Title := SecondsToTimeHMS(Minimum, ShortTimeFormat.Checked) +
        ' - ' + Messsage;
      MainForm.Caption := SecondsToTimeHMS(Minimum, ShortTimeFormat.Checked) +
        ' - ' + Messsage;
    end
    else
    begin
      Application.Title := 'Alarmer ' + SecondsToTimeHMS(Minimum,
        ShortTimeFormat.Checked) + '';
      MainForm.Caption := 'Alarmer ' + SecondsToTimeHMS(Minimum,
        ShortTimeFormat.Checked) + '';
      //TrayIcon1.Hint:= 'Alarmer '+ SecondsToTimeHMS(Minimum)+ '';
    end;
  end
  else
  begin
    Application.Title := 'Alarmer';
    MainForm.Caption := 'Alarmer';
    //TrayIcon1.Hint:= 'Alarmer';
  end;

  if DisplayNextAlarmAsTaskbarIcon.Checked then
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
      //bmp.Canvas.TextOut(1, 16, SecondsToTimeHMS(Minimum, ShortTimeFormat.Checked));
      Messsage := SecondsToTimeHMS(Minimum, ShortTimeFormat.Checked);
      bmp.Canvas.TextOut((bmp.Width - bmp.Canvas.TextWidth(Messsage)) div
        2, (bmp.Height - bmp.Canvas.TextHeight(Messsage)) div 2, Messsage);
      Application.Icon.Assign(bmp);
    finally
      bmp.Free;
    end;
  end
  else
  if ChangeApplicationIconIfAnAlarmIsPassed.Checked and AnAlarmIsPassed then
  begin
    bmp := TBitmap.Create;
    try
      ImageList2.GetBitmap(1, bmp);
      Application.Icon.Assign(bmp);
    finally
      bmp.Free;
    end;
  end
  else
  begin
    bmp := TBitmap.Create;
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

end.

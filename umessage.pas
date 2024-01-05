unit uMessage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ExtCtrls;

type

  { TMessageForm }

  TMessageForm = class(TForm)
    buCancel: TButton;
    buLaunch: TButton;
    Label1: TLabel;
    Label2: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mmMessage: TMainMenu;
    Timer1: TTimer;
    procedure buCancelClick(Sender: TObject);
    procedure buLaunchClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public
    LaunchAlarm: integer;
    Interval: integer;
  end;

var
  MessageForm: TMessageForm;

implementation

{$R *.lfm}

{ TMessageForm }

procedure TMessageForm.buCancelClick(Sender: TObject);
begin
  Timer1.Enabled := False;
  LaunchAlarm := 0;
  Close;
end;

procedure TMessageForm.buLaunchClick(Sender: TObject);
begin
  Timer1.Enabled := False;
  LaunchAlarm := 1;
  Close;
end;

procedure TMessageForm.Timer1Timer(Sender: TObject);
begin
  LaunchAlarm := 1;
  Interval := Interval - Timer1.Interval;
  if Interval = 0 then
  begin
    Timer1.Enabled := True;
    LaunchAlarm := 1;
    MessageForm.Close;
  end;
  Label2.Caption := 'Launch file in ' + IntToStr(Interval div 1000) + ' seconds';
end;

end.


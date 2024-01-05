unit uNew;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ExtCtrls, Menus;

type

  { TNewAlarmForm }

  TNewAlarmForm = class(TForm)
    buCancel: TButton;
    buOk: TButton;
    edStartTime: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label9: TLabel;
    MainMenu1: TMainMenu;
    meMessage: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenDialog1: TOpenDialog;
    seHours: TSpinEdit;
    seMinutes: TSpinEdit;
    seSeconds: TSpinEdit;
    Timer1: TTimer;
    procedure buCancelClick(Sender: TObject);
    procedure buOkClick(Sender: TObject);
    procedure seHoursChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public
    function Execute: boolean;
  end;

var
  NewAlarmForm: TNewAlarmForm;

implementation

{$R *.lfm}

{ TNewAlarmForm }

procedure TNewAlarmForm.seHoursChange(Sender: TObject);
begin
  buOk.Enabled := seHours.Value + seMinutes.Value + seSeconds.Value > 0;
end;

procedure TNewAlarmForm.Timer1Timer(Sender: TObject);
begin
  edStartTime.Text := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now());
end;

procedure TNewAlarmForm.buCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TNewAlarmForm.buOkClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

function TNewAlarmForm.Execute: boolean;
begin
  Result := ShowModal = mrOk;
end;

end.


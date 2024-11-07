program alarmer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  uMain,
  uNew,
  uMessage { you can add units after this };

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfNew, fNew);
  Application.CreateForm(TfMessage, fMessage);
  Application.Run;
end.

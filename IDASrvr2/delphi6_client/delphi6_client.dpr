program CopyDataSender;

uses
  Forms,
  SenderMain in 'SenderMain.pas' {SenderMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSenderMainForm, SenderMainForm);
  Application.Run;
end.

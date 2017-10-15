unit SenderMain;

{

 base project by Zarko Gajic
  http://delphi.about.com/od/windowsshellapi/a/wm_copydata.htm

}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type

(*
  Declared in Windows.pas

  TCopyDataStruct = packed record
    dwData: DWORD; //up to 32 bits of data to be passed to the receiving application
    cbData: DWORD; //the size, in bytes, of the data pointed to by the lpData member
    lpData: Pointer; //Points to data to be passed to the receiving application. This member can be nil.
  end;

*)

  TSenderMainForm = class(TForm)
    ListBox1: TListBox;
    procedure OnCreate(Sender: TObject);
  private
    procedure WMCopyData(var Msg : TWMCopyData); message WM_COPYDATA;
    procedure SendCMD(msg: string);
    function  SendCMDRecvText(msg: string) : string;
    function  SendCMDRecvInt(msg: string) : Integer;


  public
    { Public declarations }
  end;

var
  SenderMainForm: TSenderMainForm;
  Server_hwnd : Integer;
  Response_Buffer: string;

implementation

{$R *.dfm}

procedure TSenderMainForm.WMCopyData(var Msg: TWMCopyData);
begin

  //ListBox1.AddItem('Received WM_CopyData message',nil );

  if Msg.CopyDataStruct.dwData = 3 then
  begin
     Response_Buffer := PChar(Msg.CopyDataStruct.lpData);
     ListBox1.AddItem('Recv( '+ Response_Buffer + ')', nil);
  end;

  //we can send back an int if we want..
  //msg.Result := cdMemo.Lines.Count;
end;

function TSenderMainForm.SendCMDRecvText(msg: string) : string;
begin
        SendCMD(msg);
        Result :=  Response_Buffer;
end;

function TSenderMainForm.SendCMDRecvInt(msg: string) : Integer;
begin
        SendCMD(msg);
        Result :=  StrToInt(Response_Buffer);
end;

procedure TSenderMainForm.SendCMD(msg: string);
var
  copyDataStruct : TCopyDataStruct;
  receiverHandle  : THandle;
  res : integer;
begin

  Response_Buffer := '';
  receiverHandle := Server_hwnd;
  if receiverHandle = 0 then
  begin
    ListBox1.AddItem('CopyData Receiver NOT found!',nil);
    Exit;
  end;

  copyDataStruct.dwData := 3 ;
  copyDataStruct.cbData := 1 + Length(msg);
  copyDataStruct.lpData := PChar(msg);

  ListBox1.AddItem('SendCMD( "'+msg+'" , ' + IntToStr(receiverHandle)+' )',nil);
  res := SendMessage(receiverHandle, WM_COPYDATA, Integer(Handle), Integer(@copyDataStruct));

end;

procedure Split
   (const Delimiter: Char;
    Input: string;
    const Strings: TStrings) ;
begin
   Assert(Assigned(Strings)) ;
   Strings.Clear;
   Strings.Delimiter := Delimiter;
   Strings.DelimitedText := Input;
end;

procedure TSenderMainForm.OnCreate(Sender: TObject);
var
        i:Integer ;
        msg: string;
        resp: string;
        A: TStringList;
begin

   if ParamCount = 1 then
   begin
        A := TStringList.Create;

        try
                Split(',', ParamStr(1), A) ;
                Server_hwnd := StrToInt(a[0]) ;
                ListBox1.AddItem('Server_hwnd='+IntToStr(Server_hwnd), nil);
                msg := a[1];
                ListBox1.AddItem('Message='+msg, nil);
                SendCMD(msg);
                resp := SendCMDRecvText('PINGME='+IntToStr(Self.Handle));
                ListBox1.AddItem('Response = '+resp, nil);
        finally
                A.Free;
        end;
   end
   else
         ListBox1.AddItem('arguments should be hwnd,msg', nil);

   //for i := 0 to ParamCount do
   //        ListBox1.AddItem('Parameter '+IntToStr(i)+' = '+ParamStr(i), nil);

end;







end.

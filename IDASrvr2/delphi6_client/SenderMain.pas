unit SenderMain;

{

 base project by Zarko Gajic
  http://delphi.about.com/od/windowsshellapi/a/wm_copydata.htm

}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, registry;

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
    ListBox2: TListBox;
    Label1: TLabel;
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
  ida_hwnd : Integer;
  Response_Buffer: string;

implementation

{$R *.dfm}

procedure TSenderMainForm.WMCopyData(var Msg: TWMCopyData);
begin

  //ListBox1.AddItem('Received WM_CopyData message',nil );

  if Msg.CopyDataStruct.dwData = 3 then
  begin
     Response_Buffer := PChar(Msg.CopyDataStruct.lpData);
     if Length(Response_Buffer) > Msg.CopyDataStruct.cbData then
        Response_Buffer := Copy(Response_Buffer,0, Msg.CopyDataStruct.cbData);

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
        try
                Result :=  StrToInt(Response_Buffer);
        except
                Result := -1;
        end;
end;

procedure TSenderMainForm.SendCMD(msg: string);
var
  copyDataStruct : TCopyDataStruct;
  receiverHandle  : THandle;
  res : integer;
begin

  Response_Buffer := '';
  receiverHandle := ida_hwnd;
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
        reg:TRegistry;
        resp: string;
        idb: string;
        dasm: string;
        i: Integer;
        va: Integer;
begin
       reg:=TRegistry.Create;

       if reg.OpenKey('Software\VB and VBA Program Settings\IPC\Handles', False) then
       begin
                ida_hwnd := StrToInt(reg.ReadString('IDA_SERVER'));
                if ida_hwnd = 0 then
                begin
                      ListBox2.AddItem('IDA Handle not found.', nil);
                      Exit;
                end;

                ListBox1.AddItem('IDA Server HWND ='+IntToStr(ida_hwnd), nil);

                idb := SendCMDRecvText('loadedfile:' + IntToStr(Self.Handle));
                ListBox2.AddItem('Loaded file: '+ idb, nil);

                i := SendCMDRecvInt('numfuncs:' + IntToStr(Self.Handle));
                ListBox2.AddItem('NumFuncs: '+ IntToStr(i), nil);

                va := SendCMDRecvInt('funcstart:0:' + IntToStr(Self.Handle));
                ListBox2.AddItem('func[0].start: '+ Format('%x',[va]), nil);

                i := SendCMDRecvInt('funcend:0:' + IntToStr(Self.Handle));
                ListBox2.AddItem('func[0].end: '+ Format('%x',[i]), nil);

                dasm := SendCMDRecvText('getasm:' + IntToStr(va) + ':' + IntToStr(Self.Handle));
                ListBox2.AddItem('func[0].asm: '+ dasm, nil);

                ListBox2.AddItem('jumping to func[0].start', nil);
                SendCMD('jmp:'+ IntToStr(va) );

       end
       else
            ListBox2.AddItem('Could not find IDA IPC Handle Key', nil);


end;







end.

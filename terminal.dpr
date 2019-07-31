program terminal;

{$APPTYPE CONSOLE}

uses
  SysUtils, Variants, Windows, Classes, Forms, Graphics, IBDatabase, ExtCtrls,
  IBCustomDataSet, IBQuery, Contnrs, Reg, ConstUnit, FileInfo, Printers, StdCtrls, CPort,
  barcode in 'barcode.pas',
  draw in 'draw.pas',
  print in 'print.pas';

const
 dtSale                  = 1;  //��������� ���������
 dtReturnFullSale        = 1;  //������� ����� ���������

 dtBuy                   = 2;  //��������� ���������

 dtReturn                = 3;  //��������� ��������
 dtRemoving              = 4;  //��������� ��������

 dtTransportationIn      = 5;  //��������� ����������� �� �������� �����
 dtTransportationBetween = 6;  //��������� ����������� � ��������� ������ �� �������� �����
 dtTransportationOut     = 7;  //��������� ����������� � ��������� ������

 dtRoutes                = 8;  //���������� � �������� �����
 dtStorageDoc            = 9;  //��������� ��������
 dtCarConsSale           = 11; //������� ����������� ��������� �� ������
 dtSaleBonus             = 13; //�������� ���������



 InputLineStr='000000000000000000000000'; //������ ����������� ������
 InputLineGoods='0000000000000';//������ �����-���� ������
 LeftIndention=1; // ������ �����
 TopIndention=1; // ������ ������
 TopMenuIndention=1; //������ ������ ����
 LengthStr=20; //����������� ������ ������ � �������
 MaxCountError=100000000;
 Version='3.5.59.1';

type

 //���������
 TTermMenu = record
 Id: integer;
 PosMenu: integer;
 ParentId: integer;
 Title: string;
 end;

 PSale = ^TSale;
 TSale = record
 Id: String;
 SqnNo: String;
 Present: String;
 StorageId: String;
 StorageSectionId: String;
 LoadSaleType:integer;
 TotalBoxCount:integer;
 Loader: String;
 LoaderName:String;
 DrinkKindId:String;
 end;

 PBuy = ^TBuy;
 TBuy = record
 Id: string;
 Present: string;
 SqnNo: string;
 StorageId: string;
 Single: Boolean;
 DrinkKindId: string;
 RackId: string;
 end;

 PTransportation = ^TTransportation;
 TTransportation = record
 Id: string;
 Present:string;
 FromStorageId: string;
 ToStorageId: string;
 FromStorageType: integer;
 ToStorageType: integer;
 Single: Boolean;
 ToDrinkKindId: string;
 RackId: string;
 RackName: string;
 end;

 PTransportationFromRackToRack=^TTransportationFromRackToRack;
 TTransportationFromRackToRack = record
 FromStorageId:string;
 ToStorageId:string;
 CountBoxTransportation:integer;//��������������� ���-��
 ExistsBoxTransportation:integer;//������� ��� ����������
 SourceDrinkKindId:string;
 DestinationDrinkKindId:string;
 DrinkID:integer;
 DrinkName:string;
 SourceRackId:string;
 SourceRackName:string;
 DestinationRackId:string;
 DestinationRackName:string;
 TransportationFullRack:boolean;
 NewTransportation:boolean;
 BoxID:string;
 CapacityID:string;
 SaleBoxID:string;
 ContractorderID:string;
 TypemarketgroupID:string;
 Capacity:string;
 ReserveBoxCount:integer;
 ExistsBottleCount:integer;
 ReserveBottleCount:integer;
 DestinationStorageTypeId:integer;
 DestinationRackOneDrink:integer;
 CountBottleTransportation:integer;
 end;

 PTransportationBetweenRack = ^TTransportationBetweenRack;
 TTransportationBetweenRack = record
 TransportationID: string;
 Present:string;
 FromStorageId: string;
 ToStorageId: string;
 FromStorageTypeID: integer;
 ToStorageTypeID: integer;
 FromDrinkKindID:string;
 ToDrinkKindId: string;
 DrinkTransportationID:string;
 FromRackId: string;
 FromRackName: string;
 ToRackId: string;
 ToRackName: string;
 BottleCount:integer;
 DrinkRackCount:integer;
 DrinkRackCountOut:integer;
 FromBoxCapacity:integer;
 ToBoxCapacity:integer;
 DrinkName:string;
 Volume:string;
 TransBottlecount:integer;
 fromboxcount:integer;
 end;

 PReturn = ^TReturn;
 TReturn = record
 Id: String;
 Present: String;
 Sqnno: String;
 StorageId: String;
 RackId:string;
 RackName:string;
 NewDrinkKindID:integer;
 NewBoxCapacity:integer;
 IsFullSale:boolean;
 Loader: String;
 LoaderName:String;
 end;

 PRemoving = ^TRemoving;
 TRemoving = record
 Id: String;
 Present: String;
 SqnNo: String;
 StorageId: String;
 DrinkKindId: String;
 RackId:string;
 CodesID:string;
 end;

 PPrintCodes = ^TPrintCodes;
 TPrintCodes = record
 Single: Boolean;
 Codes: array of string;
 DrinkFactory: string;
 DrinkMark:string;
 DrinkVolume:string;
 DrinkGroupName:string;
 WhoCreated:string;
 RackName:string;
 DrinkId:string;
 BuyBox:string;
 SaleBox:string;
 DateFactory:string;
 RackID:string;
 FlagSaveRack:smallint;
 end;

 TUserInfo =record
 Id:integer;
 Name:string;
 Login:string;
 DeptId:integer;
 FirmName:string;
 PhoneFirm:string;
 end;

 TLoadSaleInfo = record
  CleradBoxCount:integer;
  TotalBoxCount:integer;
  StorageSectionName: string;
 end;

 TPrinterSettings=record
 Enable:boolean;
 Name:string;
 Port:string;
 FontPath:string;
 end;


var
//-----------------------------------------
//     ������ � ���� ���������
//-----------------------------------------
 ConHandle  : THandle; // ���������� ����������� ����
 Coord      : TCoord;  // ��� ��������/��������� ������� ������
 MaxX, MaxY : Word;    // ��� �������� ������������ �������� ����
 CCI        : TConsoleCursorInfo;
 NOAW       : THandle; // ��� �������� ����������� ��������� �������
 IBuff      : TInputRecord;
 IEvent     : DWord;
 Continue,KeyVkReturn : Bool;
 TermMenu:array of TTermMenu;
 MenuPosition:array[0..5] of integer;
 InputLine: string;
 ErrorMessage:string;
 TermMode,dwCount:DWORD;

//-----------------------------------------
//      ��������
//-----------------------------------------
 TerminalID:string;//1 - ���������, 2 - �.��������
 TermStorageID:string;
 FlagLoader: string;

//-----------------------------------------
//      ������
//-----------------------------------------
 PrinterSettings:TPrinterSettings;
 ComPort: TComPort;

//-----------------------------------------
//      ������ � �����
//-----------------------------------------
 DatabaseIBD:TIBDatabase;

 ReadIBQ:TIBQuery;
 InUpDelIBQ:TIBQuery;
 ErrorIBQ:TIBQuery;

 ReadIBT:TIBTransaction;
 InUpDelIBT:TIBTransaction;
 ErrorIBT:TIBTransaction;


//-----------------------------------------
//     ������ ��� ��������
//-----------------------------------------
 Sale:PSale;
 Buy:PBuy;
 Transportation:PTransportation;
 TransportationFromRackToRack:PTransportationFromRackToRack;
 TransportationBetweenRack:PTransportationBetweenRack;
 Return:PReturn;
 Removing:PRemoving;
 PrintCodes:PPrintCodes;
 UserInfo:TUserInfo;
label GoToOnLogin;

function ReplaceSub(str, sub1, sub2: string): string;
 var aPos: Integer;
     rslt: string;
 begin
  aPos := Pos(sub1, str);
  rslt := '';
  while (aPos <> 0) do
   begin
    rslt := rslt + Copy(str, 1, aPos - 1) + sub2;
    Delete(str, 1, aPos + Length(sub1) - 1);
    aPos := Pos(sub1, str);
   end;
  Result := rslt + str;
 end;

//-----------------------------------------
//      ��������� ����������� ��� ����������� �����
//-----------------------------------------

function GetConInputHandle : THandle;
begin
 Result := GetStdHandle(STD_INPUT_HANDLE)
end;

//-----------------------------------------
//      ��������� ����������� ��� ����������� ������
//-----------------------------------------
function GetConOutputHandle : THandle;
begin
 Result := GetStdHandle(STD_OUTPUT_HANDLE)
end;

//-----------------------------------------
//        ��������� ������� � ���������� X, Y
//-----------------------------------------
procedure GotoXY(X, Y : Word);
begin
 Coord.X := X;
 Coord.Y := Y;
 SetConsoleCursorPosition(ConHandle, Coord);
end;

//-----------------------------------------
//   ������� ������ - ���������� ��� ���������
//-----------------------------------------
procedure ClearConsole;
var csbi:CONSOLE_SCREEN_BUFFER_INFO;
    sz,dw:word;
begin

 Coord.X := 0; Coord.Y := 0;

 GetConsoleScreenBufferInfo(ConHandle, csbi);
 sz:=csbi.dwSize.X * csbi.dwSize.Y;
 FillConsoleOutputCharacter(ConHandle, ' ', sz, Coord, NOAW);
 FillConsoleOutputAttribute(ConHandle, csbi.wAttributes, sz, Coord, NOAW);

 {FillConsoleOutputCharacter(ConHandle,' ',MaxX*MaxY, Coord, NOAW);
 FillConsoleOutputAttribute(ConHandle,0,MaxX*MaxY,Coord, NOAW);}
 GotoXY(0, 0);
end;

//--------------------------------------
//   ������� �����, ��� ������ � ���� ��������� �������
//--------------------------------------
procedure ClearLine(X:integer;Y:integer);
begin
 Coord.X := 0; Coord.Y := Y;
 FillConsoleOutputCharacter(ConHandle, ' ', MaxX*MaxY,  Coord, NOAW);
 FillConsoleOutputAttribute(ConHandle, 0, MaxX*MaxY, Coord, NOAW);
 GotoXY(X, Y);
end;

//--------------------------------------
//           ����������/�������� ������
//--------------------------------------
procedure ShowCursor(Show : Bool);
begin
 CCI.bVisible := Show;
 CCI.dwSize:=500;
 SetConsoleCursorInfo(ConHandle, CCI);
end;

//--------------------------------------
// ������������� ���������� ����������
//--------------------------------------
procedure Init;
begin
// �������� ���������� ������ (output)
 ConHandle := GetConOutputHandle;
// �������� ������������ ������� ����
 Coord := GetLargestConsoleWindowSize(ConHandle);
 MaxX := Coord.X;
 MaxY := Coord.Y;
end;

//--------------------------------------
// ������ ���� � �������
//--------------------------------------
function ReadLine(var Line:String):boolean;
var WaitFlag:boolean;
begin
 WaitFlag:=true;
 Result:=false;
 GotoXY(1,Coord.Y);
 Write(Line);

 while WaitFlag do
  begin
   ReadConsoleInput(GetConInputHandle, IBuff, 1, IEvent);
   case IBuff.EventType of
    KEY_EVENT:
     begin
      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode in [48,49,50,51,52,53,54,55,56,57])) then
       Line:=Line+(IntToStr(IBuff.Event.KeyEvent.wVirtualKeyCode-48));

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode in [96,97,98,99,100,101,102,103,104,105])) then
       Line:=Line+(IntToStr(IBuff.Event.KeyEvent.wVirtualKeyCode-96));

      if ((IBuff.Event.KeyEvent.bKeyDown = True)
       and (IBuff.Event.KeyEvent.wVirtualKeyCode in [46,190,110,191])) then
       Line:=Line+'.';

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_RETURN)) then
       begin
        WaitFlag:=false;
        if Line='' then Result:=false
                   else Result:=true;
       end;

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_ESCAPE)) then
       begin
        WaitFlag:=false;
        Result:=false;
       end;

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_BACK)) then
       begin
        ClearLine(LeftIndention,Coord.Y);
        Line:=Copy(Line,1,length(Line)-1);
       end;

      if (IBuff.Event.KeyEvent.bKeyDown = True) then
       begin
        GotoXY(1,Coord.Y);
        Write(Line);
       end;
     end;
   end;
  end;
end;

//--------------------------------------
// ������ ������ � �������
//--------------------------------------
function capslock(flag:integer;s,l:string):string;
begin
 result:=l; if flag=32 then result:=s;
end;

function ReadStr(var Line:String):boolean;
var WaitFlag:boolean;
begin
 WaitFlag:=true;
 Result:=false;
 GotoXY(1,Coord.Y);
 Write(Line);

 while WaitFlag do
  begin
   ReadConsoleInput(GetConInputHandle, IBuff, 1, IEvent);
   case IBuff.EventType of
    KEY_EVENT:
     begin
      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode in [48,49,50,51,52,53,54,55,56,57]) ) then
       Line:=Line+(IntToStr(IBuff.Event.KeyEvent.wVirtualKeyCode-48));

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode in [96,97,98,99,100,101,102,103,104,105])) then
       Line:=Line+(IntToStr(IBuff.Event.KeyEvent.wVirtualKeyCode-96));

      if ((IBuff.Event.KeyEvent.bKeyDown = True)
       and (IBuff.Event.KeyEvent.wVirtualKeyCode in [65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
                                                     //97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,121,
                                                     186,190,191])) then
       begin
        case IBuff.Event.KeyEvent.wVirtualKeyCode of
         65:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'a','A');
         66:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'b','B');
         67:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'c','C');
         68:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'d','D');
         69:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'e','E');
         70:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'f','F');
         71:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'g','G');
         72:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'h','H');
         73:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'i','I');
         74:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'j','J');
         75:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'k','K');
         76:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'l','L');
         77:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'m','M');
         78:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'n','N');
         79:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'o','O');
         80:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'p','P');
         81:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'q','Q');
         82:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'a','R');
         83:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'s','S');
         84:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'t','T');
         85:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'u','U');
         86:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'v','V');
         87:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'w','W');
         88:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'x','X');
         89:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'y','Y');
         90:Line:=Line+capslock(IBuff.Event.KeyEvent.dwControlKeyState,'z','Z');
         186:Line:=Line+':';
         190:Line:=Line+'.';
         191:Line:=Line+'/';
        end;
       end;

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_RETURN)) then
       begin
        WaitFlag:=false;
        if Line='' then Result:=false
                   else Result:=true;
       end;

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_ESCAPE)) then
       begin
        WaitFlag:=false;
        Result:=false;
       end;

      if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_BACK)) then
       begin
        ClearLine(LeftIndention,Coord.Y);
        Line:=Copy(Line,1,length(Line)-1);
       end;

      if (IBuff.Event.KeyEvent.bKeyDown = True) then
       begin
        GotoXY(1,Coord.Y);
        Write(Line);
       end;
     end;
   end;
  end;
end;
//---------------------------------------
//          ������ ������
//---------------------------------------
procedure DrawMenuLine(OutputLine : String; Gorizont:integer; Vertic:integer; ColorText:word);
begin
 OutputLine:=AnToAs(OutputLine);
 Coord.X := Gorizont; Coord.Y := Vertic;
 WriteConsoleOutputCharacter(ConHandle,PChar(OutputLine),Length(OutputLine)+1,Coord,NOAW);
 FillConsoleOutputAttribute (ConHandle,ColorText,Length(OutputLine),Coord,NOAW);
 GotoXY(Gorizont,Vertic);
end;

procedure DrawLine(OutputLine : String; Gorizont:integer; Vertic:integer; ColorText:word);
begin
 OutputLine:=AnToAs(OutputLine);
 Coord.X := Gorizont;
 Coord.Y := Vertic;
 WriteConsoleOutputCharacter(ConHandle, PChar(OutputLine),   Length(OutputLine)+1, Coord, NOAW);
 FillConsoleOutputAttribute (ConHandle, ColorText, Length(OutputLine),   Coord, NOAW);
 GotoXY(Gorizont,Vertic+1);
end;

//--------------------------------------
// ������������ ���������������� ������
//--------------------------------------
procedure DrawText(text:string);
var i,j,z: integer;
    flagnextline:boolean;
    str,finalystr:array of string;
begin
 flagnextline:=false;
 ClearConsole;
 i:=0;j:=1;
 while i<length(text) do //������� ���������� ���� � ������
  begin
   if IsDelimiter(' '#10#13,text,i) then
     inc(j);
   inc(i);
  end;
 SetLength(str,j); //������� ������ ����

 j:=0;i:=0;z:=1;
 while i<length(text) do //������� ����� � ������
  begin
   if IsDelimiter(' '#10#13,text,i) then
    begin
     if trim(copy(text,z,i-z))<>'' then
      begin
       str[j]:=trim(copy(text,z,i-z));
       z:=i;
       inc(j);
      end;
    end;
   inc(i);
  end;
 if trim(copy(text,z,i-z))<>'' then
  str[j]:=trim(copy(text,z,i-z+1));

 i:=1;z:=0;
 if str[z][1]='"' then
  str[z]:=copy(str[z],2,length(str[z]));
 while i<j+1 do //������� ������ ������������ ������
  begin
   if (length(str[z]+' '+str[i])<=lengthstr) and (str[i][1]<>'"') and (str[i][length(str[i])]<>'"') then
    begin
     if flagnextline then
      str[z]:=str[i]
     else
      str[z]:=str[z]+' '+str[i];
     flagnextline:=false;
    end
   else
    begin
     if (str[i][1]<>'"') and (str[i][length(str[i])]<>'"') then
      begin
       if not flagnextline then
        inc(z);
       str[z]:=copy(str[i],1,length(str[i]));
       flagnextline:=false;
      end
     else
      begin
       if (str[i][1]='"') and (str[i][length(str[i])]<>'"') then
        begin
         if not flagnextline then
          inc(z);
         str[z]:=copy(str[i],2,length(str[i]));
         flagnextline:=false;
        end;
       if (str[i][1]='"') and (str[i][length(str[i])]='"') then
        begin
         if not flagnextline then
          inc(z);
         str[z]:=copy(str[i],2,length(str[i])-2);
         inc(z);
         flagnextline:=true;
        end;
       if (str[i][1]<>'"') and (str[i][length(str[i])]='"') then
        begin
         str[z]:=str[z]+' '+copy(str[i],1,length(str[i])-1);
         inc(z);
         flagnextline:=true;
        end;
      end;
    end;
   inc(i);
  end;

 if flagnextline then
  dec(z);
 i:=0; SetLength(finalystr,z+1);
 while i<z+1 do // ������� � ��������� ������ ����� � ����������
  begin
   finalystr[i]:=str[i];
   finalystr[i]:=Copy(finalystr[i],1,lengthstr);
   while length(finalystr[i])<lengthstr do
    begin
     if (lengthstr-length(finalystr[i])) mod 2<>0 then
      finalystr[i]:=finalystr[i]+' '
     else
      finalystr[i]:=' '+finalystr[i]+' ';
    end;
   DrawLine(finalystr[i],LeftIndention,i+TopIndention,WhiteOnBlack);
   inc(i);
  end;
end;

function CleanStr(text:string):string;
var i:integer;
begin
 i:=length(text);
 while i>0 do
  begin
   if text[i]=' ' then
    result:=Copy(text,0,i-1)
   else
    break;
   Dec(i);
  end;
end;

function BuildLine(text:string;lengthtext:integer):string;
begin
 Result:=Copy(text,1,lengthtext);
 if length(Result)>=lengthtext then
  Result:=Copy(Result,1,lengthtext)
 else
  while length(Result)<lengthtext do
   Result:=Result+' ';
end;

//-----------------------------------------------------
//               ���������� ���������� �������
//-----------------------------------------------------
function ConProc(CtrlType : DWord) : Bool; stdcall; far;
var
 S : String;
begin
 case CtrlType of
   CTRL_C_EVENT        : S := 'CTRL_C_EVENT';
   CTRL_BREAK_EVENT    : S := 'CTRL_BREAK_EVENT';
   CTRL_CLOSE_EVENT    : S := 'CTRL_CLOSE_EVENT';
   CTRL_LOGOFF_EVENT   : S := 'CTRL_LOGOFF_EVENT';
   CTRL_SHUTDOWN_EVENT : S := 'CTRL_SHUTDOWN_EVENT';
  else
   S := 'UNKNOWN_EVENT';
 end;
 MessageBox(0, PChar(S + ' detected'), 'Win32 Console', MB_OK);
 Result := True;
end;
//--------------------------------------
// ������ ����
//--------------------------------------
procedure DrawMenu(ParentId:integer);
var i,j:integer;
begin
 ClearConsole;
 i:=1;
 j:=0;
 while i<Length(TermMenu) do
  begin
   if TermMenu[i].ParentId=ParentID then
    begin
     DrawMenuLine(TermMenu[i].Title,MenuPosition[5],j+TopMenuIndention,WhiteOnBlack);
     Inc(j);
    end;
   Inc(i);
  end;
 MenuPosition[3]:=j;//���������� ����� � ����
 MenuPosition[4]:=TermMenu[MenuPosition[0]+MenuPosition[2]].Id;
 DrawMenuLine(TermMenu[MenuPosition[0]+MenuPosition[2]].Title,MenuPosition[5],MenuPosition[0]+TopMenuIndention-1,BlackOnWhite);
end;

//--------------------------------------
// ������ ������
//--------------------------------------
procedure DrawError(ErrorMes:string);
var X,Y:integer;
begin
{ X:=Coord.X;
 Y:=Coord.Y;}
 DrawText(ErrorMes);
 Write(#27+'8');
 Write(#27+'%5;2;2T');
 //GotoXY(X,Y+1);
 GotoXY(0,0);
 InputLine:='';
 readline(InputLine);
 ClearConsole;
end;

procedure InitializationPrinter;
begin
 PrinterSettings.Enable:=false;
 ReadParamFromRegistry(PrinterSettings.Name,Root,TerminalFolder,'PrinterName','Printer');
 ReadParamFromRegistry(PrinterSettings.Port,Root,TerminalFolder,'PrinterPort','COM1');
 ReadParamFromRegistry(PrinterSettings.FontPath,Root,TerminalFolder,'PrinterFontPath','C:\Fonts');
 ReadParamFromRegistry(FlagLoader,Root,TerminalFolder,'FlagLoader','1');
 try
  if not (PrinterSettings.Name='Printer') then
   begin
    if not Assigned(ComPort) then
     begin
      ComPort:=TComPort.Create(nil);
      ComPort.DiscardNull:=true;
     end;
    ComPort.Port:=PrinterSettings.Port;
    ComPort.Open;
    ComPort.Close;
   end;
  PrinterSettings.Enable:=true;
 except
  PrinterSettings.Enable:=false;
 end;
end;

function SettingsScreen_0(FromMainMenu:boolean):boolean;
var login,password:string;
begin
 Result:=true;
 DrawText('��� ������������');
 ExtractParamFromRegistry(login,password,ReadStringFromRegistry('logpas',TerminalFolder,root,''));
 if ReadStr(login) then
  WriteStringToRegistry(CreateParamToRegistry(login+':'+password),'logpas',TerminalFolder,root)
 else
   Result:=false;
end;

function SettingsScreen_1(FromMainMenu:boolean):boolean;
var login,password:string;
begin
 DrawText('������ ������������');
 ExtractParamFromRegistry(login,password,ReadStringFromRegistry('logpas',TerminalFolder,root,''));
 password:='';

 if ReadStr(password) then
  begin
   if password<>'' then
    WriteStringToRegistry(CreateParamToRegistry(login+':'+password),'logpas',TerminalFolder,root);
   Result:=true;
  end
 else
  Result:=false;
end;

function SettingsScreen_2(FromMainMenu:boolean):boolean;
var BasePath:string;
begin
 Result:=true;
 DrawText('���� � ��');
 ReadParamFromRegistry(BasePath,Root,BaseFolder,'BaseMainPath',DefaultBasePath);
 if ReadStr(BasePath) then
  WriteStringToRegistry(BasePath,'BaseMainPath',BaseFolder,Root)
 else
   Result:=false;
end;

function SettingsScreen_3(FromMainMenu:boolean):boolean;
var PrinterPort:string;
begin
 Result:=true;
 DrawText('���� ��������');
 ReadParamFromRegistry(PrinterPort,Root,TerminalFolder,'PrinterPort','COM1');
 if ReadStr(PrinterPort) then
  WriteStringToRegistry(PrinterPort,'PrinterPort',TerminalFolder,Root)
 else
  Result:=false;

 InitializationPrinter;
end;

function SettingsScreen_4(FromMainMenu:boolean):boolean;
var PrinterName:string;
begin
 Result:=true;
 DrawText('�������� ��������');
 ReadParamFromRegistry(PrinterName,Root,TerminalFolder,'PrinterName','Printer');
 if ReadStr(PrinterName) then
  WriteStringToRegistry(PrinterName,'PrinterName',TerminalFolder,Root)
 else
  Result:=false;

 InitializationPrinter;
end;

function SettingsScreen_5(FromMainMenu:boolean):boolean;
var PrinterFontPath:string;
begin
 Result:=true;
 DrawText('���� � �������');
 ReadParamFromRegistry(PrinterFontPath,Root,TerminalFolder,'PrinterFontPath','C:\Fonts');
 if ReadStr(PrinterFontPath) then
  WriteStringToRegistry(PrinterFontPath,'PrinterFontPath',TerminalFolder,Root)
 else
   Result:=false;
end;

function SettingsScreen_6(FromMainMenu:boolean):boolean;
begin
 Result:=true;
 if PrinterSettings.Enable then
  begin
   DrawText('�������� ������� ������ ��������� �����');
   try
    ComPort.Open;
    ComPort.WriteStr(#02+'Q');
    ComPort.Close;

    if (PrinterSettings.Name='CLP2001') or
       (PrinterSettings.Name='CLP7201') or
       (PrinterSettings.Name='CLP6001') then
     begin
      CopyFile(PChar(PrinterSettings.FontPath+'\font.id'),PChar(PrinterSettings.Port), false);
      CopyFile(PChar(PrinterSettings.FontPath+'\aria7wi.sfp'),PChar(PrinterSettings.Port), false);
     end;
    if (PrinterSettings.Name='DMXI4208') or
       (PrinterSettings.Name='DMXM4206') then
     CopyFile(PChar(PrinterSettings.FontPath+'\arial7r_dmx.prn'),PChar(PrinterSettings.Port), false);
   except
    ;
   end;
  end
 else
  DrawError('�� ���������� ������� "��� �����������" "������� Ok"');
end;

function VersionScreen_0(FromMainMenu:boolean):boolean;
begin
 DrawError('"������: '+Version+'" "������: '+Copy(DatabaseIBD.DatabaseName,1,Pos(':',DatabaseIBD.DatabaseName)-1)+'"');
end;

//-----------------------------------------------------
//   ��������� ����-��� �� ������������ ���������
//-----------------------------------------------------
function CheckBarcodeOnDoc(Mes: String; const DocType: Integer): Boolean;
begin
 Result:=((StrToIntDef(Copy(Mes,1,4),-1)=100+DocType) and (Length(Mes)>=11));
end;
//-----------------------------------------------------
//   ��������� ����-��� �� ������������ ���������
//-----------------------------------------------------
function CheckDocBarcode(Mes: String; const DocType: Integer): Boolean;
begin
 Result:=((StrToIntDef(Copy(Mes,1,2),-1)=DocType) and (Length(Mes)=16));
end;

function CheckDocBarcode18(Mes: String; const DocType: Integer): Boolean;
begin
 Result:=((StrToIntDef(Copy(Mes,1,3),-1)=DocType) and (Length(Mes)=18));
end;

//-----------------------------------------------------
//   ��������� ����-��� �� ������������ ��������
//-----------------------------------------------------
function CheckBarcodeOnLabel(Mes: String): Boolean;
begin
 Result:=((Mes[1]='2') and ((Length(Mes)=20) or (Length(Mes)=21) or (Length(Mes)=13)));
end;
//-----------------------------------------------------
//   ��������� ����-��� �� ������������ ��������
//-----------------------------------------------------
function CheckBarcodeOnGoods(Mes: String): Boolean;
begin
 Result:=(Length(Mes)>7); //�.�. ���� ������ ������� ������� �� ����� ����� 8,12,13 ��������
end;

//--------------------------------------
// �������������� ����� � �����
//--------------------------------------
function SetDatabaseParams(var errorstr:string): Boolean;
var BasePath,BaseSQLDialect,BaseCharacterSet,Login,Password:string;
begin
 Result:=false;

 DatabaseIBD:=TIBDatabase.Create(nil);
 ReadIBT:=TIBTransaction.Create(nil);
 InUpDelIBT:=TIBTransaction.Create(nil);
 ErrorIBT:=TIBTransaction.Create(nil);
 ReadIBQ:=TIBQuery.Create(nil);
 InUpDelIBQ:=TIBQuery.Create(nil);
 ErrorIBQ:=TIBQuery.Create(nil);

 DatabaseIBD.Connected:=false;
 if  (not ReadParamFromRegistry(BasePath,Root,BaseFolder,'BaseMainPath',DefaultBasePath))
  or (not ReadParamFromRegistry(BaseSQLDialect,Root,BaseFolder,'BaseMainSQLDialect',DefaultBaseSQLDialect))
  or (not ReadParamFromRegistry(BaseCharacterSet,Root,BaseFolder,'BaseMainCharacterSet',DefaultBaseCharacterSet))
  or (not ExtractParamFromRegistry(Login,Password,ReadStringFromRegistry('logpas',TerminalFolder,Root,''))) then
   begin
    errorstr:='fileuser';
    exit;
   end;

 DatabaseIBD.DatabaseName:=BasePath;
 DatabaseIBD.SQLDialect:=StrToIntDef(BaseSQLDialect,1);
 DatabaseIBD.Params.Clear;
 DatabaseIBD.Params.Add('lc_ctype='+BaseCharacterSet);
 DatabaseIBD.Params.Add('user_name='+Login);
 DatabaseIBD.Params.Add('password='+Password);
 DatabaseIBD.LoginPrompt:=false;

 ReadIBT.Active:=false;
 ReadIBT.AutoStopAction:=saRollback;
 ReadIBT.DefaultAction:=TARollback;
 ReadIBT.DefaultDatabase:=DatabaseIBD;
 ReadIBT.Params.Add('read_committed');
 ReadIBT.Params.Add('rec_version');
 ReadIBT.Params.Add('nowait');

 InUpDelIBT.Active:=false;
 InUpDelIBT.AutoStopAction:=saNone;
 InUpDelIBT.DefaultAction:=TARollback;
 InUpDelIBT.DefaultDatabase:=DatabaseIBD;
 InUpDelIBT.Params.Add('read_committed');
 InUpDelIBT.Params.Add('rec_version');
 InUpDelIBT.Params.Add('nowait');

 ErrorIBT.Active:=false;
 ErrorIBT.AutoStopAction:=saNone;
 ErrorIBT.DefaultAction:=TARollback;
 ErrorIBT.DefaultDatabase:=DatabaseIBD;
 ErrorIBT.Params.Add('read_committed');
 ErrorIBT.Params.Add('rec_version');
 ErrorIBT.Params.Add('nowait');

 ReadIBQ.Database:=DatabaseIBD;
 ReadIBQ.Transaction:=ReadIBT;

 InUpDelIBQ.Database:=DatabaseIBD;
 InUpDelIBQ.Transaction:=InUpDelIBT;

 ErrorIBQ.Database:=DatabaseIBD;
 ErrorIBQ.Transaction:=ErrorIBT;
 try
  DatabaseIBD.Connected:=true;
  Result:=true;
 except on E:Exception do
  errorstr:=E.Message;
 end;
end;

//--------------------------------------
// ������� ������ � ����
//--------------------------------------
procedure CreateErrorMessage(const objecterror, messageerror: string);
const CmdText='insert into errormessage(objecterror, messageerror) values("%s","%s")';
var s   : string;
    stmp: string;
    idx : integer;
begin
 ErrorIBT.StartTransaction;
 try
  stmp:=messageerror;

  idx:=Pos('"', stmp);
  while idx > 0 do
   begin
    Delete(stmp,idx,1);
    idx:=Pos('"', stmp);
   end;

  s:=Format(CmdText,[objecterror,stmp]);
  ErrorIBQ.Close;
  ErrorIBQ.SQL.Clear;
  ErrorIBQ.SQL.Add(s);
  ErrorIBQ.ExecSQL;
  ErrorIBT.Commit;
 except
  ErrorIBT.Rollback;
 end;
end;

//--------------------------------------
// ���������� �������
//--------------------------------------
function OpenIBQ(IBQ:TIBQuery; CmdText:string; var Error:boolean; var ErrorMessage:string):boolean;
begin
 Error:=false;
 ErrorMessage:='';
 try
  IBQ.Close;
  IBQ.SQL.Clear;
  IBQ.SQL.Add(CmdText);
  IBQ.Open;
  IBQ.FetchAll;
  Result:= not IBQ.IsEmpty;
 except on E:Exception do
  begin
   Result:=false;
   Error:=true;
   CreateErrorMessage('TERMINAL - OpenDS '+Copy(IBQ.SQL.CommaText,2,length(IBQ.SQL.CommaText)-2),E.Message);
   ErrorMessage:=E.Message;
   if InUpDelIBT.Active then
    InUpDelIBT.Rollback;
  end;
 end;
end;

function CheckDrinkKindInCash(Mes: String): Boolean;
var CmdText:string;
    Error: Boolean;
begin
 CmdText:='select 1 from cashe ch '+
          'where ch.drinkkindid='+IntToStr(StrToIntDef(Mes,-1))+
          ' and ch.storageid in ('+TermStorageid+')';

 Result:=OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage);
end;

//--------------------------------------
// ������� ����
//--------------------------------------
function CreateMenuItem: Boolean;
var i,j:integer;
    CmdText:string;
    Error:boolean;
begin
 result:=false;
 CmdText:='select posmenu,number,parentnumber,name from termmenu where isenable=1 order by parentnumber, posmenu';

 if OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   ReadIBQ.First;
   SetLength(TermMenu,ReadIBQ.RecordCount+1);
   i:=1;
   j:=0;
   while not ReadIBQ.Eof do
    begin
     TermMenu[i].Id:=ReadIBQ.FieldByName('number').AsInteger;
     TermMenu[i].PosMenu:=ReadIBQ.FieldByName('posmenu').AsInteger;
     TermMenu[i].ParentId:=ReadIBQ.FieldByName('parentnumber').AsInteger;
     TermMenu[i].Title:=ReadIBQ.FieldByName('name').AsString;
     if TermMenu[i].ParentId=1 then
      Inc(j);
     ReadIBQ.Next;
     inc(i);
    end;

   MenuPosition[0]:=1;//������� � ����
   MenuPosition[1]:=1;//��������
   MenuPosition[2]:=0;//������� � ������
   MenuPosition[3]:=j;//���������� �������
   MenuPosition[4]:=100;//�������������� ����� ������� � ����
   MenuPosition[5]:=6;//������ �����
  end
 else
  if Error then
   DrawError('� �������� ���������� ��������� ������. ��� ����������� ������� Ok')
  else
   DrawError('���� ��� ������������� ����. ��� ����������� ������� Ok');

end;

function OnLogin:boolean;
var flag,error,settingsflag:boolean;
    CmdText,errorstr:string;
begin
 result:=false;
 flag:=true;
 settingsflag:=false;
 while flag do
  begin
   DrawText('"���� � ���������" "���������� �����-���"');
   InputLine:='';
   if ReadLine(InputLine) then
    begin
     DrawText('������������� ���� ������ ��������� ������');
     if ((InputLine='') or (StrToIntDef(Copy(InputLine,2,Length(InputLine)-2),0)<=0) or (length(InputLine)<2)) then
      begin
       DrawError('"�� ����������" "���� ������" "��� �����������" "������� Ok"');
       flag:=true;
      end
     else
      begin
       if (not SetDatabaseParams(errorstr)) or (TerminalID='0') or (TermStorageID='0') then
        begin
         {if pos('file',errorstr)>0 then
          if SettingsScreen_2(true) then
           settingsflag:=true;
         if pos('user',errorstr)>0 then
          if SettingsScreen_0(true) then
           if SettingsScreen_1(true) then
            settingsflag:=true;
         if not settingsflag then}
         DrawError('�� ������� ���������� ����������� � ����. ���������� � ���������� ��������������.');
        end
       else
        begin
         CmdText:=
          'select distinct id, name '+
          'from terminal_userlog('+#39+InputLine+#39+') '+
          'where terminalid in ('+TerminalID+')';
         if OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
          begin
           ReadIBQ.First;
           UserInfo.Id:=ReadIBQ.FieldByName('id').AsInteger;
           UserInfo.Name:=ReadIBQ.FieldByName('name').AsString;
           UserInfo.Login:='';
           result:=true;
           CreateMenuItem;
           //DrawMenu(1);
           break;
          end
         else
          DrawError('"�� ����������" "���� ������" "��� �����������" "������� Ok"');
        end;//else if not SetDatabaseParams then
      end;//else if ((InputLine='')
    end //if ReadLine(InputLine) then
   else
    flag:=true;
  end;//while flag do
end;

function GetDisplacing(ParentId:integer):integer;
var i:integer;
begin
 i:=1;
 Result:=0;
 while i<Length(TermMenu) do
  begin
   if TermMenu[i].ParentId=ParentId then
    begin
     Result:=i-1;
     break;
    end;
   Inc(i);
  end;
end;

function GetPosition(ParentId:integer):integer;
var i:integer;
begin
 i:=1;
 Result:=0;
 while i<Length(TermMenu) do
  begin
   if TermMenu[i].Id=ParentID then
    begin
     Result:=TermMenu[i].PosMenu;
     break;
    end;
   Inc(i);
  end;
end;

procedure PrintOnDefaultPrinter(ZoomPercent:Integer);
var ImageBarcode:TImage;
    BarcodeText:TBarcode;
    relHeight, relWidth, i: integer;
begin
 try
  BarcodeText:=TBarcode.Create(nil);
  BarcodeText.Angle:=0;
  BarcodeText.Checksum:=false;
  BarcodeText.CheckSumMethod:=csmModulo10;
  BarcodeText.Height:=30;
  BarcodeText.Left:=30;
  BarcodeText.Modul:=1;
  BarcodeText.Ratio:=2;
  BarcodeText.ShowText:=bcoCodeBottom;
  BarcodeText.Tag:=0;
  BarcodeText.Top:=10;
  BarcodeText.Typ:=bcCode128C;

  Printer.BeginDoc;
  i:=0;
  while i<Length(PrintCodes.Codes) do
   begin
    ImageBarcode:=TImage.Create(nil);
    ImageBarcode.Height:=100;
    ImageBarcode.Width:=200;
    ImageBarcode.Picture.Bitmap := TBitmap.Create;

    with ImageBarcode.Picture.Bitmap do
     begin
      Width := ImageBarcode.Width;
      Height := ImageBarcode.Height;
      Canvas.FillRect(Canvas.ClipRect);
      Canvas.Brush.Color := clWhite;
      Canvas.Pen.Color := clBlack;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(10, 5);
      Canvas.LineTo(10, 190);
      Canvas.MoveTo(10, 50);
      Canvas.LineTo(190,50);
      Canvas.MoveTo(10, 70);
      Canvas.LineTo(190,70);
      BarcodeText.Text:=PrintCodes.Codes[i];
      BarcodeText.DrawBarcode(Canvas);
      Transparent := TRUE;


      if ((Width / Height) > (Printer.PageWidth / Printer.PageHeight)) then
       begin
        relWidth := Printer.PageWidth;
        relHeight := MulDiv(Height, Printer.PageWidth, Width);
       end
      else
       begin
        relWidth := MulDiv(Width, Printer.PageHeight, Height);
        relHeight := Printer.PageHeight;
       end;
      relWidth := Round(relWidth * ZoomPercent / 100);
      relHeight := Round(relHeight * ZoomPercent / 100);
     end;
    DrawImage(Printer.Canvas, Rect(i, i*700, relWidth, relHeight),ImageBarcode.Picture.Bitmap);
    Inc(i);
   end;
  Printer.EndDoc;
 except
  ;
 end;
end;

procedure PrintOnCLPEtiquettePrinter;
var PrintStr:string;
    i:integer;
begin
 if not Assigned(ComPort) then
  begin
   ComPort:=TComPort.Create(nil);
   ComPort.DiscardNull:=true;
   ComPort.Port:=PrinterSettings.Port;
  end;

 if not ComPort.Connected then
  ComPort.Open;

 i:=0;
 if not PrintCodes.Single then
  while i<Length(PrintCodes.Codes) do
   begin
    PrintStr:=#02+'n'+ //m - ������� � ����������� �������
              #02+'e'+
              #02+'L'+ //������� ������ ������������ ������ ��������
              'PK'+    //������������� �������� ���������� �������.   K=152.4 mm/sec
              'SO'+    //������������� �������� ������������ �������. O=203.2 mm/sec
              #02+'D11'+ //D11 - ������ �������� �� ����������� � �� ���������
              'C'+'0'+ //�������� ������������ ������ ���� ��������
              'R'+'0'+ //�������� ������������ ������� ���� ��������
              'H10';   //������������� ��������� ������ (������� ������� ����������� �� ���������� �������)
    try
     ComPort.WriteStr(PrintStr);
     //�����
     PrintStr:='1X1100000000025L001110'+#13#10; //7    //���������
     ComPort.WriteStr(PrintStr);
     PrintStr:='1X1100000350026L210001'+#13#10; //7    1 //�������
     ComPort.WriteStr(PrintStr);

     //������ ����� ����
     PrintStr:='1e2205500400050C'+PrintCodes.Codes[i]+#13#10;
     ComPort.WriteStr(PrintStr);
     //������ ����������� �����-����
     PrintStr:='121100000950050'+Copy(PrintCodes.Codes[i],1,9)+'  '+Copy(PrintCodes.Codes[i],10,7)+'  '+Copy(PrintCodes.Codes[i],17,5)+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ����
     PrintStr:='191112500240030���� ����: '+PrintCodes.BuyBox+
                             ' ���� ����: '+PrintCodes.SaleBox+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ��������
     PrintStr:='191112500120030'+PrintCodes.DrinkFactory+' '+
                                 PrintCodes.DrinkGroupName+#13#10;
     ComPort.WriteStr(PrintStr);
     PrintStr:='191112500000030'+PrintCodes.DrinkMark+' '+
                                 PrintCodes.DrinkVolume+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ����������
     PrintStr:='291112501100000��:'+PrintCodes.DrinkId+
                              ' �:'+PrintCodes.DateFactory+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='291112501100010���:'+PrintCodes.WhoCreated+
                              ' ��:'+PrintCodes.RackName+#13#10;
     ComPort.WriteStr(PrintStr+'E');
    except on E:Exception do
     begin
      DrawError('������ ��� ������: '+E.Message+' ��� ����������� ������� Ok');
      break;
     end;
    end;//try..except
    Inc(i);
   end
 else
  while i<Length(PrintCodes.Codes) do
   begin
    PrintStr:=#02+'m'+ //m - ������� � ����������� �������
              #02+'L'+ //������� ������ ������������ ������ ��������
              'PK'+    //������������� �������� ���������� �������.   K=152.4 mm/sec
              'SO'+    //������������� �������� ������������ �������. O=203.2 mm/sec
              #02+'D11'+//D11 - ������ �������� �� ����������� � �� ���������
              'C'+'0'+ //�������� ������������ ������ ���� ��������
              'R'+'0'+ //�������� ������������ ������� ���� ��������
              'H10';   //������������� ��������� ������ (������� ������� ����������� �� ���������� �������)
    try
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501500000'+PrintCodes.DrinkFactory+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501300000'+PrintCodes.DrinkGroupName+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501100000'+Copy(PrintCodes.DrinkMark,1,17)+' '+
                                      PrintCodes.DrinkVolume+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='1F3204000500000'+Copy(PrintCodes.Codes[i],1,9)+'000'+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112500240000���:'+PrintCodes.WhoCreated+
                              ' ��:'+PrintCodes.RackName+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112500000000��:'+PrintCodes.DrinkId+
                               '�:'+PrintCodes.DateFactory+#13#10;
     ComPort.WriteStr(PrintStr+'E');
    except on E:Exception do
     begin
      DrawError('������ ��� ������: '+E.Message+' ��� ����������� ������� Ok');
      break;
     end;
    end;//try..except
    Inc(i);
   end;
  if ComPort.Connected then
   ComPort.Close;
end;

procedure PrintOnDMXEtiquettePrinter;
var PrintStr:string;
    i:integer;
begin
 if not Assigned(ComPort) then
  begin
   ComPort:=TComPort.Create(nil);
   ComPort.DiscardNull:=true;
   ComPort.Port:=PrinterSettings.Port;
  end;

 if not ComPort.Connected then
  ComPort.Open;

 i:=0;
 if (PrintCodes.FlagSaveRack=1) then
  begin
   PrintStr:=#02+'n'+
                    #02+'L'+ //������� ������ ������������ ������ ��������
                    #02+'D11'; //D11 - ������ �������� �� ����������� � �� ���������
   try
    ComPort.WriteStr(PrintStr);

    PrintStr:='122200002500010'+Copy(PrintCodes.Codes[i],1,9)+'  '+Copy(PrintCodes.Codes[i],10,7)+'  '+Copy(PrintCodes.Codes[i],17,5)+#13#10;//����������� �����-����
    ComPort.WriteStr(PrintStr);

    PrintStr:='1e3409001500010C'+PrintCodes.Codes[i]+#13#10;//����� ���
    ComPort.WriteStr(PrintStr);

    PrintStr:='192212501200010'+PrintCodes.DrinkFactory+#13#10; //��������
    ComPort.WriteStr(PrintStr);

    PrintStr:='192212501000010'+Copy(PrintCodes.DrinkMark+' '+PrintCodes.DrinkVolume,1,30)+#13#10; //��������
    ComPort.WriteStr(PrintStr);

    PrintStr:='192212500800010'+Copy(PrintCodes.DrinkMark+' '+PrintCodes.DrinkVolume,31,30)+#13#10; //��������
    ComPort.WriteStr(PrintStr);

    PrintStr:='192212500600010'+copy(PrintCodes.DateFactory,1,26)+#13#10;//���� �������
    ComPort.WriteStr(PrintStr);

    PrintStr:='195512500000010'+PrintCodes.RackID+#13#10; //��� ������
    ComPort.WriteStr(PrintStr);

    PrintStr:='195512500000165'+PrintCodes.RackName+#13#10; //�������� ������

    ComPort.WriteStr(PrintStr+'E');
   except on E:Exception do
    DrawError('������ ��� ������: '+E.Message+' ��� ����������� ������� Ok');
   end;//try..except
  end;
{ else
 if (not PrintCodes.Single) then
  while i<Length(PrintCodes.Codes) do
   begin
    PrintStr:=#02+'n'+
              #02+'L'+ //������� ������ ������������ ������ ��������
              #02+'D11'; //D11 - ������ �������� �� ����������� � �� ����������
    try
     ComPort.WriteStr(PrintStr);
     //�����
     PrintStr:='1X1100000000025L001110'+#13#10; //7    //���������
     ComPort.WriteStr(PrintStr);
     PrintStr:='1X1100000350026L210001'+#13#10; //7    1 //�������
     ComPort.WriteStr(PrintStr);

     //������ ����� ����
     PrintStr:='1e2205500400050C'+PrintCodes.Codes[i]+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ����������� �����-����
     PrintStr:='121100000950050'+Copy(PrintCodes.Codes[i],1,9)+'  '+Copy(PrintCodes.Codes[i],10,7)+'  '+Copy(PrintCodes.Codes[i],17,5)+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ����
     PrintStr:='191112500240030���� ����: '+PrintCodes.BuyBox+
                             ' ���� ����: '+PrintCodes.SaleBox+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ��������
     PrintStr:='191112500120030'+PrintCodes.DrinkFactory+' '+
                                 PrintCodes.DrinkGroupName+#13#10;
     ComPort.WriteStr(PrintStr);
     PrintStr:='191112500000030'+PrintCodes.DrinkMark+' '+
                                 PrintCodes.DrinkVolume+#13#10;
     ComPort.WriteStr(PrintStr);

     //������ ����������
     PrintStr:='291112601100000��:'+PrintCodes.DrinkId+
                              ' �:'+Copy(PrintCodes.DateFactory,1,10)+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='291112601100010���:'+PrintCodes.WhoCreated+
                              ' ��:'+PrintCodes.RackName+#13#10;
     ComPort.WriteStr(PrintStr+'E');
    except on E:Exception do
     begin
      DrawError('������ ��� ������: '+E.Message+' ��� ����������� ������� Ok');
      break;
     end;
    end;//try..except
    Inc(i);
   end
 else
  while i<Length(PrintCodes.Codes) do
   begin
    PrintStr:=#02+'m'+
              #02+'L'+ //������� ������ ������������ ������ ��������
              #02+'D11'; //D11 - ������ �������� �� ����������� � �� ���������
    try
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501500000'+PrintCodes.DrinkFactory+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501300000'+PrintCodes.DrinkGroupName+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112501100000'+Copy(PrintCodes.DrinkMark,1,17)+' '+
                                      PrintCodes.DrinkVolume+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='1F3204000500000'+Copy(PrintCodes.Codes[i],1,9)+'000'+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112500240000���:'+PrintCodes.WhoCreated+
                              ' ��:'+PrintCodes.RackName+#13#10;
     ComPort.WriteStr(PrintStr);

     PrintStr:='191112500000000��:'+PrintCodes.DrinkId+
                               '�:'+Copy(PrintCodes.DateFactory,1,10)+#13#10;
     ComPort.WriteStr(PrintStr+'E');
    except on E:Exception do
     begin
      DrawError('������ ��� ������: '+E.Message+' ��� ����������� ������� Ok');
      break;
     end;
    end;//try..except
    Inc(i);
   end;}
  if ComPort.Connected then
   ComPort.Close;
end;

procedure PrintEtiquette(enablequestion:boolean);
var CmdText:string;
    Error:boolean;
begin
 if not PrinterSettings.Enable then
  exit;

 if not Assigned(PrintCodes) then
  exit;

 if enablequestion then
  begin
   ClearConsole;
   DrawLine('',LeftIndention,0,WhiteOnBlack);
   InputLine:=AnToAs('�������� ��������?');
   if not ReadLine(InputLine) then
    exit;
  end;
 CmdText:='select * from terminal_printcodes('+Copy(PrintCodes.Codes[0],2,8)+')';

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    DrawError('������ ��� ������ ��������.');
   exit;
  end;

 if ReadIBQ.FieldByName('capacity').AsInteger=1 then
  PrintCodes.Single:=true
 else
  PrintCodes.Single:=false;

 PrintCodes.DrinkFactory:=ReadIBQ.FieldByName('drinkfactory').AsString;
 PrintCodes.DrinkMark:=ReadIBQ.FieldByName('drinkmark').AsString;
 PrintCodes.DrinkVolume:=ReadIBQ.FieldByName('drinkvolume').AsString;
 PrintCodes.DrinkGroupName:=ReadIBQ.FieldByName('drinkgroupname').AsString;
 PrintCodes.WhoCreated:='';//ReadIBQ.FieldByName('whocreated').AsString;
 PrintCodes.RackName:=ReadIBQ.FieldByName('rackname').AsString;
 PrintCodes.DrinkId:=ReadIBQ.FieldByName('drinkid').AsString;
 PrintCodes.BuyBox:=ReadIBQ.FieldByName('buybox').AsString;
 PrintCodes.SaleBox:=ReadIBQ.FieldByName('salebox').AsString;
 PrintCodes.DateFactory:=ReadIBQ.FieldByName('datefactory').AsString;
 PrintCodes.RackID:=ReadIBQ.FieldByName('rackid').AsString;
 PrintCodes.FlagSaveRack:=ReadIBQ.FieldByName('flagsaverack').AsInteger;

 {if PrinterSettings.Name='Printer' then
  PrintOnDefaultPrinter(25);

 if (PrinterSettings.Name='CLP2001') or
    (PrinterSettings.Name='CLP7201') or
    (PrinterSettings.Name='CLP6001') then
  PrintOnCLPEtiquettePrinter;}

 if (PrinterSettings.Name='DMXI4208') or
    (PrinterSettings.Name='DMXM4206') then
  PrintOnDMXEtiquettePrinter;
end;

procedure GoToMainMenu;
begin
 MenuPosition[0]:=GetPosition(MenuPosition[1]);
 MenuPosition[1]:=1;
 MenuPosition[2]:=GetDisplacing(MenuPosition[1]);
 MenuPosition[5]:=6;
end;

procedure GoToUpSubMenu(ParentMenu:integer);
begin
 MenuPosition[0]:=1;
 MenuPosition[1]:=ParentMenu;
 MenuPosition[2]:=GetDisplacing(MenuPosition[1]);
 MenuPosition[5]:=2;
end;

procedure GoToDownSubMenu(ParentMenu:integer);
begin
if (ParentMenu mod 100)=0 then
 GoToMainMenu
else
 begin
  MenuPosition[0]:=GetPosition(MenuPosition[1]);
  MenuPosition[1]:=round(ParentMenu/100)*100;
  MenuPosition[2]:=GetDisplacing(round(ParentMenu/100)*100);
  MenuPosition[5]:=2;
 end;
end;

function CheckEmployee(TextInfo:string;var EmployeeID,EmployeeName:string):boolean;
var CmdText:string;
    Error:boolean;
begin
 Result:=false;
 EmployeeID:='null';
 EmployeeName:='';
 if (FlagLoader <> '1') then
  exit;

 DrawText(TextInfo+'"���������� �����-���" "����������" ');
 InputLine := '';
 if ReadLine(InputLine) then
  begin
   EmployeeID:=Copy(InputLine,1,11);
   
   if (Length(InputLine)<>12) then
    DrawError('�������� �����-��� ��� ����������� ������� Ok')
   else
    begin                                   
     CmdText:='select shortname from employee where id = '+EmployeeID;

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('����������� ��������� � ���������� '+EmployeeID+'. ��� ����������� ������� Ok');
       exit;
      end;
     Result:=true;
     EmployeeName:='"'+ReadIBQ.FieldByName('shortname').AsString+'"';
    end;
  end;
end;

function SaleScreen_2:boolean;
var CmdText: String;
    Error:boolean;
    CodesId,DrinkKindId, RackId: String; //����: ��������,�������,������
    DrinkName: String;
    OutDrinkRackID:integer;
    DKAlreadyScanBoxCount:Integer; // ������� Codes'�� ��� �������� �� ����������� ���������
    DKTotalBoxCountInDoc:Integer;  // ������� ������ ����� � ����������� ��������� �� ������� ������
    TotalBoxCountArrayFactor: array [1..2] of Integer; {����� ���������� ������ �� ��������� � ��������� �� 1 � 2 �����}
    CodesScann: Boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') or (not CheckBarcodeOnLabel(InputLine)) then
    DrawError('"�������� �����-���" '+
              '"��� �����������" '+
              '"������� Ok"')
   else
    begin
     CmdText:='select Codes.Id CodesId,Codes.DrinkKindId,Codes.RackId,Rack.Name RackName,'+
        ' pc.datefactory, pc.numberakzis, Drink.Factory, Drink.Mark, Drink.Volume, '+
        ' RAckType.SingleRack, RAck.StorageId, rack.factor, codes.outdrinkrackid'+
        ' from Codes, Rack, PartyCertificate pc, Drink, DrinkKind, RackType'+
        ' where Codes.RackId=Rack.Id'+
        ' and Codes.DrinkKindId=DrinkKind.Id'+
        ' and DrinkKind.DrinkId=Drink.Id'+
        ' and DrinkKind.PartyCertificateId=pc.Id'+
        ' and RAck.RacktypeId=0+RackType.Id'+
        ' and Codes.Id = '+Copy(InputLine,2,8);
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('"�������� �����-���" '+
                  '"��� �����������" '+
                  '"������� Ok"');
       exit;
      end;
     ReadIBQ.First;
     with ReadIBQ do
      begin
       CodesId:=FieldByName('CodesId').asString;
       DrinkKindId:=FieldByName('DrinkKindId').asString;
       RackId:=FieldByName('RackId').asString;
       DrinkName:=FieldByName('Mark').asString+' '+FieldByName('Volume').asString;
       CodesScann:=not FieldByName('outdrinkrackid').IsNull;
       if CodesScann then
        OutDrinkRackID:=FieldByName('outdrinkrackid').AsInteger;
      end;

     // �������� �� �������������� ����� ���������
     CmdText:='select dr.id drinkrackid,(dr.bottlecount/cast(bx.capacity as double precision)) boxcount '+
         'from sale s '+
         'join distribution db on db.id=s.distributionid '+
         'join drinksale ds on ds.saleid=s.id '+
         'join drinkrack dr on dr.racktableid=ds.id '+
         'join drinkkind dk on dk.id=dr.drinkkindid '+
         'join box bx on bx.id=dk.saleboxid '+
         'where s.newpresent='+#39+Sale.Present+#39+
         ' and db.firmid= '+Sale.Id+
         ' and ds.drinkkindid ='+DrinkKindId+
         ' and dr.racktablesid=1 '+
         ' and dr.rackid='+RackId+
         'PLAN JOIN (S INDEX (SALENEWPRESENTINDEX), DB INDEX(RDB$PRIMARY111,RDB$FOREIGN109), '+
         '           DS INDEX (RDB$FOREIGN52,RDB$FOREIGN180), DR INDEX (RACKTABLEIDINDEX), '+
         '           DK INDEX (RDB$PRIMARY103), BX INDEX (RDB$PRIMARY3))';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('����� �� �� ����������� ���������. ��� ����������� ������� Ok');
       exit;
      end;

     if CodesScann then
      begin
       CmdText:='select min(s.sqnno) sqnno from drinkrack dr '+
                'join drinksale ds on ds.id=dr.racktableid '+
                'join sale s on s.id=ds.saleid '+
                'join distribution db on db.id=s.distributionid '+
                'where dr.racktablesid=1 and dr.id='+IntToStr(OutDrinkRackID)+
                ' and db.firmid='+Sale.Id+
                ' and s.newpresent='+#39+Sale.Present+#39;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('������ �������� ��� �������� �� ������ ���������!. ��� ����������� ������� Ok');
         exit;
        end;
        DrawError('������ �������� ��� �������� � ������� ��������� N'+
                   ReadIBQ.FieldByName('sqnno').AsString+' ��� ����������� ������� Ok');
        exit;
      end;

     //�������� �� ������������ ���������� ����������� ������ ���������� �� ���������
     CmdText:=' select count(co.id) boxcount'+
        ' from sale s'+
        ' join drinksale ds on s.id=ds.saleid'+
        ' join drinkrack dr on ds.id=dr.racktableid and dr.racktablesid=1'+
        ' join codes co on dr.id=co.outdrinkrackid and co.rackid=dr.rackid'+
        ' join rack r on r.id=co.rackid'+
        ' where s.firmid='+Sale.Id+
        '  and s.newpresent='+#39+Sale.Present+#39+
        '  and co.drinkkindid='+DrinkKindId+
        ' PLAN JOIN (S INDEX (SALENEWPRESENTINDEX),'+
        ' DS INDEX (RDB$FOREIGN52),'+
        ' DR INDEX (RACKTABLEIDINDEX),'+
        ' CO INDEX (RDB$FOREIGN204),'+
        ' R INDEX (RDB$PRIMARY164))';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;
     DKAlreadyScanBoxCount:=ReadIBQ.FieldByName('BoxCount').AsInteger;

     CmdText:=' select sum(dr.bottlecount) bottlecount,'+
        '  sum(dr.BottleCount /cast(bx.capacity as double precision)) boxcount'+
        ' from sale s '+
        ' join drinksale ds on s.id=ds.saleid '+
        ' join drinkkind dk on dk.id=ds.drinkkindid '+
        ' join box bx on bx.id=dk.saleboxid '+
        ' join drinkrack dr on ds.id=dr.racktableid and dr.racktablesid=1 '+
        ' where s.firmid = '+Sale.Id+
        '  and s.newpresent='+#39+Sale.Present+#39+
        '  and dk.id = '+DrinkKindId+
        ' PLAN JOIN (S INDEX (SALENEWPRESENTINDEX),'+
        ' DS INDEX (RDB$FOREIGN52), '+
        ' DK INDEX (RDB$PRIMARY103),'+
        ' BX INDEX (RDB$PRIMARY3),'+
        ' DR INDEX (RACKTABLEIDINDEX))';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;
     if not ReadIBQ.FieldByName('BoxCount').IsNull then
      DKTotalBoxCountInDoc:=ReadIBQ.FieldByName('BoxCount').AsInteger
     else
      DKTotalBoxCountInDoc:=0;

     if DKTotalBoxCountInDoc <= DKAlreadyScanBoxCount then // ���� �������������� ��� ����� � ���������
      begin
       DrawError('������� ����������� ���������. ��� ����������� ������� Ok');
       exit;
      end;

     CmdText:='execute procedure executefactconssale('+CodesId+','+Sale.Id+','+#39+Sale.Present+#39+','+IntToStr(UserInfo.Id)+')';
     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       end;
      InUpDelIBT.Commit;
      Result:=true;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ������� ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try
    end;//else if (InputLine='')
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Sale) then
    begin
     Dispose(Sale);
     Sale:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

function SaleScreen_WithDrinkKindID_2(DrinkKindID:integer):boolean;
var CmdText: String;
    Error,ErrorFlag:boolean;
    RackId: String; //����: ��������,�������,������
    DrinkName: String;
    CountCodesNeedScan,CountCodesScan,CountCodesNotScan :integer;
begin
 ErrorFlag:=false;
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   try
    CountCodesNeedScan:=StrToInt(InputLine);
   except
    ErrorFlag:=true;
   end;
   if (ErrorFlag) then
    DrawError('"�������� ���-��" '+
              '"��� �����������" '+
              '"������� Ok"')
   else
    begin

     CmdText:='select cast(floor(dr.bottlecount/cast(bx.capacity as double precision)+0.01) as integer) boxcount, '+
      '        count(co.id) clearingboxcount,r.id rackid,dk.id drinkkindid '+
      'from sale s '+
      'join drinksale ds on ds.saleid=s.id '+
      'join drinkrack dr on dr.racktableid=ds.id and dr.racktablesid=1 '+
      'join rack r on r.id=dr.rackid '+
      'join drinkkind dk on dk.id=ds.drinkkindid '+
      'join box bx on bx.id=dk.saleboxid '+
      'left join codes co on co.outdrinkrackid=dr.id '+
      'where s.id='+Sale.Id+' and r.storagesectionid='+Sale.StorageSectionId+
      ' and dr.drinkkindid='+IntToStr(DrinkKindID)+
      ' group by dr.bottlecount,bx.capacity,r.id,dk.id '+
      'having cast(floor(dr.bottlecount/cast(bx.capacity as double precision)+0.01) as integer)<>count(co.id)';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('"������ �������" '+
                   '"��������� ��������" '+
                   '"��� �����������" '+
                   '"������� Ok"');
       exit;
      end;

     with ReadIBQ do
      begin
       if FieldByName('boxcount').AsInteger<=FieldByName('clearingboxcount').AsInteger then
        begin
         DrawError('"������ �������" '+
                   '"��������� ��������" '+
                   '"��� �����������" '+
                   '"������� Ok"');
         exit;
        end;
       RackId:=FieldByName('RackId').asString;
       CountCodesScan:=FieldByName('clearingboxcount').AsInteger;
       CountCodesNotScan:=FieldByName('boxcount').AsInteger-FieldByName('clearingboxcount').AsInteger;
      end;

     if CountCodesNeedScan>CountCodesNotScan then
      begin
       DrawError('"��������� �������� " '+
                 '"��������� ���-��" '+
                 '"�� ����������" '+
                 '"��������" '+
                 '"��� �����������" '+
                 '"������� Ok"');
       exit;
      end;

     CmdText:='execute procedure codesclearingdrinkkindsale('+
              Sale.Id+','+Sale.StorageId+','+Sale.StorageSectionId+
              ','+IntToStr(DrinkKindId)+','+RackId+','+
              IntToStr(CountCodesNeedScan)+','+IntToStr(UserInfo.Id)+')';
     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       end;
      //InUpDelIBT.Rollback;
      InUpDelIBT.Commit;
      Result:=true;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ������� ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try}
    end;//else if (InputLine='')
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Sale) then
    begin
     Dispose(Sale);
     Sale:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

function SaleScreen_WithDrinkKindID_1(DrinkKindID:integer):boolean;
var CmdText: String;
    Error:boolean;
    RackId,RackName: String; //����: ��������,�������,������
    DrinkName: String;
    CountCodesScan,CountCodesNotScan,DKID:integer;
begin

 Result:=false;
     CmdText:='select cast(floor(dr.bottlecount/cast(bx.capacity as double precision)+0.01) as integer) boxcount, '+
      '        count(co.id) clearingboxcount,r.id rackid,r.name rackname, '+
      '        dk.id drinkkindid, '+
      '        d.mark drinkname,d.volume '+
      'from sale s '+
      'join drinksale ds on ds.saleid=s.id '+
      'join drinkrack dr on dr.racktableid=ds.id and dr.racktablesid=1 '+
      'join rack r on r.id=dr.rackid '+
      'join drinkkind dk on dk.id=ds.drinkkindid '+
      'join box bx on bx.id=dk.saleboxid '+
      'join drink d on d.id=dk.drinkid '+
      'left join codes co on co.outdrinkrackid=dr.id '+
      'where s.id='+Sale.Id+' and r.storagesectionid='+Sale.StorageSectionId+
      ' and dr.drinkkindid='+IntToStr(DrinkKindId)+
      ' group by dr.bottlecount,bx.capacity,r.id,dk.id,r.name,d.mark,d.volume '+
      'having cast(floor(dr.bottlecount/cast(bx.capacity as double precision)+0.01) as integer)<>count(co.id)';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('"������ �������" '+
                   '"��������� ��������" '+
                   '"��� �����������" '+
                   '"������� Ok"');
       exit;
      end;

     with ReadIBQ do
      begin
       if FieldByName('boxcount').AsInteger=FieldByName('clearingboxcount').AsInteger then
        begin
         DrawError('"������ �������" '+
                   '"��������� ��������" '+
                   '"��� �����������" '+
                   '"������� Ok"');
         exit;
        end;
       ReadIBQ.First;
       RackId:=FieldByName('RackId').asString;
       RackName:=FieldByName('RackName').asString;
       DrinkName:=Copy(Trim(ReadIBQ.FieldByName('drinkname').AsString),1,15)+' '+
                  FloatToStr(ReadIBQ.FieldByName('volume').AsFloat);
       CountCodesScan:=FieldByName('clearingboxcount').AsInteger;
       CountCodesNotScan:=FieldByName('boxcount').AsInteger-FieldByName('clearingboxcount').AsInteger;
      end;

     DrawText('"�������� ��������'+
               '" "�� ��������� N'+Sale.SqnNo+
               '" "�� '+Sale.Present+
               '" "������: '+IntToStr(DrinkKindId)+
               '" "'+DrinkName+
               '" "������: '+RackName+
               '" "�� ��������: '+IntToStr(CountCodesNotScan)+
               '" "���-�� ��� �������?');

     if not SaleScreen_WithDrinkKindID_2(DrinkKindId) then
      Result:=true;
end;

function SaleScreen_1:boolean;
var CmdText: String;
    Error,ErrorFlag:boolean;
    ReCodesId,CodesId,DrinkKindId,RackId: String; //����: ��������,�������,������
    DrinkName: String;
    OutDrinkRackID,DKID:integer;
    DKAlreadyScanBoxCount:Integer; // ������� Codes'�� ��� �������� �� ����������� ���������
    DKTotalBoxCountInDoc:Integer;  // ������� ������ ����� � ����������� ��������� �� ������� ������
    TotalBoxCountArrayFactor: array [1..2] of Integer; {����� ���������� ������ �� ��������� � ��������� �� 1 � 2 �����}
    CodesScann,ReCodesScann: Boolean;
begin
 ErrorFlag:=false;
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') or (not CheckBarcodeOnLabel(InputLine)) then
    begin
     try
      DKId:=StrToInt(InputLine);
     except
      ErrorFlag:=true;
     end;
     if ErrorFlag then
      DrawError('"�������� �����-���" '+
                '"��� �����������" '+
                '"������� Ok"')
     else
      if not SaleScreen_WithDrinkKindID_1(DKID) then
       Result:=true;
    end
   else
    begin
     CmdText:='select Codes.Id CodesId,Codes.DrinkKindId,Codes.RackId,Rack.Name RackName,'+
        ' pc.datefactory, pc.numberakzis, Drink.Factory, Drink.Mark, Drink.Volume, '+
        ' RAckType.SingleRack, RAck.StorageId, rack.factor, codes.outdrinkrackid, codes.recodesid'+
        ' from Codes, Rack, PartyCertificate pc, Drink, DrinkKind, RackType'+
        ' where Codes.RackId=Rack.Id'+
        ' and Codes.DrinkKindId=DrinkKind.Id'+
        ' and DrinkKind.DrinkId=Drink.Id'+
        ' and DrinkKind.PartyCertificateId=pc.Id'+
        ' and RAck.RacktypeId=0+RackType.Id'+
        ' and Codes.Id = '+Copy(InputLine,2,8)+
        ' and Rack.storagesectionid = '+Sale.StorageSectionId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('"�������� �����-���" '+
                  '"��� �����������" '+
                  '"������� Ok"');
       exit;
      end;
     ReadIBQ.First;
     with ReadIBQ do
      begin
       CodesId:=FieldByName('CodesId').asString;
       DrinkKindId:=FieldByName('DrinkKindId').asString;
       RackId:=FieldByName('RackId').asString;
       DrinkName:=FieldByName('Mark').asString+' '+FieldByName('Volume').asString;
       CodesScann:=not FieldByName('outdrinkrackid').IsNull;
       ReCodesScann:=not FieldByName('recodesid').IsNull;
       if CodesScann then
        OutDrinkRackID:=FieldByName('outdrinkrackid').AsInteger;
       if ReCodesScann then
        ReCodesId:=FieldByName('recodesid').asString;
      end;

     // �������� �� �������������� ����� ���������
     CmdText:='select DrinkRack.Id DrinkRackId,(DrinkRack.BottleCount/Box.Capacity) BoxCount'+
        ' from DrinkSale,DrinkRack,DrinkKind,Box'+
        ' where DrinkSale.SaleId = '+Sale.Id+
        ' and DrinkSale.DrinkKindId ='+DrinkKindId+
        ' and DrinkRack.RackTablesId=1'+
        ' and DrinkSale.Id=DrinkRack.RackTableId'+
        ' and DrinkRack.rackId = '+RackId+
        ' and DrinkKind.Id=DrinkSale.DrinkKindId'+
        ' and DrinkKind.SaleBoxId = Box.Id'+
        ' PLAN JOIN (DRINKSALE INDEX (RDB$FOREIGN52),'+
        ' DRINKKIND INDEX (RDB$PRIMARY103),'+
        ' BOX INDEX (RDB$PRIMARY3),'+
        ' DRINKRACK INDEX (RACKTABLEIDINDEX))';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('����� �� �� ����������� ���������. ��� ����������� ������� Ok');
       exit;
      end;

     if CodesScann then
      begin
       CmdText:='select s.sqnno from drinkrack dr '+
                'join drinksale ds on ds.id=dr.racktableid '+
                'join sale s on s.id=ds.saleid '+
                'where dr.racktablesid=1 and dr.id='+IntToStr(OutDrinkRackID)+
                ' and ds.saleid='+Sale.Id;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;
         //���� ������ � ��������� �������� �� ��� 2 ��� �� ������� ��������� ��� ��� if ReCodesScann then
        end
       else
        begin
         DrawError('������ �������� ��� �������� � ������� ��������� N'+
                   ReadIBQ.FieldByName('sqnno').AsString+' ��� ����������� ������� Ok');
         exit;
        end;
      end;

     if ReCodesScann then
      begin
       CmdText:='select s.sqnno from drinkrack dr '+
                'join drinksale ds on ds.id=dr.racktableid '+
                'join sale s on s.id=ds.saleid '+
                'join codes co on co.outdrinkrackid=dr.id and co.id='+ReCodesId+
                ' where dr.racktablesid=1 '+
                '  and ds.saleid='+Sale.Id;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('������ �������� ��� �������� �� ������ ���������!. ��� ����������� ������� Ok');
         exit;
        end;
       DrawError('������ �������� ��� �������� � ������� ��������� N'+
                  ReadIBQ.FieldByName('sqnno').AsString+' ��� ����������� ������� Ok');
       exit;
      end;

     //�������� �� ������������ ���������� ����������� ������ ���������� �� ���������
     CmdText:='select Count(Codes.Id) BoxCount'+
        ' from Codes,DrinkRack,DrinkSale, Rack, RackType'+
        ' where Codes.DrinkKindId = '+DrinkKindId+
        ' and Codes.RackId=DrinkRack.RackId'+
        ' and Codes.OutDrinkRackId = DrinkRack.Id'+
        ' and DrinkRack.RackTablesId=1'+
        ' and DrinkRack.RackTableId= DrinkSale.Id'+
        ' and DrinkSale.SaleId = '+Sale.Id+
        ' and Codes.RackId=Rack.Id'+
        ' and Rack.RAckTypeId=0+RackType.id'+
        ' and Rack.storagesectionid='+sale.StorageSectionId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;
     DKAlreadyScanBoxCount:=ReadIBQ.FieldByName('BoxCount').AsInteger;

     CmdText:='select Sum(DrinkRack.BottleCount) BottleCount,'+
        ' Sum(DrinkRAck.BottleCount /Box.Capacity ) BoxCount'+
        ' from DrinkSale, DrinkRAck, Rack,RAckType, DrinkKind, Box'+
        ' where DrinkSale.SaleId = '+Sale.Id+
        ' and DrinkSale.DrinkKindId = '+DrinkKindId+
        ' and DrinkSale.Id=DrinkrAck.RAckTableId'+
        ' and DrinkRAck.RackTablesId=1'+
        ' and DrinkRAck.RAckId=Rack.Id'+
        ' and Rack.RackTypeId=0+RackType.Id'+
        ' and Rack.storagesectionid='+sale.StorageSectionId+
        ' and DrinkSale.DrinkKindId=DrinkKind.Id'+
        ' and DrinkKind.SaleBoxId=Box.Id';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;
     if not ReadIBQ.FieldByName('BoxCount').IsNull then
      DKTotalBoxCountInDoc:=ReadIBQ.FieldByName('BoxCount').AsInteger
     else
      DKTotalBoxCountInDoc:=0;

     if DKTotalBoxCountInDoc <= DKAlreadyScanBoxCount then // ���� �������������� ��� ����� � ���������
      begin
       DrawError('������� ����������� ���������. ��� ����������� ������� Ok');
       exit;
      end;

     CmdText:='execute procedure codesclearingforsale('+CodesId+','+Sale.Id+','+IntToStr(UserInfo.Id)+')';
     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       end;
      InUpDelIBT.Commit;
      Result:=true;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ������� ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try
    end;//else if (InputLine='')
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Sale) then
    begin
     Dispose(Sale);
     Sale:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

function SaleScreen_FullSale_1:boolean;
var CmdText: String;
    Error,ErrorFlag:boolean;
    InBoxCount:integer;
begin
 Result:=false;
 InputLine:='';
 ErrorFlag:=false;
 if ReadLine(InputLine) then
  begin
   try
    InBoxCount:=StrToInt(InputLine);
   except
    ErrorFlag:=true;
   end;
   if (ErrorFlag) or (InBoxCount<>Sale.TotalBoxCount) then
    DrawError('"�������� ��� �������" '+
              '"��� �����������" '+
              '"������� Ok"')
   else
    try
     InUpDelIBT.StartTransaction;
     CmdText:='execute procedure terminal_ship_salecleardetail('+Sale.Id+','+Sale.StorageId+','+Sale.StorageSectionId+','+Sale.DrinkKindId+','+IntToStr(UserInfo.Id)+','+Sale.Loader+')';
     if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        begin
         DrawError(ErrorMessage+' ��� ����������� ������� Ok');
         exit;
        end;
      end;
     InUpDelIBT.Commit;
     Result:=true;
    except on E:Exception do
     begin
      if InUpDelIBT.Active then
       InUpDelIBT.Rollback;
      DrawError('������ ������� ���������. ��� ����������� ������� Ok');
     end; //on E:Exception
    end;//try}
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Sale) then
    begin
     Dispose(Sale);
     Sale:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;
                
function SaleScreen_FullCar_1:boolean;
var CmdText: String;
    Error:boolean;
    ReCodesId,CodesId,DrinkKindId,RackId: String; //����: ��������,�������,������
    DrinkName: String;
    OutDrinkRackID:integer;
    DKAlreadyScanBoxCount:Integer; // ������� Codes'�� ��� �������� �� ����������� ���������
    DKTotalBoxCountInDoc:Integer;  // ������� ������ ����� � ����������� ��������� �� ������� ������
    TotalBoxCountArrayFactor: array [1..2] of Integer; {����� ���������� ������ �� ��������� � ��������� �� 1 � 2 �����}
    CodesScann,ReCodesScann,ErrorFlag: Boolean;
    InBoxCount:integer;
begin
 Result:=false;
 InputLine:='';
 ErrorFlag:=false;
 if ReadLine(InputLine) then
  begin
   try
    InBoxCount:=StrToInt(InputLine);
   except
    ErrorFlag:=true;
   end;
   if (ErrorFlag) or (InBoxCount<>Sale.TotalBoxCount) then
    DrawError('"�������� ��� �������" '+
              '"��� �����������" '+
              '"������� Ok"')
   else
    try
     InUpDelIBT.StartTransaction;
     CmdText:='execute procedure terminal_ship_carconssaleclear('+Sale.Id+','+IntToStr(UserInfo.Id)+','+Sale.Loader+')';
     if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        begin
         DrawError(ErrorMessage+' ��� ����������� ������� Ok');
         exit;
        end;
      end;
     InUpDelIBT.Commit;
     Result:=true;
    except on E:Exception do
     begin
      if InUpDelIBT.Active then
       InUpDelIBT.Rollback;
      DrawError('������ ������� ���������. ��� ����������� ������� Ok');
     end; //on E:Exception
    end;//try}
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Sale) then
    begin
     Dispose(Sale);
     Sale:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

function SaleScreen_SaleInfoView(DetailScanCode:string;var DrinkKindId,LoadSaleText:string;var DetailResult,EgaisFlag:boolean):boolean;
var CmdText,temptext:string;
    Error:boolean;
    LoadSaleInfo:array of TLoadSaleInfo;
    i:integer;
begin
 Result:=false;DetailResult:=false;EgaisFlag:=false;InputLine:='';
 temptext:='�������'; if DetailScanCode='null' then temptext:='���������';
 CmdText:='select * from terminal_ship_saleviewdetail('+Sale.StorageId+','+
                                                        Sale.StorageSectionId+','+
                                                        Sale.Id+','+
                                                        DetailScanCode+')';

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    DrawError('����������� ��������� �� '+temptext+'. "��� �����������" "������� Ok"');
   if DetailScanCode<>null then Result:=true;
   exit;
  end;

 if ReadIBQ.FieldByName('SQNNO').AsInteger=0 then
  begin
   DrawError('����������� ��������� �� '+temptext+'. "��� �����������" "������� Ok"');
   if DetailScanCode<>null then Result:=true;
   exit;
  end;

 ReadIBQ.First;
 SetLength(LoadSaleInfo,ReadIBQ.RecordCount);
 Sale.SqnNo:=ReadIBQ.FieldByName('SQNNO').asString;
 Sale.Present:=FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('newpresent').AsDateTime);

 if ReadIBQ.FieldByName('drinkkindid').IsNull then DrinkKindId:='null'
                                              else DrinkKindId:=ReadIBQ.FieldByName('drinkkindid').AsString;
 LoadSaleText:='';
 for i:=0 to ReadIBQ.RecordCount-1 do
  begin
   LoadSaleInfo[i].StorageSectionName:=ReadIBQ.FieldByName('storagesectionname').AsString;
   LoadSaleInfo[i].CleradBoxCount:=ReadIBQ.FieldByName('clearedboxcount').AsInteger;
   LoadSaleInfo[i].TotalBoxCount:=ReadIBQ.FieldByName('totalboxcount').AsInteger;
   LoadSaleText:=LoadSaleText+'" "'+LoadSaleInfo[i].StorageSectionName+'['+
                 IntToStr(LoadSaleInfo[i].CleradBoxCount)+' �� '+
                 IntToStr(LoadSaleInfo[i].TotalBoxCount)+']';
   ReadIBQ.Next;
  end;//while

 if DetailScanCode='null' then
  begin
   if (LoadSaleInfo[1].totalboxcount<=LoadSaleInfo[1].cleradboxcount) or
      (LoadSaleInfo[0].totalboxcount<=LoadSaleInfo[0].cleradboxcount) then
    begin
     if (LoadSaleInfo[1].totalboxcount<=LoadSaleInfo[1].cleradboxcount) then
        DrawError('"��������� N'+Sale.SqnNo+
                   '" "�� '+Sale.Present+
                   '" "��������� ��������'+
                   '" "��� �����������'+
                   '" "������� Ok"')
     else
      DrawError('"�������� ��������'+
                '" "�� ��������� N'+Sale.SqnNo+
                '" "�� '+Sale.Present+
                LoadSaleText+'" "'+
                '" "��� �������� ��'+
                '" "��������� ��������'+
                '" "��� �����������'+
                '" "������� Ok"');
    end
   else
    begin
     LoadSaleText:='"�������� ��������" '+
                '"�� ��������� N'+Sale.SqnNo+'" '+
                '"�� '+Sale.Present+
                 LoadSaleText+'" ';
     Sale.TotalBoxCount:=LoadSaleInfo[0].totalboxcount;
     Result:=true;
    end
  end
 else
  begin
   Result:=true;
   if (LoadSaleInfo[1].totalboxcount<=LoadSaleInfo[1].cleradboxcount) or
      (LoadSaleInfo[0].totalboxcount<=LoadSaleInfo[0].cleradboxcount) then
    begin
     if (LoadSaleInfo[1].totalboxcount<=LoadSaleInfo[1].cleradboxcount) then
      DrawError('"��������� N'+Sale.SqnNo+
                 '" "�� '+Sale.Present+
                 '" "'+Copy(ReadIBQ.FieldByName('detailname').AsString,1,16)+
                 '" "������� ��������'+
                 '" "��� �����������'+
                 '" "������� Ok"')

     else
      DrawError('"�������� ��������'+
                '" "�� ��������� N'+Sale.SqnNo+
                '" "�� '+Sale.Present+
                '" "'+Copy(ReadIBQ.FieldByName('detailname').AsString,1,16)+
                LoadSaleText+'" "'+
                '" "������� ��'+
                '" "��������� ��������'+
                '" "��� �����������'+
                '" "������� Ok"');

    end
   else
    begin
     LoadSaleText:='"�������� ��������" '+
                   '"�� ��������� N'+Sale.SqnNo+'" '+
                   '"�� '+Sale.Present+'" '+
                   '"'+Copy(ReadIBQ.FieldByName('detailname').AsString,1,16)+
                   '"������ '+ReadIBQ.FieldByName('drinkkindid').AsString+
                   LoadSaleText+'" ';
     Sale.TotalBoxCount:=LoadSaleInfo[0].totalboxcount;
     if (Length(LoadSaleInfo)=3) and (LoadSaleInfo[2].totalboxcount>LoadSaleInfo[2].cleradboxcount) then EgaisFlag:=true;
     DetailResult:=true;
    end;
  end;
end;

function SaleScreen_FullDetail_1:boolean;
var CmdText,LoadSaleText,TextInfo,ScanCode,ResultValue:string;
    Error:boolean;
    EgaisFlag,DetailResult:boolean;
begin
 Result:=false;
 InputLine:='';
 while ReadStr(InputLine) do
  begin
   ScanCode:=#39+InputLine+#39;
   if not SaleScreen_SaleInfoView(ScanCode,Sale.DrinkKindId,LoadSaleText,DetailResult,EgaisFlag) then
    break
   else
    if EgaisFlag and DetailResult then
     begin
      InUpDelIBT.StartTransaction;
      try
       CmdText:='select * from terminal_ship_salescanexcise('+Sale.Id+','+Sale.DrinkKindId+','+ScanCode+')';

       if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        end
       else
        begin
         if InUpDelIBQ.FieldByName('resultvalue').IsNull then
          InUpDelIBT.Commit
         else
          begin
           ResultValue:=InUpDelIBQ.FieldByName('resultvalue').AsString;
           InUpDelIBT.Rollback;
           DrawError(ResultValue+' ��� ����������� ������� Ok');
          end;
        end;
       except on E:Exception do
        begin
         if InUpDelIBT.Active then
          InUpDelIBT.Rollback;
         DrawError('������ ������� ���������. ��� ����������� ������� Ok');
        end; //on E:Exception
       end;//try}
     end;

   if DetailResult and SaleScreen_SaleInfoView(ScanCode,Sale.DrinkKindId,LoadSaleText,DetailResult,EgaisFlag) and (not EgaisFlag) then
    begin
     DrawText(LoadSaleText+Sale.LoaderName+' �������� �������?');
     Result:=SaleScreen_FullSale_1;
    end;

   if (not DetailResult) or (not EgaisFlag) then ScanCode:='null';

   if SaleScreen_SaleInfoView(ScanCode,Sale.DrinkKindId,LoadSaleText,DetailResult,EgaisFlag) then
    DrawText(LoadSaleText+Sale.LoaderName+' �����-��� ������:')
   else
    break;
  end;
end;

procedure SaleScreen_0(FromMainMenu:boolean);
var CmdText,TextInfo: String;
    CountError,i:integer;
    Error,EgaisFlag:boolean;
    MaxLine,Str:string;
    //LoadSaleInfo:array of TLoadSaleInfo;
    LoadSaleText:string;
    ClearedConsBoxCount,TotalConsBoxCount:integer;
begin
 CountError:=0;
 MaxLine:='____________________';//20 ��������
 while Assigned(Sale) or FromMainMenu do
  begin
   FromMainMenu:=false;
   InputLine:='';
   if CountError>=MaxCountError then
    break;

   if not Assigned(Sale) then
    begin
     DrawText('"�������� ��������" "���������� �����-���"');
     if ReadLine(InputLine) then
      if (InputLine='') or ( (not CheckDocBarcode(InputLine,dtSale))
                         and (not CheckDocBarcode(InputLine,dtCarConsSale))
                         and (not CheckDocBarcode(InputLine,dtSaleBonus))
                         and (not CheckDocBarcode18(InputLine,dtSaleBonus))
                         and (not ((Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256)) )) then
       begin
        DrawError('"�������� �����-���" '+
                  '"��� �����������" '+
                  '"������� Ok"');
        FromMainMenu:=true;
       end
      else
       begin
        Sale:=New(PSale);

        if (Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256) then
         Sale.LoadSaleType:=dtSale
        else
         if CheckDocBarcode18(InputLine,dtSaleBonus) then
          Sale.LoadSaleType:= StrToInt(Copy(InputLine,1,3))
         else
          Sale.LoadSaleType:= StrToInt(Copy(InputLine,1,2));

        if Sale.LoadSaleType=dtSale then
         begin
          if (Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256) then
           begin
            Sale.StorageId:='0';
            Sale.StorageSectionId:='0';
            Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,5,8),0));
           end
          else
           begin
            Sale.StorageId:=IntToStr(StrToIntDef(Copy(InputLine,3,3),0));
            Sale.StorageSectionId:=IntToStr(StrToIntDef(Copy(InputLine,6,3),0));
            Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,9,8),0));
           end
         end;

        if Sale.LoadSaleType=dtCarConsSale then
         begin
          Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,9,8),0));
          Sale.StorageId:='0';
          Sale.StorageSectionId:='0';
         end;

        if Sale.LoadSaleType=dtSaleBonus then
         begin
          if CheckDocBarcode(InputLine,dtSaleBonus) then
           begin
            Sale.StorageId:=IntToStr(StrToIntDef(Copy(InputLine,3,2),0));
            Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,11,6),0));
            Sale.Present:=Copy(InputLine,9,2)+'.'+Copy(InputLine,7,2)+'.'+Copy(InputLine,5,2);
           end;

          if CheckDocBarcode18(InputLine,dtSaleBonus) then
           begin
            Sale.StorageId:=IntToStr(StrToIntDef(Copy(InputLine,4,3),0));
            Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,13,6),0));
            Sale.Present:=Copy(InputLine,11,2)+'.'+Copy(InputLine,9,2)+'.'+Copy(InputLine,7,2);
           end;
         end;

        if Sale.Id='0' then
         begin //���� ����� �����-���� �� ������
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          FromMainMenu:=true;
          if Assigned(Sale) then
           begin
            Dispose(Sale);
            Sale:=nil;
           end;
         end;//if Sale.Id=0 the
       end;//else if ReadLine(InputLine) then
    end;//if not Assigned(Sale) then

   if Assigned(Sale) then
    begin
     CmdText:='select * from storage st where st.isdummy=1 and st.id='+Sale.StorageId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        begin
         DrawError(ErrorMessage+' ��� ����������� ������� Ok');
         break;
        end;
      end
     else
      begin
       Sale.StorageId:='0';
       Sale.StorageSectionId:='0';
      end;

{----------------------------------����� �������-------------------------------}
     if Sale.LoadSaleType=dtCarConsSale then
      begin
       CmdText:='select * from terminal_ship_carconssaleview('+Sale.Id+')';
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('����������� ��������� �� ��������. "��� �����������" "������� Ok"');
         break;
        end;

       if (ReadIBQ.FieldByName('clearedboxcount').AsInteger>=ReadIBQ.FieldByName('totalboxcount').AsInteger) then
        begin
         DrawError('"'+ReadIBQ.FieldByName('present').AsString+
                   '" "'+ReadIBQ.FieldByName('carname').AsString+
                   '" "'+ReadIBQ.FieldByName('wayno').AsString+
                   '" "'+ReadIBQ.FieldByName('drivername').AsString+
                   '" "��������� �������'+
                   '" "��� �����������'+
                   '" "������� Ok"');
         if Assigned(Sale) then
          begin
           Dispose(Sale);
           Sale:=nil;
          end;
         FromMainMenu:=true;
        end
       else
        begin
         TextInfo:='"�������� ��������" '+
                   '"'+ReadIBQ.FieldByName('present').AsString+
                   '" "'+ReadIBQ.FieldByName('carname').AsString+
                   '" "'+ReadIBQ.FieldByName('wayno').AsString+
                   '" "'+ReadIBQ.FieldByName('drivername').AsString+
                   '" "��������: '+ReadIBQ.FieldByName('clearedboxcount').AsString+
                   '" "�����: '+ReadIBQ.FieldByName('totalboxcount').AsString+'" ';
         Sale.TotalBoxCount:=ReadIBQ.FieldByName('totalboxcount').AsInteger;

         if CheckEmployee(TextInfo,Sale.Loader,Sale.LoaderName) then
          begin
           TextInfo:= TextInfo+Sale.LoaderName+' �������� ���������?';
           DrawText(TextInfo);

           if not SaleScreen_FullCar_1 then
            Inc(CountError)
           else
            CountError:=0;
          end
         else
          begin
           if Sale.Loader='null' then
            if Assigned(Sale) then
             begin
              Dispose(Sale);
              Sale:=nil;
             end;
          end;
        end;//else (Sale.StorageId='0') and (Sale.StorageSectionId='0') then
      end; //if Sale.LoadSaleType=dtCarConsSale then


{-------------------------��������� ������� ���������--------------------------}
     if Sale.LoadSaleType=dtSale then
      begin
{-------------------------��������� ���----------------------------------------}
       if (Sale.StorageId='0') and (Sale.StorageSectionId='0') then
        begin//������� ��������� �� ������� ��� ������ ������ �������
         CmdText:=
          'select sf.isclearing, s.sqnno, s.newpresent '+
          'from salefullreturn sf '+
          'join sale s on s.id=sf.newsaleid '+
          'where sf.newsaleid='+Sale.Id;

         if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
          begin
           if Error then
            DrawError(ErrorMessage+' ��� ����������� ������� Ok')
           else
            DrawError('����������� ��������� �� ���������. "��� �����������" "������� Ok"');
           break;
          end;

         if (ReadIBQ.FieldByName('isclearing').AsInteger=1) then
          begin
           DrawError('��������� N'+ReadIBQ.FieldByName('sqnno').AsString+' ��������. "��� �����������" "������� Ok"');
           break;
          end;

         if (ReadIBQ.FieldByName('isclearing').AsInteger=0) then
          begin
           TextInfo:=
            '"�������� ��������" '+
            '"��������� N'+ReadIBQ.FieldByName('sqnno').AsString+'" '+
            '"�� '+ReadIBQ.FieldByName('newpresent').AsString+'" ';

           if not CheckEmployee(TextInfo,Sale.Loader,Sale.LoaderName) then
            begin
             FromMainMenu:=true;
             break;
            end;

           TextInfo:= TextInfo+Sale.LoaderName+' �������� ���������? (0-���,1-��)';

           DrawText(TextInfo);
           InputLine:='';
           if (not ReadLine(InputLine)) then
            begin
            if InputLine='0' then
             break
            else
             begin
              InUpDelIBT.StartTransaction;
              try
              CmdText:='execute procedure terminal_ship_sfrclear('+Sale.Id+','+IntToStr(UserInfo.Id)+','+Sale.Loader+')';

              if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
               begin
                if Error then
                 begin
                  DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                  break;
                 end;
               end;

              InUpDelIBT.Commit;
             except on E:Exception do
              begin
               if InUpDelIBT.Active then
                InUpDelIBT.Rollback;
               DrawError('������ ������� ���������. ��� ����������� ������� Ok');
              end; //on E:Exception
             end;//try}
            end; //if (not ReadLine(InputLine)) then
            end;
          end;//if (ReadIBQ.FieldByName('isclearing').AsInteger=0) then
        end //if (Sale.StorageId='0') and (Sale.StorageSectionId='0') then

       else{--------------------��������� ����������� ���������----------------}

        begin
         if not SaleScreen_SaleInfoView('null',Sale.DrinkKindId,LoadSaleText,EgaisFlag,EgaisFlag) then
          begin
           if LoadSaleText='' then
            break
           else
            begin
             if Assigned(Sale) then
              begin
               Dispose(Sale);
               Sale:=nil;
              end;
             FromMainMenu:=true;
            end;
          end
         else
          begin
           TextInfo:=LoadSaleText;

           if CheckEmployee(TextInfo,Sale.Loader,Sale.LoaderName) then
            begin
             if (Sale.DrinkKindId='null') then
              begin
               TextInfo:= TextInfo+Sale.LoaderName+' �������� ���������?';
               DrawText(TextInfo);

               if not SaleScreen_FullSale_1 then
                Inc(CountError)
               else
                CountError:=0;
              end
             else
              begin
               TextInfo:= TextInfo+Sale.LoaderName+' �����-��� ������:';
               DrawText(TextInfo);
               if not SaleScreen_FullDetail_1 then
                Inc(CountError)
               else
                CountError:=0;
              end
            end
           else
            begin
             if Sale.Loader='null' then
              if Assigned(Sale) then
               begin
                Dispose(Sale);
                Sale:=nil;
               end;
            end;
          end; //if (LoadSaleInfo[1].totalboxcount<=LoadSaleInfo[1].cleradboxcount) or
        end;//else (Sale.StorageId='0') and (Sale.StorageSectionId='0') then
      end;//if Sale.LoadSaleType=dtSale then

{---------------------��������� �������� ���������-----------------------------}
     if Assigned(Sale) and (Sale.LoadSaleType=dtSaleBonus) then
      begin
       CmdText:='select * from terminal_ship_bbview('+Sale.StorageId+','+Sale.Id+','+#39+Sale.Present+#39+')';
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('����������� ���������� �� �������� ���������. "��� �����������" "������� Ok"');
         break;
        end;

       if ReadIBQ.FieldByName('issued').AsInteger=1 then
        begin
         DrawError('"����� N'+ ReadIBQ.FieldByName('sqnno').AsString+
                   '" "�� '+ReadIBQ.FieldByName('present').AsString+
                   '" "��������� �������'+
                   '" "��� �����������'+
                   '" "������� Ok"');

         if Assigned(Sale) then
          begin
           Dispose(Sale);
           Sale:=nil;
          end;
         FromMainMenu:=true;
        end
       else
        begin
         TextInfo:='"�������� ��������" '+
                   '"����� N'+ReadIBQ.FieldByName('sqnno').AsString+'" '+
                   '"�� '+ReadIBQ.FieldByName('present').AsString+'" ';

         if CheckEmployee(TextInfo,Sale.Loader,Sale.LoaderName) then
          begin
           InUpDelIBT.StartTransaction;
           try
            CmdText:='execute procedure terminal_ship_bbclear('+Sale.StorageId+','+Sale.Id+','+IntToStr(UserInfo.Id)+','+Sale.Loader+')';

            if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
             begin
              if Error then
               begin
                DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                break;
               end;
             end;

            InUpDelIBT.Commit;
           except on E:Exception do
            begin
             if InUpDelIBT.Active then
              InUpDelIBT.Rollback;
             DrawError('������ ������� ���������. ��� ����������� ������� Ok');
            end; //on E:Exception
           end;//try}
          end
         else
          begin
           if Sale.Loader='null' then
            if Assigned(Sale) then
             begin
              Dispose(Sale);
              Sale:=nil;
             end;
          end;
        end;
      end;//if Assigned(Sale) and (Sale.LoadSaleType=dtSaleBonus) then
    end;//if Assigned(Sale) then
  end;//while Assigned(Sale) or FromMainMenu do

 if Assigned(Sale) then
  begin
   Dispose(Sale);
   Sale:=nil;
  end;
end;

function BuyScreen_4:boolean;
var CmdText:string;
    MesIn,i:integer;
    RestBoxes, LimitBoxes, RestBootles: Double;
    DrinkKindId, RackId, BoxCapacity, RackTableId:string;
    Error:boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   MesIn:=StrToIntDef(InputLine,0);
   if (InputLine='') or (MesIn<=0) then
    DrawError('�������� ���-�� ������ ���� 0 ��������. ��� ����������� ������� Ok')
   else
    begin
     with ReadIBQ do
      begin
       CmdText:='select min(db.id) id, min(db.storageid) storageid, '+
        ' min(c.acapacity) capacity, min(pc.datefactory) datefactory,'+
        ' min(pc.numberakzis) numberakzis, min(b.inputnumber) inputnumber , '+
        ' min(b.inputdate) inputdate, min(db.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecount, max(d.volume) volume, max(dg.name) drinkgroupname, '+
        ' max(d.factory) factory, max(d.mark) mark, max(bx.capacity) boxcapacity, '+
        ' max(dk.saleboxid) saleboxid,max(bx.fullname) boxname, min(db.isready) isready, min(i.make) make, '+
        ' min(s.ratecapacity) ratecapacity '+
        ' from buy b '+
        ' join drinkbuy db on b.id = db.buyid '+
        ' join drinkkind dk on db.drinkkindid = dk.id '+
        ' join storage s on s.id=db.storageid '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' left join drinkrack dr on (db.id = dr.racktableid and dr.racktablesid = 3) '+
        ' join drink d on d.id = dk.drinkid '+
        ' join drinkgroup dg on dg.id=d.drinkgroupid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' left join inventory i on i.id=b.inventoryid '+
        ' where b.id = '+ Buy.Id +' and db.storageid ='+ Buy.StorageId +' and db.drinkkindid ='+ Buy.DrinkKindId;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       First;
       (* ���������� ���-�� ������ ��� ���������� �� ������ ��������� *)
       RestBoxes:=FieldByName('BoxCount').asInteger - FieldByName('StorageCount').asInteger;

       (* ��������, ���������� ����� �������� � ������ *)
       LimitBoxes:=FieldByName('Capacity').asInteger * FieldByName('RateCapacity').asFloat{1.5};

       (* ���������� ���-�� ������� ��� ���������� �� ������ ��������� *)
       RestBootles:=Round((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)*FieldByName('BoxCapacity').asInteger);

       if not((RecordCount > 0)// ���� �� ����� ������� � ���������
        and ((LimitBoxes>=Abs(MesIn)) or (MesIn<0))// �������� ���� ���������� �� ��������� ���������� �������� �� ������ ��� �������� � ������ (������ ����)
        and ((abs(RestBoxes) >=Abs(MesIn)) or ((MesIn<0) and (abs(RestBootles) >= Abs(MesIn))))) then// �� ��������� �� ���-�� �� ���������
         DrawError('�������� ���������� ������. ��� ����������� ������� Ok')
       else
        begin
         if Assigned(PrintCodes) then
          begin
           Dispose(PrintCodes);
           PrintCodes:=nil;
          end;
         PrintCodes:=New(PPrintCodes);

         BoxCapacity:=FieldByName('BOXCAPACITY').AsString;
         RackTableId:=FieldByName('ID').AsString;

         if (MesIn > 0 ) then
          begin
           DrinkKindId:=Copy(InputLineStr, 1, 7-Length(Buy.DrinkKindId))+Buy.DrinkKindId;
           RackId:=Copy(InputLineStr, 1, 5-Length(Buy.RackId))+Buy.RackId;
           CmdText:='select codesid from terminal_addcodes('+Buy.DrinkKindId+','+
                                                    InputLine+','+BoxCapacity+','+Buy.RackId+','+
                                                    RackTableId+',3,'+IntToStr(UserInfo.Id)+')';

           InUpDelIBT.StartTransaction;
           try
            if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
             begin
              if Error then
               DrawError(ErrorMessage+' ��� ����������� ������� Ok')
              else
               DrawError('��� ��������� �����. ��� ����������� ������� Ok');

              if Assigned(PrintCodes) then
               begin
                Dispose(PrintCodes);
                PrintCodes:=nil;
               end;
              exit;
             end
            else
             begin
              i:=0;
              SetLength(PrintCodes.Codes,Trunc(MesIn));
              InUpDelIBQ.First;
              while (not InUpDelIBQ.Eof) or (i < MesIn) do
               begin
                PrintCodes.Codes[i]:='2'+ Copy(InputLineStr, 1, 8-Length(InUpDelIBQ.FieldByName('CodesId').AsString))+
                                     InUpDelIBQ.FieldByName('CodesId').AsString+DrinkKindId+RackId;
                InUpDelIBQ.Next;
                Inc(i);
               end;
             end;
            InUpDelIBT.Commit;
            PrintEtiquette(true);
            Result:=true;
           except on E:Exception do
            begin
             if InUpDelIBT.Active then
              InUpDelIBT.Rollback;
             DrawError('������ �������� ��������. ��� ����������� ������� Ok');
            end;
           end;
         end;//if (MesIn > 0 ) then
        end;//else if not((RecordCount > 0)
      end;//with ReadIBQ do
    end;//else if (InputLine='') or (MesIn<=0) then
  end// if ReadLine(InputLine) then
 else
  begin
   if Assigned(Buy) then
    begin
     Dispose(Buy);
     Buy:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;

function BuyScreen_3:boolean;
var CmdText:string;
    RackName:string;
    SingleOrBox:string;
    Error:boolean;
begin
 Result:=false;
 with ReadIBQ do
  begin
   CmdText:='select * from getfree_rack('+Buy.DrinkKindId+',0,'+Buy.StorageId+') where id='+Buy.RackId;
   if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
    begin
     if Error then
      DrawError(ErrorMessage+' ��� ����������� ������� Ok')
     else
      DrawError('����������� ��������� ������. ��� ����������� ������� Ok');
     exit;
    end;
   First;

   RackName:=FieldByName('name').AsString;

   CmdText:='select min(db.id) id, min(db.StorageId) storageid, '+
        ' min(c.acapacity) capacity, Min(pc.datefactory) datefactory,'+
        ' Min(pc.numberakzis) numberakzis, Min(b.inputnumber) inputnumber , '+
        ' Min(b.inputdate) inputdate, min(db.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecount, max(d.volume) volume, '+
        ' max(d.factory) factory, max(d.mark) name, max(bx.capacity) boxcapacity, '+
        ' max(dk.SaleBoxId) SaleBoxid, min(db.isready) isready, min(i.make) make '+
        ' from Buy b '+
        ' join drinkbuy db on b.id = db.buyid '+
        ' join drinkkind dk on db.drinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' left join drinkrack dr on (db.id = dr.racktableid and dr.racktablesid = 3) '+
        ' join drink d on d.id = dk.drinkid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' left join inventory i on i.id=b.inventoryid '+
        ' where b.id = '+ Buy.Id +' and db.storageid ='+Buy.StorageId +' and db.drinkkindid ='+Buy.DrinkKindId;

   if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
    if Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

   if ((RecordCount > 0) and ((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)<>0)) then
    begin
     if Buy.Single then
      SingleOrBox := '������� ��. ����-��?'
     else
      SingleOrBox := '������� ��. ����-��?';
     DrawText('"������� N'+Buy.SqnNo+
              '" "�� '+Buy.Present+
              '" "'+Copy(Trim(FieldByName('name').AsString),1,15)+' '+Trim(FloatToStr(FieldByName('volume').AsFloat))+
              '" "��� ������:'+Buy.DrinkKindId+
              '" "�������� ��-�: '+FloatToStr(Trunc((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)*100)/100)+
              ' �.�.:'+IntToStr(FieldByName('Capacity').asInteger)+
              '" "������:'+RackName+
              '" "'+SingleOrBox+'"');
     if BuyScreen_4 then
      Result:=true;
    end
   else
    begin
     DrawError('������� ������ ������������ ���������. ��� ����������� ������� Ok');
     Result:=true;
    end;
  end;
end;

function BuyScreen_2:boolean;
var CmdText,TextInfo,RackName,DrinkID:string;
    Error,Flag:boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  if (InputLine='') or (not (CheckBarcodeOnGoods(InputLine))) then
    DrawError('�������� �����-��� ������. ��� ����������� ������� Ok')
  else
   begin
    with ReadIBQ do
     begin
      CmdText:='select dk.drinkid from drinkkind dk '+
               'join drinkbarcode db on db.drinkid=dk.drinkid '+
               'where dk.id='+Buy.DrinkKindId+
               ' and db.barcode='+#39+InputLine+#39;
      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
         DrawError('�������� �����-��� ������');
        exit;
       end;
      DrinkId:=FieldByName('drinkid').AsString;

      CmdText:='select * from getfree_rack('+Buy.DrinkKindId+',0,'+Buy.StorageId+')';
      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
         DrawError('����������� ��������� ������. ��� ����������� ������� Ok');
        exit;
       end;
      First;

      RackName:=FieldByName('name').AsString;

      Buy.RackId:=FieldByName('Id').AsString;

      CmdText:='select min(db.id) id, min(db.StorageId) storageid, '+
        ' min(c.acapacity) capacity, Min(pc.datefactory) datefactory,'+
        ' Min(pc.numberakzis) numberakzis, Min(b.inputnumber) inputnumber , '+
        ' Min(b.inputdate) inputdate, min(db.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecount, max(d.volume) volume, '+
        ' max(d.factory) factory, max(d.mark) name, max(bx.capacity) boxcapacity, '+
        ' max(dk.SaleBoxId) SaleBoxid, min(db.isready) isready, min(i.make) make '+
        '  from Buy b '+
        ' join drinkbuy db on b.id = db.buyid '+
        ' join drinkkind dk on db.drinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' left join drinkrack dr on (db.id = dr.racktableid and dr.racktablesid = 3) '+
        ' join drink d on d.id = dk.drinkid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' left join inventory i on i.id=b.inventoryid '+
        ' where b.id = '+ Buy.Id +' and db.storageid ='+Buy.StorageId +
                       ' and db.drinkkindid ='+Buy.DrinkKindId+' and d.id='+DrinkId;

      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       if Error then
        begin
         DrawError(ErrorMessage+' ��� ����������� ������� Ok');
         exit;
        end;
      First;

      if FieldByName('boxcapacity').AsInteger=1 then
       Buy.Single:=True
      else
       Buy.Single:=False;

      if ((RecordCount > 0) and ((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)<>0)) then
       begin
        TextInfo:='"������� N '+Buy.SqnNo+
                  '" "�� '+Buy.Present+
                  '" "'+Copy(Trim(FieldByName('Name').AsString),1,15)+' '+Trim(FloatToStr(FieldByName('volume').AsFloat)) +
                  '" "��� ������:'+Buy.DrinkKindId+
                  '" "�������� ��-�: '+FloatToStr(Trunc((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)*100)/100)+
                  '" "������:'+RackName+'?"';
        DrawText(TextInfo);
        flag:=true;
        while flag and ReadLine(Buy.RackId) do
         begin
          if Buy.RackId='' then
           begin
            DrawError('�������� ��� ������.');
            DrawText(TextInfo);
           end
          else
           begin
            CmdText:='select * from getfree_rack('+Buy.DrinkKindId+',0,'+Buy.StorageId+') where id='+Buy.RackId;
            if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
             begin
              if Error then
               begin
                DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                exit;
               end
              else
               begin
                DrawError('�������� ��� ������.');
                DrawText(TextInfo);
               end;
             end
            else
             flag:=false
           end;
         end;

        if flag then
         begin
          if Assigned(Buy) then
           begin
            Dispose(Buy);
            Buy:=nil;
           end;
          if Assigned(PrintCodes) then
           begin
            Dispose(PrintCodes);
            PrintCodes:=nil;
           end;
          Result:=true;
         end
        else
         if BuyScreen_3 then
          Result:=true;
       end
      else
       begin
        DrawError('������� ������ ������������ ���������. ��� ����������� ������� Ok');
        Result:=true;
       end;
     end;
   end
 else
  begin
   if Assigned(Buy) then
    begin
     Dispose(Buy);
     Buy:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;

function BuyScreen_1:boolean;
var CmdText,TextInfo:string;
    Error:boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  if (InputLine='')
   or (not (CheckBarcodeOnDoc('0'+InputLine,dtBuy)))
   or (not (StrToInt(Copy(InputLine, 4, 8))= StrToInt(Buy.Id))) then
    DrawError('�������� �����-���. ��� ����������� ������� Ok')
  else
   begin
    Buy.DrinkKindId:=IntToStr(StrToIntDef(Copy(InputLine, 12, 7),0));
    if Buy.DrinkKindId='0' then
     begin
      DrawError('�������� �����-���. ��� ����������� ������� Ok');
      exit;
     end;

    with ReadIBQ do
     begin
      CmdText:='select min(db.id) id, min(db.StorageId) storageid, '+
        ' min(c.acapacity) capacity, Min(pc.datefactory) datefactory,'+
        ' Min(pc.numberakzis) numberakzis, Min(b.inputnumber) inputnumber , '+
        ' Min(b.inputdate) inputdate, min(db.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecount, max(bx.capacity) boxcapacity, '+
        ' max(dk.SaleBoxId) SaleBoxid, min(db.isready) isready, min(i.make) make '+
        ' from Buy b '+
        ' join drinkbuy db on b.id = db.buyid '+
        ' join drinkkind dk on db.drinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' left join drinkrack dr on (db.id = dr.racktableid and dr.racktablesid = 3) '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' left join inventory i on i.id=b.inventoryid '+
        ' where b.id = '+ Buy.Id +' and db.storageid ='+Buy.StorageId +' and db.drinkkindid ='+Buy.DrinkKindId;

      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       if Error then
        begin
         DrawError(ErrorMessage+' ��� ����������� ������� Ok');
         exit;
        end;
      First;

      if ((RecordCount > 0) and ((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)<>0)) then
       begin
        TextInfo:='"������� N '+Buy.SqnNo+
                  '" "�� '+Buy.Present+
                  '" "��� ������:'+Buy.DrinkKindId+
                  '" "�������� ��-�: '+FloatToStr(Trunc((FieldByName('BoxCount').asFloat - FieldByName('StorageCount').asFloat)*100)/100)+
                  '" ���������� �����-��� c �������� ������';
        DrawText(TextInfo);
        if BuyScreen_2 then
         Result:=true;
       end
      else
       begin
        DrawError('������� ������ ������������ ���������. ��� ����������� ������� Ok');
        Result:=true;
       end;
     end;
   end
 else
  begin
   if Assigned(Buy) then
    begin
     Dispose(Buy);
     Buy:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;


procedure BuyScreen_0(FromMainMenu:boolean);
var CmdText:string;
    CountError:integer;
    Error:boolean;
begin
 CountError:=0;
 while Assigned(Buy) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(Buy) then
    begin
     DrawText('"�������� �������" "���������� �����-���" "������ �� �������" "������"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') or (not (CheckBarcodeOnDoc('0'+InputLine,dtBuy))) then
       DrawError('�������� �����-���. ��� ����������� ������� Ok')
      else
       begin
        Buy:=New(PBuy);
        Buy.Id:=IntToStr(StrToIntDef(Copy(InputLine, 4, 8),0));
        Buy.StorageId:=IntToStr(StrToIntDef(Copy(InputLine,12,7),0));

        if (Buy.Id='0') or (Buy.StorageId='0') then
         begin
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          break;
         end;
       end;
    end;

   if Assigned(Buy) then
    begin
     with ReadIBQ do
      begin
       CmdText:='select min(b.numberdoc) inputnumber, min(b.inputdate) inputdate, '+
              ' sum(db.bottlecount/cast(bx.capacity as double precision)) bottlecount, '+
              ' min(b.storageid) storageid, '+
              ' sum(db.drinkrackcount/cast(bx.capacity as double precision))*sign(sum(db.bottlecount)) storagecount, '+
              ' min(i.make) Make, min(b.tickedform) tickedform '+
              ' from buy b '+
              ' join drinkbuy db on b.id = db.buyid '+
              ' join drinkkind dk on db.drinkkindid = dk.id '+
              ' join box bx on dk.saleboxid = bx.id '+
              ' left join inventory i on i.id=b.inventoryid '+
              ' where b.id ='+Buy.Id +
              ' and (0>='+Buy.StorageId+' or db.storageid='+Buy.StorageId+') '+
              ' and b.directorview = 2';
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       First;
       if (FieldByName('InputNumber').IsNull) or (FieldByName('BottleCount').asInteger-FieldByName('StorageCount').asInteger=0) then
        begin
         if FieldByName('InputNumber').IsNull then
           DrawError('��������� �� ������� ��� �� ��������� ������� ���������. ��� ����������� ������� Ok')
         else
          if FieldByName('BottleCount').AsInteger-FieldByName('StorageCount').AsInteger<=0 then
           DrawError('��������� ��������� N '+FieldByName('InputNumber').AsString+
           ' �� '+FormatDateTime('dd.mm.yyyy',FieldByName('InputDate').AsDateTime)+
           ' ���������� ���������. ��� ����������� ������� Ok');

         break;
        end
       else
        begin
         Buy.SqnNo:=FieldByName('InputNumber').AsString;
         Buy.Present:=FormatDateTime('dd.mm.yyyy',FieldByName('InputDate').AsDateTime);
         DrawText('"������� N'+Buy.SqnNo+
                  '" "�� '+Buy.Present+
                  '" "����� ��-�: '+FloatToStr(Int(FieldByName('BottleCount').AsFloat*100)/100)+
                  '" "�� �������: '+IntToStr(FieldByName('BottleCount').asInteger-FieldByName('StorageCount').asInteger)+
                  '" ���������� �����-��� ������� ������ ������ �� �������');
         if not BuyScreen_1 then
          Inc(CountError)
         else
          CountError:=0;
        end;
      end;
    end;
  end;

 if Assigned(Buy) then
  begin
   Dispose(Buy);
   Buy:=nil;
  end;
 if Assigned(PrintCodes) then
  begin
   Dispose(PrintCodes);
   PrintCodes:=nil;
  end;
end;

function TransportationInRackScreen_3:boolean;
var CmdText: string;
    Error,EnableFreeRackId:boolean;
    MesIn:integer;
    RestBoxes, LimitBoxes, RestBootles: Double;
    DrinkKindId, RackId, BoxCapacity, RackTableId,FromDrinkKindId, RackName :string;
    i: Integer;
begin
 Result:=false;
 EnableFreeRackId:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   MesIn:=StrToIntDef(InputLine,0);
   if (InputLine='') or (MesIn<=0) then
    DrawError('�������� ���-�� ������ ���� 0 ��������. ��� ����������� ������� Ok')
   else
    begin
     CmdText:='select dt.DrinkKindId drinkkindid, '+
        ' min(dt.id) id, min(c.acapacity) capacity, '+
        ' min(pc.datefactory) datefactory, min(pc.numberakzis) numberakzis, '+
        ' min(t.sqnno) inputnumber , min(t.present) inputdate, '+
        ' min(t.storageid) fromstorageid, min(t.tostorageid) tostorageid, '+
        ' min(fs.storagetype) fromstoragetype, min(ts.storagetype) tostoragetype, '+
        ' min(dt.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecountout, max(dg.name) drinkgroupname, '+
        ' max(d.factory) factory, max(d.mark) mark, max(d.volume) volume,'+
        ' max(bx.capacity) boxcapacity, max(dk.saleboxid) saleboxid, max(bx.fullname) boxname, '+
        ' min(ts.ratecapacity) ratecapacity '+
        ' from transportation t '+
        ' join drinktransportation dt on t.id = dt.transportationid '+
        ' join drinkkind dk on dt.todrinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' join drink d on d.id = dk.drinkid '+
        ' join drinkgroup dg on dg.id=d.drinkgroupid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' join storage fs on t.storageid = fs.id '+
        ' join storage ts on t.tostorageid = ts.id '+
        ' left join drinkrack dr on (dt.id = dr.racktableid and dr.racktablesid = 22) '+
        ' where t.id = '+ Transportation.Id +
        ' and dt.todrinkkindid = '+ Transportation.ToDrinkKindId +
        ' and (dt.drinkrackcountout is null or dt.bottlecount <> dt.drinkrackcountout) '+
        ' group by dt.drinkkindid ';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;

     (* ���������� ���-�� ������ ��� ���������� �� ������ ��������� *)
     RestBoxes:=ReadIBQ.FieldByName('boxcount').asInteger - ReadIBQ.FieldByName('storagecountout').asInteger;
     (* ��������, ���������� ����� �������� � ������ *)
     LimitBoxes:=ReadIBQ.FieldByName('capacity').asInteger * ReadIBQ.FieldByName('ratecapacity').asFloat{1.5};
     (* ���������� ���-�� ������� ��� ���������� �� ������ ��������� *)
     RestBootles:=Round((ReadIBQ.FieldByName('boxcount').asFloat - ReadIBQ.FieldByName('storagecountout').asFloat)*ReadIBQ.FieldByName('boxcapacity').asInteger);

     if not((ReadIBQ.RecordCount > 0) and // ���� �� ����� ������� � ���������
      ((LimitBoxes>=Abs(MesIn)) OR (MesIn<0)) and // �������� ���� ���������� �� ��������� ���������� �������� �� ������ ��� �������� � ������ (������ ����)
      ((RestBoxes >=Abs(MesIn)) OR ((MesIn<0) and (RestBootles >= Abs(MesIn))))// �� ��������� �� ���-�� �� ���������
        )then
      begin
       DrawError('�������� ���������� ������. ��� ����������� ������� Ok');
       exit;
      end;

     Transportation.FromStorageType:=ReadIBQ.FieldByName('fromstoragetype').Value;
     Transportation.FromStorageId:=ReadIBQ.FieldByName('fromstorageid').Value;
     FromDrinkKindId:=ReadIBQ.FieldByName('drinkkindid').AsString;

     if ReadIBQ.FieldByName('boxcapacity').AsInteger=1 then
      Transportation.Single:=True
     else
      Transportation.Single:=False;

     if Assigned(PrintCodes) then
      begin
       Dispose(PrintCodes);
       PrintCodes:=nil;
      end;

     PrintCodes:=New(PPrintCodes);

     BoxCapacity:=ReadIBQ.FieldByName('boxcapacity').AsString;
     RackTableId:=ReadIBQ.FieldByName('id').AsString;

     CmdText:='select * from getfree_rack('+Transportation.ToDrinkKindId+',0,'+Transportation.ToStorageId+')'+
              ' where id='+Transportation.RackId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('��� ������ ����� �� �����, ���� ������ ������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     RackName:=ReadIBQ.FieldByName('Name').AsString;

     if (MesIn > 0 ) then //���� � ������� ������
      begin
       DrinkKindId:=Copy(InputLineStr, 1, 7-Length(Transportation.ToDrinkKindId)) + Transportation.ToDrinkKindId;
       RackId:=Copy(InputLineStr, 1, 5-Length(Transportation.RackId)) + Transportation.RackId;
       RackName:=Trim(ReadIBQ.FieldByName('Name').Value);

       CmdText:='select codesid from terminal_transtorack('+Transportation.ToDrinkKindId+','+
                InputLine+','+BoxCapacity+','+ReadIBQ.FieldByName('Id').AsString+','+
                RackTableId+',22,'+IntToStr(UserInfo.Id)+')';


       InUpDelIBT.StartTransaction;
       try
        if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
         begin
          if Error then
           begin
            DrawError(ErrorMessage+' ��� ����������� ������� Ok');
            if Assigned(PrintCodes) then
             begin
              Dispose(PrintCodes);
              PrintCodes:=nil;
             end;
            exit;
           end
          else
           if Assigned(PrintCodes) then
            begin
             Dispose(PrintCodes);
             PrintCodes:=nil;
            end;
         end
        else
         begin
          i:=0;
          SetLength(PrintCodes.Codes,Trunc(MesIn));
          InUpDelIBQ.First;
          while (not InUpDelIBQ.Eof) or (i < MesIn) do
           begin
            PrintCodes.Codes[i]:=
             '2'+ Copy(InputLineStr, 1, 8-Length(InUpDelIBQ.FieldByName('CodesId').AsString))+
            InUpDelIBQ.FieldByName('CodesId').AsString + DrinkKindId + RackId;
            InUpDelIBQ.Next;
            Inc(i);
           end;
         end;
        InUpDelIBT.Commit;
        //PrintEtiquette(true);
        Result:=true;
       except on E:Exception do
        begin
         if InUpDelIBT.Active then
          InUpDelIBT.Rollback;
         DrawError('������: '+E.Message+' ��� ����������� ������� Ok');
        end;
       end;//try
      end;//if (MesIn > 0 ) then
    end;// else if (InputLine='') or (MesIn<=0) then
  end// if ReadLine(InputLine) then
 else
  begin
   if Assigned(Transportation) then
    begin
     Dispose(Transportation);
     Transportation:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;

function TransportationInRackScreen_2:boolean;
var CmdText,RackName: String;
    Error:boolean;
begin
 Result:=false;
 CmdText:='select dt.DrinkKindId drinkkindid, '+
        ' min(dt.id) id, min(c.acapacity) capacity, '+
        ' Min(pc.datefactory) datefactory, Min(pc.numberakzis) numberakzis, '+
        ' Min(t.sqnno) inputnumber , Min(t.present) inputdate, '+
        ' Min(t.storageid) fromstorageid, Min(t.tostorageid) tostorageid, '+
        ' Min(fs.storagetype) fromstoragetype, Min(ts.storagetype) tostoragetype, '+
        ' min(dt.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecountout, '+
        ' max(d.volume) volume, max(d.factory) factory, max(d.mark) name, '+
        ' max(bx.capacity) boxcapacity, max(dk.saleboxid) saleboxid, '+
        ' min(ts.ratecapacity) ratecapacity '+
        ' from transportation t '+
        ' join drinktransportation dt on t.id = dt.Transportationid '+
        ' join drinkkind dk on dt.todrinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' join drink d on d.id = dk.drinkid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' join storage fs on t.storageid = fs.id '+
        ' join storage ts on t.tostorageid = ts.id '+
        ' left join drinkrack dr on (dt.id = dr.racktableid and dr.racktablesid = 22) '+
        ' where t.id = '+ Transportation.Id +
        ' and dt.todrinkkindid = '+ Transportation.ToDrinkKindId +
        ' and (dt.drinkrackcountout is null or dt.bottlecount <> dt.drinkrackcountout) '+
        ' group by dt.drinkkindid ';

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  if Error then
   begin
    DrawError(ErrorMessage+' ��� ����������� ������� Ok');
    exit;
   end;
 ReadIBQ.First;

 if ((ReadIBQ.RecordCount > 0) and ((ReadIBQ.FieldByName('boxcount').asFloat - ReadIBQ.FieldByName('StorageCountout').asFloat)>0)) then
  begin
   DrawText('"�������� �����������" '+
            '"�� �������� �����" '+
            '"��������� N'+Transportation.Id+'" '+
            '"�� '+Transportation.Present+'" '+
            '"'+Copy(Trim(ReadIBQ.FieldByName('name').AsString),1,15)+' '+Trim(FloatToStr(ReadIBQ.FieldByName('volume').AsFloat))+'" '+
            '"���:'+Transportation.ToDrinkKindId+' �.�.:'+IntToStr(ReadIBQ.FieldByName('capacity').asInteger)+'" '+
            '"�������:'+FloatToStr(Trunc((ReadIBQ.FieldByName('boxcount').asFloat - ReadIBQ.FieldByName('storagecountout').asFloat)*100)/100)+'��." '+
            '"������:'+Transportation.RackName+'" '+
            '"������������ ���-��?"');
   if TransportationInRackScreen_3 then
    Result:=true;
  end
 else
  DrawError('������� ������ ���������� ���������. ��� ����������� ������� Ok');
end;

function TransportationInRackScreen_1:boolean;
var CmdText,TextInfo: String;
    Error,flag:boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') or (not ((StrToInt(Copy(InputLine,2,2)) = dtTransportationIn) and
                        (StrToInt(Copy(InputLine, 4, 8))= StrToInt(Transportation.Id)) and
                        (Length(InputLine)>=18))) then
    DrawError('�������� �����-���. ��� ����������� ������� Ok')
   else
    begin
     Transportation.ToDrinkKindId:=IntToStr(StrToIntDef(Copy(InputLine,12,7),0));
     if Transportation.ToDrinkKindId='0' then
      begin
       DrawError('�������� �����-���. ��� ����������� ������� Ok');
       exit;
      end;

     CmdText:='select * from getfree_rack('+Transportation.ToDrinkKindId+',0,'+Transportation.ToStorageId+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('����������� ��������� ������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     Transportation.RackName:=ReadIBQ.FieldByName('name').AsString;

     Transportation.RackId:=ReadIBQ.FieldByName('id').AsString;

     CmdText:='select dt.DrinkKindId drinkkindid, '+
        ' min(dt.id) id, min(c.acapacity) capacity, '+
        ' Min(pc.datefactory) datefactory, Min(pc.numberakzis) numberakzis, '+
        ' Min(t.sqnno) inputnumber , Min(t.present) inputdate, '+
        ' Min(t.storageid) fromstorageid, Min(t.tostorageid) tostorageid, '+
        ' Min(fs.storagetype) fromstoragetype, Min(ts.storagetype) tostoragetype, '+
        ' min(dt.bottlecount/cast(bx.capacity as double precision)) boxcount, '+
        ' sum(dr.bottlecount/cast(bx.capacity as double precision)) storagecountout, '+
        ' max(d.volume) volume, max(d.factory) factory, max(d.mark) name, '+
        ' max(bx.capacity) boxcapacity, max(dk.saleboxid) saleboxid, '+
        ' min(ts.ratecapacity) ratecapacity '+
        ' from transportation t '+
        ' join drinktransportation dt on t.id = dt.Transportationid '+
        ' join drinkkind dk on dt.todrinkkindid = dk.id '+
        ' join box bx on dk.saleboxid = bx.id '+
        ' join drink d on d.id = dk.drinkid '+
        ' join capacity c on dk.capacityid = c.id '+
        ' join partycertificate pc on pc.id = dk.partycertificateid '+
        ' join storage fs on t.storageid = fs.id '+
        ' join storage ts on t.tostorageid = ts.id '+
        ' left join drinkrack dr on (dt.id = dr.racktableid and dr.racktablesid = 22) '+
        ' where t.id = '+ Transportation.Id +
        ' and dt.todrinkkindid = '+ Transportation.ToDrinkKindId +
        ' and (dt.drinkrackcountout is null or dt.bottlecount <> dt.drinkrackcountout) '+
        ' group by dt.drinkkindid ';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        exit;
       end;
     ReadIBQ.First;

     if ((ReadIBQ.RecordCount > 0) and ((ReadIBQ.FieldByName('boxcount').asFloat - ReadIBQ.FieldByName('StorageCountout').asFloat)>0)) then
      begin
       TextInfo:='"�������� �����������" '+
                 '"�� �������� �����" '+
                 '"��������� N'+Transportation.Id+'" '+
                 '"�� '+Transportation.Present+'" '+
                 '"'+Copy(Trim(ReadIBQ.FieldByName('name').AsString),1,15)+' '+Trim(FloatToStr(ReadIBQ.FieldByName('volume').AsFloat))+'" '+
                 '"���:'+Transportation.ToDrinkKindId+' �.�.:'+IntToStr(ReadIBQ.FieldByName('capacity').asInteger)+'" '+
                 '"�������:'+FloatToStr(Trunc((ReadIBQ.FieldByName('boxcount').asFloat - ReadIBQ.FieldByName('storagecountout').asFloat)*100)/100)+'��." '+
                 '"������:'+Transportation.RackName+'"';
       DrawText(TextInfo);
       flag:=true;
       while flag and ReadLine(Transportation.RackId) do
        begin
         if Transportation.RackId='' then
          begin
           DrawError('�������� ��� ������');
           DrawText(TextInfo);
          end
          else
           begin
            CmdText:='select * from getfree_rack('+Transportation.ToDrinkKindId+',0,'+Transportation.ToStorageId+') '+
                     'where id='+Transportation.RackId;
            if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
             begin
              if Error then
               begin
                DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                exit;
               end
              else
               begin
                DrawError('�������� ��� ������');
                DrawText(TextInfo);
               end;
             end
            else
             begin
              Transportation.RackName:=ReadIBQ.FieldByName('name').AsString;
              flag:=false
             end;
           end;
         end;

        if flag then
         begin
          if Assigned(Transportation) then
           begin
            Dispose(Transportation);
            Transportation:=nil;
           end;
          if Assigned(PrintCodes) then
           begin
            Dispose(PrintCodes);
            PrintCodes:=nil;
           end;
          Result:=true;
         end
        else
         if TransportationInRackScreen_2 then
          Result:=true;
      end
     else
      DrawError('������� ������ ���������� ���������. ��� ����������� ������� Ok');
    end;//else if (InputLine='')
  end// if ReadLine(InputLine) then
 else
  begin
   if Assigned(Transportation) then
    begin
     Dispose(Transportation);
     Transportation:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;

procedure TransportationInRackScreen_0(FromMainMenu:boolean);
var CmdText:string;
    CountError:integer;
    Error:boolean;
begin
 CountError:=0;
 while Assigned(Transportation) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(Transportation) then
    begin
     DrawText('�������� ����������� �� �������� ����� ���������� �����-���');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') or (not(CheckBarcodeOnDoc('0'+InputLine,dtTransportationIn))) then
        DrawError('�������� �����-��� ��� ����������� �� ����� 1-�� ����. ��� ����������� ������� Ok')
      else
       begin
        Transportation:=New(PTransportation);
        Transportation.Id:=IntToStr(StrToIntDef(Copy(InputLine,4,8),0));
        if Transportation.Id='0' then
         begin //���� ����� �����-���� �� ������
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          break;
         end;//if Transportation.Id=0 the
       end;//else if ReadLine(InputLine) then
    end;//if not Assigned(Transportation) then

   if Assigned(Transportation) then
    begin
     CmdText:='select transportationid, transportationpresent, fromstorageid, tostorageid, '+
              'fromstoragetypeid, tostoragetypeid, '+
              'allbox, remainingbox '+
              'from terminal_transinfo('+Transportation.Id+') ti '+
              'join storage st on st.id=ti.fromstorageid '+
              'where st.terminalid in ('+TerminalID+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        break;
       end;
     ReadIBQ.First;

     if ReadIBQ.FieldByName('transportationid').IsNull then
      begin
       DrawError('��������� �� ����������� ���������� ��� �� ����������. ��� ����������� ������� Ok');
       break;
      end;

     Transportation.Present:=FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('transportationpresent').AsDateTime);

     if ReadIBQ.FieldByName('remainingbox').AsInteger=0 then
      begin
       DrawError('"��� ������� ��" '+
                 '"��������� N'+Transportation.Id+'" '+
                 '"�� '+Transportation.Present+'" '+
                 '"����������" '+
                 '"��� �����������" '+
                 '"������� Ok"');
       break;
      end;
     Transportation.FromStorageId:=ReadIBQ.FieldByNAme('fromstorageid').AsString;
     Transportation.ToStorageId:=ReadIBQ.FieldByNAme('tostorageid').AsString;
     Transportation.FromStorageType:=ReadIBQ.FieldByNAme('fromstoragetypeid').Value;
     Transportation.ToStorageType:=ReadIBQ.FieldByNAme('tostoragetypeid').Value;

     DrawText('"�������� �����������" '+
              '"�� �������� �����" '+
              '"��������� N'+Transportation.Id+'" '+
              '"�� '+Transportation.Present+'" '+
              '"�����: '+ReadIBQ.FieldByName('allbox').AsString+'��." '+
              '"�������: '+ReadIBQ.FieldByName('remainingbox').AsString+'��." '+
              '"���������� �����-���"');
     if not TransportationInRackScreen_1 then
      Inc(CountError)
     else
      CountError:=0;
    end;//if Assigned(Transportation) then
  end;//while Assigned(Transportation) or FromMainMenu do

 if Assigned(Transportation) then
  begin
   Dispose(Transportation);
   Transportation:=nil;
  end;

 if Assigned(PrintCodes) then
  begin
   Dispose(PrintCodes);
   PrintCodes:=nil;
  end;
end;

function TransportationOutRackScreen_1:boolean;
var CmdText,TextInfo:string;
    CodesId:string;
    Error,ErrorFlag:boolean;
    RetValue,DrinkKindID,CountNeedClear:integer;
    flag:boolean;
begin
 Result:=false;
 ErrorFlag:=false;
 InputLine:=''; 
 if ReadLine(InputLine) then
  begin
   if (InputLine='') then
    begin
     DrawError('�������� �����-���. ��� ����������� ������� Ok')
    end
   else
    if (not CheckBarcodeOnLabel(InputLine)) then
     begin
      try
       DrinkKindID:=StrToInt(InputLine);
      except
       ErrorFlag:=true;
      end;

      if (ErrorFlag) then
       begin
        DrawError('�� ������ ��� ������. ��� ����������� ������� Ok');
        exit;
       end;

      CmdText:='select d.id, d.mark, d.volume, '+
               ' sum(coalesce(dt.drinkrackcount,0)) drinkrackcount, '+
               ' sum(coalesce(dt.drinkrackcountout,0)) drinkrackcountout '+
               'from transportation tr '+
               'join drinktransportation dt on tr.id=dt.transportationid '+
               'join drinkkind dk on dk.id=dt.todrinkkindid '+
               'join box bx on bx.id=dk.saleboxid '+
               'join drink d on d.id=dk.drinkid '+
               'where tr.id='+Transportation.Id+
               ' and dk.id='+IntToStr(DrinkKindID)+
               ' group by d.id, d.mark, d.volume, dk.id';

      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
         DrawError('�� ������ ��� ������. ��� ����������� ������� Ok');
        exit;
       end;
      ReadIBQ.First;

      if ReadIBQ.FieldByName('drinkrackcount').AsInteger=ReadIBQ.FieldByName('drinkrackcountout').AsInteger then
       begin
        DrawError('������� �� ��������� N'+Transportation.Id+' ��������� ����������. ��� ����������� ������� Ok');
        exit;
       end;

      TextInfo:='"�������� �����������" '+
                '"� ��������� ������" '+
                '"��������� N'+Transportation.Id+'" '+
                '"�� '+Transportation.Present+'" '+
                '"'+Copy(Trim(ReadIBQ.FieldByName('mark').AsString),1,15)+' '+Trim(FloatToStr(ReadIBQ.FieldByName('volume').AsFloat))+'" '+
                '"�����: '+ReadIBQ.FieldByName('drinkrackcount').AsString+'��." '+
                '"�������: '+IntToStr(ReadIBQ.FieldByName('drinkrackcount').AsInteger-ReadIBQ.FieldByName('drinkrackcountout').AsInteger)+'��." '+
                '"���-�� ��� �������?"';
      DrawText(TextInfo);
      flag:=true;
      InputLine:=IntToStr(ReadIBQ.FieldByName('drinkrackcount').AsInteger-ReadIBQ.FieldByName('drinkrackcountout').AsInteger);
      while flag and ReadLine(InputLine) do
       begin
        if InputLine='' then
         begin
          DrawError('�������� ���-��.');
          DrawText(TextInfo);
         end
        else
         begin
          ErrorFlag:=false;
          try
           CountNeedClear:=StrToInt(InputLine);
          except
           ErrorFlag:=true;
          end;
          if (ErrorFlag) or (CountNeedClear>(ReadIBQ.FieldByName('drinkrackcount').AsInteger-ReadIBQ.FieldByName('drinkrackcountout').AsInteger)) then
           begin
            DrawError('�������� ���-��.');
            DrawText(TextInfo);
           end
          else
           flag:=false
         end;
       end;
       if flag then
        exit;

      CmdText:='select * from codesclearingdrinkkindtrans_1('+
        Transportation.Id+','+IntToStr(DrinkKindID)+','+
        IntToStr(UserInfo.Id)+','+IntToStr(CountNeedClear)+')';
      InUpDelIBT.StartTransaction;
      try
       if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('����������� ������. ��� ����������� ������� Ok');
         exit;
        end
       else
        begin
         InUpDelIBQ.First;
         RetValue:=InUpDelIBQ.FieldByName('aresult').AsInteger;
         if RetValue = 0 then
          begin
           InUpDelIBT.Commit;
           Result:=true;
          end
         else
          begin
           case RetValue of
            1: DrawError('������ �������� ��� �������� ���� �� ����������. ��� ����������� ������� Ok');
            2: DrawError('������ ��������� �� �����������. �������� �� ������. ��� ����������� ������� Ok');
            3: DrawError('���� �� �� ������� ��������� �� �����������. ��� ����������� ������� Ok');
            4: DrawError('����������� ������� ���������� �������. ��� ����������� ������� Ok');
            5: DrawError('��������� �� ����������� �� �� ������ ��������� ����. ��� ����������� ������� Ok');
            6: DrawError('����� �� ������ ��������� �������. ��� ����������� ������� Ok');
          end;
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end;
       end;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ��� ������������ ����� �� ��������� �� �����������. ��� ����������� ������� Ok');
      end;
     end;//try

     end
    else
     begin
     CodesId:= IntToStr(StrToIntDef(Copy(InputLine,2,8),0));
     if CodesId='0' then//���� �����-���� �� ���e�
      begin
       DrawError('�������� �����-���. ��� ����������� ������� Ok');
       exit;
      end;
     CmdText:='select * from CodesClearing_ForTr_From1('+Transportation.Id+','+CodesId+','+IntToStr(UserInfo.Id)+')';
     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
          DrawError('����������� ������. ��� ����������� ������� Ok');
        exit;
       end
      else
       begin
        InUpDelIBQ.First;
        RetValue:=InUpDelIBQ.FieldByName('aresult').AsInteger;
        if RetValue = 0 then
         begin
          InUpDelIBT.Commit;
          Result:=true;
         end
        else
         begin
          case RetValue of
           1: DrawError('������ �������� ��� �������� ���� �� ����������. ��� ����������� ������� Ok');
           2: DrawError('������ ��������� �� �����������. �������� �� ������. ��� ����������� ������� Ok');
           3: DrawError('���� �� �� ������� ��������� �� �����������. ��� ����������� ������� Ok');
           4: DrawError('����������� ������� ���������� �������. ��� ����������� ������� Ok');
           5: DrawError('��������� �� ����������� �� �� ������ ��������� ����. ��� ����������� ������� Ok');
           6: DrawError('����� �� ������ ��������� �������. ��� ����������� ������� Ok');
          end;
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end;
       end;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ��� ������������ ����� �� ��������� �� �����������. ��� ����������� ������� Ok');
      end;
     end;//try
    end;
  end
 else
  begin
   if Assigned(Transportation) then
    begin
     Dispose(Transportation);
     Transportation:=nil;
    end;
   Result:=true;
  end;
end;

procedure TransportationOutRackScreen_0(FromMainMenu:boolean);
var CmdText:string;
    CountError:integer;
    Error:boolean;
    DRCOuntOut: integer;
begin
 CountError:=0;
 while Assigned(Transportation) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(Transportation) then
    begin
     DrawText('"�������� �����������" "� ��������� ������" "���������� �����-���"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') or (not(CheckBarcodeOnDoc('0'+InputLine,dtTransportationOut))) then
        DrawError('�������� �����-��� ��� ����������� �� ������ 1-�� ����. ��� ����������� ������� Ok')
      else
       begin
        Transportation:=New(PTransportation);
        Transportation.Id:=IntToStr(StrToIntDef(Copy(InputLine,4,8),0));
        if Transportation.Id='0' then
         begin //���� ����� �����-���� �� ������
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          break;
         end;//if transportation.id=0 then
       end;//else if readline(InputLine) then
    end;//if not Assigned(Transportation) then

   if Assigned(Transportation) then
    begin
     CmdText:='select transportationid,transportationpresent,storageid, '+
              '       tostorageid, fstoragetype, tstoragetype, '+
              'drinkrackcount, drinkrackcountout, allbox, remainingbox '+
              'from transportation_info('+Transportation.Id+') ti '+
              'join storage st on st.id=ti.storageid '+
              'where st.terminalid in ('+TerminalID+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        break;
       end;
     ReadIBQ.First;

     if ReadIBQ.FieldByName('transportationid').IsNull then
      begin
       DrawError('��������� �� ����������� �� ����������. ��� ����������� ������� Ok');
       break;
      end;

     if ReadIBQ.FieldByName('remainingbox').AsInteger=0 then
      begin
       DrawError('��� ������� �� ��������� N'+Transportation.Id+' ����������. ��� ����������� ������� Ok');
       break;
      end;
     Transportation.Present:=FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('transportationpresent').AsDateTime);
     DrawText('"�������� �����������" '+
              '"� ��������� ������" '+
              '"��������� N'+Transportation.Id+'" '+
              '"�� '+Transportation.Present+'" '+
              '"�����: '+ReadIBQ.FieldByName('allbox').AsString+'��." '+
              '"�������: '+ReadIBQ.FieldByName('remainingbox').AsString+'��." '+
              '"���������� ��������"');
     if not TransportationOutRackScreen_1 then
      Inc(CountError)
     else
      CountError:=0;
    end;//if Assigned(Transportation) then
  end;//while Assigned(Transportation) or FromMainMenu do

 if Assigned(Transportation) then
  begin
   Dispose(Transportation);
   Transportation:=nil;
  end;
end;

function TransportationFromRackToRackScreen_custom:boolean;
var CmdText: String;
    Error:boolean;
    CodesId: String;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (((InputLine='') or (not CheckBarcodeOnLabel(InputLine))) and (not (TransportationFromRackToRack.SourceDrinkKindId=InputLine))) then
    DrawError('�������� �����-���. ��� ����������� ������� Ok')
   else
    begin
     if TransportationFromRackToRack.SourceDrinkKindId=InputLine then
      begin
       CmdText:='select * from terminal_transfromracktorackall('+TransportationFromRackToRack.SourceRackId+','+
                                                                  TransportationFromRackToRack.SourceDrinkKindId+','+
                                                                  TransportationFromRackToRack.DestinationRackId+','+
                                                                  IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+','+
                                                                  IntToStr(UserInfo.Id)+',null)';
      end
     else
      begin
       CodesId:= IntToStr(StrToIntDef(Copy(InputLine,2,8),0));
       CmdText:='select id from codes co where co.outdrinkrackid is null'+
                ' and co.rackid='+TransportationFromRackToRack.SourceRackId+
                ' and co.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindId+
                ' and co.id='+CodesId;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('�������� ��� ��������, ���� �� �������� ��� ��������� ����������. ��� ����������� ������� Ok');
         exit;
        end;
       ReadIBQ.First;

       CmdText:='execute procedure terminal_transfromracktorack('+CodesId+','+TransportationFromRackToRack.SourceRackId+','+
                                                                  TransportationFromRackToRack.DestinationRackId+','+
                                                                  TransportationFromRackToRack.SourceDrinkKindId+','+
                                                                  IntToStr(TransportationFromRackToRack.CountBoxTransportation)+','+
                                                                  IntToStr(UserInfo.Id)+',null)';
      end;

     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       end;
      InUpDelIBT.Commit;
      Result:=true;
      TransportationFromRackToRack.NewTransportation:=false;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
        DrawError('������ ��� ����������. ��� ����������� ������� Ok.'+E.Message);
       end;
      end;//try
    end; //else if (InputLine='') or (not CheckBarcodeOnLabel(InputLine)) then
  end
 else
  begin
   if Assigned(TransportationFromRackToRack) then
    begin
     Dispose(TransportationFromRackToRack);
     TransportationFromRackToRack:=nil;
    end;
   Result:=true;
  end;
end;

function TransportationFromRackToRackScreen_full:boolean;
var CmdText: String;
    Error:boolean;
begin
 InUpDelIBT.StartTransaction;
 try
  CmdText:=
  'select * from terminal_transfromracktorackall('+
   TransportationFromRackToRack.SourceRackId+','+
   TransportationFromRackToRack.SourceDrinkKindId+','+
   TransportationFromRackToRack.DestinationRackId+','+
   IntToStr(TransportationFromRackToRack.CountBoxTransportation)+','+
   IntToStr(UserInfo.Id)+',null)';


  if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
   if Error then
    begin
     DrawError(ErrorMessage+' ��� ����������� ������� Ok');
     exit;
    end;
  InUpDelIBT.Commit;
  Result:=true;
  TransportationFromRackToRack.NewTransportation:=false;
 except on E:Exception do
  begin
   if InUpDelIBT.Active then
    InUpDelIBT.Rollback;
   DrawError('������ ��� ����������. ��� ����������� ������� Ok'+E.Message);
  end;
 end;//try
end;

function TransportationFromRackToRackScreen_Full_WithNewDrinkKindId:boolean;
var ErrorCode,TextConfirmation,CmdText:string;
    BuyId,DrinkBuyId,PartycertificateId,ContractorderId,NewDrinkkindId:string;
    i,j,m,n:integer;
    Error:boolean;
    BoxCapacity,BoxCount,NewBottleCount:integer;
    providerpricesum,providerndssum:double;
    NewPriceContractorder,NewNDSContractorder:double;
    oldsourcecodesid,olddestinationcodesid:array of array of integer;
    newcodesid:array of array of integer;
    sourcebottlecount,sourcedrinkkindid,
    destinationbottlecount,destinationdrinkkindid:string;
    sourceremovingid,sourceremovingdrinkrackid,sourcestorageid,
    destinationremovingid,destinationremovingdrinkrackid,destinationstorageid:string;
//    storageid:string;
    CodesDate:Real;
begin
 result:=false;
 CmdText:='select ch.bottlecount,ch.drinkkindid,ch.storageid '+
          'from cashe ch '+
          'where ch.rackid='+TransportationFromRackToRack.SourceRackId+
          ' and ch.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindId;
 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  if Error then
   begin
    DrawError(ErrorMessage+' ��� ����������� ������� Ok');
    exit;
   end;
 sourcebottlecount:=ReadIBQ.FieldByName('bottlecount').AsString;
 sourcedrinkkindid:=ReadIBQ.FieldByName('drinkkindid').AsString;
 sourcestorageid:=ReadIBQ.FieldByName('storageid').AsString;
 CmdText:='select ch.bottlecount,ch.drinkkindid,ch.storageid '+
          'from cashe ch where ch.rackid='+TransportationFromRackToRack.DestinationRackId;
 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  if Error then
   begin
    DrawError(ErrorMessage+' ��� ����������� ������� Ok');
    exit;
   end;
 destinationbottlecount:=ReadIBQ.FieldByName('bottlecount').AsString;
 destinationdrinkkindid:=ReadIBQ.FieldByName('drinkkindid').AsString;
 destinationstorageid:=ReadIBQ.FieldByName('storageid').AsString;
 InUpDelIBQ.Transaction.StartTransaction;
 try
  ErrorCode:='������ ��� ����� ��������� ���������.';
  CmdText:='execute procedure i_buy(cast('+#39+'today'+#39+' as timestamp),'+
           'null,4783,2,'+destinationstorageid+',1,1,1,'+
           #39+'100'+#39+','+#39+'100'+#39+',6,100,null,0)';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.ExecSQL;

  CmdText:='select max(id) buyid from buy b where b.firmid=4783 and b.inventoryid=100';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  BuyId:=InUpDelIBQ.FieldByName('buyid').AsString;

{-------------------------------------��������---------------------------------}
  ErrorCode:='������ ��� ����� �������� �� �������� ������.';
  CmdText:='select aremovingid from createnewremoving ('+
           sourcedrinkkindid+','+sourcestorageid+','+
           TransportationFromRackToRack.SourceRackId+','+
           sourcebottlecount+','+
           #39#39+',88,null,null,100,0)';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select r.id removingid, dr.id removingdrinkrackid from removing r '+
           'join drinkrack dr on dr.racktableid=r.id and dr.racktablesid=11 '+
           'where r.removingtypeid=88'+
           ' and dr.rackid='+TransportationFromRackToRack.SourceRackId+
           ' and r.drinkkindid='+sourcedrinkkindid+
           ' and r.id='+InUpDelIBQ.Fields[0].AsString;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  sourceremovingid:=InUpDelIBQ.FieldByName('removingid').AsString;
  sourceremovingdrinkrackid:=InUpDelIBQ.FieldByName('removingdrinkrackid').AsString;



  ErrorCode:='������ ��� ����� �������� �� ������ ����������.';
  CmdText:='select aremovingid from createnewremoving ('+
           destinationdrinkkindid+','+destinationstorageid+','+
           TransportationFromRackToRack.DestinationRackId+','+
           destinationbottlecount+','+
           #39#39+',88,null,null,100,0)';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select r.id removingid, dr.id removingdrinkrackid from removing r '+
           'join drinkrack dr on dr.racktableid=r.id and dr.racktablesid=11 '+
           'where r.removingtypeid=88'+
           ' and dr.rackid='+TransportationFromRackToRack.DestinationRackId+
           ' and r.drinkkindid='+destinationdrinkkindid+
           ' and r.id='+InUpDelIBQ.Fields[0].AsString;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  destinationremovingid:=InUpDelIBQ.FieldByName('removingid').AsString;
  destinationremovingdrinkrackid:=InUpDelIBQ.FieldByName('removingdrinkrackid').AsString;

  //----------------������� �������� �������� ������
  ErrorCode:='������ ��� ������� �������� �������� ������.';
  CmdText:='select co.id codesid,co.indrinkrackid indrinkrackid,co.whencreate from codes co '+
           'where co.drinkkindid='+sourcedrinkkindid+
           ' and co.rackid='+TransportationFromRackToRack.SourceRackId+
           ' and co.outdrinkrackid is null';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;
  InUpDelIBQ.First;
  i:=0;
  while not InUpDelIBQ.Eof do
   begin
    Inc(i);
    SetLength(oldsourcecodesid,i,3);
    oldsourcecodesid[i-1,0]:=InUpDelIBQ.FieldByName('codesid').AsInteger;
    oldsourcecodesid[i-1,1]:=InUpDelIBQ.FieldByName('indrinkrackid').AsInteger;
    oldsourcecodesid[i-1,2]:=Round(Int(InUpDelIBQ.FieldByName('whencreate').AsDateTime));
    InUpDelIBQ.Next;
   end;

  for i:=0 to Length(oldsourcecodesid)-1 do
   begin
    CmdText:='execute procedure codes_clearing('+
                sourceremovingid+','+IntToStr(oldsourcecodesid[i,0])+','+
                TransportationFromRackToRack.SourceRackId+','+
                sourcedrinkkindid+','+IntToStr(UserInfo.Id)+')';
    InUpDelIBQ.Close;
    InUpDelIBQ.SQL.Clear;
    InUpDelIBQ.SQL.Add(CmdText);
    InUpDelIBQ.ExecSQL;
   end;

  //----------------������� �������� ������ ����������
  ErrorCode:='������ ��� ������� �������� ������ ����������.';
  CmdText:='select co.id codesid,co.indrinkrackid indrinkrackid,co.whencreate from codes co '+
           'where co.drinkkindid='+destinationdrinkkindid+
           ' and co.rackid='+TransportationFromRackToRack.DestinationRackId+
           ' and co.outdrinkrackid is null';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;
  InUpDelIBQ.First;
  j:=0;
  while not InUpDelIBQ.Eof do
   begin
    Inc(j);
    SetLength(olddestinationcodesid,j,3);
    olddestinationcodesid[j-1,0]:=InUpDelIBQ.FieldByName('codesid').AsInteger;
    olddestinationcodesid[j-1,1]:=InUpDelIBQ.FieldByName('indrinkrackid').AsInteger;
    olddestinationcodesid[j-1,2]:=Round(Int(InUpDelIBQ.FieldByName('whencreate').AsDateTime));
    InUpDelIBQ.Next;
   end;

  for j:=0 to Length(olddestinationcodesid)-1 do
   begin
    CmdText:='execute procedure codes_clearing('+
                destinationremovingid+','+IntToStr(olddestinationcodesid[j,0])+','+
                TransportationFromRackToRack.DestinationRackId+','+
                destinationdrinkkindid+','+IntToStr(UserInfo.Id)+')';
    InUpDelIBQ.Close;
    InUpDelIBQ.SQL.Clear;
    InUpDelIBQ.SQL.Add(CmdText);
    InUpDelIBQ.ExecSQL;
   end;
{------------------------------------------------------------------------------}

{--------------------------���������� � ����� �������--------------------------}
  ErrorCode:='������ ��� ����� ���������� � �������.';
  CmdText:='select * from TERMINAL_TRANSUNIONRACKADDPC_1('+sourcedrinkkindid+','+destinationdrinkkindid+')';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  PartycertificateId:=InUpDelIBQ.FieldByName('partycertificateid').AsString;
{------------------------------------------------------------------------------}

{--------------------------���������� � ��������� �����------------------------}
  CmdText:='select co.id contractorderid,co.pricecontractorder,co.ndscontractorder '+
           'from contractorder co where co.id= '+
           '(select max(dk.contractorderid) from drinkkind dk where dk.id in ('+
            sourcedrinkkindid+','+destinationdrinkkindid+'))';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  ContractorderId:=InUpDelIBQ.FieldByName('contractorderid').AsString;
  NewPriceContractorder:=InUpDelIBQ.FieldByName('pricecontractorder').AsFloat;
  NewNDSContractorder:=InUpDelIBQ.FieldByName('ndscontractorder').AsFloat;
{------------------------------------------------------------------------------}

{--------------------------���������� � ���� ������------------------------}
  CmdText:='select dk.drinkid, dk.boxid, dk.saleboxid,'+
           ' dk.capacityid, dk.typemarketgroupid, '+
           ' sb.capacity, dk.terminalid, dk.departmentid '+
           'from drinkkind dk '+
           'join box sb on sb.id=dk.saleboxid '+
           'where dk.id='+sourcedrinkkindid;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;
  BoxCapacity:=InUpDelIBQ.FieldByName('capacity').AsInteger;
{------------------------------------------------------------------------------}

{-------------------------------����� ��� ������-------------------------------}
  ErrorCode:='������ ��� ������� ������ ���� ������.;';
  CmdText:='select drinkkindid from drinkkind_getorcreate('+
           InUpDelIBQ.FieldByName('drinkid').AsString+','+
           InUpDelIBQ.FieldByName('boxid').AsString+','+
           '1,'+
           ContractorderId+','+
           InUpDelIBQ.FieldByName('saleboxid').AsString+','+
           InUpDelIBQ.FieldByName('capacityid').AsString+','+
           PartycertificateId+','+
           InUpDelIBQ.FieldByName('typemarketgroupid').AsString+','+
           InUpDelIBQ.FieldByName('terminalid').AsString+','+
           InUpDelIBQ.FieldByName('departmentid').AsString+')';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;
  NewDrinkkindId:=InUpDelIBQ.FieldByName('drinkkindid').AsString;
{------------------------------------------------------------------------------}

{-----------------------------------������ �������-----------------------------}
  ErrorCode:='������ ��� ��������� ������� �������';
  NewBottleCount:=StrToInt(DestinationBottleCount)+StrToInt(SourceBottleCount);
  BoxCount:=Round(NewBottleCount/BoxCapacity);

  CmdText:='select id from I_DRINKBUY('+
           BuyId+','+
           NewDrinkKindId+',0,'+
           IntToStr(NewBottleCount)+','+
           IntToStr(BoxCount)+','+destinationstorageid+','+
           FloatToStr(NewBottleCount*Round(NewPriceContractorder*1000)/1000)+','+
           FloatToStr(NewBottleCount*Round(NewNDSContractorder*1000)/1000)+','+
           IntToStr(0)+',null)';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  DrinkBuyId:=InUpDelIBQ.FieldByName('id').AsString;

  ProviderPriceSum:=ProviderPriceSum+NewBottleCount*Round(NewPriceContractorder*1000)/1000;
  ProviderNDSSum:=ProviderNDSSum+NewBottleCount*Round(NewNDSContractorder*1000)/1000;
{------------------------------------------------------------------------------}

{---------------------------�������� ����� ��������----------------------------}
  ErrorCode:='������ ��� �������� ����� ��������.';

  CmdText:='select codesid,drinkrackid from AddCodes('+
           NewDrinkKindId+','+IntToStr(BoxCount)+','+IntToStr(BoxCapacity)+','+
           TransportationFromRackToRack.DestinationRackId+','+
           DrinkBuyId+',3,'+IntToStr(UserInfo.Id)+')';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  m:=0;
  while not InUpDelIBQ.Eof do
   begin
    Inc(m);
    SetLength(newcodesid,m,2);
    newcodesid[m-1,0]:=InUpDelIBQ.FieldByName('codesid').AsInteger;
    newcodesid[m-1,1]:=InUpDelIBQ.FieldByName('drinkrackid').AsInteger;
    InUpDelIBQ.Next;
   end;
{------------------------------------------------------------------------------}

{--------------------------------������ ��������-------------------------------}
 ErrorCode:='������ ��� ������ ��������.';
  if m<>i+j then
   begin
    InUpDelIBQ.Transaction.Rollback;
    exit;
   end;

  for n:=0 to m-1 do
   begin
    if n<i then
     begin
      CmdText:='update codes co set co.drinkkindid='+newdrinkkindid+','+
               'co.indrinkrackid='+IntToStr(newcodesid[n,1])+','+
               'co.whencreate=cast('+#39+'now'+#39+' as timestamp),'+
               'co.outdrinkrackid=null,'+
               'co.rackid='+TransportationFromRackToRack.DestinationRackId+','+
               'co.whencleared=null '+
               ' where co.id='+IntToStr(oldsourcecodesid[n,0]);
      InUpDelIBQ.Close;
      InUpDelIBQ.SQL.Clear;
      InUpDelIBQ.SQL.Add(CmdText);
      InUpDelIBQ.Open;

      CmdText:='update codes co set co.drinkkindid='+sourcedrinkkindid+','+
               'co.indrinkrackid='+IntToStr(oldsourcecodesid[n,1])+','+
               'co.whencreate=cast('+#39+DateToStr(FloatToDateTime(oldsourcecodesid[n,2]))+#39+' as timestamp),'+
               'co.outdrinkrackid='+sourceremovingdrinkrackid+','+
               'co.whocleared='+IntToStr(UserInfo.Id)+','+
               'co.rackid='+TransportationFromRackToRack.SourceRackId+
               ' where co.id='+IntToStr(newcodesid[n,0]);
      InUpDelIBQ.Close;
      InUpDelIBQ.SQL.Clear;
      InUpDelIBQ.SQL.Add(CmdText);
      InUpDelIBQ.Open;
     end
    else
     begin
      CmdText:='update codes co set co.drinkkindid='+newdrinkkindid+','+
               'co.indrinkrackid='+IntToStr(newcodesid[n,1])+','+
               'co.whencreate=cast('+#39+'now'+#39+' as timestamp),'+
               'co.outdrinkrackid=null,'+
               'co.rackid='+TransportationFromRackToRack.DestinationRackId+','+
               'co.whencleared=null '+
               ' where co.id='+IntToStr(olddestinationcodesid[n-i,0]);
      InUpDelIBQ.Close;
      InUpDelIBQ.SQL.Clear;
      InUpDelIBQ.SQL.Add(CmdText);
      InUpDelIBQ.Open;

      CmdText:='update codes co set co.drinkkindid='+destinationdrinkkindid+','+
               'co.indrinkrackid='+IntToStr(olddestinationcodesid[n-i,1])+','+
               'co.whencreate=cast('+#39+DateToStr(FloatToDateTime(olddestinationcodesid[n-i,2]))+#39+' as timestamp),'+
               'co.outdrinkrackid='+destinationremovingdrinkrackid+','+
               'whocleared='+IntToStr(UserInfo.Id)+','+
               'co.rackid='+TransportationFromRackToRack.DestinationRackId+
               ' where co.id='+IntToStr(newcodesid[n,0]);
      InUpDelIBQ.Close;
      InUpDelIBQ.SQL.Clear;
      InUpDelIBQ.SQL.Add(CmdText);
      InUpDelIBQ.Open;
     end;
   end;
{------------------------------------------------------------------------------}
  ErrorCode:='������ ��� ����� ������� ��������� ���������.';
  CmdText:='update buy b set b.providerpricesum='+FloatToStr(providerpricesum)+','+
           ' b.providerndssum='+FloatToStr(providerndssum)+','+'b.directorview=2 '+
           'where b.id='+buyid;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='update buy b set b.directorview=2 where b.id='+buyid;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  InUpDelIBQ.Transaction.Commit;
   result:=true;
  TransportationFromRackToRack.NewTransportation:=false;
 except on E:Exception do
  begin
   InUpDelIBQ.Transaction.RollBack;
   DrawError(ErrorCode+' '+Trim(E.Message));
   exit;
  end;//on E:Exception
 end;//try..except

end;

function TransportationFromRackToRackScreen_ToNotRackStorageFullBox:boolean;
var CmdText,TransportationID:string;
    Error:boolean;
begin
 result:=false;
 InUpDelIBQ.Transaction.StartTransaction;
 try
  CmdText:='insert into transportation(storageid,tostorageid,present,sqnno,statusid) '+
           'values('+TransportationFromRackToRack.FromStorageId+','+TransportationFromRackToRack.ToStorageId+','+
                   'cast('+#39+'today'+#39+' as timestamp),(select max(sqnno)+1 from transportation),0)';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select max(id) trid from transportation tr '+
           'where tr.storageid='+TransportationFromRackToRack.FromStorageId+
           ' and tr.tostorageid='+TransportationFromRackToRack.ToStorageId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationID:=InUpDelIBQ.FieldByName('trid').AsString;

  CmdText:='insert into drinktransportation(transportationid, '+
           'drinkkindid, bottlecount, toboxid, tocapacityid, '+
           'toplanboxid, tocontractorderid, totypemarketgroupid, reserverackid) '+
           ' values ( '+TransportationID+','+TransportationFromRackToRack.SourceDrinkKindId+','+
                        IntToStr(TransportationFromRackToRack.CountBottleTransportation)+','+
                        TransportationFromRackToRack.SaleBoxID+','+
                        TransportationFromRackToRack.CapacityID+','+
                        TransportationFromRackToRack.BoxID+','+
                        TransportationFromRackToRack.ContractorderID+','+
                        TransportationFromRackToRack.TypemarketgroupID+','+
                        TransportationFromRackToRack.SourceRackId+')';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select dt.todrinkkindid from drinktransportation dt '+
           'where dt.transportationid='+TransportationID+
           ' and dt.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationFromRackToRack.DestinationDrinkKindId:=InUpDelIBQ.FieldByName('todrinkkindid').AsString;
  TransportationFromRackToRack.CountBoxTransportation:=Round((TransportationFromRackToRack.CountBottleTransportation/StrToInt(TransportationFromRackToRack.Capacity))+0.01);

  CmdText:='select * from codesclearingdrinkkindtrans('+
           TransportationID+','+TransportationFromRackToRack.DestinationDrinkKindId+','+
           IntToStr(UserInfo.Id)+','+IntToStr(TransportationFromRackToRack.CountBoxTransportation)+')';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  InUpDelIBQ.Transaction.Commit;
  result:=true;
 except on E:Exception do
  begin
   InUpDelIBQ.Transaction.RollBack;
   DrawError(Trim(E.Message));
   if Assigned(TransportationFromRackToRack) then
    begin
     Dispose(TransportationFromRackToRack);
     TransportationFromRackToRack:=nil;
    end;
   exit;
  end;//on E:Exception
 end;//try..except
end;

function TransportationFromRackToRackScreen_ToNotRackStorageCustom:boolean;
var CmdText,TransportationID,DrinkTransportationID,DrinkKindID,RackID:string;
    Error:boolean;
    TransToNotRackStorageBottleCount,i:integer;
begin
 result:=false;
 InUpDelIBQ.Transaction.StartTransaction;
 try
  //------------������� ��������� �� ����������� �� �� �������� �����-----------------//
  CmdText:='insert into transportation(storageid,tostorageid,present,sqnno,statusid) '+
           'values('+TransportationFromRackToRack.FromStorageId+','+TransportationFromRackToRack.ToStorageId+',cast('+
                    #39+'today'+#39+' as timestamp),(select max(sqnno)+1 from transportation),0)';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.ExecSQL;

  //---������� id ���������-----
  CmdText:='select max(id) trid from transportation tr '+
           'where tr.storageid='+TransportationFromRackToRack.FromStorageId+
           ' and tr.tostorageid='+TransportationFromRackToRack.ToStorageId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationID:=InUpDelIBQ.FieldByName('trid').AsString;
  //----������� ����� ���������� ������
  TransToNotRackStorageBottleCount:=
   (Round(TransportationFromRackToRack.CountBottleTransportation/StrToInt(TransportationFromRackToRack.Capacity)+0.01)+1)*
    StrToInt(TransportationFromRackToRack.Capacity);

  //----������� ������� � ��������� �� �����������
  CmdText:='insert into drinktransportation(transportationid, '+
           'drinkkindid, bottlecount, toboxid, tocapacityid, '+
           'toplanboxid, tocontractorderid, totypemarketgroupid, reserverackid) '+
           ' values ( '+TransportationID+','+TransportationFromRackToRack.SourceDrinkKindId+','+
                        IntToStr(TransToNotRackStorageBottleCount)+',2,'+TransportationFromRackToRack.CapacityID+',2,'+
                        TransportationFromRackToRack.ContractorderID+','+
                        TransportationFromRackToRack.TypemarketgroupID+','+
                        TransportationFromRackToRack.SourceRackId+')';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  //----������� ����� ��� ������
  CmdText:='select dt.todrinkkindid from drinktransportation dt '+
           'where dt.transportationid='+TransportationID+
           ' and dt.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationFromRackToRack.DestinationDrinkKindId:=InUpDelIBQ.FieldByName('todrinkkindid').AsString;

  //----�����(���������) �� �� �������� �����
  CmdText:='select * from codesclearingdrinkkindtrans('+
           TransportationID+','+TransportationFromRackToRack.DestinationDrinkKindId+','+
           IntToStr(UserInfo.Id)+','+IntToStr(TransportationFromRackToRack.CountBoxTransportation)+')';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;


  //---��������� ����� � �� ��������� ������ � ���� ������----------
  CmdText:='insert into transportation(storageid,tostorageid,present,sqnno,statusid) '+
           'values('+TransportationFromRackToRack.ToStorageId+','+TransportationFromRackToRack.FromStorageId+','+
                    #39+'today'+#39+',(select max(sqnno)+1 from transportation),0)';
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select max(id) trid from transportation tr '+
           'where tr.storageid='+TransportationFromRackToRack.ToStorageId+
           ' and tr.tostorageid='+TransportationFromRackToRack.FromStorageId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationID:=InUpDelIBQ.FieldByName('trid').AsString;
  TransToNotRackStorageBottleCount:=TransToNotRackStorageBottleCount-TransportationFromRackToRack.CountBottleTransportation;

  CmdText:='insert into drinktransportation(transportationid, '+
           'drinkkindid, bottlecount, toboxid, tocapacityid, '+
           'toplanboxid, tocontractorderid, totypemarketgroupid, reserverackid) '+
           ' values ( '+TransportationID+','+TransportationFromRackToRack.DestinationDrinkKindId+','+
                        IntToStr(TransToNotRackStorageBottleCount)+',2,'+TransportationFromRackToRack.CapacityID+',2,'+
                        TransportationFromRackToRack.ContractorderID+','+
                        TransportationFromRackToRack.TypemarketgroupID+','+
                        TransportationFromRackToRack.DestinationRackId+')';

  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  CmdText:='select dt.id,dt.todrinkkindid from drinktransportation dt '+
           'where dt.transportationid='+TransportationID+
           ' and dt.drinkkindid='+TransportationFromRackToRack.DestinationDrinkKindId;
  InUpDelIBQ.Close;
  InUpDelIBQ.SQL.Clear;
  InUpDelIBQ.SQL.Add(CmdText);
  InUpDelIBQ.Open;

  TransportationFromRackToRack.DestinationDrinkKindId:=InUpDelIBQ.FieldByName('todrinkkindid').AsString;
  DrinkTransportationID:=InUpDelIBQ.FieldByName('id').AsString;

  CmdText:='select codesid from AddCodesOnTransportation('+TransportationFromRackToRack.DestinationDrinkKindId+','
           +IntToStr(TransToNotRackStorageBottleCount)+',1,(select r.id from storage st '+
                                                            'join rack r on r.storageid=st.id '+
                                                            'join racktype rt on rt.id=r.racktypeid '+
                                                            'where st.id= '+TransportationFromRackToRack.FromStorageId+
                                                            ' and rt.onedrink=0 and rt.salepriority>0),'+
                DrinkTransportationID+',22,'+IntToStr(UserInfo.Id)+')';
  try
   if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
    begin
     if Error then
      begin
       DrawError(ErrorMessage+' ��� ����������� ������� Ok');
       if Assigned(PrintCodes) then
        begin
         Dispose(PrintCodes);
         PrintCodes:=nil;
        end;
       exit;
      end
     else
      if Assigned(PrintCodes) then
       begin
        Dispose(PrintCodes);
        PrintCodes:=nil;
       end;
    end
   else
    begin
     i:=0;
     DrinkKindId:=Copy(InputLineStr, 1, 7-Length('')) + '';
     RackId:=Copy(InputLineStr, 1, 5-Length(''))+'';
     if Assigned(PrintCodes) then
      begin
       Dispose(PrintCodes);
       PrintCodes:=nil;
      end;
     DrawError('���������� '+IntToStr(TransToNotRackStorageBottleCount)+'��. � ����-������');
     PrintCodes:=New(PPrintCodes);

     SetLength(PrintCodes.Codes,Trunc(TransToNotRackStorageBottleCount));
     InUpDelIBQ.First;
     while (not InUpDelIBQ.Eof) or (i < TransToNotRackStorageBottleCount) do
      begin
       PrintCodes.Codes[i]:='2'+ Copy(InputLineStr, 1, 8-Length(InUpDelIBQ.FieldByName('CodesId').AsString))+
                            InUpDelIBQ.FieldByName('CodesId').AsString + DrinkKindId + RackId;
       InUpDelIBQ.Next;
       Inc(i);
      end;
    end;
    //PrintEtiquette(true);
    Result:=true;
   except on E:Exception do
    DrawError('������ �������� ��������. ��� ����������� ������� Ok');
   end;//try}

  InUpDelIBQ.Transaction.Commit;
  result:=true;
 except on E:Exception do
  begin
   InUpDelIBQ.Transaction.RollBack;
   DrawError(Trim(E.Message));
   if Assigned(TransportationFromRackToRack) then
    begin
     Dispose(TransportationFromRackToRack);
     TransportationFromRackToRack:=nil;
    end;
   exit;
  end;//on E:Exception
 end;//try..except
end;

function TransportationFromRackToRackScreen_2:boolean;
var CmdText,RackName:string;
    Error:boolean;
    MesIn:integer;
begin
 Result:=false;
 if (TransportationFromRackToRack.DestinationStorageTypeId<>1) then
  begin
   if ((TransportationFromRackToRack.CountBottleTransportation mod StrToInt(TransportationFromRackToRack.Capacity))=0) then
    begin
     if TransportationFromRackToRackScreen_ToNotRackStorageFullBox then
      Result:=true;
    end
   else
    begin
     if TransportationFromRackToRackScreen_ToNotRackStorageCustom then
      Result:=true;
    end;
  end
 else
  begin
   CmdText:='select (select r.id from rack r where r.id='+TransportationFromRackToRack.DestinationRackId+') rackid, '+
     '(select sum(ch.bottlecount) from cashe ch where ch.rackid='+TransportationFromRackToRack.DestinationRackId+') bottlecount, '+
     '(select sum(ch.bottlereserve) from cashe ch where ch.rackid='+TransportationFromRackToRack.DestinationRackId+') bottlereserve, '+
     '(select min(ch.drinkkindid) from cashe ch '+
     ' join drinkkind dk on dk.id=ch.drinkkindid '+
     ' where ch.rackid='+TransportationFromRackToRack.DestinationRackId+
     '  and dk.drinkid=(select drinkid from drinkkind where id='+TransportationFromRackToRack.SourceDrinkKindID+') '+
     '  and dk.saleboxid=(select saleboxid from drinkkind where id='+TransportationFromRackToRack.SourceDrinkKindID+')) destinationrackdrinkkindid, '+
     ' st.id storageid,st.name storagename,st.storagetypeid,rt.onedrink '+
     'from rack r '+
     'join racktype rt on rt.id=r.racktypeid '+
     'join storage st on r.storageid=st.id '+
     'where r.id='+TransportationFromRackToRack.DestinationRackId;

   if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
    begin
     if Error then
      DrawError(ErrorMessage+' ��� ����������� ������� Ok')
     else
      DrawError('�������� ��� ������ ����������. ��� ����������� ������� Ok');
     exit;
    end;

   ReadIBQ.First;
   if (ReadIBQ.FieldByName('bottlecount').IsNull) or
      (ReadIBQ.FieldByName('onedrink').AsInteger=0) or
      (TransportationFromRackToRack.SourceDrinkKindId=ReadIBQ.FieldByName('destinationrackdrinkkindid').AsString) then
     //���� � ������ ���������� ��� ������� ��� ������ ����� ������� ��������� �������
    begin
     CmdText:='select * from getfreerack('+TransportationFromRackToRack.SourceDrinkKindID+',0,'+
                                           TransportationFromRackToRack.ToStorageId+')'+
              'where id='+TransportationFromRackToRack.DestinationRackId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('������ ���������� ������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;
     //�������� �� ��������� ������ ����������

     if TransportationFromRackToRack.TransportationFullRack then
      begin
       if TransportationFromRackToRackScreen_full then
        Result:=true;
      end //���� �� ���������� ���� ����� � ������
     else
      begin
       DrawText('"�������� �����������" '+
                '"�� ������ � ������" '+
                '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                '"'+TransportationFromRackToRack.DrinkName+'" '+
                '"����������: '+IntToStr(TransportationFromRackToRack.CountBoxTransportation)+'��." '+
                '"�������: '+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                '"���������� ��������"');
       if TransportationFromRackToRackScreen_custom then
        Result:=true;
      end;
    end //���� � ������ ���������� ��� ������� ��� ������ ����� ������� ��������� �������
   else
    begin
     if (ReadIBQ.FieldByName('destinationrackdrinkkindid').IsNull) or
        (ReadIBQ.FieldByName('bottlereserve').AsInteger<>0) then
      //���� �� �������� ������ ��� ����������� ��� � ������ ���������� ������
      begin
       DrawError('������ ���������� ������. ��� ����������� ������� Ok');
       exit;
      end;

     if not TransportationFromRackToRack.TransportationFullRack then
      begin
       DrawError('� �������� ������ ������. ��� ����������� ������� Ok');
       exit;
      end
     else
      if TransportationFromRackToRackScreen_Full_WithNewDrinkKindId then
       Result:=true;
    end;

   if Result and (StrToInt(TransportationFromRackToRack.ToStorageId)=50) then
    begin
     CmdText:=
      'select first 1 co.id codesid,co.rackid,co.drinkkindid '+
      'from codes co '+
      'where co.rackid='+TransportationFromRackToRack.DestinationRackId+
      ' and co.outdrinkrackid is null';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('������ ��� ������ ��������. ��� ����������� ������� Ok');
      end
     else
      begin
       PrintCodes:=New(PPrintCodes);
       SetLength(PrintCodes.Codes,ReadIBQ.RecordCount);
       ReadIBQ.First;
       PrintCodes.Codes[0]:=
        '2'+Copy(InputLineStr,1,8-Length(ReadIBQ.FieldByName('codesid').AsString))+ReadIBQ.FieldByName('codesid').AsString
           +Copy(InputLineStr,1,7-Length(ReadIBQ.FieldByName('drinkkindid').AsString))+ReadIBQ.FieldByName('drinkkindid').AsString
           +Copy(InputLineStr,1,5-Length(ReadIBQ.FieldByName('rackid').AsString))+ReadIBQ.FieldByName('rackid').AsString;
       //PrintEtiquette(true);
      end;
    end
  end;
end;

function TransportationFromRackToRackScreen_1:boolean;
var CmdText:string;
    MesIn:integer;
    Error:boolean;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   MesIn:=StrToIntDef(InputLine,0);
   if (InputLine='') or (MesIn<=0) or
   ((MesIn>TransportationFromRackToRack.ExistsBoxTransportation) and
    (TransportationFromRackToRack.DestinationStorageTypeId=1)) or
    ((MesIn>TransportationFromRackToRack.ExistsBottleCount) and
    (TransportationFromRackToRack.DestinationStorageTypeId<>1)) then
    DrawError('�������� ���-�� ���� 0 ��������. ��� ����������� ������� Ok')
   else
    begin
     if (TransportationFromRackToRack.DestinationStorageTypeId<>1) then
      begin
       TransportationFromRackToRack.CountBottleTransportation:=MesIn;
       TransportationFromRackToRack.ExistsBottleCount:=MesIn;
      end
     else
      begin
       TransportationFromRackToRack.CountBoxTransportation:=MesIn;

       if TransportationFromRackToRack.ExistsBoxTransportation=MesIn then
        begin
         CmdText:='select ch.rackid,sum(ch.bottlereserve) bottlereserve '+
                  'from cashe ch '+
                  'join storage st on st.id=ch.storageid '+
                  ' where ch.rackid='+TransportationFromRackToRack.SourceRackId+
                  ' and ch.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindID+
                  ' and st.storagetypeid=1 '+
                  'group by ch.rackid';

         if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
          if Error then
           begin
            DrawError(ErrorMessage+' ��� ����������� ������� Ok');
            exit;
           end;

         if ReadIBQ.FieldByName('bottlereserve').AsInteger=0 then
          TransportationFromRackToRack.TransportationFullRack:=true;
        end;
       TransportationFromRackToRack.ExistsBoxTransportation:=MesIn;
      end;

     if TransportationFromRackToRackScreen_2 then
      Result:=true;
    end;
  end
 else
  begin
   if Assigned(TransportationFromRackToRack) then
    begin
     Dispose(TransportationFromRackToRack);
     TransportationFromRackToRack:=nil;
    end;
   Result:=true;
  end;
end;

procedure TransportationFromRackToRackScreen_0(FromMainMenu:boolean);
var CmdText,TextInfo,RackDestExistsGoods:string;
    CountError:integer;
    Error,flag:boolean;
begin
 CountError:=0;
 while Assigned(TransportationFromRackToRack) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(TransportationFromRackToRack) then
    begin
     DrawText('"�������� �����������" '+
              '"�� ������ � ������" '+
              '"������� ���" '+
              '"������ ���������"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') then
        DrawError('�������� ��� �������� ������. ��� ����������� ������� Ok')
      else
       begin
        TransportationFromRackToRack:=New(PTransportationFromRackToRack);
        TransportationFromRackToRack.SourceRackId:=IntToStr(StrToIntDef(InputLine,0));
        TransportationFromRackToRack.TransportationFullRack:=false;
        TransportationFromRackToRack.NewTransportation:=true;
        if TransportationFromRackToRack.SourceRackId='0' then
         begin //���� ����� �����-���� �� ������
          DrawError('�������� ��� �������� ������. ��� ����������� ������� Ok');
          break;
         end;//if Transportation.Id=0 the
       end;//else if ReadLine(InputLine) then
    end;
   if Assigned(TransportationFromRackToRack) then
    begin
     CmdText:='select r.storageid,r.name rackname,rt.onedrink from rack r '+
            'join racktype rt on rt.id=r.racktypeid '+
            'join storage st on st.id=r.storageid '+
            'where r.id='+TransportationFromRackToRack.SourceRackId+
            ' and st.terminalid in ('+TerminalID+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        break;
       end
      else
       begin
        DrawError('��������� ������ �� �������. ��� ����������� ������� Ok');
        break;
       end;
    end;

   if Assigned(TransportationFromRackToRack) and (ReadIBQ.FieldByName('onedrink').AsInteger=0) then
    begin
     TransportationFromRackToRack.FromStorageId:=ReadIBQ.FieldByName('storageid').AsString;
     TransportationFromRackToRack.SourceRackName:=ReadIBQ.FieldByName('rackname').AsString;

     TextInfo:='"�������� �����������" '+
               '"�� ������ � ������" '+
               '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
               '"��� ������?"';
     DrawText(TextInfo);
     flag:=true;
     TransportationFromRackToRack.SourceDrinkKindId:='';
     while flag and ReadLine(TransportationFromRackToRack.SourceDrinkKindId) do
      begin
       if TransportationFromRackToRack.SourceDrinkKindId='' then
        begin
         DrawError('�������� ��� ������');
         DrawText(TextInfo);
        end
       else
        begin
         if CheckBarcodeOnGoods(TransportationFromRackToRack.SourceDrinkKindId) then
          begin
           CmdText:=
            'select min(ch.drinkkindid) drinkkindid from cashe ch '+
            'where ch.drinkid in (select distinct db.drinkid from drinkbarcode db where db.barcode='+#39+TransportationFromRackToRack.SourceDrinkKindId+#39+') '+
            ' and ch.storageid='+TransportationFromRackToRack.FromStorageId+
            ' and ch.rackid='+TransportationFromRackToRack.SourceRackId;

           if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
            begin
             if Error then
              begin
               DrawError(ErrorMessage+' ��� ����������� ������� Ok');
               break;
              end
            end;

           if ReadIBQ.FieldByName('drinkkindid').IsNull then
            TransportationFromRackToRack.SourceDrinkKindId:='0'
           else
            TransportationFromRackToRack.SourceDrinkKindId:=ReadIBQ.FieldByName('drinkkindid').AsString;
          end;

         CmdText:=
          'select ch.bottlecount,b.capacity,ch.bottlereserve, '+
          ' dk.boxid,dk.capacityid,dk.contractorderid, '+
          ' dk.saleboxid, dk.typemarketgroupid, '+
          ' (ch.bottlecount/cast(b.capacity as double precision)) boxcount, '+
          ' (ch.bottlereserve/cast(b.capacity as double precision)) boxreserve, '+
          ' d.mark drinkname,d.volume,d.id drinkid from cashe ch '+
          'join drinkkind dk on dk.id=ch.drinkkindid '+
          'join drink d on d.id=dk.drinkid '+
          'join box b on b.id=dk.saleboxid '+
          'where ch.storageid='+TransportationFromRackToRack.FromStorageId+
          ' and ch.rackid='+TransportationFromRackToRack.SourceRackId+
          ' and ch.drinkkindid='+TransportationFromRackToRack.SourceDrinkKindId;

         if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
          begin
           if Error then
            begin
             DrawError(ErrorMessage+' ��� ����������� ������� Ok');
             break;
            end
           else
            begin
             DrawError('�������� ��� ������. ��� ����������� ������� Ok');
             DrawText(TextInfo);
            end;
          end
         else
          begin
           flag:=false;
           TransportationFromRackToRack.DrinkID:=ReadIBQ.FieldByName('drinkid').AsInteger;
           TransportationFromRackToRack.DrinkName:=Copy(Trim(ReadIBQ.FieldByName('drinkname').AsString),1,15)+' '+FloatToStr(ReadIBQ.FieldByName('volume').AsFloat);
           TransportationFromRackToRack.ExistsBoxTransportation:=ReadIBQ.FieldByName('boxcount').AsInteger-ReadIBQ.FieldByName('boxreserve').AsInteger;
           TransportationFromRackToRack.ReserveBoxCount:=ReadIBQ.FieldByName('boxreserve').AsInteger;
           TransportationFromRackToRack.ExistsBottleCount:=ReadIBQ.FieldByName('bottlecount').AsInteger-ReadIBQ.FieldByName('bottlereserve').AsInteger;
           TransportationFromRackToRack.ReserveBottleCount:=ReadIBQ.FieldByName('bottlereserve').AsInteger;
           TransportationFromRackToRack.Capacity:=ReadIBQ.FieldByName('capacity').AsString;

           TransportationFromRackToRack.boxid:=ReadIBQ.FieldByName('boxid').AsString;
           TransportationFromRackToRack.capacityid:=ReadIBQ.FieldByName('capacityid').AsString;
           TransportationFromRackToRack.contractorderid:=ReadIBQ.FieldByName('contractorderid').AsString;
           TransportationFromRackToRack.saleboxid:=ReadIBQ.FieldByName('saleboxid').AsString;
           TransportationFromRackToRack.typemarketgroupid:=ReadIBQ.FieldByName('typemarketgroupid').AsString;

           CmdText:='select gfr.* from getfreerack('+TransportationFromRackToRack.SourceDrinkKindID+',0,'+
                                             TransportationFromRackToRack.FromStorageId+') gfr '+
                    'join drinkkind dk on dk.id=gfr.outdrinkkindid '+
                    'where dk.drinkid='+IntToStr(TransportationFromRackToRack.DrinkID);

           if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
            begin
             if Error then
              begin
               DrawError(ErrorMessage+' ��� ����������� ������� Ok');
               break;
              end
             else
              begin
               DrawError('�������� ��� ������ ����������. ��� ����������� ������� Ok');
               DrawText(TextInfo);
              end;
             end;

           if ReadIBQ.FieldByName('boxcapacity').AsInteger>0 then
            RackDestExistsGoods:='� ������ � �������'
           else
            RackDestExistsGoods:='� ������ ������';

           TextInfo:='"�������� �����������" '+
                 '"�� ������ � ������" '+
                 '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                 '"'+TransportationFromRackToRack.DrinkName+'" '+
                 '"����: '+TransportationFromRackToRack.Capacity+'" '+
                 '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                 '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBoxCount)+'��." '+
                 '"'+RackDestExistsGoods+'" '+
                 '"��. ����.'+ReadIBQ.FieldByName('name').AsString+'?"';
           DrawText(TextInfo);
           flag:=true;
           TransportationFromRackToRack.DestinationRackId:=ReadIBQ.FieldByName('id').AsString;
           while flag and ReadLine(TransportationFromRackToRack.DestinationRackId) do
            begin
             if TransportationFromRackToRack.DestinationRackId='' then
              begin
               DrawError('�������� ��� ������');
               DrawText(TextInfo);
              end
             else
              begin
               CmdText:='select st.id storageid,st.name storagename,st.storagetypeid,rt.onedrink,r.name rackname '+
                'from rack r '+
                'join storage st on r.storageid=st.id '+
                'join racktype rt on rt.id=r.racktypeid '+
                'where r.id='+TransportationFromRackToRack.DestinationRackId+
                ' and st.terminalid in ('+TerminalID+')';

               if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
                begin
                 if Error then
                  begin
                   DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                   break;
                  end
                 else
                  begin
                   DrawError('�������� ��� ������ ����������. ��� ����������� ������� Ok');
                   DrawText(TextInfo);
                  end;
                end;

               if ReadIBQ.RecordCount>0 then
                begin
                 TransportationFromRackToRack.DestinationRackName:=ReadIBQ.FieldByName('rackname').AsString;
                 TransportationFromRackToRack.DestinationStorageTypeId:=ReadIBQ.FieldByName('storagetypeid').AsInteger;
                 TransportationFromRackToRack.DestinationRackOneDrink:=ReadIBQ.FieldByName('onedrink').AsInteger;
                 TransportationFromRackToRack.ToStorageId:=ReadIBQ.FieldByName('storageid').AsString;
                 if ReadIBQ.FieldByName('storagetypeid').AsInteger<>1 then
                  begin
                   flag:=false;
                   DrawText('"�������� �����������" '+
                            '"�� ������ � ������" '+
                            '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                            '"'+TransportationFromRackToRack.DrinkName+'" '+
                            '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBottlecount)+'��." '+
                            '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBottleCount)+'��." '+
                            '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                            '"�������. ���-�� ��.?"');
                  end
                 else
                  begin
                   CmdText:='select * from getfreerack('+TransportationFromRackToRack.SourceDrinkKindID+',0,'+
                                             TransportationFromRackToRack.ToStorageId+')'+
                          'where id='+TransportationFromRackToRack.DestinationRackId;

                   if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
                    begin
                     if Error then
                      begin
                       DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                       break;
                      end
                     else
                      begin
                       DrawError('�������� ��� ������');
                       DrawText(TextInfo);
                      end;
                    end
                   else
                    begin
                     flag:=false;
                     TransportationFromRackToRack.DestinationRackName:=ReadIBQ.FieldByName('name').AsString;
                     DrawText('"�������� �����������" '+
                              '"�� ������ � ������" '+
                              '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                              '"'+TransportationFromRackToRack.DrinkName+'" '+
                              '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                              '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBoxCount)+'��." '+
                              '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                              '"�������. ���-�� ��.?"');
                    end;
                  end;
                end;
              end;
            end;
           if flag then
            break;
          end;
        end;
      end;
     if flag then
      break;

     if not TransportationFromRackToRackScreen_1 then
      Inc(CountError)
     else
      CountError:=0;
    end
   else
   if Assigned(TransportationFromRackToRack) then
    begin
     CmdText:='select t.storageid,t.tostorageid,dt.id drinktransportationid, '+
              '       dk.id drinkkindid,d.factory,d.mark drinkname,d.volume, '+
              '       r.name rackname,dt.drinkrackcount,dt.drinkrackcountout,bx.capacity '+
              'from transportation t '+
              'join drinktransportation dt on dt.transportationid=t.id '+
              'join drinkkind dk on dk.id=dt.drinkkindid '+
              'join drink d on d.id=dk.drinkid '+
              'join rack r on r.id=dt.reserverackid '+
              'join box bx on bx.id=dk.saleboxid '+
              'join storage st on st.id=t.storageid '+
              'join storage tst on tst.id=t.tostorageid '+
              'where st.storagetypeid=1 and st.storagetypeid=tst.storagetypeid and r.id='+TransportationFromRackToRack.SourceRackId+
              ' and dt.drinkkindid=dt.todrinkkindid '+
              ' and dt.bottlecount>0 '+
              ' and (dt.drinkrackcount>dt.drinkrackcountout or dt.drinkrackcountout is null) '+
              'PLAN JOIN (R INDEX (RDB$PRIMARY164),DT INDEX (DRINKTRANSPORTATION_IDX1), '+
              ' T INDEX (RDB$PRIMARY195),ST INDEX (RDB$PRIMARY48),TST INDEX (RDB$PRIMARY48), '+
              ' DK INDEX (RDB$PRIMARY103),BX INDEX (RDB$PRIMARY3),D INDEX (RDB$PRIMARY85))';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        break;
       end;

     if ReadIBQ.RecordCount>0 then //���������� ����������
      begin
       if ReadIBQ.FieldByName('drinkrackcount').IsNull then
        begin
         DrawError('������ ���������� � ������� �� �����������.'+' ��� ����������� ������� Ok');
         break;
        end;

       TransportationFromRackToRack.FromStorageId:=ReadIBQ.FieldByName('storageid').AsString;
       TransportationFromRackToRack.ToStorageId:=ReadIBQ.FieldByName('tostorageid').AsString;
       TransportationFromRackToRack.CountBoxTransportation:=Round(ReadIBQ.FieldByName('drinkrackcount').AsInteger/ReadIBQ.FieldByName('capacity').AsInteger);
       TransportationFromRackToRack.ExistsBoxTransportation:=Round((ReadIBQ.FieldByName('drinkrackcount').AsInteger-ReadIBQ.FieldByName('drinkrackcountout').AsInteger)/ReadIBQ.FieldByName('capacity').AsInteger);
       TransportationFromRackToRack.SourceDrinkKindID:=ReadIBQ.FieldByName('drinkkindid').AsString;
       TransportationFromRackToRack.DrinkName:=Copy(Trim(ReadIBQ.FieldByName('drinkname').AsString),1,15)+' '+FloatToStr(ReadIBQ.FieldByName('volume').AsFloat);
       TransportationFromRackToRack.SourceRackName:=ReadIBQ.FieldByName('rackname').AsString;
       CmdText:='select r.id rackid, r.name rackname from drinkrack dr '+
                'join rack r on r.id=dr.rackid '+
                'where dr.racktablesid=22 '+
                ' and dr.racktableid='+ReadIBQ.FieldByName('drinktransportationid').AsString+
                ' and dr.drinkkindid='+ReadIBQ.FieldByName('drinkkindid').AsString;
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('������ ���������� � ������� �� ����������� ����� ��������.'+' ��� ����������� ������� Ok');
         break;
        end;

       TransportationFromRackToRack.DestinationRackId:=ReadIBQ.FieldByName('rackid').AsString;
       TransportationFromRackToRack.DestinationRackName:=ReadIBQ.FieldByName('rackname').AsString;
       DrawText('"�������� �����������" '+
                '"�� ������ � ������" '+
                '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                '"'+TransportationFromRackToRack.DrinkName+'" '+
                '"����������: '+IntToStr(TransportationFromRackToRack.CountBoxTransportation)+'��." '+
                '"�������: '+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                '"���������� ��������"');
       if not TransportationFromRackToRackScreen_custom then
        Inc(CountError)
       else
        CountError:=0;
      end
     else  //����� �����������
      begin
       if not TransportationFromRackToRack.NewTransportation then
        begin
         DrawError('"����� �� '+TransportationFromRackToRack.SourceRackName+'" '+
                   '"� ���������� '+IntToStr(TransportationFromRackToRack.CountBoxTransportation)+'��." '+
                   '"��������� ���������." '+
                   '"��� �����������" '+
                   '"������� Ok');
         break;
        end;
       CmdText:='select * from terminal_transfromracktorack_i('+TransportationFromRackToRack.SourceRackId+')'+
                'where terminalid in ('+TerminalID+')';

       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          if TransportationFromRackToRack.NewTransportation then
           DrawError('� ��������� ������ ����� ��� ����������� �����������. ��� ����������� ������� Ok');
         break;
        end;
       ReadIBQ.First;

       TransportationFromRackToRack.SourceDrinkKindID:=ReadIBQ.FieldByName('drinkkindid').AsString;
       TransportationFromRackToRack.FromStorageId:=ReadIBQ.FieldByName('storageid').AsString;
       TransportationFromRackToRack.ToStorageId:=ReadIBQ.FieldByName('storageid').AsString;
       TransportationFromRackToRack.ExistsBoxTransportation:=ReadIBQ.FieldByName('boxcount').AsInteger-ReadIBQ.FieldByName('boxreserve').AsInteger;
       TransportationFromRackToRack.ReserveBoxCount:=ReadIBQ.FieldByName('boxreserve').AsInteger;
       TransportationFromRackToRack.SourceRackName:=ReadIBQ.FieldByName('rackname').AsString;
       TransportationFromRackToRack.ExistsBottleCount:=ReadIBQ.FieldByName('bottlecount').AsInteger-ReadIBQ.FieldByName('bottlereserve').AsInteger;
       TransportationFromRackToRack.ReserveBottleCount:=ReadIBQ.FieldByName('bottlereserve').AsInteger;

       TransportationFromRackToRack.boxid:=ReadIBQ.FieldByName('boxid').AsString;
       TransportationFromRackToRack.capacityid:=ReadIBQ.FieldByName('capacityid').AsString;
       TransportationFromRackToRack.contractorderid:=ReadIBQ.FieldByName('contractorderid').AsString;
       TransportationFromRackToRack.saleboxid:=ReadIBQ.FieldByName('saleboxid').AsString;
       TransportationFromRackToRack.typemarketgroupid:=ReadIBQ.FieldByName('typemarketgroupid').AsString;
       TransportationFromRackToRack.Capacity:=ReadIBQ.FieldByName('capacity').AsString;

       TransportationFromRackToRack.DrinkName:=Copy(Trim(ReadIBQ.FieldByName('drinkname').AsString),1,15)+' '+FloatToStr(ReadIBQ.FieldByName('volume').AsFloat);

       if TransportationFromRackToRack.ExistsBoxTransportation>0 then
        begin
         TextInfo:='"�������� �����������" '+
                 '"�� ������ � ������" '+
                 '"���. ��'+TransportationFromRackToRack.SourceRackName+'" '+
                 '"'+TransportationFromRackToRack.DrinkName+'" '+
                 '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                 '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBoxCount)+'��." '+
                 '"������ ����������?"';
         DrawText(TextInfo);
         flag:=true;
         TransportationFromRackToRack.DestinationRackId:='';
         while flag and ReadLine(TransportationFromRackToRack.DestinationRackId) do
          begin
           if TransportationFromRackToRack.DestinationRackId='' then
            begin
             DrawError('�������� ��� ������');
             DrawText(TextInfo);
            end
           else
            begin
             CmdText:='select st.id storageid,st.name storagename,st.storagetypeid,rt.onedrink,r.name rackname '+
              'from rack r '+
              'join storage st on r.storageid=st.id '+
              'join racktype rt on rt.id=r.racktypeid '+
              'where r.id='+TransportationFromRackToRack.DestinationRackId+
              ' and st.terminalid in ('+TerminalID+')';

             if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
              begin
               if Error then
                begin
                 DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                 break;
                end
               else
                begin
                 DrawError('�������� ��� ������ ����������. ��� ����������� ������� Ok');
                 DrawText(TextInfo);
                end;
              end;
             if ReadIBQ.RecordCount>0 then
              begin
               TransportationFromRackToRack.DestinationRackName:=ReadIBQ.FieldByName('rackname').AsString;
               TransportationFromRackToRack.DestinationStorageTypeId:=ReadIBQ.FieldByName('storagetypeid').AsInteger;
               TransportationFromRackToRack.DestinationRackOneDrink:=ReadIBQ.FieldByName('onedrink').AsInteger;
               TransportationFromRackToRack.ToStorageId:=ReadIBQ.FieldByName('storageid').AsString;
               if ReadIBQ.FieldByName('storagetypeid').AsInteger<>1 then
                begin
                 flag:=false;
                 DrawText('"�������� �����������" '+
                        '"�� ������ � ������" '+
                        '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                        '"'+TransportationFromRackToRack.DrinkName+'" '+
                        '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBottlecount)+'��." '+
                        '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBottleCount)+'��." '+
                        '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                        '"�������. ���-�� ��.?"');
                end
               else
                begin
                 CmdText:='select * from getfreerack('+TransportationFromRackToRack.SourceDrinkKindID+',0,'+
                                             TransportationFromRackToRack.ToStorageId+')'+
                          'where id='+TransportationFromRackToRack.DestinationRackId;

                 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
                  begin
                   if Error then
                    begin
                     DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                     break;
                    end
                   else
                    begin
                     DrawError('�������� ��� ������');
                     DrawText(TextInfo);
                    end;
                  end
                 else
                  begin
                   flag:=false;
                   TransportationFromRackToRack.DestinationRackName:=ReadIBQ.FieldByName('name').AsString;
                   DrawText('"�������� �����������" '+
                    '"�� ������ � ������" '+
                    '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                    '"'+TransportationFromRackToRack.DrinkName+'" '+
                    '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                    '"������ � ��.:'+IntToStr(TransportationFromRackToRack.ReserveBoxCount)+'��." '+
                    '"�����. �� '+TransportationFromRackToRack.DestinationRackName+'" '+
                    '"�������. ���-�� ��.?"');
                  end;
                end;
              end;
            end;
          end;
         if flag then
          break;
        end
       else
        begin
         DrawError('"�������� �����������" '+
                   '"�� ������ � ������" '+
                   '"���. �� '+TransportationFromRackToRack.SourceRackName+'" '+
                   '"'+TransportationFromRackToRack.DrinkName+'" '+
                   '"������� � ��.:'+IntToStr(TransportationFromRackToRack.ExistsBoxTransportation)+'��." '+
                   '"������ � ��.:'+ReadIBQ.FieldByName('bottlereserve').AsString+'��." '+
                   '"��� �����������" '+
                   '"������� Ok');
         break;
        end;
       if not TransportationFromRackToRackScreen_1 then
        Inc(CountError)
       else
        CountError:=0;
      end;
    end;
  end;//while Assigned(Transportation) or FromMainMenu do

 if Assigned(TransportationFromRackToRack) then
  begin
   Dispose(TransportationFromRackToRack);
   TransportationFromRackToRack:=nil;
  end;
end;

function TransportationBetweenRackScreen_1:boolean;
var CmdText,TextInfo: String;
    Error,flag:boolean;
    i:integer;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') then
    DrawError('�������� ��� ��������. ��� ����������� ������� Ok')
   else
    begin
     CmdText:='select * from terminal_transbetweenrack_label('+TransportationBetweenRack.TransportationID+','+#39+InputLine+#39+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� ��� ��������. ��� ����������� ������� Ok');
       exit;
      end;

     ReadIBQ.First;
     TransportationBetweenRack.DrinkTransportationID:=ReadIBQ.FieldByName('drinktransportationid').AsString;
     TransportationBetweenRack.FromRackId:=ReadIBQ.FieldByName('fromrackid').AsString;
     TransportationBetweenRack.FromRackName:=ReadIBQ.FieldByName('fromrackname').AsString;
     TransportationBetweenRack.FromDrinkKindID:=ReadIBQ.FieldByName('fromdrinkkindid').AsString;
     TransportationBetweenRack.ToDrinkKindId:=ReadIBQ.FieldByName('todrinkkindid').AsString;
     TransportationBetweenRack.FromBoxCapacity:=ReadIBQ.FieldByName('fromboxcapacity').AsInteger;
     TransportationBetweenRack.ToBoxCapacity:=ReadIBQ.FieldByName('toboxcapacity').AsInteger;
     TransportationBetweenRack.BottleCount:=ReadIBQ.FieldByName('bottlecount').AsInteger;
     TransportationBetweenRack.DrinkRackCount:=ReadIBQ.FieldByName('drinkrackcount').AsInteger;
     TransportationBetweenRack.DrinkRackCountOut:=ReadIBQ.FieldByName('drinkrackcountout').AsInteger;
     TransportationBetweenRack.DrinkName:=ReadIBQ.FieldByName('drinkname').AsString;
     TransportationBetweenRack.Volume:=ReadIBQ.FieldByName('volume').AsString;
     TransportationBetweenRack.FromBoxCount:=ReadIBQ.FieldByName('fromboxcount').AsInteger;

     {--------------������ ���---------------}
     if (TransportationBetweenRack.DrinkRackCount<TransportationBetweenRack.BottleCount) then
      begin //���� ���������� �� ������ ����������� ������ ��� �� ���������

       //�������� ������������� ���-�� ������ � ������
       TextInfo:=
        '"�������� �����������" '+
        '"� ��������� ������" '+
        '"��������� N'+TransportationBetweenRack.TransportationID+'" '+
        '"�� '+TransportationBetweenRack.Present+'" '+
        '"'+Copy(Trim(TransportationBetweenRack.DrinkName),1,15)+' '+Trim(TransportationBetweenRack.Volume)+'" '+
        '"��:'+TransportationBetweenRack.FromRackName+' ���� '+IntToStr(TransportationBetweenRack.FromBoxCapacity)+'" '+
        '"���������� '+FloatToStr(TransportationBetweenRack.FromBoxCount)+'��." '+
        '"������������ ���-��" '+
        '"��������?"';
       DrawText(TextInfo);
       flag:=true;
       InputLine:='';
       while flag and ReadLine(InputLine) do
        begin
         if InputLine='' then
          begin
           DrawError('�������� ���-�� ��.');
           DrawText(TextInfo);
          end
         else
          if StrToIntDef(InputLine,0)<>TransportationBetweenRack.FromBoxCount then
           begin
            DrawError('�������� ���-�� ��.');
            DrawText(TextInfo);
           end
          else
           flag:=false;
        end; //while flag and ReadLine(InputLine) do

       if flag then
        begin
         if Assigned(TransportationBetweenRack) then
          begin
           Dispose(TransportationBetweenRack);
           TransportationBetweenRack:=nil;
          end;
         Result:=true;
         exit;
        end;
       //����� �������� ������������� ���-�� ������ �� ������

       CmdText:=
        'insert into drinkrack(rackid, racktableid, racktablesid, bottlecount) '+
        'values('+TransportationBetweenRack.FromRackId+','+
                  TransportationBetweenRack.DrinkTransportationID+',2,'+
                  IntToStr(TransportationBetweenRack.BottleCount)+')';
       InUpDelIBT.StartTransaction;
       try
        if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
         begin
          if Error then
           begin
            DrawError(ErrorMessage+' ��� ����������� ������� Ok');
            exit;
           end;
         end;
        InUpDelIBT.Commit;
        Result:=true;
        exit;
       except on E:Exception do
        begin
         if InUpDelIBT.Active then
          InUpDelIBT.Rollback;
         DrawError('������ ������� ���������. ��� ����������� ������� Ok');
        end; //on E:Exception
       end;//try}

      end;//if (TransportationBetweenRack.DrinkRackCount<TransportationBetweenRack.BottleCount) then

     if (TransportationBetweenRack.DrinkRackCountOut<TransportationBetweenRack.BottleCount) then
      begin

       //������ ����������
       TextInfo:=
        '"�������� �����������" '+
        '"�� �������� �����" '+
        '"��������� N'+TransportationBetweenRack.TransportationID+'" '+
        '"�� '+TransportationBetweenRack.Present+'" '+
        '"'+Copy(Trim(TransportationBetweenRack.DrinkName),1,15)+' '+Trim(TransportationBetweenRack.Volume)+'" '+
        '"���������� '+FloatToStr(TransportationBetweenRack.DrinkRackCount/TransportationBetweenRack.ToBoxCapacity)+'��." '+
        '"������ ����������?"';

       DrawText(TextInfo);
       flag:=true;
       TransportationBetweenRack.ToRackId:='';
       while flag and ReadLine(TransportationBetweenRack.ToRackId) do
        begin
         if TransportationBetweenRack.ToRackId='' then
          begin
           DrawError('�������� ������ ����������');
           DrawText(TextInfo);
          end
         else
          begin
           CmdText:='select * from terminal_freerack('+TransportationBetweenRack.ToDrinkKindId+',0,'+TransportationBetweenRack.ToStorageId+') '+
                    'where id='+TransportationBetweenRack.ToRackId;
           if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
            begin
             if Error then
              begin
               DrawError(ErrorMessage+' ��� ����������� ������� Ok');
               exit;
              end
             else
              begin
               DrawError('�������� ������ ����������');
               DrawText(TextInfo);
              end;
            end
           else
            begin
             TransportationBetweenRack.ToRackName:=ReadIBQ.FieldByName('name').AsString;
             flag:=false;
            end
          end; //else if InputLine='' then
        end; //while flag and ReadLine(InputLine) do

       if flag then
        begin
         if Assigned(TransportationBetweenRack) then
          begin
           Dispose(TransportationBetweenRack);
           TransportationBetweenRack:=nil;
          end;
         if Assigned(PrintCodes) then
          begin
           Dispose(PrintCodes);
           PrintCodes:=nil;
          end;
         Result:=true;
         exit;
        end;
     //����� ���-�� ������������� ������ �� �����


     //���-�� ������������� ������ �� �����
       TextInfo:=
        '"�������� �����������" '+
        '"�� �������� �����" '+
        '"��������� N'+TransportationBetweenRack.TransportationID+'" '+
        '"�� '+TransportationBetweenRack.Present+'" '+
        '"'+Copy(Trim(TransportationBetweenRack.DrinkName),1,15)+' '+Trim(TransportationBetweenRack.Volume)+'" '+
        '"�����:'+FloatToStr(TransportationBetweenRack.BottleCount/TransportationBetweenRack.ToBoxCapacity)+'��. ���� '+IntToStr(TransportationBetweenRack.ToBoxCapacity)+'" '+
        '"�������:'+FloatToStr((TransportationBetweenRack.BottleCount-TransportationBetweenRack.DrinkRackCountOut)/TransportationBetweenRack.ToBoxCapacity)+'��." '+
        '"��: '+TransportationBetweenRack.ToRackName+'" '+
        '"�������. ���-�� ��.?"';

       DrawText(TextInfo);
       flag:=true;
       InputLine:='';
       while flag and ReadLine(InputLine) do
        begin
         if (InputLine='') or (StrToIntDef(InputLine,0)<=0) then
          begin
           DrawError('�������� ���-��');
           DrawText(TextInfo);
          end
         else
          begin
           CmdText:=
            'select dt.bottlecount from drinktransportation dt '+
            'join drinkkind fdk on fdk.id=dt.drinkkindid '+
            'join box fbx on fbx.id=fdk.saleboxid '+
            'join drinkkind tdk on tdk.id=dt.todrinkkindid '+
            'join box tbx on tbx.id=tdk.saleboxid '+
            'where dt.id='+TransportationBetweenRack.DrinkTransportationID+
            ' and dt.bottlecount-coalesce(dt.drinkrackcountout,0)>='+IntToStr(StrToIntDef(InputLine,0)*TransportationBetweenRack.ToBoxCapacity)+
            ' and mod('+IntToStr(StrToIntDef(InputLine,0)*TransportationBetweenRack.ToBoxCapacity)+',fbx.capacity)=0 '+
            ' and mod('+IntToStr(StrToIntDef(InputLine,0)*TransportationBetweenRack.ToBoxCapacity)+',tbx.capacity)=0';
           if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
            begin
             if Error then
              begin
               DrawError(ErrorMessage+' ��� ����������� ������� Ok');
               exit;
              end
             else
              begin
               DrawError('�������� ���-��');
               DrawText(TextInfo);
              end;
            end
           else
            begin
             CmdText:='select * from terminal_freerack('+TransportationBetweenRack.ToDrinkKindId+',0,'+TransportationBetweenRack.ToStorageId+') '+
                    'where id='+TransportationBetweenRack.ToRackId;
             if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
              begin
               if Error then
                begin
                 DrawError(ErrorMessage+' ��� ����������� ������� Ok');
                 exit;
                end
               else
                begin
                 DrawError('�������� ������ ����������');
                 DrawText(TextInfo);
                end;
              end
             else
              begin
               TransportationBetweenRack.TransBottlecount:=StrToIntDef(InputLine,0)*TransportationBetweenRack.ToBoxCapacity;
               flag:=false;
              end
            end;
          end //else if InputLine='' then
        end; //while flag and ReadLine(InputLine) do

       if flag then
        begin
         if Assigned(TransportationBetweenRack) then
          begin
           Dispose(TransportationBetweenRack);
           TransportationBetweenRack:=nil;
          end;
         if Assigned(PrintCodes) then
          begin
           Dispose(PrintCodes);
           PrintCodes:=nil;
          end;
         Result:=true;
         exit;
        end;
     //����� ���-�� ������������� ������ �� �����



       InUpDelIBT.StartTransaction;
       try
        CmdText:=
         'select * from terminal_transfromracktorackall('+
         TransportationBetweenRack.FromRackId+','+
         TransportationBetweenRack.FromDrinkKindId+','+
         TransportationBetweenRack.ToRackId+','+
         IntToStr(Round(TransportationBetweenRack.TransBottlecount/TransportationBetweenRack.ToBoxCapacity+0.01))+','+
         IntToStr(UserInfo.Id)+','+TransportationBetweenRack.DrinkTransportationID+')';


        if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
         begin
          if Error then
           begin
            DrawError(ErrorMessage+' ��� ����������� ������� Ok');
            exit;
           end;
         end;
        InUpDelIBT.Commit;
        Result:=true;
        exit;
       except on E:Exception do
        begin
         if InUpDelIBT.Active then
          InUpDelIBT.Rollback;
         DrawError('������ ��� ����������. ��� ����������� ������� Ok'+E.Message);
        end;
       end;//try

      end;//if (TransportationBetweenRack.DrinkRackCountOut<TransportationBetweenRack.BottleCount) then

     if (TransportationBetweenRack.DrinkRackCountOut=TransportationBetweenRack.BottleCount) then
      DrawError('������� ������ ���������� ���������. ��� ����������� ������� Ok');
    end;//else if (InputLine='')
  end// if ReadLine(InputLine) then
 else
  begin
   if Assigned(TransportationBetweenRack) then
    begin
     Dispose(TransportationBetweenRack);
     TransportationBetweenRack:=nil;
    end;
   if Assigned(PrintCodes) then
    begin
     Dispose(PrintCodes);
     PrintCodes:=nil;
    end;
   Result:=true;
  end;
end;

procedure TransportationBettwenRackScreen_0(FromMainMenu:boolean);
var CmdText,TextInfo:string;
    CountError:integer;
    Error,flag:boolean;
begin
CountError:=0;
 while Assigned(TransportationBetweenRack) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(TransportationBetweenRack) then
    begin
     DrawText('"�������� �����������" '+
              '"����� ���������" '+
              '"��������" '+
              '"���������� �����-���"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') or (not(CheckBarcodeOnDoc('0'+InputLine,dtTransportationBetween))) then
        DrawError('�������� �����-��� ��� ����������� ����� �������� 1-�� ����. ��� ����������� ������� Ok')
      else
       begin
        TransportationBetweenRack:=New(PTransportationBetweenRack);
        TransportationBetweenRack.TransportationID:=IntToStr(StrToIntDef(Copy(InputLine,4,8),0));
        if TransportationBetweenRack.TransportationID='0' then
         begin //���� ����� �����-���� �� ������
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          break;
         end;//if Transportation.Id=0 the
       end;//else if ReadLine(InputLine) then
    end;//if not Assigned(Transportation) then

   if Assigned(TransportationBetweenRack) then
    begin
     CmdText:='select transportationid, transportationpresent, fromstorageid, tostorageid, '+
              'fromstoragetypeid, tostoragetypeid, '+
              'drinkrackcountbox, drinkrackcountoutbox, allbox, remainingbox '+
              'from terminal_transinfo('+TransportationBetweenRack.TransportationID+') ti '+
              'join storage st on st.id=ti.fromstorageid '+
              'where st.terminalid in ('+TerminalID+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      if Error then
       begin
        DrawError(ErrorMessage+' ��� ����������� ������� Ok');
        break;
       end;
     ReadIBQ.First;

     if ReadIBQ.FieldByName('transportationid').IsNull then
      begin
       DrawError('��������� �� ����������� �� ����������. ��� ����������� ������� Ok');
       break;
      end;

     TransportationBetweenRack.Present:=FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('transportationpresent').AsDateTime);

     if ReadIBQ.FieldByName('remainingbox').AsInteger=0 then
      begin
       DrawError('"��� ������� ��" '+
                 '"��������� N'+TransportationBetweenRack.TransportationID+'" '+
                 '"�� '+TransportationBetweenRack.Present+'" '+
                 '"����������" '+
                 '"��� �����������" '+
                 '"������� Ok"');
       break;
      end;
     TransportationBetweenRack.FromStorageId:=ReadIBQ.FieldByNAme('fromstorageid').AsString;
     TransportationBetweenRack.ToStorageId:=ReadIBQ.FieldByNAme('tostorageid').AsString;
     TransportationBetweenRack.FromStorageTypeId:=ReadIBQ.FieldByNAme('fromstoragetypeid').Value;
     TransportationBetweenRack.ToStorageTypeId:=ReadIBQ.FieldByNAme('tostoragetypeid').Value;

     DrawText('"�������� �����������" '+
              '"����� ���������" '+
              '"��������" '+
              '"��������� N'+TransportationBetweenRack.TransportationID+'" '+
              '"�� '+TransportationBetweenRack.Present+'" '+
              '"�����: '+ReadIBQ.FieldByName('allbox').AsString+'��." '+
              '"�������: '+ReadIBQ.FieldByName('remainingbox').AsString+'��." '+
              '"� ��. ������: '+IntToStr(ReadIBQ.FieldByName('allbox').AsInteger-ReadIBQ.FieldByName('drinkrackcountbox').AsInteger)+'��." '+
              '"�� ��. �����: '+IntToStr(ReadIBQ.FieldByName('allbox').AsInteger-ReadIBQ.FieldByName('drinkrackcountoutbox').AsInteger)+'��." '+
              '"���������� ��������"');
     if not TransportationBetweenRackScreen_1 then
      Inc(CountError)
     else
      CountError:=0;
    end;//if Assigned(Transportation) then
  end;//while Assigned(Transportation) or FromMainMenu do

 if Assigned(TransportationBetweenRack) then
  begin
   Dispose(TransportationBetweenRack);
   TransportationBetweenRack:=nil;
  end;

 if Assigned(PrintCodes) then
  begin
   Dispose(PrintCodes);
   PrintCodes:=nil;
  end;
end;

function ReturnScreenFullSale_1:boolean;
var CmdText,TextInfo,newsqnno,newpresent:string;
    Error:boolean;
begin
 Result:=false;

 CmdText:=
  'select distinct s.sqnno, s.newpresent '+
  'from sale s '+
  'join drinksale ds on s.id = ds.saleid '+
  'join storage st on st.id=ds.storageid '+
  'where s.id='+Return.Id+
  ' and st.terminalid in ('+TerminalId+')'+
  ' and ds.bottlecount-ds.bottlebreak>0';

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    begin
     CmdText:=
      'select s.sqnno,s.newpresent from salefullreturn sf '+
      'join sale s on s.id=sf.newsaleid '+
      'where sf.oldsaleid='+Return.Id;

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      DrawError('�������� �����-���, ��������� �� ������. ��� ����������� ������� Ok')
     else
      DrawError('"�������� ��������'+
                '" "��� ���� ���������'+
                '" "�����:'+ReadIBQ.FieldByName('sqnno').AsString+
                '" "����:'+ReadIBQ.FieldByName('newpresent').AsString+
                '" ��� ����������� ������� ��');

     if Assigned(Return) then
      begin
       Dispose(Return);
       Return:=nil;
      end;
    end;
   exit;
  end;
 ReadIBQ.First;

 Return.SqnNo := ReadIBQ.FieldByName('SQNNO').AsString;
 Return.Present := FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('NewPresent').AsDateTime);

 {----------------------���������� ����������----------------------------------}
 TextInfo:=
  '"�������� �������" '+
  '"�������� ���������" '+
  '"N'+Return.Sqnno+' ��'+Return.Present+'" '+
  '"�� �����" '+
  '"��������������" '+
  '"����������." ';

 if CheckEmployee(TextInfo,Return.Loader,Return.LoaderName) then
  TextInfo:= TextInfo+Return.LoaderName
 else
  begin
   if ((Return.Loader='null')) then
    Result:=true;
   exit;
  end;

 TextInfo:=
  '"�������� �������" '+
  '"�������� ���������" '+
  '"N'+Return.Sqnno+' ��'+Return.Present+'" '+
  '"�� �����" '+
  '"��������������" '+
  '"����������." '+
  '"'+Return.LoaderName+'" '+
  '"�������������?"';


 DrawText(TextInfo);
 InputLine:='';
 if (not ReadLine(InputLine)) then
  exit;

 CmdText:=
  'select tf.newsqnno,tf.newpresent from terminal_return_fullsale('+Return.Id+','+IntToStr(UserInfo.Id)+','+Return.Loader+') tf';
 InUpDelIBT.StartTransaction;
 try
  if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
   begin
    if Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;
   end;
  newsqnno:=InUpDelIBQ.FieldByName('newsqnno').AsString;
  newpresent:=InUpDelIBQ.FieldByName('newpresent').AsString;
  InUpDelIBT.Commit;
  DrawError('"�������� ��������'+
            '" "������ �������'+
            '" "����� ��������'+
            '" "�����:'+newsqnno+
            '" "����:'+newpresent+
            '" ��� ����������� ������� ��');
  Result:=true;
 except on E:Exception do
  begin
   if InUpDelIBT.Active then
    InUpDelIBT.Rollback;
   DrawError(E.Message+' ��� ����������� ������� Ok');
   exit;
  end; //on E:Exception
 end;//try
end;

function ReturnScreen_2:boolean;
var CmdText: String;
    Capacity,BoxCount,BottleCount,i: integer;
    Error: Boolean;
    OldDrinkKindID,NewReturnBoxCapacity,NewReturnBoxID:string;
begin
 Result:=false;
 CmdText:='select dk.id drinkkindid, dr.bottlecount+coalesce(dr.nestedbonus,0) bottlecount, '+
          ' floor((dr.bottlecount+coalesce(dr.nestedbonus,0))/cast(rb.capacity as double precision)+0.01) boxcount, '+
          ' coalesce(dr.returnedoncasheboxcount,0) returnedoncasheboxcount, '+
          ' dr.boxid, rb.capacity '+
          'from drinkreturn dr '+
          'join drinksale ds on dr.DrinkSaleid = ds.Id '+
          'join drinkkind dk on dk.Id = ds.DrinkKindId '+
          'join box sb on sb.id = dk.saleboxid '+
          'join capacity cp on cp.id=dk.capacityid '+
          'join box rb on rb.id = dr.boxid '+
          'where dr.id='+Return.Id;

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok');
   exit;
  end;
 ReadIBQ.First;

 BoxCount:=ReadIBQ.FieldByName('boxcount').AsInteger-
           ReadIBQ.FieldByName('returnedoncasheboxcount').AsInteger;

 OldDrinkKindID:=ReadIBQ.FieldByName('drinkkindid').AsString;
 NewReturnBoxCapacity:=ReadIBQ.FieldByName('capacity').AsString;
 NewReturnBoxID:=ReadIBQ.FieldByName('boxid').AsString;
 CmdText:='select codesid from terminal_return_create(';

 if (BoxCount>0) then
  begin//������� �������
   if (Return.NewDrinkKindID>0) and (Return.NewBoxCapacity>0) then
    CmdText:=CmdText+IntToStr(Return.NewDrinkKindID)+','+
                     IntToStr(BoxCount)+','+
                     IntToStr(Return.NewBoxCapacity)+','+
                     'null,'
   else
    CmdText:=CmdText+OldDrinkKindID+','+
                     IntToStr(BoxCount)+','+
                     NewReturnBoxCapacity+','+
                     NewReturnBoxID+',';

   CmdText:=CmdText+Return.Id+','+
                    '6,'+
                    Return.RackId+','+
                    IntToStr(UserInfo.Id)+','+
                    Return.Loader+')';

   InUpDelIBT.StartTransaction;
   try
    if Assigned(PrintCodes) then
     begin
      Dispose(PrintCodes);
      PrintCodes:=nil;
     end;

    if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
     begin
      if Error then
       DrawError(ErrorMessage+' ��� ����������� ������� Ok')
      else
       DrawError('�� ������ ��� ��������� �����. ��� ����������� ������� Ok');
      exit;
     end
    else
     begin
      i:=0;
      PrintCodes:=New(PPrintCodes);
      SetLength(PrintCodes.Codes,Trunc(BoxCount));
      InUpDelIBQ.First;
      while (not InUpDelIBQ.Eof) or (i < BoxCount) do
       begin
        PrintCodes.Codes[i]:='2'+Copy(InputLineStr,1,8-Length(InUpDelIBQ.FieldByName('CodesId').AsString))+InUpDelIBQ.FieldByName('CodesId').AsString
                                +Copy(InputLineStr,1,7-Length(''))+''
                                +Copy(InputLineStr,1,5-Length(''))+'';
        InUpDelIBQ.Next;
        Inc(i);
       end;
     end;
    InUpDelIBT.Commit;
    //PrintEtiquette(true);
    Result:=true;
   except on E:Exception do
    begin
     if InUpDelIBT.Active then
      InUpDelIBT.Rollback;
     DrawError('������ �������� ��������. ��� ����������� ������� Ok');
    end;
   end;
  end;//if (BoxCount>0) then
end;


function ReturnScreen_1:boolean;
var CmdText,TextInfo,StorageName,DrinkSaleId:string;
    BoxCount, BottleCount: string;
    Error,flag:boolean;
    Flags: TReplaceFlags;
    NewDrinkKindId:integer;
begin
 Result:=false;
 CmdText:=
  'select s.sqnno, s.newpresent, ds.storageid, ds.id drinksaleid, ds.drinkkindid, '+
  ' dr.bottlecount+coalesce(dr.nestedbonus,0) bottlecount, '+
  ' floor(((dr.bottlecount+coalesce(dr.nestedbonus,0))/cast(b.capacity as double precision))*100+0.01)/100 drboxcount, '+
  ' dr.returnedoncasheboxcount, dr.tostorageid, dk.saleboxid, dr.boxid, '+
  ' dk.drinkid, dk.boxid buyboxid, dk.bottleid, dk.contractorderid, '+
  ' dk.partycertificateid, dk.capacityid, dk.typemarketgroupid,rb.capacity drcapacity,'+
  ' dk.terminalid, dk.departmentid '+
  'from drinkreturn dr '+
  'join drinksale ds on dr.drinksaleid = ds.id '+
  'join sale s on s.id = ds.saleid '+
  'join drinkkind dk on dk.id = ds.drinkkindid '+
  'join box b on b.id = dk.saleboxid '+
  'join box rb on rb.id=dr.boxid '+
  'join storage st on st.id=dr.tostorageid '+
  'where dr.id =  ' + Return.Id+
  ' and st.terminalid in ('+TerminalID+')';
 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    DrawError('�������� �����-���, ������� �� ������. ��� ����������� ������� Ok');

  if Assigned(Return) then
   begin
    Dispose(Return);
    Return:=nil;
   end;
  end;
 ReadIBQ.First;

 if ReadIBQ.FieldByName('ReturnedOnCasheBoxCount').AsFloat>=ReadIBQ.FieldByName('DRBoxCount').AsFloat then
  begin
   DrawError('���������� ��������� N'+Return.Id+' ���������� ���������. ��� ����������� ������� Ok');

   if Assigned(Return) then
    begin
     Dispose(Return);
     Return:=nil;
    end;
  end;

 if ReadIBQ.FieldByName('ToStorageId').IsNull then
  Return.StorageId := ReadIBQ.FieldByName('StorageId').AsString
 else
  Return.StorageId := ReadIBQ.FieldByName('ToStorageId').AsString;

 Return.SqnNo := ReadIBQ.FieldByName('SQNNO').AsString;
 Return.Present := FormatDateTime('dd.mm.yyyy',ReadIBQ.FieldByName('NewPresent').AsDateTime);
 BottleCount := ReadIBQ.FieldByName('BottleCount').AsString;
 BoxCount := ReadIBQ.FieldByName('DRBoxCount').AsString;
 DrinkSaleID:= ReadIBQ.FieldByName('drinksaleid').AsString;

 {--------------------------���������� � ���� ������------------------------}
 CmdText:=
  'select max(dk.id) dkid from drinkkind dk '+
  'join box sb on sb.id=dk.saleboxid '+
  'where dk.drinkid='+ReadIBQ.FieldByName('drinkid').AsString+
  ' and dk.bottleid='+ReadIBQ.FieldByName('bottleid').AsString+
  ' and dk.contractorderid='+ReadIBQ.FieldByName('contractorderid').AsString+
  ' and dk.partycertificateid='+ReadIBQ.FieldByName('partycertificateid').AsString+
  ' and dk.capacityid='+ReadIBQ.FieldByName('capacityid').AsString+
  ' and dk.typemarketgroupid='+ReadIBQ.FieldByName('typemarketgroupid').AsString+
  ' and dk.saleboxid='+ReadIBQ.FieldByName('boxid').AsString+
  ' and dk.terminalid='+ReadIBQ.FieldByName('terminalid').AsString+
  ' and dk.departmentid='+ReadIBQ.FieldByName('departmentid').AsString;

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  NewDrinkKindId:=0
 else
  NewDrinkKindId:=ReadIBQ.FieldByName('dkid').AsInteger;
 {------------------------------------------------------------------------------}

 CmdText:=
  'select name from storage where id='+Return.StorageId+' and storagetypeid=1';

 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    DrawError('������ ������� �� �� ����� 1-�� ����. ��� ����������� ������� Ok');
   exit;
  end;

  StorageName:=ReadIBQ.FieldByName('name').AsString;
  if pos('�',StorageName)>0 then
   begin
    Flags:= [rfReplaceAll, rfIgnoreCase];
    StorageName:=StringReplace(StorageName, '�', 'N', Flags);
   end;

 {----------------------���������� ����������----------------------------------}
 TextInfo:='"�������� ��������" '+
           '"�� ��������� N'+Return.Sqnno+'" '+
           '"�� '+Return.Present+'" '+
           '"�����: '+StorageName+'" ';

 if CheckEmployee(TextInfo,Return.Loader,Return.LoaderName) then
  TextInfo:= TextInfo+Return.LoaderName
 else
  begin
   if ((Return.Loader='null')) then
    Result:=true;
   exit;
  end;

 {----------------------���������� �����---------------------------------------}
 TextInfo:='"�������� ��������" '+
           '"�� ��������� N'+Return.Sqnno+'" '+
           '"�� '+Return.Present+'" '+
           '"�����: '+StorageName+'" '+
           '"���������� �����-���" '+
           '"������"';
 DrawText(TextInfo);
 flag:=true;
 InputLine:='';
 while flag and ReadLine(InputLine) do
  begin
   if InputLine='' then
    begin
     DrawError('�������� �����-���');
     DrawText(TextInfo);
    end
   else
    begin
     CmdText:=
      'select dr.returnedboxcount from drinkreturn dr '+
      'join drinksale ds on ds.id=dr.drinksaleid '+
      'join drink d on d.id=ds.drinkid '+
      'join drinkbarcode db on db.drinkid=d.id '+
      'where db.barcode='+#39+InputLine+#39+
      ' and ds.id='+DrinkSaleID;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� �����-���');
       DrawText(TextInfo);
      end
     else
      flag:=false
    end;
  end;

 if flag then
  begin
   Result:=true;
   exit;
  end;

 {----------------------���������� ������---------------------------------------}
 CmdText:=
  'select id,name,outdrinkkindid,boxcapacity '+
  'from getfreerack('+IntToStr(NewDrinkKindId)+',1,'+Return.StorageId+')';
 if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
  begin
   if Error then
    DrawError(ErrorMessage+' ��� ����������� ������� Ok')
   else
    DrawError('��� ��������� ������. ��� ����������� ������� Ok');
   exit;
  end;

 Return.RackId:=ReadIBQ.FieldByName('id').AsString;
 Return.NewDrinkKindID:=ReadIBQ.FieldByName('outdrinkkindid').AsInteger;
 Return.NewBoxCapacity:=ReadIBQ.FieldByName('boxcapacity').AsInteger;
 {------------------------------------------------------------------------------}

 if Return.NewDrinkKindID=0 then
  TextInfo:='"�������� ��������" '+
            '"�� ��������� N'+Return.Sqnno+'" '+
            '"�� '+Return.Present+'" '+
            '"� ��������� ������" '+
            '"�����: '+StorageName+'" '+
            '"��������: '+BoxCount+'" '+
            '"����: '+BottleCount+'" '+
            '"������:'+ReadIBQ.FieldByName('name').AsString+'?"'
 else
  TextInfo:='"�������� ��������" '+
            '"�� ��������� N'+Return.Sqnno+'" '+
            '"�� '+Return.Present+'" '+
            '"� ������ � �������" '+
            '"�����: '+StorageName+'" '+
            '"��������: '+BoxCount+'" '+
            '"����: '+BottleCount+'" '+
            '"������:'+ReadIBQ.FieldByName('name').AsString+'?"';
 DrawText(TextInfo);
 flag:=true;
 while flag and ReadLine(Return.RackId) do
  begin
   if Return.RackId='' then
    begin
     DrawError('�������� ��� ������');
     DrawText(TextInfo);
    end
   else
    begin
     CmdText:=
      'select * from getfreerack('+IntToStr(NewDrinkKindId)+',1,'+Return.StorageId+')'+
      'where id='+Return.RackId;
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� ��� ������');
       DrawText(TextInfo);
      end
     else
      flag:=false
    end;
  end;

 if flag then
  begin
   Result:=true;
   exit;
  end;

 if ReturnScreen_2 then
  Result:=true;
end;

procedure ReturnScreen_0(FromMainMenu:boolean);
begin
 while Assigned(Return) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if not Assigned(Return) then
    begin
     DrawText('"�������� ��������" '+
              '"���������� �����-���"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='')
       or ((not (CheckBarcodeOnDoc('0'+InputLine,dtReturn)))
       and (not (CheckDocBarcode(InputLine,dtReturnFullSale)))
       and (not ((Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256))) ) then
       begin
        DrawError('�������� �����-��� ��� �������� �� �����. ��� ����������� ������� Ok');
        FromMainMenu:=true;
       end
      else
       begin
        if (CheckDocBarcode(InputLine,dtReturnFullSale)) then
         begin
          if (StrToIntDef(Copy(InputLine, 3, 14),0)=0) then
           begin
            DrawError('�������� �����-���. ��� ����������� ������� Ok');
            FromMainMenu:=true;
           end;
          Return:=New(PReturn);
          Return.Id := IntToStr(StrToIntDef(Copy(InputLine, 3, 14),0));
          Return.IsFullSale:=true;
         end; //������ �������

        if (Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256) then
         begin
          if (StrToIntDef(Copy(InputLine, 5, 8),0)=0) then
           begin
            DrawError('�������� �����-���. ��� ����������� ������� Ok');
            FromMainMenu:=true;
           end;
          Return:=New(PReturn);
          Return.Id := IntToStr(StrToIntDef(Copy(InputLine, 4, 9),0));
          Return.IsFullSale:=true;
         end; //������ ������� �� EAN13

        if (CheckBarcodeOnDoc('0'+InputLine,dtReturn)) then
         begin
          if (StrToIntDef(Copy(InputLine, 4, 11),0)=0) then
           begin
            DrawError('�������� �����-���. ��� ����������� ������� Ok');
            FromMainMenu:=true;
           end;
          Return:=New(PReturn);
          Return.Id := IntToStr(StrToIntDef(Copy(InputLine, 4, 11),0));
          Return.IsFullSale:=false;
         end; //������� ������� �� ���������� ���������

       end;//else if (InputLine='')
    end; //if not Assigned(Return) then

   if Assigned(Return) then
    begin
     if Return.IsFullSale then
      FromMainMenu:=(not ReturnScreenFullSale_1)
     else
      FromMainMenu:=(not ReturnScreen_1);

     if not FromMainMenu then
      if Assigned(Return) then
       begin
        Dispose(Return);
        Return:=nil;
       end;
    end;
  end; //while Assigned(Return) or FromMainMenu do

 if Assigned(Return) then
  begin
   Dispose(Return);
   Return:=nil;
  end;

 if Assigned(PrintCodes) then
  begin
   Dispose(PrintCodes);
   PrintCodes:=nil;
  end;
end;

function RemovingScreen_FullBox:boolean;
var CmdText: String;
    Error: Boolean;
    CodesId: String;
    RackId,DrinkkindId,AllBottleCount,
    RemBottleCount,Capacity,NewCapacity: Integer;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') or ((not CheckBarcodeOnLabel(InputLine)) and (not CheckDrinkKindInCash(InputLine))) then
    DrawError('�������� �����-���. ��� ����������� ������� Ok')
   else
    begin
     if CheckBarcodeOnLabel(InputLine) then
      begin
       Removing.CodesID:= IntToStr(StrToIntDef(Copy(InputLine,2,8),0));

       if Removing.CodesId='0' then
        begin //���� �����-���� �� ���e�
         DrawError('�������� �����-���! ��� ����������� ������� Ok');
         exit;
        end;

       CmdText:='select Id,DrinkKindId,rackid from Codes '+
                ' where OutDrinkrackId is null and Id='+Removing.CodesId;

       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('�������� ��� ��������. ��� ����������� ������� Ok');
         exit;
        end;
       ReadIBQ.First;

       RackId:=ReadIBQ.FieldByName('rackid').Value;
       DrinkKindID:=ReadIBQ.FieldByName('DrinkKindId').Value;
      end;

     if CheckDrinkKindInCash(InputLine) then
      begin
       Removing.CodesId:='null';
       RackId:=StrToInt(Removing.RackId);
       DrinkKindID:=StrToIntDef(InputLine,0);
      end;

     CmdText:='select min(Drink.Factory||'+#39+' '+#39+'||Drink.Mark||'+#39+' '+#39+'||Drink.Volume) Name, '+
               '       min(Box.Fullname) BoxName, min(Box.Capacity) Capacity, '+
               '       min(Removing.BottleCount / (Box.Capacity+0.0)) BoxCount, '+
               '       min(Removing.BottleCount) BottleCount, min(Removing.DrinkKindId) DrinkKindId, '+
               '       min(Removing.StorageId) StorageId, '+
               '       min(Box.Capacity -mod(Removing.BottleCount, Box.Capacity)) NewBoxCapacity, '+
               '       min(DrinkRAck.RackId) RackId, min(Inventory.make) make, '+
               '       min(removing.isready) isready, count(Codes.id)*min(Box.Capacity) RemovingBottle '+
               '  from Removing '+
               '  join DrinkKind on Removing.DrinkKindId= DrinkKind.Id '+
               '  join Drink on DrinkKind.DrinkId = Drink.Id '+
               '  join Box on DrinkKind.SaleBoxId=Box.Id '+
               '  join DrinkRAck on DrinkRack.RackTableId=Removing.Id and DrinkRAck.RAckTAblesId=11 '+
               '  left join Inventory on Inventory.id=Removing.inventoryid '+
               '  left join codes on Codes.outdrinkrackid=DrinkRAck.id '+
               ' where Removing.Id= ' + Removing.Id +
               '   and DrinkRack.id not in (select indrinkrackid from codes) '+
               ' group by Removing.Id';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� �����-���, �������� �� �������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     if (RackId<>ReadIBQ.FieldByName('RackId').Value) or
        (DrinkKindId<>ReadIBQ.FieldByName('DrinkKindId').Value) then
      begin
       DrawError('���� �� �� ��������� � ��������� ������. ��� ����������� ������� Ok');
       exit;
      end;

     AllBottleCount:=ReadIBQ.FieldByNAme('BottleCount').Value;
     RemBottleCount:=ReadIBQ.FieldByNAme('RemovingBottle').Value;
     Capacity:=ReadIBQ.FieldByNAme('Capacity').Value;
     NewCapacity:=ReadIBQ.FieldByNAme('NewBoxCapacity').Value;

     CmdText:='execute procedure terminal_removingfullbox ('+
               Removing.Id+','+Removing.CodesID+','+IntToStr(RackId)+','+
               IntToStr(DrinkKindId)+','+IntToStr(UserInfo.Id)+')';
     InUpDelIBT.StartTransaction;
     try
      if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         begin
          DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
       end;
      InUpDelIBT.Commit;
      Result:=true;
     except on E:Exception do
      begin
       if InUpDelIBT.Active then
        InUpDelIBT.Rollback;
       DrawError('������ ������� ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try
    end;//else if (InputLine='')
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Removing) then
    begin
     Dispose(Removing);
     Removing:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

function RemovingScreen_NotFullBox:boolean;
var CmdText,TextInfo: String;
    Error,flag: Boolean;
    CodesId: String;
    CodesRackId,CodesDrinkKindId,NewDrinkKindId:integer;
    i: integer;
    DrinkFactory,DrinkName,rembottlecount,RackName,RackId, NewBoxCount:string;
begin
 Result:=false;
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (InputLine='') or (not CheckBarcodeOnLabel(InputLine)) then
    DrawError('�������� �����-���. ��� ����������� ������� Ok')
   else
    begin
     CodesId:= IntToStr(StrToIntDef(Copy(InputLine,2,8),0));

     if CodesId='0' then
      begin //���� �����-���� �� ���e�
       DrawError('�������� �����-���! ��� ����������� ������� Ok');
       exit;
      end;

     CmdText:='select drinkkindid,rackid from codes '+
              ' where outdrinkrackid is null and id='+CodesId;

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� ��� ��������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     CodesRackId:=ReadIBQ.FieldByName('RackId').Value;
     CodesDrinkKindId:=ReadIBQ.FieldByName('DrinkKindId').Value;

     CmdText:='select * from terminal_removingnotfullboxinfo('+removing.id+')';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� �����-���, �������� �� �������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     if (CodesRackId<>ReadIBQ.FieldByName('RackId').Value) or
        (CodesDrinkKindId<>ReadIBQ.FieldByName('DrinkKindId').Value) then
      begin
       DrawError('���� �� �� ��������� � ��������� ������. ��� ����������� ������� Ok');
       exit;
      end;

     DrinkFactory:=ReadIBQ.FieldByName('factory').AsString;
     DrinkName:=Copy(ReadIBQ.FieldByName('mark').AsString,1,15)+' '+ReadIBQ.FieldByName('volume').AsString;
     rembottlecount:=IntToStr(ReadIBQ.FieldByName('rembottlecount').AsInteger);

     if ReadIBQ.FieldByName('newdrinkkindid').IsNull then
      NewDrinkKindId:=0
     else
      NewDrinkKindId:=ReadIBQ.FieldByName('newdrinkkindid').AsInteger;

     {----------------------���������� ������---------------------------------------}
     CmdText:='select id,name from getfreerack('+IntToStr(NewDrinkKindId)+',1,'+removing.storageid+')';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('����������� ��������� ������. ��� ����������� ������� Ok');
       exit;
      end;
     Removing.RackId:=ReadIBQ.FieldByName('id').AsString;
     {------------------------------------------------------------------------------}
     TextInfo:='"�������� ��������'+
               '" "�� ������ ��������'+
               '" "'+DrinkFactory+
               '" "'+DrinkName+
               '" "� ���� 1 - '+rembottlecount+' ��.'+
               '" "������:'+ReadIBQ.FieldByName('name').AsString+'?"';
     DrawText(TextInfo);
     flag:=true;
     RackId:='';
     while flag and ReadLine(Removing.RackId) do
      begin
       if Removing.RackId='' then
        begin
         DrawError('�������� ��� ������');
         DrawText(TextInfo);
        end
       else
        begin
         CmdText:='select * from getfreerack('+IntToStr(NewDrinkKindId)+',1,'+removing.storageid+')'+
                  'where id='+Removing.RackId;
         if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
          begin
           if Error then
            begin
             DrawError(ErrorMessage+' ��� ����������� ������� Ok');
             exit;
            end
           else
            begin
             DrawError('�������� ��� ������');
             DrawText(TextInfo);
            end;
          end
         else
          flag:=false
        end;
      end;

     if not flag then
      begin
       CmdText:=
        'select * from terminal_removingnotfullbox('+
         IntToStr(CodesDrinkKindId)+','+rembottlecount+','+
         Removing.Id+',11,'+Removing.RackId+','+IntToStr(UserInfo.Id)+','+CodesId+')';

       InUpDelIBQ.Transaction.StartTransaction;
       try
        if Assigned(PrintCodes) then
         begin
          Dispose(PrintCodes);
          PrintCodes:=nil;
         end;

        if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
         begin
          if InUpDelIBQ.Transaction.Active then
           InUpDelIBQ.Transaction.Rollback;
          if Error then
           DrawError(ErrorMessage+' ��� ����������� ������� Ok')
          else
           DrawError('�� ������ ��� ��������� �����. ��� ����������� ������� Ok');
          exit;
         end
        else
         begin
          i:=0;
          PrintCodes:=New(PPrintCodes);
          SetLength(PrintCodes.Codes,InUpDelIBQ.RecordCount);
          InUpDelIBQ.First;
          while (not InUpDelIBQ.Eof) or (i < 1) do
           begin
            PrintCodes.Codes[i]:='2'+Copy(InputLineStr,1,8-Length(InUpDelIBQ.FieldByName('CodesId').AsString))+InUpDelIBQ.FieldByName('CodesId').AsString
                                    +Copy(InputLineStr,1,7-Length(''))+''
                                    +Copy(InputLineStr,1,5-Length(''))+'';
            InUpDelIBQ.Next;
            Inc(i);
           end;
         end;

        InUpDelIBQ.Transaction.Commit;
        //if Assigned(PrintCodes) then
         //PrintEtiquette(true);
        Result:=true;
       except on E:Exception do
        begin
         if InUpDelIBQ.Transaction.Active then
          InUpDelIBQ.Transaction.Rollback;
         DrawError('������ ������� ��������. ��� ����������� ������� Ok');
        end; //on E:Exception}
       end;//try}
      end; //if not flag then
    end;//else if (InputLine='')
  end//if ReadLine(InputLine) then
 else
  begin
   if Assigned(Removing) then
    begin
     Dispose(Removing);
     Removing:=nil;
    end;
   Result:=true;
  end;//else if ReadLine(InputLine) then
end;

procedure RemovingScreeen_0(FromMainMenu:boolean);
var CmdText:string;
    CountError:integer;
    Error:boolean;
begin
 CountError:=0;
 while Assigned(Removing) or FromMainMenu do
  begin
   FromMainMenu:=false;

   if CountError>=MaxCountError then
    break;

   if not Assigned(Removing) then
    begin
     DrawText('"�������� ��������" '+
              '"���������� �����-���"');
     InputLine:='';
     if ReadLine(InputLine) then
      if (InputLine='') or (not (CheckBarcodeOnDoc('0'+InputLine,dtRemoving))) then
       DrawError('�������� �����-��� ��� �������� �� ������ 1-��� ����. ��� ����������� ������� Ok')
      else
       begin
        Removing:=New(PRemoving);
        Removing.Id := IntToStr(StrToIntDef(Copy(InputLine, 4, 11),0));
        if (Removing.Id='0') then
         begin
          DrawError('�������� �����-���. ��� ����������� ������� Ok');
          break;
         end;
       end;
    end;

   if Assigned(Removing) then
    begin
     CmdText:='select min(d.factory) factory, min(d.mark) mark, min(d.volume) volume, '+
              '       min(bx.fullname) boxname, min(bx.capacity) capacity, '+
              '       min(r.BottleCount/cast(bx.Capacity as double precision)) BoxCount, '+
              '       min(r.BottleCount) BottleCount, min(r.DrinkKindId) DrinkKindId, '+
              '       min(r.StorageId) StorageId, '+
              '       min(bx.Capacity -mod(r.BottleCount, bx.capacity)) NewBoxCapacity, '+
              '       min(dr.RackId) RackId, min(i.make) make, '+
              '       min(r.isready) isready, count(co.id)*min(bx.capacity) RemovingBottle, '+
              '       min(i.id) InventoryId '+
              'from removing r '+
              'join drinkkind dk on r.drinkkindid=dk.id '+
              'join drink d on dk.drinkid = d.id '+
              'join box bx on dk.saleboxid=bx.id '+
              'join drinkrack dr on dr.racktableid=r.id and dr.racktablesid=11 '+
              'left join inventory i on i.id=r.inventoryid '+
              'left join codes co on co.outdrinkrackid=dr.id '+
              'where r.id='+Removing.Id+
              ' and dr.id not in (select indrinkrackid from codes) '+
              'group by r.id';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� �����-���, �������� �� �������. ��� ����������� ������� Ok');
       break;
      end;
     ReadIBQ.First;

     if ReadIBQ.FieldByName('RemovingBottle').AsInteger >= ReadIBQ.FieldByName('bottlecount').AsInteger then
      begin
       DrawError('"�������� ����������" '+
                 '"��� �����������" '+
                 '"������� Ok"');
       break;
      end;

     Removing.StorageId:=ReadIBQ.FieldByName('StorageId').AsString;
     Removing.DrinkKindId :=ReadIBQ.FieldByNAme('DrinkKindId').AsString;
     Removing.RackId :=ReadIBQ.FieldByNAme('RackId').AsString;


     if (ReadIBQ.FieldByName('BottleCount').AsInteger-ReadIBQ.FieldByName('RemovingBottle').AsInteger) >=
         ReadIBQ.FieldByName('Capacity').AsInteger then
      begin
       DrawText('"�������� ��������" '+
                '"����� ��������" '+
                '"'+ReadIBQ.FieldByName('factory').AsString+'" '+
                '"'+Copy(ReadIBQ.FieldByName('mark').AsString,1,15)+' '+ReadIBQ.FieldByName('volume').AsString+'" '+
                '"�����: '+IntToStr(ReadIBQ.FieldByName('BottleCount').AsInteger)+'��." '+
                '"��������: '+IntToStr(ReadIBQ.FieldByName('BottleCount').Value-ReadIBQ.FieldByName('RemovingBottle').Value)+'��." '+
                '"���������� ��������"');
       if not RemovingScreen_FullBox then
        Inc(CountError)
       else
        CountError:=0;
      end
     else
      begin
       DrawText('"�������� ��������'+
                '" "�� ������ ��������'+
                '" "'+ReadIBQ.FieldByName('factory').AsString+
                '" "'+Copy(ReadIBQ.FieldByName('mark').AsString,1,15)+' '+ReadIBQ.FieldByName('volume').AsString+
                '" "�����: '+IntToStr(ReadIBQ.FieldByName('BottleCount').AsInteger)+'��.'+
                '" "��������: '+IntToStr(ReadIBQ.FieldByName('Capacity').AsInteger-ReadIBQ.FieldByNAme('NewBoxCapacity').AsInteger)+'��.'+
                '" "���������� ��������"');

       if not RemovingScreen_NotFullBox then
        Inc(CountError)
       else
        CountError:=0;
      end;
    end;
  end;

 if Assigned(Removing) then
  begin
   Dispose(Removing);
   Removing:=nil;
  end;
 if Assigned(PrintCodes) then
  begin
   Dispose(PrintCodes);
   PrintCodes:=nil;
  end;
end;

procedure PrintCodesScreen_0(FromMainMenu:boolean);
var CmdText:string;
    Error:boolean;
    DrinkKindId, Rackid, Codesid, Code: string;
begin
 FromMainMenu:=false;
 DrawText('������� ��� ��������');
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (IntToStr(StrToIntDef(InputLine,0)) = '0') then
    DrawError('�������� ��� ��������. ��� ����������� ������� Ok')
   else
    begin
     CmdText:='select c.id codesid,co.rackid,co.drinkkindid '+
              'from cashe ch '+
              'join codes c on c.rackid=ch.rackid and c.drinkkindid=ch.drinkkindid and c.outdrinkrackid is null '+
              'where c.id= '+InputLine+
              ' order by c.id';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� ��� ��� �������� ��� ��������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     DrinkKindId:=Copy(InputLineStr, 1, 7-Length(ReadIBQ.FieldByName('drinkkindid').AsString))+ReadIBQ.FieldByName('drinkkindid').AsString;
     Rackid:=Copy(InputLineStr, 1, 5-Length(ReadIBQ.FieldByName('rackid').AsString))+ReadIBQ.FieldByName('rackid').AsString;
     CodesId:=Copy(InputLineStr, 1, 8-Length(ReadIBQ.FieldByName('CodesId').AsString))+ReadIBQ.FieldByName('CodesId').AsString;
     Code := '2'+ CodesId + DrinkKindId + Rackid;
     try
      if Assigned(PrintCodes) then
       begin
        Dispose(PrintCodes);
        PrintCodes:=nil;
       end;
      PrintCodes:=New(PPrintCodes);
      SetLength(PrintCodes.Codes,1);
      PrintCodes.Codes[0]:=Code;
      //PrintEtiquette(false);
     except on E:Exception do
      begin
       DrawError('������ ��� ������ ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try
    end;
  end;
end;

procedure PrintRackScreen_0(FromMainMenu:boolean);
var CmdText:string;
    Error:boolean;
    DrinkKindId, RackId, CodesId, Code: string;
    i: integer;
begin
 FromMainMenu:=false;
 DrawText('������� ��� ������');
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if (IntToStr(StrToIntDef(InputLine,0)) = '0') then
    DrawError('�������� ��� ������. ��� ����������� ������� Ok')
   else
    begin
     CmdText:=' select c.id codesid , c.drinkkindid, c.rackid'+
              ' from cashe ch '+
              ' join codes c on c.rackid=ch.rackid and c.drinkkindid=ch.drinkkindid and c.outdrinkrackid is null '+
              ' where ch.rackid=' + InputLine+
              ' order by c.id';
     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('�������� ��� ��� ������ ������. ��� ����������� ������� Ok');
       exit;
      end;
     ReadIBQ.First;

     DrinkKindId:=Copy(InputLineStr,1,7-Length(ReadIBQ.FieldByName('drinkkindid').AsString))+ReadIBQ.FieldByName('drinkkindid').AsString;
     RackId:=Copy(InputLineStr,1,5-Length(ReadIBQ.FieldByName('rackid').AsString))+ReadIBQ.FieldByName('rackid').AsString;
     try
      if Assigned(PrintCodes) then
       begin
        Dispose(PrintCodes);
        PrintCodes:=nil;
       end;
      PrintCodes:=New(PPrintCodes);
      SetLength(PrintCodes.Codes,ReadIBQ.RecordCount);
      i:=0;
      while not ReadIBQ.Eof do
       begin
        CodesId := Copy(InputLineStr, 1, 8-Length(ReadIBQ.FieldByName('CodesId').AsString))+ReadIBQ.FieldByName('CodesId').AsString;
        Code := '2'+ CodesId + DrinkKindId + Rackid;
        PrintCodes.Codes[i]:=Code;
        ReadIBQ.Next;
        Inc(i);
       end;
      //PrintEtiquette(false);
     except on E:Exception do
      begin
       DrawError('������ ��� ������ ��������. ��� ����������� ������� Ok');
      end; //on E:Exception
     end;//try
    end;
  end;
end;

procedure SaleInfoScreen_0(FromMainMenu:boolean);
var CmdText:string;
    Error:boolean;
    Str,SaleId: String;
    Single: integer;
    MaxLine:string;
begin
 FromMainMenu:=false;
 DrawText('���������� �����-��� ���������');
 InputLine:='';
 MaxLine:='__________';
 if ReadLine(InputLine) then
  if (InputLine='') or (not(CheckDocBarcode(InputLine,dtSale))) then
     DrawError('�������� �����-���. ��� ����������� ������� Ok')
  else
   begin
    Sale:=New(PSale);
    Sale.StorageId:=IntToStr(StrToIntDef(Copy(InputLine,3,3),0));
    Sale.StorageSectionId:=IntToStr(StrToIntDef(Copy(InputLine,6,3),0));
    Sale.Id:=IntToStr(StrToIntDef(Copy(InputLine,9,8),0));

    if SaleId='0' then
     DrawError('�������� �����-���. ��� ����������� ������� Ok');

    CmdText:='select first 7 * from get_notclearedsale('+Sale.StorageId+','+
                                                  Sale.StorageSectionId+','+
                                                  Sale.Id+')';
    if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
     begin
      if Error then
       DrawError(ErrorMessage+' ��� ����������� ������� Ok')
      else
       DrawError('��� ����� �� ��������� ��������. ��� ����������� ������� Ok');
      if Assigned(Sale) then
       begin
        Dispose(Sale);
        Sale:=nil;
       end;
      exit;
     end;
    ReadIBQ.First;
    while not ReadIBQ.Eof do
     begin
      Str:=Str+' '+ReadIBQ.FieldByName('aDrinkKindId').AsString+Copy(MaxLine,1,6-Length(ReadIBQ.FieldByName('aDrinkKindId').AsString))+'_'+
                   ReadIBQ.FieldByName('aNotClearedBoxCount').AsString+Copy(MaxLine,1,4-Length(ReadIBQ.FieldByName('aNotClearedBoxCount').AsString))+'_'+
                   ReadIBQ.FieldByName('aRack').AsString+Copy(MaxLine,1,7-Length(ReadIBQ.FieldByName('aRack').AsString));
      ReadIBQ.Next;
     end;
    DrawError('���������� �������� '+BuildLine('������_�����_������',LengthStr)+Str+' "��� �����������" "������� Ok"');
    if Assigned(Sale) then
     begin
      Dispose(Sale);
      Sale:=nil;
     end;
   end;
end;

procedure LabelInfoScreen_0(FromMainMenu:boolean);
var CmdText:string;
    Error:boolean;
    Str,SaleId,TempStr: String;
    Single: integer;
    Status:string;
begin
 FromMainMenu:=false;
 DrawText('���������� �����-��� ��������');
 InputLine:='';
 TempStr:='______________________';
 if ReadLine(InputLine) then
  if (InputLine='') or (not CheckBarcodeOnLabel(InputLine)) then
     DrawError('�������� �����-���. ��� ����������� ������� Ok')
  else
   begin
    CmdText:='select dk.id drinkkindid, r.id rackid, '+
             'r.name rackname, bx.fullname boxname, co.outdrinkrackid '+
             'from codes co '+
             'join drinkkind dk on dk.id=co.drinkkindid '+
             'join rack r on r.id=co.rackid '+
             'join box bx on bx.id=dk.saleboxid '+
             'where co.id='+Copy(InputLine,2,8);

    if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
     begin
      if Error then
       DrawError(ErrorMessage+' ��� ����������� ������� Ok')
      else
       DrawError('�������� ��������. ��� ����������� ������� Ok');
      exit;
     end;
    if ReadIBQ.FieldByName('outdrinkrackid').IsNull then
     Status:='�����������'
    else
     Status:='��������';


    DrawError('"���������� ��������'+
              '" "'+'�������� '+Status+
              '" "'+'������:'+Copy(TempStr,1,length(TempStr)-10-length(ReadIBQ.FieldByName('drinkkindid').AsString))+ReadIBQ.FieldByName('drinkkindid').AsString+
              '" "'+'�����:'+Copy(TempStr,1,length(TempStr)-9-length(ReadIBQ.FieldByName('rackid').AsString))+ReadIBQ.FieldByName('rackid').AsString+
              '" "'+'������:'+Copy(TempStr,1,length(TempStr)-10-length(ReadIBQ.FieldByName('rackname').AsString))+ReadIBQ.FieldByName('rackname').AsString+
              '" '+'��� ����������� ������� Ok');
   end;
end;

procedure RackInfoScreen_0(FromMainMenu:boolean);
var CmdText,datefack,datefack1,datefack2,datefack3:string;
    Error:boolean;
    Str,SaleId,TempStr,StorageName: String;
    Single: integer;
begin
 FromMainMenu:=false;
 DrawText('���������� �����-��� ������');
 InputLine:='';
 TempStr:='______________________';
 if ReadLine(InputLine) then
  if (InputLine='') then
     DrawError('�������� �����-���. ��� ����������� ������� Ok')
  else
   begin
    CmdText:='select dk.id dkid, d.id drinkid, d.factory, d.mark, d.volume, r.id rackid,'+
             '       r.name rackname, ch.bottlereserve reservebox, '+
             '       st.name storagename,ss.name storagesectionname, '+
             '       ch.bottlecount countbox, b.capacity bcap, pb.capacity pbcap,ps.datefactory  '+
             'from rack r '+
             'join storage st on st.id=r.storageid '+
             'join storagesection ss on ss.id=r.storagesectionid '+
             'left join cashe ch on r.id=ch.rackid '+
             'left join drinkkind dk on dk.id=ch.drinkkindid  '+
             'left join drink d on d.id=dk.drinkid '+
             'left join box b on b.id=dk.saleboxid '+
              'left join box pb on pb.id = dk.boxid '+
             'left join partycertificate ps on ps.id = dk.partycertificateid '+
             'where r.id='+InputLine+
             ' and r.storageid in ('+TermStorageid+')';
    if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
     begin
      if Error then
       DrawError(ErrorMessage+' ��� ����������� ������� Ok')
      else
       DrawError('������ �� �������. ��� ����������� ������� Ok');
      exit;
     end;

    if ReadIBQ.FieldByName('countbox').IsNull then
     begin
      DrawError('������ �����. ��� ����������� ������� Ok');
      exit;
     end;

     datefack1:='';
     datefack2:='';
     datefack3:='';
    datefack:=
    '" "'+'����:'+Copy(TempStr,1,length(TempStr)-8-length(copy(ReadIBQ.FieldByName('datefactory').AsString,1,15)))
                 +copy(ReadIBQ.FieldByName('datefactory').AsString,1,15);
    if Length(ReadIBQ.FieldByName('datefactory').AsString)>15 then
    datefack1:= '" "'+copy(ReadIBQ.FieldByName('datefactory').AsString,16,35)+
    Copy(TempStr,1,length(TempStr)-2-length(copy(ReadIBQ.FieldByName('datefactory').AsString,16,35)));
    if Length(ReadIBQ.FieldByName('datefactory').AsString)>35 then
    datefack2:= '" "'+copy(ReadIBQ.FieldByName('datefactory').AsString,36,55)+
    Copy(TempStr,1,length(TempStr)-2-length(copy(ReadIBQ.FieldByName('datefactory').AsString,36,55)));

    if Length(ReadIBQ.FieldByName('datefactory').AsString)>55 then
    datefack3:= '" "'+copy(ReadIBQ.FieldByName('datefactory').AsString,56,75)+
                 Copy(TempStr,1,length(TempStr)-2-length(copy(ReadIBQ.FieldByName('datefactory').AsString,56,75)));

    StorageName:=ReadIBQ.FieldByName('storagename').AsString;
    if pos('�',StorageName)>0 then
     StorageName:=StringReplace(StorageName, '�', 'N', [rfReplaceAll,rfIgnoreCase]);
    DrawError('"��:'+Copy(TempStr,1,length(TempStr)-9-length(ReadIBQ.FieldByName('rackname').AsString))+ReadIBQ.FieldByName('rackname').AsString+
              '" "'+'���-��:'+Copy(TempStr,1,length(TempStr)-10-length(ReadIBQ.FieldByName('countbox').AsString))+ReadIBQ.FieldByName('countbox').AsString+
              '" "'+'������:'+Copy(TempStr,1,length(TempStr)-10-length(ReadIBQ.FieldByName('reservebox').AsString))+ReadIBQ.FieldByName('reservebox').AsString+
              '" "'+'����:'+Copy(TempStr,1,length(TempStr)-10-length(ReadIBQ.FieldByName('pbcap').AsString+'/'+
                           ReadIBQ.FieldByName('bcap').AsString))
                 +ReadIBQ.FieldByName('pbcap').AsString+'/'+ReadIBQ.FieldByName('bcap').AsString+
              '" �����: '+ReadIBQ.FieldByName('factory').AsString+' '+
              ReadIBQ.FieldByName('mark').AsString+' '+ReadIBQ.FieldByName('volume').AsString+
              datefack+datefack1+datefack2 + datefack3+

              ' "��� �����������" "������� Ok"');
   end;
end;

procedure DrinkKindInfoScreen_0(FromMainMenu:boolean);
var CmdText:string;
    Error:boolean;
    Str,SaleId: String;
    Single: integer;
    MaxLine:string;
begin
 FromMainMenu:=false;
 DrawText('������� ��� ������');
 InputLine:='';
 MaxLine:='__________';
 if ReadLine(InputLine) then
  if (InputLine='') then
   DrawError('�������� ��� ������. ��� ����������� ������� Ok')
  else
   begin
    CmdText:='select first 7 r.id rackid,r.stage,r.name rackname, '+
             'round(sum(ch.bottlecount/cast(bx.capacity as double precision)),0) boxcount '+
             'from cashe ch '+
             'join drinkkind dk on dk.drinkid=ch.drinkid '+
             'join box bx on bx.id=dk.saleboxid '+
             'join rack r on r.id=ch.rackid '+
             'join storage st on st.id=r.storageid '+
             'where dk.id='+IntToStr(StrToIntDef(InputLine,0))+
             ' and st.id in ('+TermStorageID+')'+
             ' group by r.id,r.name,r.stage '+
             'order by r.stage';
    if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
     begin
      if Error then
       DrawError(ErrorMessage+' ��� ����������� ������� Ok')
      else
       DrawError('������ ������ �����������. ��� ����������� ������� Ok');
      if Assigned(Sale) then
       begin
        Dispose(Sale);
        Sale:=nil;
       end;
      exit;
     end;
    ReadIBQ.First;
    while not ReadIBQ.Eof do
     begin
      Str:=Str+' '+
       ReadIBQ.FieldByName('rackid').AsString+Copy(MaxLine,1,5-Length(ReadIBQ.FieldByName('rackid').AsString))+'_'+
       ReadIBQ.FieldByName('rackname').AsString+Copy(MaxLine,1,7-Length(ReadIBQ.FieldByName('rackname').AsString))+'_'+
       Copy(MaxLine,1,5-Length(ReadIBQ.FieldByName('boxcount').AsString))+ReadIBQ.FieldByName('boxcount').AsString;
      ReadIBQ.Next;
     end;
    DrawError('���������� �������� '+BuildLine('�����__������__����',LengthStr)+Str+' "��� �����������" "������� Ok"');
    if Assigned(Sale) then
     begin
      Dispose(Sale);
      Sale:=nil;
     end;
   end;
end;

procedure DrinkInfoScreen_0(FromMainMenu:boolean);
var CmdText,MaxLine,TextInfo,Str:string;
    Error:boolean;
    Barcode,DateFactory: String;
    flag:boolean;
begin
 FromMainMenu:=false;
 DrawText('������� �����-��� ������');
 InputLine:='';
 MaxLine:='__________';
 if ReadLine(InputLine) then
  if (InputLine='') then
   DrawError('�������� �����-��� ������. ��� ����������� ������� Ok')
  else
   begin
    if CheckBarcodeOnGoods(InputLine) then
     begin
      Barcode:=InputLine;

      CmdText:=
       'select d.mark,d.volume from drink d '+
       'join drinkbarcode db on db.drinkid=d.id '+
       'where db.barcode='+#39+Barcode+#39;

      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
         DrawError('���������� ����� � �����������');
        exit;
       end;


      TextInfo:=
       '"���������� ��" '+
       '"�����-���� ������" '+
        '"'+Copy(Trim(ReadIBQ.FieldByName('mark').AsString),1,15)+' '+Trim(ReadIBQ.FieldByName('volume').AsString)+'" '+
       '"������ �.�. 01.01.12" '+
       '"���� �������?"';

      DrawText(TextInfo);
      flag:=true;
      InputLine:='';
      while flag and ReadLine(InputLine) do
       begin
        if (not (InputLine='')) then
         begin
          DateFactory:='';
          try
           DateFactory:=
            ' and exists(select df.id from datefactory df '+
            '       where df.partycertificateid=dk.partycertificateid and df.bottlingdate=cast('+#39+DateToStr(StrToDate(InputLine))+#39+' as timestamp))';
           flag:=false;
          except
           DrawError('�������� ������ ���� �������. ��� ����������� ������� Ok');
           DrawText(TextInfo);
          end;
         end //else if InputLine='' then
        else
         begin
          if DateFactory='' then
           begin
            DrawError('�������� ������ ���� �������. ��� ����������� ������� Ok');
            DrawText(TextInfo);
           end;
         end
       end; //while flag and ReadLine(InputLine) do

      if flag then
       exit;

      CmdText:='select first 7 r.id rackid,r.stage,r.name rackname, '+
             'round(sum(ch.bottlecount/cast(bx.capacity as double precision)),0) boxcount '+
             'from cashe ch '+
             'join drinkkind dk on dk.id=ch.drinkkindid '+
             'join box bx on bx.id=dk.saleboxid '+
             'join rack r on r.id=ch.rackid '+
             'join storage st on st.id=r.storageid '+
             'join drink d on d.id=dk.drinkid '+
             'where st.id in ('+TermStorageID+')'+
             ' and d.id in (select db.drinkid from drinkbarcode db where db.barcode='+#39+Barcode+#39+')'+
             DateFactory+
             ' group by r.id,r.name,r.stage '+
             'order by r.stage';

      if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
       begin
        if Error then
         DrawError(ErrorMessage+' ��� ����������� ������� Ok')
        else
         DrawError('����� �� ������. ��� ����������� ������� Ok');
        exit;
       end;

      ReadIBQ.First;
      while not ReadIBQ.Eof do
       begin
        Str:=Str+' '+
         ReadIBQ.FieldByName('rackid').AsString+Copy(MaxLine,1,5-Length(ReadIBQ.FieldByName('rackid').AsString))+'_'+
         ReadIBQ.FieldByName('rackname').AsString+Copy(MaxLine,1,7-Length(ReadIBQ.FieldByName('rackname').AsString))+'_'+
         Copy(MaxLine,1,5-Length(ReadIBQ.FieldByName('boxcount').AsString))+ReadIBQ.FieldByName('boxcount').AsString;
        ReadIBQ.Next;
       end;
      DrawError('���������� �������� '+BuildLine('�����__������__����',LengthStr)+Str+' "��� �����������" "������� Ok"');
     end
    else
     DrawError('�������� �����-��� ������. ��� ����������� ������� Ok');
   end;
end;

procedure Tariff_Buy_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
begin
 DrawText('������� �����-��� ��������� �� �������');
 InputLine:='';
 if ReadLine(InputLine) then
  if (CheckBarcodeOnDoc('0'+InputLine,dtBuy)) then
   begin
    Barcode:=InputLine;

    CmdText:='select * from terminal_tarif_buyview('+IntToStr(StrToIntDef(Copy(Barcode,4,8),0))+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"��������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"����� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagename').AsString,1,14),'�', 'N')+'" '+
              '"������������� :param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';

    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (Length(InputLine)<>12) and (not CheckBarcodeOnDoc('0'+InputLine,dtBuy)) then
       DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
      else
       begin
        if (InputLine=BarCode) then
         begin
          CmdTextBarcode:='null';
          flag:=false //����� �� ����� �.�. ������������� ���� ���������
         end
        else
         CmdTextBarcode:=Copy(InputLine,1,11);

        CmdText:='select * from terminal_tarif_buyscan('+IntToStr(StrToIntDef(Copy(Barcode,4,8),0))+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

        InUpDelIBT.StartTransaction;
        try
         if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;

         if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
          DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

         CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
         InUpDelIBT.Commit;
        except on E:Exception do
         begin
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end; //on E:Exception
        end;//try
       end;//else
      DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� ��������� �� �������. ��� ����������� ������� Ok');
end;

procedure Tariff_Sale_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
    StorageId,StorageSectionId,SaleID:string;
begin
 DrawText('������� �����-��� ��������� �� ��������');
 InputLine:='';
 if ReadLine(InputLine) then
  begin
   if CheckDocBarcode(InputLine,dtSale) or CheckDocBarcode(InputLine,dtCarConsSale) then
    begin
     Barcode:=InputLine;

     SaleId:=IntToStr(StrToIntDef(Copy(Barcode,9,8),0));
     StorageId:=IntToStr(StrToIntDef(Copy(Barcode,3,3),0));
     StorageSectionId:=IntToStr(StrToIntDef(Copy(Barcode,6,3),0));

     CmdText:='select * from terminal_tarif_saleview('+SaleID+','+StorageID+','+StorageSectionID+')';

     if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
      begin
       DrawError(ErrorMessage+' ��� ����������� ������� Ok');
       exit;
      end;

     if not ReadIBQ.FieldByName('resultvalue').IsNull then
      begin
       DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
       exit;
      end;

     TextInfo:='"��������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
               '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
               '"����� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagename').AsString,1,14),'�', 'N')+'" '+
               '"������ '+ReadIBQ.FieldByName('sectionname').AsString+'" '+
               '"������������� :param" '+
               '"���������� �����-���" '+
               '"���������� ���" '+
               '"���������"';
     CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
     DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
     flag:=true;
     InputLine:='';
     while flag and ReadLine(InputLine) do
      begin
       if (Length(InputLine)<>12) and (not CheckDocBarcode(InputLine,dtSale)) and (not CheckDocBarcode(InputLine,dtCarConsSale)) then
        DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
       else
        begin
         if (InputLine=BarCode) then
          begin
           CmdTextBarcode:='null';
           flag:=false //����� �� ����� �.�. ������������� ���� ���������
          end
         else
          CmdTextBarcode:=Copy(InputLine,1,11);

         CmdText:='select * from terminal_tarif_salescan('+SaleID+','+StorageID+','+StorageSectionID+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

         InUpDelIBT.StartTransaction;
         try
          if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
           begin
            DrawError(ErrorMessage+' ��� ����������� ������� Ok');
            exit;
           end;

          if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
           DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

          CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
          InUpDelIBT.Commit;
         except on E:Exception do
          begin
           if InUpDelIBT.Active then
            InUpDelIBT.Rollback;
          end; //on E:Exception
         end;//try
        end;//else
       DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
       InputLine:='';
      end; //while flag and ReadLine(InputLine) do
    end
   else
    DrawError('�������� �����-��� ��������� �� ��������. ��� ����������� ������� Ok');
  end;
end;

procedure Tariff_Bonus_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
    BonusSqnNo,BonusStorageId,BonusPresent:string;
begin
 DrawText('������� �����-��� �������� ���������');
 InputLine:='';
 if ReadLine(InputLine) then
  if CheckDocBarcode(InputLine,dtSaleBonus) then
   begin
    Barcode:=InputLine;

    BonusSqnNo:=IntToStr(StrToIntDef(Copy(InputLine,3,2),0));
    BonusStorageId:=IntToStr(StrToIntDef(Copy(InputLine,11,6),0));
    BonusPresent:=Copy(InputLine,9,2)+'.'+Copy(InputLine,7,2)+'.'+Copy(InputLine,5,2);

    CmdText:='select * from terminal_tarif_bbview('+BonusStorageId+','+BonusSqnNo+','+#39+BonusPresent+#39+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"��������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"����� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagename').AsString,1,14),'�', 'N')+'" '+
              '"������������� :param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';
    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (Length(InputLine)<>12) and (not CheckDocBarcode(InputLine,dtSaleBonus)) then
       DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
      else
       begin
        if (InputLine=BarCode) then
         begin
          CmdTextBarcode:='null';
          flag:=false //����� �� ����� �.�. ������������� ���� ���������
         end
        else
         CmdTextBarcode:=Copy(InputLine,1,11);

        CmdText:='select * from terminal_tarif_bbscan('+BonusStorageId+','+BonusSqnNo+','+#39+BonusPresent+#39+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

        InUpDelIBT.StartTransaction;
        try
         if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;

         if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
          DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

         CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
         InUpDelIBT.Commit;
        except on E:Exception do
         begin
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end; //on E:Exception
        end;//try
       end;//else
      DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� �������� ���������. ��� ����������� ������� Ok');
end;

procedure Tariff_WayBill_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
begin
 DrawText('������� �����-��� ���������� � �������� �����');
 InputLine:='';
 if ReadLine(InputLine) then
  if CheckDocBarcode(InputLine,dtRoutes) then
   begin
    Barcode:=InputLine;

    CmdText:='select * from terminal_tarif_waybillview('+IntToStr(StrToIntDef(Copy(Barcode,3,16),-1))+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"���������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"'+ReadIBQ.FieldByName('drivername').AsString+'" '+
              '"'+ReadIBQ.FieldByName('licenseplate').AsString+'" '+
              '"������������� :param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';

    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (Length(InputLine)<>12) and (not CheckDocBarcode(InputLine,dtRoutes)) then
       DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
      else
       begin
        if (InputLine=BarCode) then
         begin
          CmdTextBarcode:='null';
          flag:=false //����� �� ����� �.�. ������������� ���� ���������
         end
        else
         CmdTextBarcode:=Copy(InputLine,1,11);

        CmdText:='select * from terminal_tarif_waybillscan('+IntToStr(StrToIntDef(Copy(Barcode,3,16),-1))+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

        InUpDelIBT.StartTransaction;
        try
         if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;

         if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
          DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

         CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
         InUpDelIBT.Commit;
        except on E:Exception do
         begin
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end; //on E:Exception
        end;//try
       end;//else
      DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� ���������� � �������� �����. ��� ����������� ������� Ok');
end;

procedure Tariff_Trans_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error,flag:boolean;
    flagstorage:smallint;
begin
 DrawText('������� �����-��� ��������� �� �����������');
 InputLine:='';
 if ReadLine(InputLine) then
  if CheckBarcodeOnDoc('0'+InputLine,dtTransportationIn) or
     CheckBarcodeOnDoc('0'+InputLine,dtTransportationBetween) or
     CheckBarcodeOnDoc('0'+InputLine,dtTransportationOut) then
   begin
    Barcode:=InputLine;

    flagstorage:=0;
    CmdText:='select * from terminal_tarif_transview('+IntToStr(StrToIntDef(Copy(Barcode,4,8),0))+','+IntToStr(flagstorage)+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"����������� N '+ReadIBQ.FieldByName('transportationid').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storageout').AsString,1,18),'�', 'N')+'" '+
              '"�� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagein').AsString,1,17),'�', 'N')+'" '+
              '":param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';
    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param','��������� '+CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (InputLine=BarCode) and (flagstorage=0) then
       begin
        flagstorage:=1;
        CmdText:='select * from terminal_tarif_transview('+IntToStr(StrToIntDef(Copy(Barcode,4,8),0))+','+IntToStr(flagstorage)+')';

        if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
         begin
          if Error then
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
          exit;
         end;
        CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
       end
      else
       begin
        if (Length(InputLine)<>12) and
           (not CheckBarcodeOnDoc('0'+InputLine,dtTransportationIn)) and
           (not CheckBarcodeOnDoc('0'+InputLine,dtTransportationBetween)) and
           (not CheckBarcodeOnDoc('0'+InputLine,dtTransportationOut)) then
         DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
        else
         begin
          if (InputLine=BarCode) then
           begin
            CmdTextBarcode:='null';
            flag:=false //����� �� ����� �.�. ������������� ���� ���������
           end
          else
           CmdTextBarcode:=Copy(InputLine,1,11);

          CmdText:='select * from terminal_tarif_transscan('+IntToStr(StrToIntDef(Copy(Barcode,4,8),0))+','+CmdTextBarcode+','+IntToStr(flagstorage)+','+IntToStr(UserInfo.Id)+')';

          InUpDelIBT.StartTransaction;
          try
           if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
            begin
             DrawError(ErrorMessage+' ��� ����������� ������� Ok');
             exit;
            end;

           if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
            DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

           CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
           InUpDelIBT.Commit;
          except on E:Exception do
           begin
            if InUpDelIBT.Active then
             InUpDelIBT.Rollback;
           end; //on E:Exception
          end;//try
         end;//else
       end;
      if flagstorage=0 then
       DrawText(ReplaceSub(TextInfo,':param','��������� '+CountEmployeeeID))
      else
       DrawText(ReplaceSub(TextInfo,':param','������� '+CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� ��������� �� ��������. ��� ����������� ������� Ok');
end;

procedure Tariff_Return_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
    BarcodeSaleID:string;
    IsFullSaleFlag:smallint;
begin
 DrawText('������� �����-��� ��������� �� �������');
 InputLine:='';
 if ReadLine(InputLine) then
  if CheckBarcodeOnDoc('0'+InputLine,dtReturn) or
     CheckDocBarcode(InputLine,dtReturnFullSale) or
     ((Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256)) then
   begin
    Barcode:=InputLine;

    if (CheckDocBarcode(InputLine,dtReturnFullSale)) then
     begin
      if (StrToIntDef(Copy(InputLine, 3, 14),0)=0) then
       begin
        DrawError('�������� �����-���. ��� ����������� ������� Ok');
        exit;
       end;
      BarcodeSaleID:=IntToStr(StrToIntDef(Copy(InputLine, 3, 14),0));
      IsFullSaleFlag:=1;
     end; //������ �������

    if (Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256) then
     begin
      if (StrToIntDef(Copy(InputLine, 5, 8),0)=0) then
       begin
        DrawError('�������� �����-���. ��� ����������� ������� Ok');
        exit;
       end;
      BarcodeSaleID:= IntToStr(StrToIntDef(Copy(InputLine, 4, 9),0));
      IsFullSaleFlag:=1;
     end; //������ ������� �� EAN13

    if (CheckBarcodeOnDoc('0'+InputLine,dtReturn)) then
     begin
      if (StrToIntDef(Copy(InputLine, 4, 11),0)=0) then
       begin
        DrawError('�������� �����-���. ��� ����������� ������� Ok');
        exit;
       end;
      BarcodeSaleID:= IntToStr(StrToIntDef(Copy(InputLine, 4, 11),0));
      IsFullSaleFlag:=0;
     end; //������� ������� �� ���������� ���������


    CmdText:='select * from terminal_tarif_drinkreturnview('+BarcodeSaleID+','+IntToStr(IsFullSaleFlag)+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"������� ������" '+
              '"�� ��������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"�� ����� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagename').AsString,1,14),'�', 'N')+'" '+
              '"������������� :param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';
    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (Length(InputLine)<>12) and
         (not (CheckBarcodeOnDoc('0'+InputLine,dtReturn)) and
         (not (CheckDocBarcode(InputLine,dtReturnFullSale)) and
         (not ((Length(InputLine)=13) and (StrToIntDef(Copy(InputLine,1,3),0)=256))))) then
       DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
      else
       begin
        if (InputLine=BarCode) then
         begin
          CmdTextBarcode:='null';
          flag:=false //����� �� ����� �.�. ������������� ���� ���������
         end
        else
         CmdTextBarcode:=Copy(InputLine,1,11);

        CmdText:='select * from terminal_tarif_drinkreturnscan('+IntToStr(StrToIntDef(Copy(Barcode, 4, 11),0))+','+IntToStr(IsFullSaleFlag)+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

        InUpDelIBT.StartTransaction;
        try
         if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;

         if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
          DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

         CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
         InUpDelIBT.Commit;
        except on E:Exception do
         begin
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end; //on E:Exception
        end;//try
       end;//else
      DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� ��������� �� �������. ��� ����������� ������� Ok');
end;

procedure Tariff_StorageDoc_Screen_0(FromMainMenu:boolean);
var CmdText,TextInfo,Barcode,CountEmployeeeID,CmdTextBarcode:string;
    Error:boolean;
    flag:boolean;
begin
 DrawText('������� �����-��� ���������');
 InputLine:='';
 if ReadLine(InputLine) then
  if (CheckBarcodeOnDoc('0'+InputLine,dtStorageDoc)) then
   begin
    Barcode:=InputLine;

    CmdText:='select * from terminal_tarif_storagedocview('+IntToStr(StrToIntDef(Copy(Barcode,4,15),0))+')';

    if (not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage)) and Error then
     begin
      DrawError(ErrorMessage+' ��� ����������� ������� Ok');
      exit;
     end;

    if not ReadIBQ.FieldByName('resultvalue').IsNull then
     begin
      DrawError(ReadIBQ.FieldByName('resultvalue').AsString);
      exit;
     end;

    TextInfo:='"�������� N '+ReadIBQ.FieldByName('sqnno').AsString+'" '+
              '"�� '+ReadIBQ.FieldByName('present').AsString+'" '+
              '"�������� '+ReplaceSub(Copy(ReadIBQ.FieldByName('storagename').AsString,1,14),'�', 'N')+'" '+
              '"������������� :param" '+
              '"���������� �����-���" '+
              '"���������� ���" '+
              '"���������"';

    CountEmployeeeID:=ReadIBQ.FieldByName('countemployeeid').AsString;
    DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
    flag:=true;
    InputLine:='';
    while flag and ReadLine(InputLine) do
     begin
      if (Length(InputLine)<>12) and (not CheckBarcodeOnDoc('0'+InputLine,dtStorageDoc)) then
       DrawError('�������� ������ �����-����. ��� ����������� ������� Ok')
      else
       begin
        if (InputLine=BarCode) then
         begin
          CmdTextBarcode:='null';
          flag:=false //����� �� ����� �.�. ������������� ���� ���������
         end
        else
         CmdTextBarcode:=Copy(InputLine,1,11);

        CmdText:='select * from terminal_tarif_storagedocscan('+IntToStr(StrToIntDef(Copy(Barcode,4,15),0))+','+CmdTextBarcode+','+IntToStr(UserInfo.Id)+')';

        InUpDelIBT.StartTransaction;
        try
         if (not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage)) and Error then
          begin
           DrawError(ErrorMessage+' ��� ����������� ������� Ok');
           exit;
          end;

         if not InUpDelIBQ.FieldByName('resultvalue').IsNull then
          DrawError(InUpDelIBQ.FieldByName('resultvalue').AsString);

         CountEmployeeeID:=InUpDelIBQ.FieldByName('countemployeeid').AsString;
         InUpDelIBT.Commit;
        except on E:Exception do
         begin
          if InUpDelIBT.Active then
           InUpDelIBT.Rollback;
         end; //on E:Exception
        end;//try
       end;//else
      DrawText(ReplaceSub(TextInfo,':param',CountEmployeeeID));
      InputLine:='';
     end; //while flag and ReadLine(InputLine) do
   end
  else
   DrawError('�������� �����-��� ��������� �� �������. ��� ����������� ������� Ok');
end;

procedure ExciseToDrink_0(FromMainMenu:boolean);
var CmdText,TextInfo:string;
    Error:boolean;
    Text,bt:string;
    i:integer;
begin
 while FromMainMenu do
  begin
   DrawText('���������� �����-��� ������ ��� �������� �����');
   InputLine:='';
   if ReadStr(InputLine) then
    begin
     if Length(InputLine)=68 then
      begin
       CmdText:='select * from terminal_excisetodrink('+#39+InputLine+#39+',null,null)';
       if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
        begin
         if Error then
          DrawError(ErrorMessage+' ��� ����������� ������� Ok')
         else
          DrawError('���������� ���������� �� ������');
        end
       else
        DrawError('"���������� �� ������" '+
                  '"'+Trim(ReadIBQ.FieldByName('alccode').AsString)+'" '+
                  '"'+Trim(ReadIBQ.FieldByName('factory').AsString)+'" '+
                  '"������: '+Trim(ReadIBQ.FieldByName('status').AsString)+'"');
      end
     else
      begin
     CmdText:=
      'select * from terminal_excisetodrink(null,'+InputLine+',null)';

     if not OpenIBQ(ReadIBQ,CmdText,Error,ErrorMessage) then
      begin
       if Error then
        DrawError(ErrorMessage+' ��� ����������� ������� Ok')
       else
        DrawError('���������� ������ � �����������');
      end
     else
      if (ReadIBQ.FieldByName('countunit').AsInteger=0) then
       DrawError('������ �����')
      else
       begin
        TextInfo:='"���������� �� ������" '+
                  '"'+Trim(ReadIBQ.FieldByName('rackname').AsString)+'" '+
                  '"������ '+Trim(ReadIBQ.FieldByName('drinkkindid').AsString)+'" '+
                  '"������� '+Trim(ReadIBQ.FieldByName('countunit').AsString)+' � '+Trim(ReadIBQ.FieldByName('countrack').AsString)+' ��" '+
                  '"������������� '+Trim(ReadIBQ.FieldByName('countunitscan').AsString)+'" '+
                  '"���������� �����?" ';
       DrawText(TextInfo);
       InputLine:='';
       while ReadStr(InputLine) do
        begin
         if (Length(InputLine)<>68) then
          DrawError('�� ������ ������ ������. ��� ����������� ������� Ok')
         else
          begin
           try
            CmdText:='select * from terminal_excisetodrink('+#39+InputLine+#39+','+ReadIBQ.FieldByName('rackid').AsString+',null)';

            InUpDelIBT.StartTransaction;

            if not OpenIBQ(InUpDelIBQ,CmdText,Error,ErrorMessage) then
             begin
              if Error then
               DrawError(ErrorMessage+' ��� ����������� ������� Ok')
              else
               DrawError('���������� ������ � �����������');
             end
            else
             begin
              TextInfo:='"���������� �� ������" '+
                        '"'+Trim(InUpDelIBQ.FieldByName('rackname').AsString)+'" '+
                        '"������ '+Trim(InUpDelIBQ.FieldByName('drinkkindid').AsString)+'" '+
                        '"������� '+Trim(InUpDelIBQ.FieldByName('countunit').AsString)+' � '+Trim(InUpDelIBQ.FieldByName('countrack').AsString)+' ��" '+
                        '"������������� '+Trim(InUpDelIBQ.FieldByName('countunitscan').AsString)+'" '+
                        '"���������� �����?" ';
              InUpDelIBT.Commit;
              InputLine:='';
             end
           except on E:Exception do
            begin
             if InUpDelIBT.Active then InUpDelIBT.Rollback;
             DrawError(E.Message+' ��� ����������� ������� Ok');
            end;
           end;//try
          end;//else
         DrawText(TextInfo);

        end; //while flag and ReadLine(InputLine) do
      end;
     end;
    end
   else
    FromMainMenu:=false;
  end;// while FromMainMenu do
end;

//[]---------------------------------------------------------------[]
//  �������� ���������
//[]---------------------------------------------------------------[]
begin
 Init;
 SetConsoleTitle('Terminal Consol');

 ReadParamFromRegistry(TerminalID,Root,TerminalFolder,'TerminalID','0');
 ReadParamFromRegistry(TermStorageID,Root,TerminalFolder,'StorageID','0');

 GoToOnLogin: if not OnLogin then
               exit;


 InitializationPrinter;

 KeyVkReturn:=true;
 Continue := true;
 while Continue do
  begin
   ReadConsoleInput(GetConInputHandle, IBuff, 1, IEvent);
   case IBuff.EventType of
    KEY_EVENT:
    begin
 // ��������� �������
     if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_ESCAPE)) then
      begin
       ClearConsole;
       if MenuPosition[1]<>1 then
        GoToDownSubMenu(MenuPosition[1]);
      end;

     if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_UP)) then
      begin
       if MenuPosition[0]=1 then
        MenuPosition[0]:=MenuPosition[3]
       else
        MenuPosition[0]:=MenuPosition[0]-1;
       DrawMenu(MenuPosition[1]);
      end;

     if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_DOWN)) then
      begin
       if MenuPosition[0]=MenuPosition[3] then
        MenuPosition[0]:=1
       else
        MenuPosition[0]:=MenuPosition[0]+1;
       DrawMenu(MenuPosition[1]);
      end;

     if ((IBuff.Event.KeyEvent.bKeyDown = True) and (IBuff.Event.KeyEvent.wVirtualKeyCode = VK_RETURN)) then
      begin
       if KeyVkReturn then
        begin
         try
          case MenuPosition[4] of
           100: SaleScreen_0(True);
           200: BuyScreen_0(True);
           300: ReturnScreen_0(True);
           400: RemovingScreeen_0(True);
           500: GoToUpSubMenu(MenuPosition[4]);
           510: TransportationInRackScreen_0(True);
           520: TransportationOutRackScreen_0(True);
           530: TransportationFromRackToRackScreen_0(True);
           540: GoToMainMenu;
           550: TransportationBettwenRackScreen_0(True);
           600: GoToUpSubMenu(MenuPosition[4]);
           610: PrintCodesScreen_0(True);
           620: PrintRackScreen_0(True);
           630: GoToMainMenu;
          1000: GoToUpSubMenu(MenuPosition[4]);
          1010: GoToMainMenu;
          1020: Tariff_Sale_Screen_0(True);
          1030: Tariff_WayBill_Screen_0(True);
          1040: Tariff_Trans_Screen_0(True);
          1050: Tariff_Buy_Screen_0(True);
          1060: Tariff_Bonus_Screen_0(True);
          1070: Tariff_Return_Screen_0(True);
          1080: Tariff_StorageDoc_Screen_0(True);
           700: GoToUpSubMenu(MenuPosition[4]);
           710: SaleInfoScreen_0(True);
           720: LabelInfoScreen_0(True);
           750: RackInfoScreen_0(True);
           760: DrinkKindInfoScreen_0(True);
           770: DrinkInfoScreen_0(True);
           780: ExciseToDrink_0(True);
           730: GoToMainMenu;
           800: break;
           900: GoToUpSubMenu(MenuPosition[4]);
           910: ;//GoToUpSubMenu(MenuPosition[4]);
           911: SettingsScreen_0(true);
           912: SettingsScreen_1(true);
           913: GoToDownSubMenu(MenuPosition[1]);
           914: SettingsScreen_2(true);
           920: GoToMainMenu;
           930: ;//GoToUpSubMenu(MenuPosition[4]);
           931: SettingsScreen_3(true);
           932: SettingsScreen_4(true);
           933: SettingsScreen_5(true);
           934: GoToDownSubMenu(MenuPosition[1]);
           935: SettingsScreen_6(true);
           740: VersionScreen_0(true);
          end;//case
         except
          ;
         end;
        end;//KeyVkReturn
      end; //if ((IBuff.Event.
     DrawMenu(MenuPosition[1]);
       //KeyVkReturn:=not KeyVkReturn;//���� 2 ���� ���������� ������� enter
    end; //KEY_EVENT:

  {_MOUSE_EVENT:
    begin
     if (IBuff.Event.MouseEvent.dwButtonState = VK_LBUTTON) then
      begin
       with IBuff.Event.MouseEvent.dwMousePosition do
        GotoXY(X,Y);
      end;//if
    end;//_MOUSE_EVENT}
   end;//case
  end;//while

 goto GoToOnLogin;
end.
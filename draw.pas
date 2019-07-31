unit draw;

interface

uses Windows;

function AnToAs(mes: string) : string;
function AnToAsi(mes: string) : string;
const
// ��������� ����������� �����
 YellowOnBlue = FOREGROUND_GREEN OR FOREGROUND_RED OR
                FOREGROUND_INTENSITY OR BACKGROUND_BLUE;
 WhiteOnBlue  = FOREGROUND_BLUE OR FOREGROUND_GREEN OR
                FOREGROUND_RED OR FOREGROUND_INTENSITY OR
                BACKGROUND_BLUE;
 RedOnWhite   = FOREGROUND_RED OR FOREGROUND_INTENSITY OR
                BACKGROUND_RED OR BACKGROUND_GREEN OR BACKGROUND_BLUE
                OR BACKGROUND_INTENSITY;
 WhiteOnRed   = BACKGROUND_RED OR BACKGROUND_INTENSITY OR
                FOREGROUND_RED OR FOREGROUND_GREEN OR FOREGROUND_BLUE
                OR FOREGROUND_INTENSITY;
 BlackOnWhite = 0
                OR BACKGROUND_RED OR BACKGROUND_GREEN OR BACKGROUND_BLUE OR BACKGROUND_INTENSITY;
 WhiteOnBlack = FOREGROUND_BLUE OR FOREGROUND_GREEN OR
                FOREGROUND_RED OR FOREGROUND_INTENSITY;  

implementation

//--------------------------------------
// Ansi to Ascii
//--------------------------------------
function AnToAs(mes: string) : string;
var i : integer;
begin
 for i:=1 to length(mes) do
 case mes[i] of
  '�'..'�':
  mes[i]:= Chr(Ord(mes[i]) - 64);
  '�'..'�' :
  mes[i]:= Chr (Ord(mes [i] ) -16);
 end;
 result := mes;
end;

function AnToAsi(mes: string) : string;
var i : integer;
begin
 for i:=1 to length(mes) do
 case mes[i] of
  {'�'..'�': mes[i]:= Chr(Ord(mes[i]) + 10);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 20);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 30);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 40);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 50);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 70);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 80);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 90);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 100);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 110);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 120);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 130);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 130);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 130);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 140);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 150);

  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 150);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 160);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 170);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 180);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 190);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 210);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 220);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 230);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 240);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 250);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 260);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 270);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 280);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 290);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 300);
  '�'..'�': mes[i]:= Chr(Ord(mes[i]) + 310);}

  '�'..'�': mes[i]:= Chr(440);
  '�'..'�': mes[i]:= Chr(1270);
  '�'..'�': mes[i]:= Chr(1260);
  '�'..'�': mes[i]:= Chr(1250);
  '�'..'�': mes[i]:= Chr(1240);
  '�'..'�': mes[i]:= Chr(1230);
  '�'..'�': mes[i]:= Chr(1220);
  '�'..'�': mes[i]:= Chr(1210);
  '�'..'�': mes[i]:= Chr(1200);
  '�'..'�': mes[i]:= Chr(1190);
  '�'..'�': mes[i]:= Chr(1180);
  '�'..'�': mes[i]:= Chr(1170);
  '�'..'�': mes[i]:= Chr(1160);
  '�'..'�': mes[i]:= Chr(1150);
  '�'..'�': mes[i]:= Chr(1140);
  '�'..'�': mes[i]:= Chr(1130);

  '�'..'�': mes[i]:= Chr(1120);
  '�'..'�': mes[i]:= Chr(1110);
  '�'..'�': mes[i]:= Chr(1100);
  '�'..'�': mes[i]:= Chr(1090);
  '�'..'�': mes[i]:= Chr(1080);
  '�'..'�': mes[i]:= Chr(1070);
  '�'..'�': mes[i]:= Chr(1060);
  '�'..'�': mes[i]:= Chr(1050);
  '�'..'�': mes[i]:= Chr(1040);
  '�'..'�': mes[i]:= Chr(1030);
  '�'..'�': mes[i]:= Chr(1020);
  '�'..'�': mes[i]:= Chr(1010);
  '�'..'�': mes[i]:= Chr(1000);
  '�'..'�': mes[i]:= Chr(990);
  '�'..'�': mes[i]:= Chr(980);
  '�'..'�': mes[i]:= Chr(970);

 end;

 result := mes;
end;

end.

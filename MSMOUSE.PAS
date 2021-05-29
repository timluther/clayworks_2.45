Unit msmouse;
{DEFINE NonStandardVideo}
INTERFACE
uses gbasics,crt2;

const
arrow:array[0..31]of word=(16383,8191,4095,2047,1023,511,255,127,63,127,511,4351,45311,63615,63615,64767,
0,16384,24576,28672,30720,31744,32256,32512,32640,31744,27648,17920,1536,768,768,0);
Hourglass:array[0..31]of word=
(49155,49155,49155,49155,57351,61455,63519,64575,64575,63519,61455,61455,57351,49155,49155,49155,
0,8184,8088,0,3088,1568,832,384,0,832,1568,3616,3088,8184,7832,0);
PointTo:array[0..31]of word=(33155,1,0,32784,49680,49680,49664,49664,49921,58371,64575,61455,61455,63519,64575,65151,
32380,32510,6342,6342,6342,6342,6398,6268,0,384,384,2016,960,384,0,0);

mouserect:trect=(x1:-1;y1:-1;x2:13;y2:17);
mousevisible:boolean=false;
oldvis:boolean=false;

clickwait=3;
Dclickwait=6;

Dclick_Xthreshold=2;
Dclick_Ythreshold=2;
linger_for=400;

Xgrid_Corner:integer=0;
Ygrid_Corner:integer=0;
Xgrid_size:integer=1;
Ygrid_size:integer=1;

RightShiftKey=1;
LeftShiftKey=2;
CtrlKey=4;
AltKey=8;
ScrollKey=16;
NumLockKey=32;
CapsKey=64;
InsertKey=128;

var
xm,ym,gridxm,gridym,oldgridxm,oldgridym,zm,oldxm,oldym,oldzm,ms_xdiff,ms_ydiff:integer;

ms_attrib:byte;

ms_pressed,ms_released,ms_clicked,ms_doubleclicked,ms_moved,ms_lingering,ms_gridmoved:boolean;

function chkouticon(x1,y1,x2,y2:integer):shortint;
function chkicon(x1,y1,x2,y2:integer):shortint;
Procedure stoprepeat;
Procedure stoprepeatwait(wait:word);
Function  resetmouse:boolean;
Procedure getstuff;far;
Procedure mouseon;
Procedure mouseoff;
procedure mouseoffrect(var rect:trect);
procedure setuserproc(p:pointer;callmask:word);
Procedure mpos;
Procedure mbutton;
Procedure setmouserect(x1,y1,x2,y2:integer);
Procedure Setmousepos(x,y:integer);
Procedure setmouseshape(x,y:integer;var mask);
Procedure setmickeys(x,y:integer);
procedure setsence(x,y,dspeed:integer);
Procedure xyfilter;
Procedure ymisxm;

IMPLEMENTATION
var counter,Dcounter,Lcounter:word;
{Procedure gettime(var hours,minutes,seconds,centi:byte);assembler;
asm
  pushf
  MOV   AH, 2CH
  INT   21H
  LES   DI,hours
  MOV   ES:[di],ch
  MOV   ES:[di+1],cl
  MOV   ES:[di+2],dh
  MOV   ES:[di+3],dl
  popf
end;}

Procedure Mouse(var m1,m2,m3,m4:integer);assembler;
asm
  push es
  les di,m1
  mov ax,es:[di]
  les di,m2
  mov bx,es:[di]
  les di,m3
  mov cx,es:[di]
  les di,m4
  mov dx,es:[di]
  pop es
  int $33
  les di,m1
  mov es:[di],ax
  les di,m2
  mov es:[di],bx
  les di,m3
  mov es:[di],cx
  les di,m4
  mov es:[di],dx
end;

Procedure setuserproc(p:pointer;callmask:word);assembler;
asm
  mov ax,000Ch
  mov cx,callmask
  les dx,p
  int $33
end;

Procedure Setmousepos(x,y:integer);
Var m1,m:integer;
Begin
  m1:=4;
  mouse(m1,m,x,y);
end;

Function resetmouse:boolean;
Var m1,m2,m:integer;
Begin
  M1:=0;
  Mouse(m1,m2,m,m);
  resetmouse:=m1<>0;
  {MousePicAdrs:=@arrow;}
end;

{$IFDEF NonStandardVideo}
Procedure Mouseon;
var oldrect:trect;
begin
  oldrect:=viewport;
  viewport:=screenport;
  if not mousevisible then
    drawmouse(xm,ym,0,0,MSdrawpointer);
  viewport:=oldrect;
  oldvis:=mousevisible;
  mousevisible:=true;
end;

Procedure Mouseoff;
var oldrect:trect;
begin
  oldrect:=viewport;
  viewport:=screenport;
  if mousevisible then
    drawmouse(0,0,xm,ym,MSdrawold);
  viewport:=oldrect;
  oldvis:=mousevisible;
  mousevisible:=false;
end;

Procedure setmouseshape(x,y:integer;var mask);
var oldrect:trect;
begin
  mousepicadrs:=pointer(@mask);
  drawmouse(xm,ym,oldxm,oldym,MSdrawboth);
end;

procedure mouseoffrect(var rect:trect);
begin
  if rect.overlap(mouserect) then
    mouseoff;
end;
{$ELSE}

Procedure Mouseon;assembler;
asm
  mov ax,1
  int $33
End;

Procedure Mouseoff;assembler;
asm
  mov ax,2
  int $33
End;

Procedure setmouseshape(x,y:integer;var mask);
Var M1,M2,M3,M4:integer;
Begin
  M1:=9;m2:=x;m3:=y;
  m4:=ofs(mask);
  asm
    les di,mask
  end;
  Mouse(m1,m2,m3,m4);
  setmousepos(xm+1,ym);
  setmousepos(xm,ym);
End;

procedure mouseoffrect(var rect:trect);assembler;
  {if mousevisible then begin
    if rect.overlap(mouserect) then
      mouseoff;
  end;}
  asm
    mov ax,$10
    les di,rect
    mov cx,es:[di]
    mov dx,es:[di+2]
    mov si,es:[di+4]
    mov di,es:[di+6]
    int $33
end;

{$ENDIF}

Procedure getdirection(var hor,ver:integer);
Var m1,m2,m3,m4:integer;
Begin
  m1:=11;
  mouse(m1,m2,hor,ver);
End;

function getxmove:integer;
Var m1,m2,m3,m4,ver,hor:integer;
Begin
  m1:=11;
  mouse(m1,m2,hor,ver);
  getxmove:=hor;
End;

function getymove:integer;
Var m1,m2,m3,m4,ver,hor:integer;
Begin
  m1:=11;
  mouse(m1,m2,hor,ver);
  getymove:=ver;
End;

Procedure setmouserect(x1,y1,x2,y2:integer);
Var M1,M2,M3,M4:integer;
Begin
  M1:=7;M3:=X1;M4:=X2;
  Mouse(M1,M2,M3,M4);
  M1:=8;M3:=Y1;M4:=Y2;
  Mouse(M1,M2,M3,M4);
End;



Procedure setmickeys(x,y:integer);assembler;
asm
  mov ax,0fh
  mov cx,x
  mov dx,y
  int 33h
end;

Procedure setsence(x,y,dspeed:integer);assembler;
asm
  mov ax,1Ah
  mov bx,x
  mov cx,y
  mov dx,dspeed
  int 33h
end;

var oldmouserect:trect;

Procedure mbutton;


begin

  asm
    push gridxm
    push gridym
    push oldgridxm
    push oldgridym
    push xm
    push ym
    push oldxm
    push oldym
  end;
  mpos;
  asm
    pop oldym
    pop oldxm
    pop ym
    pop xm
    pop oldgridym
    pop oldgridxm
    pop gridym
    pop gridxm
  end;

end;

Procedure mpos;
var M1:integer;
oldwritemode,oldcol:byte;
oldrect:trect;
Begin
  M1:=3;
  oldxm:=xm;oldym:=ym;oldzm:=zm;
  oldgridxm:=gridxm;oldgridym:=gridym;
  Mouse(m1,zm,xm,ym);
  mouserect.rpos(xm,ym);

  if Xgrid_size>1 then
    GridXm:=(((Xm-Xgrid_corner) div Xgrid_size)*Xgrid_size)+Xgrid_corner
  else
    gridXm:=Xm;
  if Ygrid_size>1 then
    GridYm:=(((Ym-Ygrid_corner) div Ygrid_size)*Ygrid_size)+Ygrid_corner
  else
    GridYm:=Ym;

  ms_xdiff:=xm-oldxm;ms_ydiff:=ym-oldym;
  ms_moved:=(oldxm<>xm)or(oldym<>ym);
  ms_gridmoved:=(oldgridxm<>gridxm)or(oldgridym<>gridym);
  ms_released:=(oldzm<>0)and(zm=0);

  ms_pressed:=(oldzm<>zm)and(zm<>0);

  if ms_pressed then counter:=timer+clickwait;
  ms_clicked:=(ms_released)and(timer<counter);
  ms_doubleclicked:=(timer<dcounter)and(ms_clicked)and(oldmouserect.contains(xm,ym));
  if ms_clicked then Dcounter:=timer+dclickwait;
  if ms_clicked then
    oldmouserect.rassign(xm-Dclick_xthreshold,ym-Dclick_ythreshold,
    xm+Dclick_xthreshold,ym+Dclick_ythreshold);
  if (xm=oldxm)and(oldym=ym)then begin
    inc(Lcounter);
    ms_lingering:=Lcounter>linger_for;
  end else begin
    Lcounter:=0;
    ms_lingering:=false;
  end;

  {$IFDEF NonStandardVideo}
  if (ms_moved)and(mousevisible) then begin
    drawmouse(xm,ym,oldxm,oldym,msdrawboth);
  end;
  {$Endif}
end;

Procedure xyfilter;
begin
  if scan and 2<>0 then xm:=oldxm else
  if scan and 4<>0 then ym:=oldym;
end;

Procedure ymisxm;Begin
  if scan and 4<>0 then begin ym:=xm;oldym:=oldxm;end;
end;

Procedure stoprepeat;
Begin
While zm<>0 do mpos;
end;

function chkicon(x1,y1,x2,y2:integer):shortint;
Begin
  if (xm>=x1) and (ym>=y1) and (xm<=x1+x2) and (ym<=y1+y2) then
    chkicon:=zm
  else chkicon:=-1;
end;

function chkouticon(x1,y1,x2,y2:integer):shortint;
Begin
  if (xm<x1) or (ym<y1) or (xm>x1+x2) or (ym>y1+y2) then
    chkouticon:=zm
  else chkouticon:=-1;
end;

Procedure stoprepeatwait(wait:word);
Var start,count:word;
Begin
  start:=timer;
  count:=0;
  While (zm<>0) and (count<wait)do Begin
    mpos;
    count:=timer-start;
  end;
end;

Procedure getstuff;
Begin
  asm
    mov byte ptr ms_attrib,al
    mov word ptr xm,cx
    mov word ptr ym,dx
    mov word ptr zm,bx
  end;
  ms_moved:=ms_attrib and 1<>0;
end;

Begin
  counter:=clickwait;
  Dcounter:=Dclickwait;
  Lcounter:=linger_for;
  {setuserproc(@getstuff,255);}
end.

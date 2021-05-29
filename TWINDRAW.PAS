Unit Twindraw;
{$X+}{$g+}{$a+}
INTERFACE

uses ggraph,gbasics,chardef,SinCos,Tmaths;
{define backtex}


Const
circlepic:array[0..7] of byte=(0,24,60,126,126,60,24,0);
Tickpic:array[0..7] of byte=(0,1,3,6,140,216,112,32);
closegadget:array[0..7] of byte=(00,00,126,126,0,00,00,00);
uparrow:array[0..7] of byte=(24,60,126,255,60,60,60,60);
downarrow:array[0..7] of byte=(60,60,60,60,255,126,60,24);
resizegadget:array[0..7] of byte=(253,253,253,253,253,253,1,255);
leftarrow:array[0..7] of byte=(16,48,127,255,255,127,48,16);
rightarrow:array[0..7] of byte=(8,12,254,255,255,254,12,8);
updownarrow:array[0..7] of byte=(24,60,126,0,126,60,24,0);
{Diricon:array[0..7] of byte=(252,132,159,161,161,194,252,0);
Fileicon:array[0..7] of byte=(127,145,161,193,129,129,255,0);
flopdrivel:array[0..7] of byte=(255,128,143,129,128,128,255,255);
flopdriver:array[0..7] of byte=(255,1,241,129,49,1,255,255);
Harddrivel:array[0..7] of byte=(255,144,160,192,128,128,128,255);
Harddriver:array[0..7] of byte=(255,1,1,1,1,13,1,255);}

gadgetsize=6;
border=8;
halfgadget=gadgetsize div 2;
maxborder=border+halfgadget;

nodesize=2;
nodesizedec1=nodesize-1;

{$ifdef backtex}

black=0;  {A}
grey1=4;  {B}
grey2=6;  {C}
grey3=8;  {D}
grey4=9;  {E}
grey5=12;  {F}
grey6=13;  {G}
white=15;  {H}
darkblue=8;{I}
yellow=12;  {J}
lightgreen=11;{K}
red=14;       {L}
biege=12;     {M}
{darkgreen=11; {N}
purple=9;    {N}
blue=9;
orange=15;    {O}
lightblue=10; {P}

textboxcol=grey5;
Highlight=white; {for icons e.t.c.}
textcol=grey1;   {text colour}
titletextcol=grey1; {for window titles}
scrollcol=grey2; {scroller background}
scrollhighlight=grey3;
lightcol=grey5;  {highlight colour}
midcol=grey4;    {button colour}
mid_darkcol=grey2;   {shadow colour 1}
darkcol=grey1;   {shadow colour 2}
backcol=darkblue;   {background colour}
gridcol=blue;    {grid colour}
selectcol=black;  {selection colour}
titlecol=blue;   {titlebar colour}
disabledcol=grey3;

menuselcolback=grey2;

menuselcolfore=white;
{$else}


black=0;  {A}
grey1=1;  {B}
grey2=2;  {C}
grey3=3;  {D}
grey4=4;  {E}
grey5=5;  {F}
grey6=6;  {G}
white=7;  {H}
darkblue=8;{I}
yellow=12;  {J}
lightgreen=11;{K}
red=14;       {L}
biege=12;     {M}
{darkgreen=11; {N}
purple=9;    {N}
blue=9;
orange=15;    {O}
lightblue=10; {P}

textboxcol=grey5;
Highlight=white; {for icons e.t.c.}
textcol=grey1;   {text colour}
titletextcol=grey1; {for window titles}
scrollcol=grey2; {scroller background}
scrollhighlight=grey3;
lightcol=grey5;  {highlight colour}
midcol=grey4;    {button colour}
mid_darkcol=grey2;   {shadow colour 1}
darkcol=grey1;   {shadow colour 2}
backcol=darkblue;   {background colour}
gridcol=blue;    {grid colour}
selectcol=black;  {selection colour}
titlecol=blue;   {titlebar colour}
disabledcol=grey3;

menuselcolback=grey2;

menuselcolfore=grey4;
{$endif}


var
backtex:bitmaptypeptr;
backdark:bitmaptypeptr;
{type
barprocedure=procedure(x1,y1,x2,y2:integer);}

Procedure Outtextxy3d(x,y:integer;txt:string);
Procedure OuttextxyU(x,y:integer;txt:string;underchar:byte);
Procedure OuttextxyU3d(x,y:integer;txt:string;underchar:byte);
Procedure Drawx(x,y:integer);
Procedure drawcursor(x,y:integer);
Procedure grid(x,y,gxsize,gysize,stpx,stpy:integer);
Procedure dotgrid(x,y,gxsize,gysize,stpx,stpy:integer);
Procedure boxgrid(x,y:integer;gxsize,gysize,stpx,stpy:integer);
Procedure colourgrid(x,y:integer;gxsize,gysize,stpx,stpy:integer;scol:byte);
Procedure stipcolourgrid(x,y:integer;gxsize,gysize,stpx,stpy,scol:integer);
Procedure stipcolourgridb(x,y:integer;gxsize,gysize,stpx,stpy,scol:integer);
Procedure solidrect(x1,y1,x2,y2:integer);

Procedure ButtonBar(x1,y1,x2,y2:integer);
Procedure ButtonBarDown(x1,y1,x2,y2:integer);
Procedure outbox(x1,y1,x2,y2:integer);
Procedure outboxcol(x1,y1,x2,y2:integer);
Procedure inbox(x1,y1,x2,y2:integer);
Procedure inboxcol(x1,y1,x2,y2:integer);
Procedure inboxcolb(x1,y1,x2,y2:integer);
Procedure Insetborder(x1,y1,x2,y2:integer;txt:string);
Procedure textcurs(x,y,y2:integer);
Procedure textsel(x,y,x2:integer);
Procedure textbox(x1,y1,x2,y2:integer);
Procedure textboxfilled(x1,y1,x2,y2:integer);
Procedure hline3d(x1,x2,y1:integer);
procedure draw3dborder(x1,y1,x2,y2:integer;inv:boolean);
procedure rectangle_rotated(x1,y1,x2,y2,cx,cy:integer;angle:real);
Procedure drawbound(x1,y1,x2,y2:integer);
procedure rotate_point(var x,y:integer;cx,cy:integer;angle:real);
procedure DrawArrow(x1,y1,x2,y2:integer);
Function lineangle(x1,y1,x2,y2:integer):integer;
procedure drawboundmulti(x1,y1,x2,y2,x3,y3,x4,y4:longint;count:integer;drawfirst:boolean);
procedure rectangle_rotatedmulti(x1,y1,x2,y2,cx,cy:integer;angle,oldangle:real;num:integer;drawfirst:boolean);

IMPLEMENTATION

procedure tilebitmap;
var xlop,ylop:byte;
begin

  for ylop:=0 to SC.size.y shr 6 do
    for xlop:=0 to SC.size.x shr 6 do
      putbitmap(xlop shl 6,ylop shl 6,backtex);

end;


procedure tilebitmapb;
var xlop,ylop:byte;
begin

  for ylop:=0 to SC.size.y shr 6 do
    for xlop:=0 to SC.size.x shr 6 do
      putbitmap(xlop shl 6,ylop shl 6,backdark);

end;

procedure ButtonBar(x1,y1,x2,y2:integer);
var oldvp,temp:trect;

begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1,y1,x2,y2);
  SC.viewport.intersect(temp);

  tilebitmap;
    SC.viewport:=oldvp;
  {$else}

  bar(x1,y1,x2,y2);
  {$endif}
end;

procedure ButtonBarDown(x1,y1,x2,y2:integer);
var oldvp,temp:trect;

begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1,y1,x2,y2);
  SC.viewport.intersect(temp);

  tilebitmapb;
    SC.viewport:=oldvp;
  {$else}

  bar(x1,y1,x2,y2);
  {$endif}


end;


Procedure outboxcol(x1,y1,x2,y2:integer);
var oldvp,temp:trect;
Begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1+1,y1+1,x2-2,y2-2);
  SC.viewport.intersect(temp);

  tilebitmap;
    SC.viewport:=oldvp;
  {$else}
  bar(x1+1,y1+1,x2-2,y2-2);
  {$endif}


  t_col:=lightcol;vline(x1,y1,y2-1); hline(x1,x2-1,y1);
  t_col:=highlight;putpixel(x1,y1);
  t_col:=grey3;vline(x2-1,y1+1,y2-1);hline(x1+1,x2-1,y2-1);
  t_col:=darkcol;vline(x2,y1,y2); hline(x1,x2,y2);
end;

Procedure outbox(x1,y1,x2,y2:integer);
var
oldvp,temp:trect;

Begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1+1,y1+1,x2-2,y2-2);
  SC.viewport.intersect(temp);

  tilebitmap;
  SC.viewport:=oldvp;
  {$else}
  t_fillcol:=midcol;bar(x1+1,y1+1,x2-2,y2-2);
  {$endif}



  t_col:=lightcol;vline(x1,y1,y2-1); hline(x1,x2-1,y1);
  t_col:=highlight;putpixel(x1,y1);
  t_col:=grey3;vline(x2-1,y1+1,y2-1);hline(x1+1,x2-1,y2-1);
  t_col:=darkcol;vline(x2,y1,y2); hline(x1,x2,y2);
end;

Procedure inbox(x1,y1,x2,y2:integer);

var
oldvp,temp:trect;

Begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1+1,y1+1,x2,y2);
  SC.viewport.intersect(temp);
  tilebitmapb;
  SC.viewport:=oldvp;
  {$else}

  t_fillcol:=midcol;bar(x1+2,y1+2,x2,y2);
  {$endif}
  t_col:=mid_darkcol;vline (x1+1,y1+1,y2);hline (x1+1,x2,y1+1);
  t_col:=darkcol;vline (x1,y1,y2);hline (x1,x2,y1);
end;

Procedure inboxcol(x1,y1,x2,y2:integer);
var
oldvp,temp:trect;

Begin
  {$ifdef backtex}
  oldvp:=SC.viewport;
  temp.rassign(x1+1,y1+1,x2,y2);
  SC.viewport.intersect(temp);
  tilebitmapb;
  SC.viewport:=oldvp;
  {$else}
  bar(x1+2,y1+2,x2,y2);
  {$endif}
  t_col:=mid_darkcol;vline (x1+1,y1+1,y2);hline (x1+1,x2,y1+1);
  t_col:=darkcol;vline (x1,y1,y2);hline (x1,x2,y1);
end;

Procedure inboxcolb(x1,y1,x2,y2:integer);
Begin
  bar(x1+1,y1+1,x2-1,y2-1);
  t_col:=darkcol;vline (x1,y1,y2);hline (x1,x2,y1);
  t_col:=lightcol;vline (x2,y1+1,y2-1);hline (x1+1,x2-1,y2);
  t_col:=15;putpixel(x2,y2);
end;

Procedure Insetborder(x1,y1,x2,y2:integer;txt:string);
Begin
  t_col:=(darkcol);
  outtextxy(x1+8,y1-2,txt);
  vline(x1,y1+1,y2-1);vline(x2,y1+1,y2-1);
  t_col:=(15);
  vline(x1+1,y1+1,y2-1);vline(x2+1,y1+1,y2);
  hline3d(x1+1,x1+4,y1+1);hline3d(x1+10+TStrlen(txt,@tcharset),x2-1,y1+1);
  hline3d(x1+1,x2+1,y2+1);
end;

Procedure Hline3d(x1,x2,y1:integer);
begin
  hline(x1,x2,y1+1);
  t_col:=darkcol;
  hline(x1,x2,y1);
end;

Procedure grid(x,y,gxsize,gysize,stpx,stpy:integer);
var lop,x2,y2:integer;
Begin
  x2:=gxsize*stpx;
  y2:=gysize*stpy;
  For lop:=1 to stpx do
    vline(x+(lop*gxsize),y-1,y2+y-1);
  For lop:=1 to stpy do
    hline(x+1,x2+x+1,y+(lop*gysize));
End;

Procedure dotgrid(x,y,gxsize,gysize,stpx,stpy:integer);
var xlop,ylop,ycount:integer;
Begin
  For xlop:=1 to stpx do begin
    ycount:=y;
    For ylop:=1 to stpy do begin
      {hline(x,x,ycount);}
      putpixel(x,ycount);
      inc(ycount,gysize);
      {ycount:=ycount+gysize;}
    end;
    inc(x,gxsize);
    {x:=x+gxsize;}
  end;
End;

Procedure boxgrid(x,y:integer;gxsize,gysize,stpx,stpy:integer);
var xlop,ylop:byte;
Begin
  For ylop:=0 to stpy-1 do
    For xlop:=0 to stpx-1 do
      outbox(x+(xlop*gxsize),y+(ylop*gysize),
      x+(xlop*gxsize)+gxsize-1,y+(ylop*gysize)+gysize-1);
End;

Procedure colourgrid(x,y:integer;gxsize,gysize,stpx,stpy:integer;scol:byte);
var xlop,ylop:byte;
Begin
  t_fillcol:=scol;
  For ylop:=0 to stpy-1 do
    For xlop:=0 to stpx-1 do
    Begin
      bar(x+(xlop*gxsize),y+(ylop*gysize),
      x+(xlop*gxsize)+gxsize-1,y+(ylop*gysize)+gysize-1);
      inc(t_fillcol);
    end;
End;

Procedure stipcolourgrid(x,y:integer;gxsize,gysize,stpx,stpy,scol:integer);
var xlop,ylop,stipval:byte;
    blackrun:boolean;
Begin
  t_col:=scol div 64;
  blackrun:=(scol and 63)<=31;
  if blackrun then
    t_fillcol:=black
  else
    t_fillcol:=white;
  stipval:=scol mod 32;
  For ylop:=0 to stpy-1 do
    For xlop:=0 to stpx-1 do
    Begin
      setfillpattern(greyfills[stipval xor (byte(blackrun) * 31)],true);
      bar(x+(xlop*gxsize),y+(ylop*gysize),
      x+(xlop*gxsize)+gxsize-1,y+(ylop*gysize)+gysize-1);
      if stipval=maxgreyfills then begin
        if blackrun then begin
          t_fillcol:=white;
          blackrun:=blackrun xor true;
        end else begin
          t_col:=t_col+1;
          t_fillcol:=black;
          blackrun:=blackrun xor true;
        end;
        stipval:=0;
      end else inc(stipval);
    end;
  setsolidfill;
End;

Procedure stipcolourgridb(x,y:integer;gxsize,gysize,stpx,stpy,scol:integer);
var xlop,ylop,stipval:byte;
Begin
  t_col:=scol div 32;
  t_fillcol:=t_col+1;
  stipval:=scol mod 32;
  For ylop:=0 to stpy-1 do
    For xlop:=0 to stpx-1 do
    Begin
      setfillpattern(greyfills[stipval],true);
      bar(x+(xlop*gxsize),y+(ylop*gysize),x+(xlop*gxsize)+gxsize-1,y+(ylop*gysize)+gysize-1);
      if stipval=maxgreyfills then begin
        inc(t_col);
        inc(t_fillcol);
        stipval:=0;
      end else inc(stipval);
    end;
  setsolidfill;
End;

Procedure textbox(x1,y1,x2,y2:integer);
Begin
  T_col:=grey4;hline(x1+1,x2-2,y1+1);
  vline(x1+1,y1+1,y2-2);
  T_col:=grey6;hline(x1+1,x2-1,y2-1);
  vline(x2-1,y1+1,y2-1);
  t_col:=darkcol;rectangle(x1,y1,x2,y2);
end;

Procedure textboxfilled(x1,y1,x2,y2:integer);
Begin
  T_col:=grey4;hline(x1+1,x2-2,y1+1);
  vline(x1+1,y1+1,y2-2);
  T_col:=grey6;hline(x1+1,x2-1,y2-1);
  vline(x2-1,y1+1,y2-1);
  t_col:=darkcol;rectangle(x1,y1,x2,y2);
  T_fillcol:=textboxcol;
  bar(x1+2,y1+2,x2-2,y2-2);
end;

Procedure textsel(x,y,x2:integer);
Begin
if x>x2 then asm mov ax,x;Xchg x2,ax;mov x,ax;end;
if x<>x2 then Begin dec(x2);solidrect(x,y,x2,y+8);end;
end;

Procedure textcurs(x,y,y2:integer);
begin
  Hline(x-2,x+2,y-1);
  Hline(x-2,x+2,y+y2);
  Vline(x,y,y+y2-1);
end;

Procedure solidrect(x1,y1,x2,y2:integer);
Var lop:word;
Begin
For lop:=y1 to y2 do
  HLine(x1,x2,lop);
End;

Procedure drawcursor(x,y:integer);
Begin
  hLine(x-7,x+7,y);
  hLine(x-7,x+7,y+1);
  vLine(x+1,y-7,y+7);
  vLine(x,y-7,y+7);
End;

Procedure Drawx(x,y:integer);
Begin
  Line(x-5,y-5,x+5,y+5);
  Line(x-5,y+5,x+5,y-5);
End;

procedure rotate_point(var x,y:integer;cx,cy:integer;angle:real);
var tmp:integer;
begin

  if angle<>0 then begin
  dec(x,cx);dec(y,cy);
  tmp:=trunc((x*cos(angle)) - (y* sin(angle)) );
  y:=trunc( (x* sin(angle)) + (y*cos(angle)) );
  x:=tmp;
  inc(x,cx);inc(y,cy);
  end;
end;

procedure draw3dborder(x1,y1,x2,y2:integer;inv:boolean);
begin
  if inv then t_col:=darkcol else t_col:=lightcol;
  hline(x1,x2,y1);
  vline(x1,y1,y2-1);
  if inv then t_col:=lightcol else t_col:=darkcol;
  hline(x1,x2-1,y2);
  vline(x2,y1,y2);
  t_col:=highlight;
  if inv then
    putpixel(x2,y2)
  else
    putpixel(x1,y1);
end;

{the first drawn rectangle often stays still so you have the option to draw it or not to avoid flicker}
procedure rectangle_rotatedmulti(x1,y1,x2,y2,cx,cy:integer;angle,oldangle:real;num:integer;drawfirst:boolean);
var
addstep,cangle:real;
lop:word;
begin

  if (num>0) and(angle<>oldangle) then begin

    cangle:=0;
    addstep:=(angle-oldangle) /num;
    SetLinePattern(170,false);
    for lop:=0 to num-1 do begin
      if (lop<>0)or(drawfirst) then
         rectangle_rotated(x1,y1,x2,y2,cx,cy,cangle);
      cangle:=cangle+addstep;
    end;
    SetLinePattern(255,false);
  end;
  rectangle_rotated(x1,y1,x2,y2,cx,cy,angle);
end;

procedure rectangle_rotated(x1,y1,x2,y2,cx,cy:integer;angle:real);
var p:array[0..7] of pointtype;
    lop:byte;
    dist:real;
    tmp:integer;
begin
  dec(x1,border);dec(y1,border);
  inc(x2,border);inc(y2,border);
  p[0].x:=x1;p[0].y:=y1;
  p[1].x:=x2;p[1].y:=y1;

  p[2].x:=x2;p[2].y:=y1+1;
  p[3].x:=x2;p[3].y:=y2-1;

  p[4].x:=x1;p[4].y:=y2;
  p[5].x:=x2;p[5].y:=y2;

  p[6].x:=x1;p[6].y:=y1+1;
  p[7].x:=x1;p[7].y:=y2-1;



  if angle<>0 then
  for lop:=0 to 7 do with p[lop] do begin
    rotate_point(x,y,cx,cy,angle);
  end;





  line(p[0].x,p[0].y,p[1].x,p[1].y);
  line(p[2].x,p[2].y,p[3].x,p[3].y);
  line(p[4].x,p[4].y,p[5].x,p[5].y);
  line(p[6].x,p[6].y,p[7].x,p[7].y);
end;

procedure drawboundmulti(x1,y1,x2,y2,x3,y3,x4,y4:longint;count:integer;drawfirst:boolean);
var addx1,addy1,addx2,addy2,
    px1,py1,px2,py2:longint;
    lop:word;
const
   s=halfgadget;
   shiftby=16;

begin

  if (count>0)and((x1<>x3)or(x2<>x4)or(y1<>y3)or(y2<>y4)) then begin

    x1:=x1 shl shiftby;
    y1:=y1 shl shiftby;
    x2:=x2 shl shiftby;
    y2:=y2 shl shiftby;
    addx1:=((x3 shl shiftby)-x1)div count;
    addy1:=((y3 shl shiftby)-y1)div count;
    addx2:=((x4 shl shiftby)-x2)div count;
    addy2:=((y4 shl shiftby)-y2)div count;

    SetLinePattern(170,false);
    for lop:=1 to count do begin
       if (lop<>1)or(drawfirst) then
         rectangle((x1 shr shiftby)-s,(y1 shr shiftby)-s,
                   (x2 shr shiftby)+s,(y2 shr shiftby)+s);
       inc(x1,addx1);
       inc(y1,addy1);
       inc(x2,addx2);
       inc(y2,addy2);
    end;
    SetLinePattern(255,false);
  end;
  drawbound(x3,y3,x4,y4);
end;




Procedure drawbound(x1,y1,x2,y2:integer);
const s=halfgadget;
var halfx,halfy:integer;
Begin
  dec(x1,border);dec(y1,border);inc(x2,border);inc(y2,border);
  Rectangle(x1,y1,x2,y2);
  Rectangle(x2-s,y2-s,x2+s,y2+s);
  Rectangle(x1-s,y2-s,x1+s,y2+s);
  Rectangle(x1-s,y1-s,x1+s,y1+s);
  Rectangle(x2-s,y1-s,x2+s,y1+s);
  halfx:=(x2-x1) shr 1;
  halfy:=(y2-y1) shr 1;
  Rectangle(halfx+x1-s,y2-s,halfx+x1+s,y2+s);
  Rectangle(x2-s,halfy+y1-s,x2+s,halfy+y1+s);
  Rectangle(halfx+x1-s,y1-s,halfx+x1+s,y1+s);
  Rectangle(x1-s,halfy+y1-s,x1+s,halfy+y1+s);
end;

Function lineangle(x1,y1,x2,y2:integer):integer;
var hyp,opp,adj:integer;
    tmp:real;
begin
  opp:=abs(x2-x1);
  adj:=abs(y2-y1);
  Hyp:=isqrt((opp*opp)+(adj*adj));
  if hyp=0 then hyp:=1;
  lineangle:=round(sin(sin(90)*opp )/hyp);
end;

procedure DrawArrow(x1,y1,x2,y2:integer);
{var p1,p2:pointtype;
    angle:integer;}

begin
  line(x1,y1,x2,y2);
  drawbytes(x2-4,y2-4,@circlepic,8);
  {p1.x:=x2-6;p1.y:=x2+6;
  p2.x:=x2+6;p2.y:=x2+6;
  angle:=lineangle(x1,y1,x2,y2);
  rotate_point(p1.x,p1.y,x2,y2,angle);
  rotate_point(p2.x,p2.y,x2,y2,angle);
  line(x2-1,y2-1,p1.x,p1.y);
  line(x2+1,y2+1,p2.x,p2.y);}
end;

Procedure Outtextxy3d(x,y:integer;txt:string);
begin
  t_col:=lightcol;
  Outtextxy(x+1,y+1,txt);
  t_col:=textcol;
  Outtextxy(x,y,txt);
end;

Procedure OuttextxyU(x,y:integer;txt:string;underchar:byte);
var lop:byte;
    xpos:integer;
begin
  outtextxy(x,y,txt);
  if underchar>0 then begin
    lop:=fontmax;
    while (lop>=0) and (Tcharset.typeface[ord(txt[underchar]),lop]=0) do
      dec(lop);
    xpos:=x+(TStrlen_at(txt,underchar,@tcharset));
    hline(xpos,xpos+tcharset.widths[ord(txt[underchar])]-2,y+2+lop);
  end;
end;

Procedure OuttextxyU3d(x,y:integer;txt:string;underchar:byte);
begin
  t_col:=lightcol;
  OuttextxyU(x+1,y+1,txt,underchar);
  t_col:=textcol;
  OuttextxyU(x,y,txt,underchar);
end;

end.
Highlight=15; {for icons e.t.c.}
textcol=3;   {text colour}
titletextcol=3; {for window titles}
scrollcol=14; {scroller background}
lightcol=6;  {highlight colour}
midcol=5;    {middle colour}
mid_darkcol=4;   {shadow colour}
darkcol=3;   {shadow colour}
backcol=2;   {background colour}
gridcol=1;    {grid colour}
selectcol=15;  {selection colour}
titlecol=13;   {titlebar colour}
disabledcol=4;
menuselcolback=10;
menuselcolfore=12;
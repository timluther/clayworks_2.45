Unit LCD;

INTERFACE
uses ggraph,tmaths,msmouse,gbasics;


type
lcdsize=record
  height,width,size,gap:integer;
end;

const
BigLcd:lcdsize=(height:150;width:75;size:15;gap:12);
SmallLcd:lcdsize=(height:40;width:20;size:6;gap:5);

LCD_dark=4;
LCD_light=12;

LCD_dot=128;      {h}
LCD_mid=64;       {g}
LCD_TopLeft=32;   {f}
LCD_BottomLeft=16;{e}
LCD_Bottom=8;     {d}
LCD_BottomRight=4;{c}
LCD_TopRight=2;   {b}
LCD_Top=1;        {a}

digits:array[0..9] of byte=(63,6,91,79,102,109,125,7,127,111);
chars:array[0..29] of byte=(119,124,88,94,123,113,111,116,4,14,
                            120,56,56,84,92,115,103,80,109,
                            112,28,28,28,118,110,91,0,99,64,8);

Procedure drawdigit(x,y:integer;dig:byte;size:LCDsize);
Function getlight(x,y:integer;size:LCDsize):byte;
Procedure lcd_num(x,y,num:integer;size:lcdsize;dotornot:boolean);
Procedure Lcd_string(x,y:integer;text:string;size:lcdsize);

IMPLEMENTATION

Procedure HorizDiamond(x1,y1,x2,y2:integer);
var depth,yp:integer;
begin
  if x1>x2 then fswap(x1,x2,sizeof(integer));
  if y1>y2 then fswap(y1,y2,sizeof(integer));
  depth:=(y2-y1) shr 1;

  yp:=1+y1+(y2-y1) shr 1;
  bar(x1+depth,y1,x2-depth,y2);
  inc(y2);
  triangle(x1,yp,x1+depth,y1,x1+depth,y2);
  triangle(x2,yp,x2-depth,y1,x2-depth,y2);
end;

Procedure VertDiamond(x1,y1,x2,y2:integer);
var depth,px:integer;
begin
  if x1>x2 then fswap(x1,x2,sizeof(integer));
  if y1>y2 then fswap(y1,y2,sizeof(integer));
  depth:=(x2-x1) shr 1;
  px:=x1+(x2-x1) shr 1;

  bar(x1,y1+depth,x2,y2-depth);
  triangle(px,y1,x1,y1+depth,x2,y1+depth);
  inc(y2);
  triangle(px,y2,x1,y2-depth,x2,y2-depth);
end;

Function getlight(x,y:integer;size:LCDsize):byte;
var halfheight:integer;
begin
  with size do begin
    halfheight:=height shr 1;
    getlight:=0;
    if chkicon(x+size,y,width-size,size)<>-1 then getlight:=LCD_top;
    if chkicon(x,y+size,size,halfheight)<>-1 then getlight:=LCD_topleft;
    if chkicon(x+width-size,y+size,size,halfheight)<>-1 then getlight:=LCD_topright;

    inc(y,halfheight-size);
    if chkicon(x+size,y,width-size,size)<>-1 then getlight:=LCD_mid;
    if chkicon(x,y+size,size,halfheight)<>-1 then getlight:=LCD_bottomleft;
    if chkicon(x+width-size,y+size,size,halfheight)<>-1 then getlight:=LCD_bottomright;

    inc(y,halfheight-size);
    if chkicon(x+size,y,width-size,size)<>-1 then getlight:=LCD_bottom;
  end;
end;

Procedure drawdigit(x,y:integer;dig:byte;size:LCDsize);

procedure setbright(bright:byte);
begin
  if bright<>0 then
    T_fillcol:=LCD_light else T_fillcol:=LCD_dark;
end;

var
halfheight:integer;

begin
  with size do begin
  halfheight:=height shr 1;
  setbright(dig and LCD_top);
  horizDiamond(x+gap,y,x+width-gap,y+size);

  setbright(dig and LCD_topleft);
  vertdiamond(x,y+gap,x+size,y+halfheight-gap);

  setbright(dig and LCD_topright);
  vertdiamond(x+width-size,y+gap,x+width,y+halfheight-gap);

  inc(y,halfheight-size);

  setbright(dig and LCD_mid);
  horizDiamond(x+gap,y,x+width-gap,y+size);

  setbright(dig and LCD_bottomleft);
  vertdiamond(x,y+gap,x+size,y+halfheight-gap);

  setbright(dig and LCD_bottomright);
  vertdiamond(x+width-size,y+gap,x+width,y+halfheight-gap);

  inc(y,halfheight-size);

  setbright(dig and LCD_bottom);
  horizDiamond(x+gap,y,x+width-gap,y+size);

  inc(x,width+gap);
  setbright(dig and LCD_dot);
  if t_fillcol=LCD_light then
    bar(x,y,x+size,y+size);
  end;
end;





Procedure lcd_num(x,y,num:integer;size:lcdsize;dotornot:boolean);
var lop,numlen,numcount,dot:byte;
    precalc,powered:integer;
begin
  dot:=0;
  numlen:=1{numlength(num)-1};
  numcount:=numlen;
  for lop:=0 to numlen do begin
    if (lop=numlen)and(dotornot) then dot:=LCD_dot;
    powered:=power(10,numcount);
    precalc:=num div powered;
    drawdigit(x+lop*(size.width+10),y,digits[precalc]+dot,size);
    dec(num,precalc * powered);
    dec(numcount);
  end;
end;

Procedure Lcd_string(x,y:integer;text:string;size:lcdsize);
var lop:byte;
begin
  for lop:=1 to length(text) do
    drawdigit(x+lop*(size.width+10),y,chars[ord(text[lop])-ord('a')],size);
end;


end.
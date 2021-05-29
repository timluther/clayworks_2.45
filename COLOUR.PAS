unit colour;
{$R-}
INTERFACE
uses PITtimer,ttypes;

const
maxRGBval=64;
{colour weights }
rwt=12; gwt=26; bwt=14;
type
RGBtype=object
  R,G,B:byte;
End;

RGBwordtype=object
  R,G,B:word;
End;

ColourEntry=object(rgbtype)
  Used:word;
end;

RGBarray=^RGBarray_;
RGBarray_=array[0..0] of RGBtype;

RGBwordarray=^RGBwordarray_;
RGBwordarray_=array[0..0] of RGBwordtype;

ColourEntryArray=^ColourEntryArray_;
ColourEntryArray_=array[0..0] of ColourEntry;

procedure readpal(filename:string;pal:RGBarray);
procedure savepal(filename:string;pal:RGBarray);
procedure savepalpas(filename:string;pal:RGBarray);
Function AllocateRGB(Rc,Gc,Bc:byte):byte;
Procedure FreeColour(colindex:byte);
Procedure FreeAllColours;
Procedure InitColours(NumCols:word);
Procedure DoneColours;
Procedure copycol(col1,col2:byte);
Procedure swapcol(col1,col2:byte);
Procedure grad(col1,col2:byte);
procedure LoadColourMap(pal:ColourEntryArray);
Procedure Gethardwarepal(pal:RGBarray);
Procedure SetHardwarepal(pal:RGBarray;start,length:word);
Procedure setpal(pal:RGBarray;start,length:word);
Procedure getpal(pal:RGBarray);
Procedure Fadepal(pal1,pal2:RGBarray;step:byte;background:boolean);
Procedure getrgb(colno:byte;var r,g,b:byte);
Procedure setrgb(colno:byte;r,g,b:byte);
Procedure sethsv(colno:byte;H,S,V:Real);
Procedure gethsv(colno:byte;var Hi,Si,Vi:byte);
function checkforfade:boolean;
function ColoursAvailable:word;
Procedure usecolours(start,length:word);

IMPLEMENTATION

var
MaxColours:integer;
ColoursAvail:integer;
ColourMap:ColourEntryArray;
fading:boolean;

function checkforfade:boolean;
begin
  checkforfade:=fading;
end;

Function ColoursAvailable:word;
begin
  ColoursAvailable:=ColoursAvail;
end;

Procedure usecolours(start,length:word);
var lop:word;
begin
  for lop:=start to start+(length-1) do
    inc(colourmap^[lop].used);
  dec(coloursavail,length);
  if coloursavail<0 then coloursavail:=0;
end;


{swaps two variables of arbitary length, inline into the code}
Procedure FSwap(Var s,d; L:Integer);
Begin
  Inline($1e /$c5/$b6/s /$c4/$be/d /$8b/$8e/l /$fc /$26/$8a/$05
         /$86/$04 /$46 /$aa /$e2/$f7 /$1f);
End;

procedure readpal(filename:string;pal:RGBarray);
var f:file;
recsize:word;
lop:byte;
begin
  recsize:=1;
  assign(f,filename);
  reset(f,recsize);
  blockread(f,pal^,maxcolours*sizeof(rgbtype),recsize);
  close(f);
end;

procedure savepal(filename:string;pal:RGBarray);
var f:file;
recsize:word;
lop:byte;
begin
  assign(f,filename);
  rewrite(f,recsize);
  blockwrite(f,pal^,sizeof(pal),recsize);
  close(f);
  {for lop:=0 to 15 do begin
    pal[lop].r:=pal[lop].r div 4;
    pal[lop].g:=pal[lop].g div 4;
    pal[lop].b:=pal[lop].b div 4;
  end;}
end;

procedure savepalpas(filename:string;pal:RGBarray);
var f:text;
lop:byte;
begin
  assign(f,filename);
  rewrite(f);
  write(f,'pal:palltype=(');
  for lop:=0 to maxcolours-1 do begin
    write(f,'(r:',pal^[lop].r,';');
    write(f,'g:',pal^[lop].g,';');
    write(f,'b:',pal^[lop].b,')');
    if lop=maxcolours-1 then
      write(f,')')
    else
      write(f,',');
    if (lop and 3=0) then
      writeln(f,'');
  end;
  close(f);
end;

procedure freecolour(colindex:byte);
begin
  ColourMap^[colindex].used:=0;
  inc(ColoursAvail);
end;

procedure freeallcolours;
var lop:byte;
begin
  for lop:=0 to maxcolours-1 do
    ColourMap^[lop].used:=0;
  ColoursAvail:=MaxColours;
end;

Procedure InitColours(NumCols:word);
begin
  MaxColours:=NumCols;
  getmem(Colourmap,MaxColours*sizeof(ColourEntry));
  FreeAllColours;
  LoadColourMap(ColourMap);
  fading:=false;
end;

Procedure DoneColours;
begin
  freemem(Colourmap,MaxColours*sizeof(ColourEntry));
end;


Function AllocateRGB(Rc,Gc,Bc:byte):byte;
var CurrCol:word;matchindex:byte;
    ColFound:boolean;
    diff,match:word;
begin
  CurrCol:=0;
  match:=32000;
  ColFound:=false;

  While (not ColFound)and(currcol<maxcolours) do with Colourmap^[CurrCol] do begin
    if (r=rc)and(g=gc)and(b=bc) then
      ColFound:=true;
    if (ColFound<>true)and(coloursavail<=0) then begin
      diff:=abs(gc-g)*gwt;
      if diff<match then begin
        inc(diff,( abs(rc-r)*rwt+
                   abs(bc-b)*bwt));
        if (diff<match)then begin
          match:=diff;
          matchindex:=currcol;
        end;
      end;
    end;
    inc(currcol);
  end;

  dec(CurrCol);
  if (ColFound)and(colourmap^[currcol].used>0) then begin
    AllocateRGB:=CurrCol;
    inc(ColourMap^[CurrCol].used);
  end else if ColoursAvail>0 then begin
    CurrCol:=0;
    While (ColourMap^[CurrCol].used<>0)and(CurrCol<maxcolours-1) do
      inc(CurrCol);
    ColourMap^[CurrCol].used:=1;
    AllocateRGB:=CurrCol;
    Setrgb(CurrCol,Rc,Gc,Bc);
    dec(ColoursAvail);
  end else begin
    AllocateRGB:=Matchindex;
    inc(ColourMap^[MatchIndex].used);
  end;
end;

Procedure setPal(pal:RGBarray;start,length:word);
var lop:byte;
    CurrCol:^RGBtype;
begin
  CurrCol:=pointer(pal);
  for lop:=start to start+(length-1) do begin
    colourmap^[lop].r:=CurrCol^.r;
    colourmap^[lop].g:=CurrCol^.g;
    colourmap^[lop].b:=CurrCol^.b;
    inc(CurrCol);
  end;
  SetHardWarePal(pal,start,length);
end;

Procedure getPal(pal:RGBarray);
var lop:byte;
    CurrCol:^RGBtype;
begin
  CurrCol:=pointer(pal);
  for lop:=0 to maxcolours-1 do begin
    CurrCol^.r:=colourmap^[lop].r;
    CurrCol^.g:=colourmap^[lop].g;
    CurrCol^.b:=colourmap^[lop].b;
    inc(CurrCol);
  end;
end;

Procedure LoadColourMap(pal:ColourEntryArray);assembler;
asm
  mov dx,$3C7
  mov al,0
  out dx,al
  mov dx,$3C9

  les di,pal
  mov cx,maxcolours;
  @colloop:
    in al,dx; mov es:[di],al; inc di
    in al,dx; mov es:[di],al; inc di
    in al,dx; mov es:[di],al; inc di
    mov ax,0; mov es:[di],ax; add di,2
  loop @colloop
End;

Procedure Gethardwarepal(pal:RGBarray);assembler;
asm
  mov dx,$3C7
  mov al,0
  out dx,al
  mov dx,$3C9

  les di,pal
  mov cx,maxcolours;
  @colloop:
    in al,dx; mov es:[di],al; inc di
    in al,dx; mov es:[di],al; inc di
    in al,dx; mov es:[di],al; inc di
  loop @colloop
End;

Procedure SetHardwarePal(pal:RGBarray;start,length:word);assembler;
  asm
    mov dx,$3C8
    mov al,0
    out dx,al
    inc dx

    les di,pal
    xor ax,ax
    xor cx,cx
    mov ax,start
    add di,ax
    mov cx,length
    @colloop:
      mov al,es:[di]; out dx,al ;inc di
      mov al,es:[di]; out dx,al ;inc di
      mov al,es:[di]; out dx,al ;inc di
    loop @colloop
end;

Procedure getrgb(colno:byte;var r,g,b:byte);
begin
  colno:=colno mod maxcolours;
  r:=ColourMap^[colno].r;
  g:=ColourMap^[colno].g;
  b:=ColourMap^[colno].b;
end;
{assembler;
asm
  mov dx,$3c7
  mov al,colno
  out dx,al
  mov sx,$3c9

  in  al,dx;les di,r;   mov es:[di],al
  in  al,dx;les di,g; mov es:[di],al
  in  al,dx;les di,b;  mov es:[di],al
end;}

Procedure setrgb(colno:byte;r,g,b:byte);{assembler;}
begin
  if colno<maxcolours then begin
    ColourMap^[Colno].R:=r;
    ColourMap^[Colno].G:=g;
    ColourMap^[Colno].B:=b;
    asm
      mov dx,$3c8
      mov al,colno
      out dx,al
      inc dx

      mov al,r;   out dx,al
      mov al,g; out dx,al
      mov al,b;  out dx,al
    end;
  end;
end;

Procedure sethsv(colno:byte;H,S,V:Real);
var
  r,g,b,f,q,p,t:real; i:integer;
begin
  H:=H * 6;
  S:=S / 64;V:=V /64;
  if s=0 then begin
    r:=v;g:=v;b:=v;
  end else begin
    if h=384 then H:=0;
    H:=H / 64;
    i:=trunc(H);
    f:=H-i;
    p:=V*(1-S);
    q:=V*(1-(S*f));
    t:=V*(1-(S*(1-f)));
    {with 1/6 is Hue in?}
    case i of
      0:begin R:=v;G:=t;B:=p;end;
      1:begin R:=q;G:=v;B:=p;end;
      2:begin R:=p;G:=v;B:=t;end;
      3:begin R:=p;G:=q;B:=v;end;
      4:begin R:=t;G:=p;B:=v;end;
      5:begin R:=v;G:=p;B:=q;end;
    end;
  end;
  Setrgb(colno,trunc(R*64),trunc(G*64),trunc(B*64));
end;

Procedure gethsv(colno:byte;var Hi,Si,Vi:byte);
var max,min,diff,r_dist,g_dist,b_dist,r,g,b,H,S,V:real;
    ri,gi,bi:byte;
begin
  Getrgb(colno,ri,gi,bi);
  r:=ri / 64; g:=gi / 64; b:=bi / 64;
  If R>G then max:=R else max:=G;
  iF B>max then max:=B;
  If R<G then min:=R else min:=G;
  If B<min then min:=B;
  Diff:=max-min;
  v:=max;
  if max<>0 then s:=diff/max else S:=0;
  if S=0 then
    H:=0
  else begin
    r_dist:=(max - R)/diff;
    g_dist:=(max - G)/diff;
    b_dist:=(max - B)/diff;
    if R=max then
      H:=b_dist-G_dist
    else if G=max then
      H:=2+r_dist-b_dist
    else if B=max then
      H:=4+g_dist-R_dist;
    H:=H * 64;
    if H< 0 then H:=H+384;
  end;
  Hi:=trunc(H / 6);
  Si:=trunc(S * 64);
  Vi:=trunc(V * 64);
end;

Procedure swapcol(col1,col2:byte);
var col1val,col2val:RGBtype;
Begin
  getrgb(col1,col1val.r,col1val.g,col1val.b);
  getrgb(col2,col2val.r,col2val.g,col2val.b);
  setrgb(col2,col1val.r,col1val.g,col1val.b);
  setrgb(col1,col2val.r,col2val.g,col2val.b);
end;

Procedure copycol(col1,col2:byte);
var col1val:RGBtype;
Begin
  getrgb(col1,col1val.r,col1val.g,col1val.b);
  setrgb(col2,col1val.r,col1val.g,col1val.b);
end;

Procedure grad(col1,col2:byte);
const shiftby=6;
var Rplus,Bplus,Gplus,rp,gp,bp,step:integer;
    pal:rgbarray;
Begin
  getmem(pal,maxcolours*sizeof(rgbtype));
  if col2<col1 then fswap(col1,col2,1);
  step:=col2-col1-2;
  getpal(pal);
  Rplus:=((pal^[col2].r-pal^[col1].r)shl shiftby)div step;
  bplus:=((pal^[col2].b-pal^[col1].b)shl shiftby)div step;
  gplus:=((pal^[col2].g-pal^[col1].g)shl shiftby)div step;
  rp:=rplus;Gp:=Gplus;Bp:=Bplus;
  step:=col1+1;
  if (step)<col2 then
  while step<=col2 do begin
    setrgb(step,pal^[col1].r+(rp shr shiftby),
                pal^[col1].g+(gp shr shiftby),
                pal^[col1].b+(bp shr shiftby));
    inc(rp,rplus); inc(Gp,Gplus); inc(Bp,Bplus);
    inc(step);
  End;
  freemem(pal,maxcolours*sizeof(rgbtype));
end;

var
F_pal1:RGBarray;
F_ScaledPal,F_PalIncs:RGBwordarray;
F_counter:integer;
const F_shiftby=6;

Procedure doincs;
var lop2:byte;
begin
  dec(F_counter);
  For lop2:=0 to maxcolours-1 do begin
    F_pal1^[lop2].r:=  F_ScaledPal^[lop2].r shr F_shiftby;
    F_pal1^[lop2].g:=  F_ScaledPal^[lop2].g shr F_shiftby;
    F_pal1^[lop2].b:=  F_ScaledPal^[lop2].b shr F_shiftby;
    inc(F_ScaledPal^[lop2].r,F_PalIncs^[lop2].r);
    inc(F_ScaledPal^[lop2].g,F_Palincs^[lop2].g);
    inc(F_ScaledPal^[lop2].b,F_PalIncs^[lop2].b);
  end;
  {waitvbl;}
  if F_counter>0 then
    sethardwarepal(F_pal1,0,maxcolours)
  else
    setpal(F_pal1,0,maxcolours)
end;

Procedure addincs;interrupt;
begin
  if F_counter=0 then begin
    fading:=false;
    cleanuptimer;
  end;
  doincs;
end;

Procedure Fadepal(pal1,pal2:RGBarray;step:byte;background:boolean);
Var lop:byte;
Begin
  getmem(F_pal1,maxcolours*sizeof(rgbtype));
  getmem(F_ScaledPal,maxcolours*sizeof(rgbwordtype));
  getmem(F_PalIncs,maxcolours*sizeof(rgbwordtype));

  For lop:=0 to maxcolours-1 do Begin
    with F_ScaledPal^[lop] do begin
      r:=pal1^[lop].r shl F_shiftby;
      g:=pal1^[lop].g shl F_shiftby;
      b:=pal1^[lop].b shl F_shiftby;
    end;
    with F_palincs^[lop] do begin
      r:=((pal2^[lop].r-pal1^[lop].r)shl F_shiftby)div step;
      g:=((pal2^[lop].g-pal1^[lop].g)shl F_shiftby)div step;
      b:=((pal2^[lop].b-pal1^[lop].b)shl F_shiftby)div step;
    end;
  end;
  F_counter:=step;
  if background then begin
    fading:=true;
    settimer(@addincs,1000)
  end else
  while F_counter>0 do
    doincs;

  Freemem(F_pal1,maxcolours*sizeof(rgbtype));
  Freemem(F_ScaledPal,maxcolours*sizeof(rgbwordtype));
  Freemem(F_PalIncs,maxcolours*sizeof(rgbwordtype));
end;

end.

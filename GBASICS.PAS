unit Gbasics;


{Graphics Basics}
{$X+}{$a+}
INTERFACE

uses ttypes,chardef,tmaths;

type

hlinetypeptr=^hlinetype;
hlinetype=record
  x1,x2:integer;
end;


bytepointtypeptr=^bytepointtype;
bytepointtype=object
  x,y:byte;
  procedure moveto(x_,y_:byte);
end;


pointtypeptr=^pointtype;
pointtype=object
  x,y:integer;
  procedure moveto(x_,y_:integer);
end;

pointtypearray=^pointtypearray_;
  pointtypearray_=array[0..0] of pointtype;

{used to initialize a graphics mode}

screenidtype=record
  Driver:byte;   {screen mode describes the general graphics driver}
  graphmode:byte;    {Graph mode is the exact mode that the above driver understands}
  colourdepth:word;  {the amount of colours available with this mode}
  size:pointtype;    {resolution of the screen}
  bitplanes:byte;    {Number of bits per pixel}
end;


const
{these are used in 16 colour or plainiar modes. They are included in here
instead of inside those specific Libraries as the 16 colour bitmap routines
are always included and will need these constants}
singlepixelbitmasks:array[0..7] of byte=
(128,64,32,16,8,4,2,1);
left_pixelbitmasks:array[0..7] of byte=
(255,127,63,31,15,7,3,1);
right_pixelbitmasks:array[0..7] of byte=
(0,128,192,224,240,248,252,254);

{dirty rectangle constants}

RSlist=2;
RSobscured=1;
RSnooverlap=0;


{Logical modes}
xorput=24;
andput=$10;
orput=$20;

{graphic driver identifiers}
STnull=0;
STvga_plainiar=1;
STbitmap_plainiar=2;
STvga_flat=3;
STbitmap_flat=4;
STsvga_flat=5;
STxvga_plainiar=6;

{Video modes}
{16 colour plainiar 64k}
VGA320x200x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:$d;ColourDepth:16;size:(x:320;y:200);bitplanes:4);
VGA640x200x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:$e;ColourDepth:16;size:(x:640;y:200);bitplanes:4);
VGA640x350x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:$10;ColourDepth:16;size:(x:640;y:350);bitplanes:4);
VGA640x480x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:$12;ColourDepth:16;size:(x:640;y:480);bitplanes:4);
SVGA800x600x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:102;ColourDepth:16;size:(x:800;y:600);bitplanes:4);
SVGA1024x768x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:104;ColourDepth:16;size:(x:1024;y:768);bitplanes:4);
SVGA1280x1024x16:ScreenIdType=(Driver:STvga_plainiar;GraphMode:106;ColourDepth:16;size:(x:1280;y:1024);bitplanes:4);

{256 colour flat 64k}
VGA320x200x256:ScreenIdType=(Driver:STvga_flat;GraphMode:$13;ColourDepth:256;size:(x:320;y:200);bitplanes:1);

{256 colour flat >64k}
SVGA640x400x256:ScreenIdType=(Driver:STsvga_flat;GraphMode:5;ColourDepth:256;size:(x:640;y:400);bitplanes:1);
SVGA640x480x256:ScreenIdType=(Driver:STsvga_flat;GraphMode:1;ColourDepth:256;size:(x:640;y:480);bitplanes:1);
SVGA800x600x256:ScreenIdType=(Driver:STsvga_flat;GraphMode:3;ColourDepth:256;size:(x:800;y:600);bitplanes:1);
SVGA1024x768x256:ScreenIdType=(Driver:STsvga_flat;GraphMode:5;ColourDepth:256;size:(x:1024;y:768);bitplanes:1);

{16 million colour flat >64k}
SVGA640x480x16m:ScreenIdType=(Driver:STsvga_flat;GraphMode:$12;ColourDepth:256;size:(x:640;y:480);bitplanes:1);


{256 colour, unchained 64k}

XVGA320x200x256:ScreenIdType=(Driver:STxvga_plainiar;GraphMode:$14;ColourDepth:256;size:(x:320;y:200);bitplanes:6);
XVGA320x240x256:ScreenIdType=(Driver:STxvga_plainiar;GraphMode:$15;ColourDepth:256;size:(x:320;y:240);bitplanes:6);
XVGA400x300x256:ScreenIdType=(Driver:STxvga_plainiar;GraphMode:$16;ColourDepth:256;size:(x:400;y:300);bitplanes:6);
XVGA640x400x256:ScreenIdType=(Driver:STxvga_plainiar;GraphMode:$18;ColourDepth:256;size:(x:640;y:400);bitplanes:6);
XVGA400x600x256:ScreenIdType=(Driver:STxvga_plainiar;GraphMode:$17;ColourDepth:256;size:(x:400;y:600);bitplanes:6);

BMnull=0;
BMplanes=1;
BMflat=2;

{
clip area constants
                  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄmiddle = $0F
ÉÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍ»
ºmsb³   ³   ³   ³   ³   ³   ³lsbº
ÈÍÑÍÏÍÍÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍ¼
  ÀÄÄÄÂÄÄÄÙ   ³   ³   ³   ³   ÀÄÄÄRight  = $01
      ³       ³   ³   ³   ÀÄÄÄÄÄÄÄBellow = $02
  Undefined   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄLeft   = $04
              ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄabove  = $08
              ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄrelative = $10}

right  =$01;
bellow =$02;
left   =$04;
above  =$08;

above_right=above+right;
bellow_right=bellow+right;
above_left=above+left;
bellow_left=bellow+left;
middle=above+bellow+right+left;
type
dword=longint;

prect=^trect;
prectlist=^rectlist;
Trect=object
  x1,y1,x2,y2:integer;

  procedure Rpos(xp,yp:integer);
  procedure Rmove(xa,ya:integer);
  procedure Rgrow(xg,yg:integer);
  procedure Rassign(x1_,y1_,x2_,y2_:integer);
  function  contains(x,y:integer):boolean;

  function Clipin(var xa,ya,xb,yb:integer):boolean;
  function Clipout(var xa,ya,xb,yb:integer):boolean;
  procedure union(const r:trect);
  function intersect(const r:trect):boolean;
  function overlap(const r:trect):boolean;
  function empty:boolean;
  function inside(const r:trect):boolean;
  function equals(const r:trect):boolean;
  function concatable(const r:trect):boolean;

  function cutfrom(r:trect):prectlist;
  function halfx:integer;
  function halfy:integer;
  function height:integer;
  function width:integer;
end;

rectlist=object(trect)
  next:prectlist;
end;

ScreenDataType=record
  Driver:byte;   {screen mode describes the general graphics driver}
  graphmode:byte;    {Graph mode is the exact mode that the above driver understands}
  colourdepth:word;  {the amount of colours available with this mode}
  size:pointtype;    {resolution of the screen}
  bitplanes:byte;    {Number of bitplanes}

  nopages:byte;      {number of pages available in memory}
  bitsperpixel:byte; {how many bits per pixel}

  scrptr:bytearray;
  scrptrs:array[0..3] of bytearray;
  startoffsets:array[0..800]of word; {wordarray; {Used for quick access into the screen, an LUT for the addresses of scanlines}



  pagesize:dword;    {size in bytes of the screen}

  {quick access stuff}

  Qoffset:dword; {address position of the currentpixel as an address}
  Qbitoffset:byte; {byte mask for current pixel}
  ScreenPort,Viewport:trect;
  case byte of
    0:(offsb:byte);
    1:(offsw:word);
    1:(offsd:dword);       {width of the screen in bytes}

end;

BitmapTypeptr=^BitmapType;
Bitmaptype=record
  bitmaptype:byte;
  size:pointtype;
  planesize:dword;
  BitsPerPixel:byte;
  bitplanes:byte;
  xoff:word;
  Qbitoffset:byte;       {used in plainiar colour modes for fast drawing}
  memallocated:boolean;
  case byte of
  0:(flatdata:bytearray);
  1:(planedata:array[0..3]of bytearray);
end;

textlineptr=^textline;
textline=array[0..79] of word;
fillpatterntype=array[0..7] of byte;
fillptr=^fillpatterntype;

var
SC:ScreenDataType;  {screen context}
BC:ScreenDataType;  {bitmap context}

{Current Colours & writemode }
T_fillcol,T_col,T_writemode:byte;
tcharset:charsettype;
{for fill patterns}

maskword:word;
maskbyte:byte absolute maskword;
fillpattern:fillpatterntype;
maskbackground:boolean;
nullpattern:boolean;

{global rectangle information}
lastrect:prectlist;
Rectlist_status:byte;
Rect_count:byte;

procedure destroyplist(p:prectlist);
function CreateBitmap(xlen_,ylen_:word;bitplanes_,mode:byte):BitmapTypeptr;
function CreateBitmapFromSource(newpic:bitmaptypeptr;xlen_,ylen_:word;bitplanes_,mode:byte;src:bytearray):BitmapTypeptr;
procedure DestroyBitmap(Bitmap:BitmapTypeptr);
procedure ResizeBitmap(xlen_,ylen_:word;Bitmap:BitmapTypeptr);
function insiderect(x1,y1,x2,y2,x,y:integer):boolean;


IMPLEMENTATION

function insiderect(x1,y1,x2,y2,x,y:integer):boolean;
begin
  insiderect:=(x>=x1)and(y>=y1)and(x<=x2)and(y<=y2);
end;

function CreateBitmap(xlen_,ylen_:word;bitplanes_,mode:byte):BitmapTypeptr;
var
  bitlop:byte;
  newpic:BitmapTypeptr;
begin
  newpic:=new(BitmapTypeptr);
  with newpic^ do begin
    size.x:=xlen_;
    size.y:=ylen_;
    bitmaptype:=mode;
    Qbitoffset:=0;

    case mode of
      BMflat:begin
        BitsPerPixel:=8;
        bitplanes:=1;
        xoff:=size.x;
        planesize:=xoff*size.y;
        getmem(pointer(flatdata),planesize);
      end;
      BMplanes:begin
        xoff:=(size.x shr 3)+1;
        bitplanes:=bitplanes_;
        planesize:=xoff*size.y;
        for bitlop:=0 to 3 do begin
        getmem(pointer(planedata[bitlop]),planesize);
        end;

      end;
    end;
    memallocated:=true;
  end;
  CreateBitmap:=newpic;
end;

function CreateBitmapFromSource(newpic:bitmaptypeptr;xlen_,ylen_:word;bitplanes_,mode:byte;src:bytearray):BitmapTypeptr;
var
  bitlop:byte;

begin
  if (newpic=nil) then
     newpic:=new(BitmapTypeptr);
  with newpic^ do begin
    size.x:=xlen_;
    size.y:=ylen_;
    bitmaptype:=mode;
    Qbitoffset:=0;

    case mode of
      BMflat:begin
        BitsPerPixel:=8;
        bitplanes:=1;
        xoff:=size.x;
        planesize:=xoff*size.y;
        flatdata:=src;
      end;
      BMplanes:begin
        xoff:=(size.x shr 3);
        bitplanes:=bitplanes_;
        planesize:=xoff*size.y;
        for bitlop:=0 to 3 do begin
           planedata[bitlop]:=src;
           inc(src,planesize);
        end;

      end;
    end;
    memallocated:=false;
  end;
  CreateBitmapFromSource:=newpic;
end;


procedure ResizeBitmap(xlen_,ylen_:word;bitmap:BitmapTypeptr);
begin
  with bitmap^ do begin
    size.x:=xlen_;
    size.y:=ylen_;

    case bitmaptype of
      BMplanes:begin
        xoff:=(size.x shr 3);
        planesize:=xoff*size.y;
      end;
      BMflat:
        planesize:=size.x*size.y;
    end;
  end;
end;

procedure DestroyBitmap(Bitmap:BitmapTypeptr);
var i:byte;
begin
  with Bitmap^ do
    case bitmaptype of
      BMplanes:freemem(pointer(flatdata),planesize*bitplanes);
      BMflat:freemem(pointer(flatdata),planesize);
    end;
  Dispose(Bitmap);
end;


function Trect.Clipin(var xa,ya,xb,yb:integer):boolean;
Function outcode(xa,ya:integer):byte;
Begin
  outcode:=(byte(xa<x2))+     {right  =$01}
           (byte(ya<y2)shl 1)+{bellow =$02}
           (byte(xa>x1)shl 2)+{left   =$04}
           (byte(ya>y1)shl 3) {above  =$08};
end;
{clip a line against 'viewport'}
var code0,code1:byte;
Begin
  While 0=0 do begin
    code1:=outcode(xa,ya);code0:=outcode(xb,yb);
    if (code0 and code1)=code1 then begin
      clipin:=false;exit{Trivial accept}
    end else begin
      if not(code0 or code1)=code1 then begin
         clipin:=true;exit;{Trivial reject}
      end else If (code0=0) then begin
        fswap(code1,code0,1);
        fswap(xa,xb,2);
        fswap(ya,yb,2);
      end;
      if (code0 and bellow)<>0 then begin
        inc(xa,-(xa-xb)*(y2-yb)div(ya-yb));
        ya:=y2;
      end else if (code0 and above)<>0 then begin
        inc(xa,-(xa-xb)*(y1-yb)div(ya-yb));
        ya:=y1;
      end else if (code0 and right)<>0 then begin
        dec(ya,-(ya-yb)*(x2-xb)div(xa-xb));
        xa:=x2;
      end else if (code0 and left)<>0 then begin
        inc(ya,-(ya-yb)*(x1-xb)div(xa-xb));
        xa:=x1;
      end;
    end;
  end;
end;


function Trect.Clipout(var xa,ya,xb,yb:integer):boolean;
Function outcode(xa,ya:integer):byte;
Begin
  outcode:=(byte(xa>x2))+     {right  =$01}
           (byte(ya>y2)shl 1)+{bellow =$02}
           (byte(xa<x1)shl 2)+{left   =$04}
           (byte(ya<y1)shl 3) {above  =$08};
end;
{clip a line against 'viewport'}
var code0,code1:byte;
Begin
  While 0=0 do begin
    code1:=outcode(xa,ya);code0:=outcode(xb,yb);
    if (code0 and code1)=code1 then begin
      clipout:=false;exit{Trivial accept}
    end else begin
      if not(code0 or code1)=code1 then begin
         clipout:=true;exit;{Trivial reject}
      end else If (code0=0) then begin
        fswap(code1,code0,1);
        fswap(xa,xb,2);
        fswap(ya,yb,2);
      end;
      if (code0 and bellow)<>0 then begin
        inc(xa,(xa-xb)*(y2-yb)div(ya-yb));
        ya:=y2;
      end else if (code0 and above)<>0 then begin
        inc(xa,(xa-xb)*(y1-yb)div(ya-yb));
        ya:=y1;
      end else if (code0 and right)<>0 then begin
        dec(ya,(ya-yb)*(x2-xb)div(xa-xb));
        xa:=x2;
      end else if (code0 and left)<>0 then begin
        inc(ya,(ya-yb)*(x1-xb)div(xa-xb));
        xa:=x1;
      end;
    end;
  end;
end;

procedure bytepointtype.moveto(x_,y_:byte);
begin
 x:=x_;
 y:=y_;
end;


procedure pointtype.moveto(x_,y_:integer);
begin
 x:=x_;
 y:=y_;
end;

procedure Trect.Rmove(xa,ya:integer);
{begin
  inc(x1,xa);
  inc(x2,xa);
  inc(y1,ya);
  inc(y2,ya);
end;}
assembler;
asm
  les di,self
  mov ax,xa ;mov bx,ya
  add es:[di],ax
  add es:[di+2],bx
  add es:[di+4],ax
  add es:[di+6],bx
end;

procedure Trect.Rgrow(xg,yg:integer);
{begin
  dec(x1,xg);
  dec(y1,yg);
  inc(x2,xg);
  inc(y2,yg);
end;}
assembler;
asm
  les di,self
  mov ax,xg; sub es:[di],ax
  mov ax,yg; sub es:[di+2],ax
  mov ax,xg; add es:[di+4],ax
  mov ax,yg; add es:[di+6],ax
end;

procedure Trect.Rpos(xp,yp:integer);
{var w,h:integer;
begin
  w:=x2-x1;
  h:=y2-y1;
  x1:=xp;    y1:=yp;
  x2:=xp+w;  y2:=yp+h;
end;}

assembler;
asm
  les di,self
  mov ax,es:[di+offset x2] {load x2}
  mov bx,es:[di+offset y2] {load y2}

  sub ax,es:[di+offset x1] {get width}
  sub bx,es:[di+offset y1] {get height}

  mov cx,xp
  mov dx,yp
  mov es:[di+offset x1],cx {calc x1}
  mov es:[di+offset y1],dx {calc y1}

  add ax,cx
  add bx,dx
  mov es:[di+offset x2],ax {calc x2}
  mov es:[di+offset y2],bx {calc y2}
end;

procedure Trect.Rassign(x1_,y1_,x2_,y2_:integer);assembler;
asm

  les di,self
  mov ax,x1_; mov es:[di+offset x1],ax
  mov ax,y1_; mov es:[di+offset y1],ax
  mov ax,x2_; mov es:[di+offset x2],ax
  mov ax,y2_; mov es:[di+offset y2],ax
end;
{
begin
  x1:=x1_;
  y1:=y1_;
  x2:=x2_;
  y2:=y2_;
end;}


function Trect.overlap(const r:trect):boolean;
{begin
  overlap:=(r.x2>=x1)and (r.x1<=x2)and(r.y2>=y1)and (r.y1<=y2);
end;}
assembler;
asm
  les di,self   {point to rectangles}
  push ds
  lds si,r
  mov al,false
    mov bx,ds:[si+offset x1]; cmp bx,es:[di+offset x2]; jg @end
    mov bx,ds:[si+offset y1]; cmp bx,es:[di+offset y2]; jg @end
    mov bx,ds:[si+offset x2]; cmp bx,es:[di+offset x1]; jl @end
    mov bx,ds:[si+offset y2]; cmp bx,es:[di+offset y1]; jl @end
  mov al,true
  @end:
  pop ds
  end;


function Trect.empty:boolean;
{begin
  empty:=(x1=x2)and(y1=y2);
end;}
assembler;
asm
  les di,self
  mov al,false
  mov bx,es:[di+offset x1] ;cmp bx,es:[di+offset x2]
  jnz @end
  mov bx,es:[di+offset y1] ;cmp bx,es:[di+offset y2]
  jnz @end
  mov al,true
  @end:
end;

procedure Trect.union(const r:trect);assembler;
{
begin
  if (r.x2>x2) then x2:=r.x2;
  if (r.y2>y2) then y2:=r.y2;
  if (r.x1<x1) then x1:=r.x1;
  if (r.y1<y1) then y1:=r.y1;
end;
}


asm
  les di,self
  push ds
  lds si,r

  mov ax,ds:[si+offset x2] ;cmp ax,es:[di+offset x2]
  jle @nochangex2
    mov es:[di+offset x2],ax
  @nochangex2:

  mov ax,ds:[si+offset y2] ;cmp ax,es:[di+offset y2]
  jle @nochangey2
    mov es:[di+offset y2],ax
  @nochangey2:

  mov ax,ds:[si+offset x1] ;cmp ax,es:[di+offset x1]
  jge @nochangex1
    mov es:[di+offset x1],ax
  @nochangex1:

  mov ax,ds:[si+offset y1] ;cmp ax,es:[di+offset y1]
  jge @nochangey1
    mov es:[di+offset y1],ax
  @nochangey1:
  pop ds
end;


function Trect.intersect(const r:trect):boolean;
{begin
  if (r.x2>=x1)and (r.x1<=x2)and(r.y2>=y1)and (r.y1<=y2) then begin
    if (r.x1>=x1)and(r.x1<=x2) then x1:=r.x1;
    if (r.y1>=y1)and(r.y1<=y2) then y1:=r.y1;
    if (r.x2>=x1)and(r.x2<=x2) then x2:=r.x2;
    if (r.y2>=y1)and(r.y2<=y2) then y2:=r.y2;
    intersect:=true;
  end else begin
    fillchar(x1,8,0);
    intersect:=false;
  end;
end;}

assembler;
asm
  les di,self   {point to rectangles}
  push ds
  lds si,r
  mov ax,ds:[si+offset x1]; cmp ax,es:[di+offset x2]; jg @end
  mov bx,ds:[si+offset y1]; cmp bx,es:[di+offset y2]; jg @end
  mov cx,ds:[si+offset x2]; cmp cx,es:[di+offset x1]; jl @end
  mov dx,ds:[si+offset y2]; cmp dx,es:[di+offset y1]; jl @end

  {if (r.x1>=x1)and(r.x1<=x2) then x1:=r.x1;}
  cmp ax,es:[di+offset x2]; jg @endx1
  cmp ax,es:[di+offset x1]; jl @endx1
    mov es:[di+offset x1],ax;
  @endx1:
  {if (r.y1>=y1)and(r.y1<=y2) then y1:=r.y1;}
  cmp bx,es:[di+offset y2]; jg @endy1
  cmp bx,es:[di+offset y1]; jl @endy1
    mov es:[di+offset y1],bx
  @endy1:
  {if (r.x2>=x1)and(r.x2<=x2) then x2:=r.x2;}
  cmp cx,es:[di+offset x1]; jl @endx2
  cmp cx,es:[di+offset x2]; jg @endx2
    mov es:[di+offset x2],cx
  @endx2:
  {if (r.y2>=y1)and(r.y2<=y2) then y2:=r.y2;}
  cmp dx,es:[di+offset y1]; jl @endy2
  cmp dx,es:[di+offset y2]; jg @endy2
    mov es:[di+offset y2],dx
  @endy2:
  mov al,true           {intersection was made, return true}
  jmp @noclear
  @end:
    xor ax,ax           {fill rectangle with 0's and return with false}
    mov cx,4
    rep stosw
  @noclear:
  pop ds
end;



function trect.inside(const r:trect):boolean;assembler;
{begin
  inside:=(x1>=r.x1)and(x2<=r.x2)and(y1>=r.y1)and(y2<=r.y2);
end;
}

asm
  les di,self
  push ds
  lds si,r
  mov al,0                                           {set to zero -not inside}
  mov bx,[si+offset x1] ;cmp bx,es:[di+offset x1]
  jg @end
  mov bx,[si+offset y1] ;cmp bx,es:[di+offset y1]
  jg @end
  mov bx,[si+offset x2] ;cmp bx,es:[di+offset x2]
  jl @end
  mov bx,[si+offset y2] ;cmp bx,es:[di+offset y2]
  jl @end
  mov al,1                                            {if you get to here then it is inside}

  @end:
  pop ds
end;

function Trect.contains(x,y:integer):boolean;
begin
  contains:=(x>=x1)and(y>=y1)and(x<=x2)and(y<=y2);
end;
(*assembler;asm
  les di,self
  mov bx,x                                           {load up x..}
  mov cx,y                                           {..and y}

  mov al,0                                           {set to zero -not inside}
  cmp bx,es:[di+offset x1]
  jl @end
  cmp cx,es:[di+offset y1]
  jl @end
  cmp bx,es:[di+offset x2]
  jg @end
  cmp cx,es:[di+offset y2]
  jg @end

  mov al,1                                            {if you get to here then it is inside}
  @end:
end;*)

Function Trect.equals(const r:trect):boolean;
begin
  equals:=(x1=r.x1)and(y1=r.y1)and(x2=r.x2)and(y2=r.y2);
end;
(*assembler;asm
  les di,self
  push ds
  lds si,r
  mov al,0                                           {set to zero -not equal}
  mov bx,ds:[si+offset x1] ;cmp bx,es:[di+offset x1]
  jnz @end
  mov bx,ds:[si+offset y1] ;cmp bx,es:[di+offset y1]
  jnz @end
  mov bx,ds:[si+offset x2] ;cmp bx,es:[di+offset x2]
  jnz @end
  mov bx,ds:[si+offset y2] ;cmp bx,es:[di+offset y2]
  jnz @end
  mov al,1                                            {if you get to here then it is equal}

  @end:
  pop ds
end;*)


function Trect.concatable(const r:trect):boolean;
begin
  concatable:=((r.x2>=x1-1)and(r.x1<=x2+1)and(r.y1=y1)and(r.y2=y2))
        or    ((r.x1=x1)and(r.x2=x2)and(r.y2>=y1-1)and(r.y1<=y2+1));
end;
(*assembler;asm
  les di,self
  push ds
  lds si,r
  mov ax,es:[di+offset x1]
  mov bx,es:[di+offset y1]
  mov cx,es:[di+offset x2]
  mov dx,es:[di+offset y2]
  mov di,ax
  mov al,false                  {preset to false}

  dec di; inc cx                {dec and inc for compare}
  {(r.x2>=x1-1)and(r.x1<=x2+1)and(r.y1=y1)and(r.y2=y2)}
  cmp ds:[si + offset x2],di; jl  @half
  cmp ds:[si + offset x1],cx; jg  @half
  cmp ds:[si + offset y1],bx; jne @half
  cmp ds:[si + offset y2],dx; jne @half
  mov al,true
  jmp @end
  @half:
  inc di; dec cx               {get these back to original size}
  dec bx; inc dx               {dec and inc for compare}
  cmp ds:[si + offset x1],di; jne @end
  cmp ds:[si + offset x2],cx; jne @end
  cmp ds:[si + offset y2],bx; jl  @end
  cmp ds:[si + offset y1],dx; jg  @end
  mov al,true
  @end:
  pop ds                        {restore data segment}
end;*)

(*
function Trect.cutfrom(r:trect):prectlist;

var newlist,nextrect,firstrect:prectlist;
    ovrlap:boolean;

begin
  Rect_count:=0;
  ovrlap:=r.intersect(self);
  if (not equals(r)) then begin
    if not ovrlap then begin
      new(nextrect);
      nextrect^.rassign(x1,y1,x2,y2);
      newlist:=nextrect;
      rectlist_status:=RSnooverlap;
    end else begin
      new(firstrect);
      nextrect:=firstrect;
      if y1<>r.y1 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        inc(rect_count); newlist:=nextrect;
        nextrect^.rassign(x1,y1,x2,r.y1-1);
        if nextrect^.y1<y1 then nextrect^.y1:=y1;
      end;
      if x1<>r.x1 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(x1,r.y1,r.x1-1,r.y2);
        if nextrect^.x1<x1 then nextrect^.x1:=x1;
      end;
      if x2<>r.x2 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(r.x2+1,r.y1,x2,r.y2);
        if nextrect^.x2>x2 then nextrect^.x2:=x2;
      end;
      if y2<>r.y2 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(x1,r.y2+1,x2,y2);
        if nextrect^.y1>y2 then nextrect^.y1:=y2;
      end;
      rectlist_status:=RSlist;
      dispose(firstrect);
    end;
    lastrect:=nextrect;
    cutfrom:=newlist;
    nextrect^.next:=nil;
  end else begin
    cutfrom:=nil;
    rectlist_status:=RSobscured
  end;
end;

procedure destroyplist(p:prectlist);
var curr_p,next_p:prectlist;
begin
  curr_p:=p;
  while curr_p<>nil do begin
    next_p:=curr_p^.next;
    dispose(curr_p);
    curr_p:=next_p;
  end;
end;
*)

function Trect.cutfrom(r:trect):prectlist;

var newlist,nextrect,firstrect:prectlist;
    ovrlap:boolean;

begin
  Rect_count:=0;
  ovrlap:=r.intersect(self);
  if (not equals(r)) then begin
    if not ovrlap then begin
      new(nextrect);
      nextrect^.rassign(x1,y1,x2,y2);
      newlist:=nextrect;
      rectlist_status:=RSnooverlap;
    end else begin
      new(firstrect);
      nextrect:=firstrect;
      if y1<>r.y1 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        inc(rect_count); newlist:=nextrect;
        nextrect^.rassign(x1,y1,x2,r.y1-1);
        if nextrect^.y1<y1 then nextrect^.y1:=y1;
      end;
      if x1<>r.x1 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(x1,r.y1,r.x1-1,r.y2);
        if nextrect^.x1<x1 then nextrect^.x1:=x1;
      end;
      if x2<>r.x2 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(r.x2+1,r.y1,x2,r.y2);
        if nextrect^.x2>x2 then nextrect^.x2:=x2;
      end;
      if y2<>r.y2 then begin
        new(nextrect^.next); nextrect:=nextrect^.next;
        if rect_count=0 then newlist:=nextrect;
        inc(rect_count);

        nextrect^.rassign(x1,r.y2+1,x2,y2);
        if nextrect^.y1>y2 then nextrect^.y1:=y2;
      end;
      rectlist_status:=RSlist;
      dispose(firstrect);
    end;
    lastrect:=nextrect;
    cutfrom:=newlist;
    nextrect^.next:=nil;
  end else begin
    cutfrom:=nil;
    rectlist_status:=RSobscured
  end;
end;


procedure destroyplist(p:prectlist);
var curr_p,next_p:prectlist;
begin
  curr_p:=p;
  while curr_p<>nil do begin
    next_p:=curr_p^.next;
    dispose(curr_p);
    curr_p:=next_p;
  end;
end;





Function Trect.width:integer;
begin
   width:=x2-x1;
end;

Function Trect.height:integer;
begin
   height:=y2-y1;
end;

Function Trect.halfx:integer;
begin
  halfx:=(x2-x1) shr 1;
end;

{assembler;
asm
  les di,self
  mov ax,es:[di+offset x2]
  sub ax,es:[di+offset x1]
  shr ax,1
end;}

Function Trect.halfy:integer;
begin
  halfy:=(y2-y1) shr 1;
end;
{

assembler;
asm
  les di,self
  mov ax,es:[di+offset y2]
  sub ax,es:[di+offset y1]
  shr ax,1
end;}
end.

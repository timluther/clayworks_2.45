Unit Ggraph;
{Generic Graphics unit}

{$DEFINE VGA256}
{$DEFINE XVGA256}
{$DEFINE SVGA256}
{$DEFINE VGA16}
{$DEFINE BITMAP16}
{$DEFINE BITMAP25}

INTERFACE
{stuff to be preserved for mouse inter:
  GRPH_ADDR
  3,logicmode
  0,colour
  5,WriteMode (Normaly 3)
  4,ReadMask
}

uses {$IFDEF XVGA256}xvga256,{$ENDIF}
     {$IFDEF VGA256}vga256,{$ENDIF}
     {$IFDEF SVGA256}svga256,{$ENDIF}
     {$IFDEF VGA16}vga16,{$ENDIF}
     {$IFDEF BITMAP16}bitmap16,{$ENDIF}
     {$IFDEF bitmap25}bitmap25,{$ENDIF}
gbasics,chardef,ttypes,dos,colour,tmaths;



Const

{active and visual page indicies}
active:byte=0;
visual:byte=1;

ctext=$3;
bwtext=$2;
allplanes=3841;

{****-mouse draw modes-*****}
MSdrawold=1;
MSdrawpointer=2;
MSdrawboth=3;

Type
Piclist=^piclist_;
piclist_=array[0..0] of bitmaptypeptr;

const
Normal=0;
pingpong=1;
type
Animtype=object
  numframes,mode,curframe:byte;
  frames:piclist;
  direction:shortint;

  constructor create(mode_,numframes_,start:byte);
  Procedure Play(x,y:integer);
  destructor done;
end;

set_modeproc=function (mode:byte):boolean;
GetBitmapProc=function(x1,y1,x2,y2:integer):Bitmaptypeptr;
PutBitmapProc=procedure(x,y:integer;bitmap:bitmaptypeptr);
QuadProc=procedure(x1,y1,x2,y2:integer);
TriProc=procedure(a,b,c:integer);
GTriAngleProc=procedure(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);
TriAngleProc=procedure(xa,ya,xb,yb,xc,yc:integer);
NoParamProc=procedure;
PutPixelProc=procedure(x1,y1:integer);
GetPixelProc=function(x1,y1:integer):byte;
OutTextxyProc=procedure(x1,y1:integer;txt:string);
OutTextxylengthProc=procedure(x1,y1:integer;txt:pchar;length:byte);
DrawBytesProc=procedure(x1,y:Integer;pic:bytearray;nbytes:byte);
DrawBytesxyProc=procedure(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
ScreenCopyProc=procedure(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
QwriteProc=procedure(count:word);
QgetProc=function:byte;
PolygonProc=procedure(points:pointtypeptr;numpoints:byte);


Procedure Qpop;
Procedure Qpush;
Procedure Qnextline;

Procedure BMQpop;
Procedure BMQpush;
Procedure BMQnextline;

Procedure thickrectangle(x1,y1,x2,y2,thickness:integer);
Procedure rectangle(x1,y1,x2,y2:integer);

function initgraph(var screen:screenidtype):boolean;
procedure closegraph;

Procedure Setbase(scrnbase:word);
Procedure waitvbl;
procedure pageswap;
Procedure Setvisualpage(pageno:byte);
Procedure Setactivepage(pageno:byte);
Procedure setoffset(offst:byte);

procedure setlinepattern(pattern:byte;background:boolean);
procedure setfillpattern(const pattern:fillpatterntype;background:boolean);
procedure setsolidfill;

Procedure SetBitmapContext(data:bitmaptypeptr);
{Procedure SetGraphicsContext(scrtype:byte;data:dword);}

var
set_mode:set_modeProc;
bar,BMbar:QuadProc;
GTriangle,BMGTriangle:GTriAngleProc;
Triangle,BMTriangle:TriangleProc;
polygon,BMpolygon:PolygonProc;
line,BMline:QuadProc;
Hline,BMHline:TriProc;
Vline,BMVline:TriProc;
ClearDevice,BMClearDevice:NoParamProc;
putpixel,BMputpixel:putpixelproc;
getpixel,BMgetpixel:getpixelproc;
outtextxy,BMouttextxy:outtextxyproc;
outtextxy_length,BMouttextxy_length:outtextxylengthproc;
DrawBytes,BMDrawBytes:DrawBytesProc;
DrawBytesxy,BMDrawBytesxy:DrawBytesxyProc;
ScreenCopy,BMScreenCopy:ScreencopyProc;
PutBitmap,BMPutBitmap:PutBitmapProc;
GetBitmap,BMGetBitmap:GetBitmapProc;
Qsetxy,BMQsetxy:putpixelproc;
Qwrite,BMQwrite:QwriteProc;
Qget,BMQget:Qgetproc;
savescreenregs:procedure;
restorescreenregs:procedure;

mousepicadrs:^word;

const
maxgreyfills=31;
greyfills:array[0..31]of fillpatterntype=((0,0,0,0,0,0,0,0),(0,0,0,0,16,0,0,0),
(0,0,8,0,0,64,2,0),(0,64,0,2,0,32,4,0),(0,32,4,128,0,16,130,0),
(0,68,0,17,0,68,0,17),(0,132,32,1,0,84,0,17),(0,34,0,73,0,34,0,73),
(0,162,0,73,0,170,0,73),(16,170,1,170,16,170,68,9),
(16,170,65,170,20,170,84,9),(17,170,69,170,17,170,84,9),
(81,170,69,170,17,170,85,138),(81,170,85,170,17,170,85,170),
(85,170,81,170,21,170,85,170),(85,170,85,170,85,170,85,170),(85,170,85,170,93,170,85,170),
(85,170,87,170,117,170,85,170),(87,170,85,170,119,170,85,170),
(87,170,93,170,119,170,85,186),(119,170,93,170,119,170,213,123),
(247,170,95,170,245,170,213,123),(247,170,127,170,247,170,221,123),
(255,174,255,91,255,170,255,91),(255,187,255,214,255,187,255,214),
(255,111,251,223,255,117,255,221),(255,238,255,187,255,238,255,187),
(255,239,253,191,255,247,190,255),(255,223,255,254,255,239,253,255),
(255,255,251,255,255,223,254,255),(255,255,255,255,247,255,255,255),
(255,255,255,255,255,255,255,255));

solidfill:fillpatterntype=(255,255,255,255,255,255,255,255);
emptyfill:fillpatterntype=(0,0,0,0,0,0,0,0);
midgreyfill:fillpatterntype=(170,85,170,85,170,85,170,85);

var
{oldscreen:array[0..3999] of byte;}
oldcrsx,oldcrsy:byte;

IMPLEMENTATION

procedure setlinepattern(pattern:byte;background:boolean);assembler;
asm
  mov al,pattern
  mov ah,al
  mov maskword,ax
  mov al,background
  mov maskbackground,al
end;

procedure setfillpattern(const pattern:fillpatterntype;background:boolean);
var i:byte;
begin
  fillpattern:=pattern;
  nullpattern:=true;
  i:=0;
  while (nullpattern=true)and(i<8) do begin
    nullpattern:=solidfill[i]=pattern[i];
    inc(i);
  end;
  maskbackground:=background;
end;

procedure setsolidfill;
begin
  maskbackground:=false;
  nullpattern:=true;
  maskword:=$ffff;
end;


Procedure pageswap;begin
  visual:=visual xor 1;active:=active xor 1;
  setactivepage(active);setvisualpage(visual);
end;

Procedure setoffset(offst:byte);assembler;
asm
  mov dx,CRTC_ADDR         {load dx with CRT controller address}
  mov al,$1                {function $1}
  mov ah,offst             {screen offset}
  out dx,ax                {write to port}

  mov al,$13               {funtion $13}
  out dx,ax                {write to port}

  mov al,0                 {function 0}
  shl ah,1                 {half offset}
  out dx,ax                {write to port}

  mov byte ptr SC.offsd,ah              {set my offset value}
end;

procedure mapmask(mask:byte);assembler;
asm
  mov dx,SEQU_ADDR;             {load Sequencer}
  mov al,2; mov ah,mask         {function 2, mask}
  out dx,ax                     {write to port}
end;

procedure readmask(plane:byte);assembler;
asm
  mov dx,GRPH_ADDR              {Load graphics address}
  mov al,4                      {function 4-set readmask}
  mov ah,plane                  {Planes to mask}
  out dx,ax                     {write to port}
end;

Procedure Setvisualpage(pageno:byte);   {set page that is displayed}
begin
  setbase(pageno*SC.pagesize);
end;

Procedure Setactivepage(pageno:byte);
begin
  SC.scrptr:=ptr($a000,pageno*SC.pagesize);
end;

Procedure memorymode(mask:byte);assembler;
asm
  mov dx,SEQU_ADDR               {write to sequencer}
  mov al,4                       {function 4-memory modes}
  mov ah,mask                    {set up mask}
  out dx,ax                      {write to port}
end;

{address mode control the way in which data is written to the screen.
3=No bitmask needed.
1=use bitmask.
0=32 bit screen to screen transfer.
}
Procedure adrsmode(mask:byte);assembler;
asm
  mov dx,GRPH_ADDR               {Graphics address}
  mov al,5;                      {function 5, address mode}
  mov ah,mask;                   {load mode}
  out dx,ax                      {write to port}
end;

Procedure Setbase(scrnbase:word);assembler;
asm
  mov dx,CRTC_ADDR               {CRT controller}
  mov bx,scrnbase                {base of screen}
  mov al,$C ;mov ah,bh           {load up low bits}
  out dx,ax                      {write to port}
  inc al    ;mov ah,bl           {load up high bits}
  out dx,ax                      {write to port}
end;


{wait for vertiacal blank}
Procedure waitvbl;assembler;
Asm
  mov dx,STATUS_ADDR   {load status address}
  @runloop:
    in al,dx           {get status}
    test al,08h        {is it equal to al?}
  jz @runloop          {if not then loop}
end;

procedure setcurs(x,y:byte);assembler;
  asm
    mov ah,02h
    mov bh,0
    mov dh,x
    mov dl,y
    int 10h
  end;

procedure getcurs(var x,y:byte);assembler;
asm
  mov ah,03h
  mov bh,0
  int 10h
  les di,x
  mov es:[di],dh
  les di,y
  mov es:[di],dl
end;

{data is either a pointtype or a bitmap}
Procedure SetGraphicsContext(scrtype:byte{;data:dword});
var i:byte;
begin
  {set up screen address -$a000 for screens, supplied address for bitmaps}
end;


Procedure SetBitmapContext(data:bitmaptypeptr);
var
i:byte;
coffset:integer;
begin
  BC.bitplanes:=data^.bitplanes;
  BC.offsd:=data^.xoff;
  BC.size:=data^.size;
  BC.screenport.rassign(0,0,BC.size.x-1,BC.size.y-1);
  BC.viewport:=BC.screenport;
  BC.pagesize:=data^.planesize;
  BC.qbitoffset:=128;
  BC.scrptr:=data^.flatdata;
  BC.qoffset:=0;
  coffset:=0;
  for i:=0 to BC.size.y do begin
    BC.startoffsets[i]:=coffset;
    inc(coffset,BC.offsd);
  end;

 {if BC.Driver<>data^.bitmaptype then }begin
    BC.Driver:=data^.bitmaptype;
    case BC.driver of
      255:;
      {$IFDEF Bitmap25}
      BMflat:begin
        BMbar:=bitmap25.bar;
        BMGTriangle:=bitmap25.GTriangle;
        BMTriangle:=bitmap25.Triangle;
        BMline:=bitmap25.line;
        BMHline:=bitmap25.hline;
        BMVline:=bitmap25.vline;
        BMClearDevice:=bitmap25.ClearDevice;
        BMPutPixel:=bitmap25.putpixel;
        BMGetPixel:=bitmap25.getpixel;
        BMOuttextxy:=bitmap25.Outtextxy;
        BMDrawBytes:=bitmap25.drawbytes;
        BMPutBitmap:=bitmap25.putbitmap;
        BMGetBitmap:=bitmap25.getbitmap;
        BMQsetxy:=bitmap25.Qsetxy;
        BMQget:=bitmap25.Qget;
        BMQwrite:=bitmap25.Qwrite;
      end;
      {$ENDIF}
      {$IFDEF BITMAP16}
      BMplanes:begin

        for i:=0 to data^.bitplanes-1 do
          BC.scrptrs[i]:=data^.planedata[i];
        BMputpixel:=bitmap16.putpixel;
        BMgetpixel:=bitmap16.getpixel;
        BMcleardevice:=bitmap16.cleardevice;
        BMqsetxy:=bitmap16.qsetxy;
        BMqwrite:=bitmap16.qwrite;
        BMqget:=bitmap16.qget;
      end;
      {$ENDIF}
    end;
  end;
end;

{set graphics mode and setup varilbes}
function initgraph(var screen:screenidtype):boolean;
var
    installed:boolean;
    i,tempoffset:word;
Begin

    SC.Driver:=Screen.Driver;
    SC.graphmode:=Screen.Graphmode;

    case SC.driver of
      {$IFDEF vga256}
      STvga_flat:begin
        set_mode:=vga256.set_mode;
        bar:=vga256.bar;
        GTriangle:=vga256.GTriangle;
        Triangle:=vga256.Triangle;
        line:=vga256.line;
        Hline:=vga256.hline;
        Vline:=vga256.vline;
        ClearDevice:=vga256.ClearDevice;
        PutPixel:=vga256.putpixel;
        GetPixel:=vga256.getpixel;
        Outtextxy:=vga256.Outtextxy;
        Outtextxy_length:=vga256.outtextxy_length;
        DrawBytes:=vga256.drawbytes;
        DrawBytesxy:=vga256.drawbytesxy;
        ScreenCopy:=vga256.screencopy;
        PutBitmap:=vga256.putbitmap;
        GetBitmap:=vga256.getbitmap;
        Qsetxy:=vga256.Qsetxy;
        Qget:=vga256.Qget;
        Qwrite:=vga256.Qwrite;
        savescreenregs:=vga256.savescreenregs;
        restorescreenregs:=vga256.restorescreenregs;
        {Polygon:=vga256.polygon;}
      end;
      {$endif}
      {$ifdef SVGA256}
      STsvga_flat:begin
        set_mode:=svga256.set_mode;
        bar:=svga256.bar;
        GTriangle:=svga256.GTriangle;
        Triangle:=svga256.Triangle;
        line:=svga256.line;
        Hline:=svga256.hline;
        Vline:=svga256.vline;
        ClearDevice:=svga256.ClearDevice;
        PutPixel:=svga256.putpixel;
        GetPixel:=svga256.getpixel;
        Outtextxy:=svga256.Outtextxy;
        Outtextxy_length:=svga256.outtextxy_length;
        DrawBytes:=svga256.drawbytes;
        DrawBytesxy:=svga256.drawbytesxy;
        ScreenCopy:=svga256.screencopy;
        PutBitmap:=svga256.putbitmap;
        GetBitmap:=svga256.getbitmap;
        Qsetxy:=svga256.Qsetxy;
        Qget:=svga256.Qget;
        Qwrite:=svga256.Qwrite;
        savescreenregs:=svga256.savescreenregs;
        restorescreenregs:=svga256.restorescreenregs;
      end;
      {$endif}
      {$IFDEF VGA16}
      STvga_plainiar:begin
        set_mode:=vga16.set_mode;
        bar:=vga16.bar;
        GTriangle:=vga16.GTriangle;
        Triangle:=vga16.Triangle;
        line:=vga16.line;
        Hline:=vga16.hline;
        Vline:=vga16.vline;
        ClearDevice:=vga16.ClearDevice;
        PutPixel:=vga16.putpixel;
        GetPixel:=vga16.getpixel;
        Outtextxy:=vga16.Outtextxy;
        Outtextxy_length:=vga16.outtextxy_length;
        DrawBytes:=vga16.drawbytes;
        DrawBytesxy:=vga16.drawbytesxy;
        ScreenCopy:=vga16.screencopy;
        PutBitmap:=vga16.putbitmap;
        GetBitmap:=vga16.getbitmap;
        Qsetxy:=vga16.Qsetxy;
        Qget:=vga16.Qget;
        Qwrite:=vga16.Qwrite;
        savescreenregs:=vga16.savescreenregs;
        restorescreenregs:=vga16.restorescreenregs;
      end;
      {$endif}
    end;


    SC.colourdepth:=Screen.Colourdepth;
    SC.size:=Screen.Size;
    SC.bitplanes:=Screen.Bitplanes;
    SC.scrptr:=ptr($a000,00);
    SC.bitsperpixel:=SC.colourdepth shr SC.bitplanes;
    SC.offsd:=SC.size.x;
    if SC.driver=STvga_plainiar then
    SC.offsd:=SC.offsd shr 3;
    SC.screenport.rassign(0,0,SC.size.x-1,SC.size.y-1);

    SC.viewport:=SC.screenport;
    SC.pagesize:=SC.size.y*SC.offsd;


    SC.Qbitoffset:=128;
    SC.Qoffset:=0;{SC.Scrptr;}
    SC.nopages:=4;
    installed:=set_mode(SC.graphmode);
    initcolours(SC.colourdepth);
    {getmem(SC.startoffsets,SC.Size.y shl 1);}
    tempoffset:=0;
    for i:=0 to SC.Size.y do begin

      SC.startoffsets[i]:=tempoffset;
      inc(tempoffset,SC.offsw);
    end;


    t_fillcol:=0;
    t_col:=SC.ColourDepth-1;
    t_writemode:=0;
    maskbyte:=255;
    setsolidfill;
    cleardevice;
    initgraph:=true;
end;

Procedure CloseGraph;
begin
  {while CheckForFade do;}
  DoneColours;
  {freemem(SC.startoffsets,SC.Size.y shl 1);}
  asm

      mov al,ctext;
      mov ah,0;
  int 10h end;
  {setcurs(oldcrsx,oldcrsy);}
end;

Procedure thickrectangle(x1,y1,x2,y2,thickness:integer);
Begin
  for thickness:=1 to thickness do begin
    rectangle(x1,y1,x2,y2);
    inc(x1); inc(y1);
    dec(x2); dec(y2);
  end;
end;

Procedure rectangle(x1,y1,x2,y2:integer);
Begin
  if x1>x2 then asm mov ax,x2;xchg x1,ax;mov x2,ax;end;
  if y1>y2 then asm mov ax,y2;xchg y1,ax;mov y2,ax;end;
  if y1<>y2 then begin
    hline(x1,x2,y1);
    vLine(x2,y1+1,y2-1);
    vLine(x1,y1+1,y2-1);
  end;
  hLine(x1,x2,y2);
end;



{these Qwrite procedures are the same for all Graphics Devices}
var
BMoldoffset:Dword;
SMoldoffset:Dword;

Procedure Qpush;assembler;
asm
  mov ax,word ptr SC.qoffset
  mov word ptr SMoldoffset,ax
end;

Procedure Qpop;assembler;
asm
  mov ax,word ptr SMoldoffset
  mov word ptr SC.qoffset,ax
end;

Procedure Qnextline;
begin
  inc(SC.qoffset,SC.offsd);
end;


Procedure BMQpush;assembler;
asm
  mov ax,word ptr BC.qoffset
  mov word ptr BMoldoffset,ax
end;

Procedure BMQpop;assembler;
asm

  mov ax,word ptr BMoldoffset
  mov word ptr BC.qoffset,ax
end;

Procedure BMQnextline;
begin
  inc(BC.qoffset,BC.offsd);
end;

{------------------****Animation stuff****---------------------}

Constructor Animtype.create(mode_,numframes_,start:byte);
begin
  direction:=1;
  curframe:=start mod numframes_;
  mode:=mode_;
  numframes:=numframes_;
  getmem(frames,sizeof(bitmaptypeptr)*numframes);
end;

Procedure Animtype.play(x,y:integer);
begin
  putbitmap(x,y,frames^[curframe]);
  if mode=pingpong then begin
    if ((curframe=0)and(direction<0))or
    ((curframe=numframes-1)and(direction>0)) then
      direction:=-direction
  end else
    if curframe=numframes-1 then curframe:=255;
  inc(curframe,direction);
end;

Destructor Animtype.done;
var i:byte;
begin
  for i:=0 to numframes-1 do
    DestroyBitmap(frames^[i]);
end;

begin
{load in default font}
   fillchar(tcharset,255*fontheight,0);
   asm
    (*
    {get address of 8 pixel high font}
    mov ah,$35
    mov al,fontintr
    int $21
    {correct vector, subtract a k}
    sub bx,1024

    {get tcharset pointer}
    lea si,tcharset

    {inititiate a loop}
    mov cx,256
    @copyloop:
      push cx
      mov cx,8
      @byteloop:
        mov al,es:[bx]
        mov ds:[si+(fontheight shr 1)-4],al
        inc bx
        inc si
      loop @byteloop
      add si,fontheight shr 1
      pop cx
    loop @copyloop*)
  end;
End.



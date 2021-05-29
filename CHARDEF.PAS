Unit chardef;
{$X+}{$a+}

INTERFACE
uses dos,ttypes,tmaths;
const
fontshift=4;    {shift by this amount to get to next font in list}
fontheight=1 shl fontshift;        {font height}
Fontmax=Fontheight-1;              {often need height-1}
FontsizeY=14;                      {size of the font in pixels -Two for tail}
{Fontheight:byte absolute $40:$85;}
fontintr=$1f;

CTproportional=1;

type

Fonttype=array[0..Fontmax] of byte;

charsettypeptr=^charsettype;
charsettype=record
  typeface:array[0..255]of fonttype;
  widths:array[0..255] of byte;
  attrib:byte;
end;


Procedure not_font(font:bytearray;fontsize:word);
procedure ror_font(font:bytearray;fontwidth,fontheight:word);
procedure rod_font(font:bytearray;fontwidth,fontheight:word);
procedure rol_font(font:bytearray;fontwidth,fontheight:word);
procedure rou_font(font:bytearray;fontwidth,fontheight:word);
procedure flipx_font(font:bytearray;fontwidth,fontheight:word);
procedure flipy_font(font:bytearray;fontwidth,fontheight:word);

Procedure savefontlist(filename:string;var ch:charsettype);
Procedure loadfontlist(filename:string;var ch:charsettype);
Procedure Setcharset(lcharset:charsettype;block:byte);
Procedure setblock(block:byte);
Procedure Maxline(maxlines:integer);
Function TStrLen(txt:string;charset:charsettypeptr):word;
Function TStrLen_at(txt:string;index:byte;charset:charsettypeptr):word;
Function TStrLen_null(txt:pchar;charset:charsettypeptr):word;
function getindex(txt:string;x:integer;charset:charsettypeptr):byte;
Procedure proportionalize(var ch:charsettype);
function strippath(pstr:string):string;

IMPLEMENTATION

function strippath(pstr:string):string;
var i,lastindx:byte;
retstr:string;
begin
  for i:=1 to length(pstr) do begin
    if pstr[i]='\' then
      lastindx:=i;
  end;
  retstr:=copy(pstr,0,lastindx);
  strippath:=retstr;
end;

Function TStrLen_at(txt:string;index:byte;charset:charsettypeptr):word;
var len:word; lop:byte;
begin
  if index<=1 then
    TStrLen_at:=0
  else
  with charset^ do
    if attrib=CTproportional then begin
      len:=0;
      for lop:=1 to index-1 do begin
        inc(len,widths[byte(txt[lop])]);
      end;
      TStrLen_at:=len;
    end else
      TStrLen_at:=index shl 3;
end;


function TStrLen(txt:string;charset:charsettypeptr):word;
var len:word; lop:byte;
begin
  with charset^ do
    if attrib=CTproportional then begin
      len:=0;
      for lop:=1 to byte(txt[0]) do begin
        inc(len,widths[byte(txt[lop])]);
      end;
      TStrLen:=len;
    end else
      TStrLen:=byte(txt[0]) shl 3;
end;

function getindex(txt:string;x:integer;charset:charsettypeptr):byte;
var lop:byte;currlen:integer;
begin
  currlen:=0;
  lop:=0;
  while x>currlen do begin
    inc(lop);
    inc(currlen,charset^.widths[byte(txt[lop])])
  end;
  getindex:=lop;
end;

function TStrLen_null(txt:pchar;charset:charsettypeptr):word;
var len:word;
begin
  len:=0;
  with charset^ do
  if attrib=CTproportional then
    while byte(txt^)<>0 do begin
      inc(len,widths[byte(txt^)]);
      inc(txt);
    end
  else
    while byte(txt^)<>0 do begin
      inc(len,8);
      inc(txt);
    end;
  TStrLen_null:=len;
end;


Procedure Maxline(maxlines:integer);
Begin
  port[$3d4]:=9;port[$3d5]:=maxlines;
end;

Procedure setblock(block:byte);assembler;
asm
  mov bl,block
  mov ax,$1103
  int $10
end;

procedure mapmask(mask:byte);assembler;
asm
  mov dx,$3c5
  mov al,2
  out dx,al
  mov al,mask
  out dx,al
end;

{Procedure Setcharset(lcharset:charsettype);assembler;
const block=0;
asm
  {set mapmask to two}
  {mov dx,$3c5
  mov al,2
  out dx,al
  mov al,$4
  out dx,al

  {load character set into generator 0)}
  {push ds
  lds si,lcharset
  mov ax,$B800
  mov es,ax
  mov di,block
  mov cx,256*4
  movsw

  {set block to 0}
  {
end;}

Procedure setcharset(lcharset:charsettype;block:byte);assembler;
asm
  mov ah,$11
  mov al,$0
  {mov ax,2816}
  mov bh,Fontheight
  mov bl,block
  mov cx,255
  mov dx,0
  push bp
    les bp,lcharset
    int $10
  pop bp
end;


Procedure savefontlist(filename:string;var ch:charsettype);
Var scans:byte;norecs:word;
    f:file;
Begin
  norecs:=1;
  assign(f,filename);
  Rewrite(f,norecs);
  scans:=Fontheight;
  blockwrite(f,scans,1,norecs);
  blockwrite(f,ch.typeface,256*Fontheight,norecs);
  close(f);
end;

Procedure proportionalize(var ch:charsettype);
var
currwidth:byteptr;
fontlop,bytelop,bitlop,currbit:byte;
begin
  currwidth:=@ch.widths;
  ch.attrib:=ctproportional;
  for fontlop:=0 to 255 do begin
    currwidth^:=0;
    for bytelop:=0 to fontmax do begin
      currbit:=0;
      for bitlop:=7 downto 0 do begin
        if ch.typeface[fontlop][bytelop] and (1 shl bitlop)<>0 then
          currbit:=bitlop xor 7;
      end;
      if currbit>currwidth^ then
        currwidth^:=currbit;
    end;
    inc(currwidth^,2);
    inc(currwidth);
  end;
  ch.widths[32]:=6;
end;

Procedure loadfontlist(filename:string;var ch:charsettype);
const offset=0;
Var scans:byte;norecs:word;
    fontlop,bytelop,bitlop,currbit:byte;
    dummy:array[0..offset] of word;
    
    f:file;
Begin
  norecs:=1;
  assign(f,filename);
  Reset(f,norecs);
  blockread(f,scans,1,norecs);
  blockread(f,dummy,offset,norecs);
  blockread(f,ch.typeface,256*scans,norecs);
  proportionalize(ch);
  close(f);
end;

{Procedure loadfontlistb(filename:string;var ch:charsettype);
Var lop,lop2,scans:byte;f:text;temp:char;tempstr:string;code:integer;
Begin
  Assign(f,filename);
  Reset(f);
  readln(f,tempstr);
  tempstr:=copy(tempstr,1,9);
  val(tempstr,scans,code);
  for lop:=0 to 255 do
    for lop2:=1 to Fontheight do
    begin
      read(f,temp);ch^[lop][lop2]:=ord(temp);
    end;
  close(f);
end;

{the above is the old byte by byte method
below is the dynamicly sized array saver}

{Procedure loadfontlistc(filename:string;var ch:charsettype);
Var scans,lop:byte;f:file;norecs:word;
Begin
  norecs:=1;
  Assign(f,filename);
  Reset(f,norecs);
  blockread(f,scans,1,norecs);
  for lop:=0 to 255 do
    blockread(f,ch^[lop],scans,norecs);
  close(f);
end;}

procedure rorblock(block:pointer;count:word;shiftby:byte);assembler;
asm
  les di,block
  mov cl,shiftby
  mov bx,count

  dec bx
  add di,bx

  {do first byte, save in dx}
  mov dl,es:[di]
  xor dh,dh
  ror dx,cl
  mov es:[di],dl
  dec di
  cmp bx,0
  jz @lastbyte

  @shiftloop:
    mov al,es:[di]
    xor ah,ah
    ror ax,cl
    mov es:[di],al
    or es:[di+1],ah
    dec di
    dec bx
  jnz @shiftloop
  {do last byte}
  @lastbyte:
  or es:[di+1],dh
end;

procedure rolblock(block:pointer;count:word;shiftby:byte);assembler;
asm
  les di,block
  mov cl,shiftby
  mov bx,count
  dec bx
  {do first byte, save in dx}
  mov dh,es:[di]
  xor dl,dl
  rol dx,cl
  mov es:[di],dh
  inc di
  cmp bx,0
  jz @lastbyte

  @shiftloop:
    mov ah,es:[di]
    xor al,al
    rol ax,cl
    mov es:[di],ah
    or es:[di-1],al
    inc di
    dec bx
  jnz @shiftloop
  {do last byte}
  @lastbyte:
  or es:[di-1],dl
end;

procedure rol_font(font:bytearray;fontwidth,fontheight:word);
var lop:byte;
begin
  for lop:=0 to fontheight-1 do
    rolblock(@font^[lop*(fontwidth shr 3)],fontwidth shr 3,1);
end;

procedure rou_font(font:bytearray;fontwidth,fontheight:word);
var lop:word;
    xbytes:byte;
    temp:^byte;

begin
  getmem(temp,xbytes);
  xbytes:=fontwidth shr 3;
  move(font^[0],temp^,xbytes);
  for lop:=0 to fontheight-2 do
    move(font^[(lop+1)*xbytes],font^[lop*xbytes],xbytes);
  move(temp^,font^[(fontheight-1)*xbytes],xbytes);

end;

procedure ror_font(font:bytearray;fontwidth,fontheight:word);
var lop:byte;
begin
  for lop:=0 to fontheight-1 do
    rorblock(@font^[lop*(fontwidth shr 3)],fontwidth shr 3,1);
end;

procedure rod_font(font:bytearray;fontwidth,fontheight:word);
var lop:word;
    xbytes:byte;
    temp:^byte;

begin
  xbytes:=fontwidth shr 3;
  getmem(temp,xbytes);

  move(font^[(fontheight-1)*xbytes],temp^,xbytes);
  for lop:=fontheight-1 downto 1  do
    move(font^[(lop-1)*xbytes],font^[(lop)*xbytes],xbytes);
  move(temp^,font^[0],xbytes);
  freemem(temp,xbytes);
  

end;
{assembler;
asm
  les di,font

  mov cx,Fontheight
  dec cx
  mov ah,es:[di]
  @shiftlop:
    mov al,es:[di+1]
    mov es:[di],al
    inc di
  loop @shiftlop
  mov es:[di],ah
end;}

procedure not_font(font:bytearray;fontsize:word);assembler;
asm
  les di,font
  mov cx,Fontsize
  @notlop:
    mov al,es:[di]
    not al
    mov es:[di],al
    inc di
  loop @notlop
end;

procedure flipbyte(var c:byte);assembler;
asm
  les di,c
  mov al,es:[di]
  mov cx,8
  @bitlop:
    rcr al,1
    adc ah,0
    cmp cl,1
    jz @noshift
      shl ah,1
    @noshift:
  loop @bitlop
  mov es:[di],ah
end;

procedure flipx_font(font:bytearray;fontwidth,fontheight:word);
var xlop,ylop,xbytes,byte1,byte2:word;
begin
  xbytes:=(fontwidth shr 3);
  for ylop:=0 to xbytes*fontheight do
    flipbyte(font^[ylop]);
  if xbytes>1 then
  for ylop:=0 to fontheight-1 do
    for xlop:=0 to (xbytes-1) shr 1 do
      fswap(font^[(ylop*xbytes)+xlop],font^[(ylop*xbytes)+xbytes-1-xlop],1);
end;

procedure flipy_font(font:bytearray;fontwidth,fontheight:word);
var lop,xbytes:byte;
begin
  xbytes:=fontwidth shr 3;
  for lop:=0 to (Fontheight-1) shr 1 do
    fswap(font^[lop*xbytes],font^[(fontheight-1-lop)*xbytes],xbytes);
end;
End.

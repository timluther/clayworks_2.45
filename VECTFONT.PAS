Unit vectfont;
INTERFACE
uses ggraph,ttypes;

const
Prefix_Size=$80;
Major_Version=1;
Minor_Version=0;
SIGNATURE='+';

type
op_codes=(end_of_char,do_scan,moveit,drawit);

Fheader=record
  header_size           :word;      { Version 2.0 Header Format    }
  font_name             :string[4]; { Font Internal Name           }
  font_size             :integer;   { Size in byte of file         }
  font_major, font_minor:byte;      { Driver Version Information   }
  min_major, min_minor  :byte;      { BGI Revision Information     }
end;

Header_type=record
  sig        :char;        { SIGNATURE byte                       }
  nchrs      :integer;     { number of characters in file         }
  mystery    :byte;        { Currently Undefined                  }
  first      :byte;        { first character in file              }
  cdefs      :integer;     { offset to char definitions           }
  scan_flag  :boolean;     { True if set is scanable              }
  org_to_cap :shortint;    { Height from origin to top of capitol }
  org_to_base:shortint;    { Height from origin to baseline       }
  org_to_dec :shortint;    { Height from origin to bot of decender}
  fntname    :string[3];   { Four character name of font          }
  unused     :byte;        { Currently undefined                  }
end;

stroke_type=record
  opcode:op_codes;         { Stroke opcode byte                   }
  x,y:shortint;
end;

strokearray=^strokearray_;
strokearray_=array[0..0] of stroke_type;

stroke_char=record
  num_ops:integer;
  S:strokearray;
end;

font_type=object
  first,nchars:byte;
  org_to_cap,org_to_base,org_to_dec :shortint;
  Strokes:array[0..255]of stroke_char;
  Widths:array[0..255] of byte;
  Procedure drawbm(xoff,yoff,zoom:integer;text:string);
  Procedure draw(xoff,yoff,zoom:integer;text:string);
  function load(filename:string):boolean;
  Procedure done;
end;

IMPLEMENTATION

function font_type.load(filename:string):boolean;
var
len,base:longint;
recsize,i:word;
ffile:file;

Font:bytearray;  {Dynamic array of font storage}
header:header_type;
Prefix:array[0..Prefix_size-1] of byte;
Offset:array[0..255] of word;

{unpacking variables}
pb:^word; lop:integer; dummy:shortint; opc:op_codes;

{decode a word}
Function decode(iptr:word;var x,y:shortint):byte;
type
decoder=record x,y:byte; end;
var cword:decoder;
tmp:byte;
begin
  cword:=decoder(iptr);
  x:=(cword.x and 127);
  tmp:=(cword.y and 127);
  {if top bit of singed thingy is set then copy over}
  if boolean(tmp and 64) then tmp:=tmp+128;
  y:=(org_to_cap)-tmp;
  cword.x:=(cword.x and 128) shr 7;
  cword.y:=(cword.y and 128) shr 7;
  decode:=(cword.x shl 1)+cword.y;
end;

begin
  recsize:=1;
  assign(ffile,filename);
  reset(ffile,recsize);

  blockread(ffile,prefix,prefix_size,recsize);
  blockread(ffile,header,sizeof(header),recsize);
  if header.sig<>signature then begin
    load:=false;
    close(ffile);
    exit;
  end;
  first:=header.first;
  nchars:=header.nchrs;
  org_to_cap:=header.org_to_cap;
  org_to_dec:=header.org_to_dec;
  org_to_base:=header.org_to_base;
  blockread(ffile,offset[first],nchars shl 1,recsize);
  blockread(ffile,widths[first],nchars,recsize);

  len:=filesize(ffile)-filepos(ffile);

  {allocate space for and load in font raw data}
  getmem(font,len);
  if font=nil then begin load:=false;exit end;
  blockread(ffile,font^,len,recsize);
  for i:=first to first+nchars-1 do begin
    {pointer position in font list}
    pb:=@font^[offset[i]];
    strokes[i].num_ops:=0;
    opc:=moveit;

    While opc<>end_of_char do begin
      opc:=op_codes(decode(pb^,dummy,dummy));
      inc(pb);
      inc(strokes[i].num_ops);
    end;
    {dec(strokes[i].num_ops,2);}

    getmem(strokes[i].s,strokes[i].num_ops*sizeof(stroke_type));
    if strokes[i].s<>nil then begin
      pb:=@font^[offset[i]];
      for lop:=0 to strokes[i].num_ops-1 do begin
        with strokes[i].s^[lop] do
          opcode:=op_codes(decode(pb^,x,y));
        inc(pb);
      end;
    end else begin load:=false;exit;end;
  end;
  freemem(font,len);
  close(ffile);
  load:=true;
end;
Procedure font_type.drawbm(xoff,yoff,zoom:integer;text:string);
var lop,tmp:byte;
lop1,mx,my:integer;
stroke:^stroke_type;
begin
  for lop:=1 to ord(text[0]) do begin
    tmp:=ord(text[lop]);
    stroke:=pointer(strokes[tmp].s);
    for lop1:=0 to strokes[tmp].num_ops-3 do
    with stroke^ do begin
      if opcode=drawit then
        bmline(zoom*mx+xoff,zoom*my+yoff,zoom*x+xoff,zoom*y+yoff);
      mx:=x;my:=y;
      inc(stroke);
    end;
    inc(xoff,widths[tmp]*zoom);
  end;
end;


Procedure font_type.draw(xoff,yoff,zoom:integer;text:string);
var lop,tmp:byte;
lop1,mx,my:integer;
stroke:^stroke_type;
begin
  for lop:=1 to ord(text[0]) do begin
    tmp:=ord(text[lop]);
    stroke:=pointer(strokes[tmp].s);
    for lop1:=0 to strokes[tmp].num_ops-3 do
    with stroke^ do begin
      if opcode=drawit then
        line(zoom*mx+xoff,zoom*my+yoff,zoom*x+xoff,zoom*y+yoff);
      mx:=x;my:=y;
      inc(stroke);
    end;
    inc(xoff,widths[tmp]*zoom);
  end;
end;

Procedure font_type.done;
var i:word;
begin
  for i:=first to first+nchars-1 do
    freemem(strokes[i].s,strokes[i].num_ops*sizeof(stroke_type));
end;

end.
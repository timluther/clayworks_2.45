Unit PCX256;
INTERFACE
uses ggraph,gbasics,tmaths,ttypes,diskop,colour;

const
{////PICTURE ATTRIBUTES////}
PAflat=BMflat;
PAPlanes=BMPlanes;
PACheckVidMode=0;  {DDB}
PAtypemask=BMflat+BMPlanes;

PAcolcheck=4;

type
pcx_header=record
   header:byte;
   version:byte;  {5 for extra colours at end of file}
   encoding:byte; {1 for runlength}
   bits_per_pixel:byte;
   window:trect;
   resolution:pointtype;
   cmap:array[0..15]of RGBtype;
   reserved:byte;
   numplanes:byte;
   offset:integer; {screen width in bytes}
   PaletteInfo:integer; {1 =colour/bw, 2=greyscale}
   screensize:pointtype;
   filler:array[0..53]of byte;
end;

var
LCmap:bytearray;
header:pcx_header;

const
  no_bytes_back=769;
  Check_256Val=12;
  chkbits=$C0;
  maskbits=255-chkbits;

Function readPCX(filename:string;Pattrib:byte):pointer;
Procedure writePCX(pic:bitmaptypeptr;filename:string);
IMPLEMENTATION

Procedure writePCX(pic:bitmaptypeptr;filename:string);
var
  writecol:rgbtype;
  lop:byte;
  xlop,ylop,runsize,subtotal:integer;
  writeheader:pcx_header;
  f:file;
  recsize,bufsize:word;
  linebuf,currbyte:^byte;
  temp,oldbyte,runcolour:byte;

procedure endrun;
begin
  currbyte^:=chkbits or runsize;
  inc(currbyte);
  inc(bufsize);
  currbyte^:=runcolour;
  runsize:=0;
  {on off subtotal count -there was a 'run flag' byte}
end;

begin
  recsize:=1;
  assign(f,filename);
  rewrite(f,recsize);

  with writeheader,pic^ do begin
    header:=$0a;
    version:=5;
    encoding:=1;
    bits_per_pixel:=8;
    window.rassign(0,0,size.x,size.y-1);
    resolution.x:=1+sc.screenport.x2-sc.screenport.x1;
    resolution.y:=1+sc.screenport.y2-sc.screenport.y1;
    for lop:=0 to 15 do with cmap[lop] do
      getrgb(lop,r,g,b);
    reserved:=0;
    numplanes:=1;
    offset:=size.x;
    if offset mod 2<>0 then inc(offset);
    PaletteInfo:=1;
    screensize:=resolution;
    fillchar(filler,54,0);
    blockwrite(f,writeheader,sizeof(writeheader),recsize);
    {reset internal picture coords}
    Qsetxy(0,0);
    getmem(linebuf,size.x);
    {blockwrite(f,pic^,planesize,recsize);}
    for ylop:=1 to size.y do begin
      currbyte:=linebuf;
      bufsize:=0;
      oldbyte:=currbyte^+1;
      runsize:=0;
      subtotal:=0;
      while (subtotal<offset) do begin

        currbyte^:=qget;
        temp:=currbyte^;
        if oldbyte<>temp then begin
          {end an ongoing run?}
          if runsize>0 then
            endrun;
          {no run}
          inc(currbyte);
          inc(bufsize);
          if temp and chkbits<>0 then dec(temp);
          oldbyte:=temp;
          {inc(subtotal);
          {reset runsize}
        end else if runsize<=64 then begin
          {run in progress...}
          if runsize=0 then runcolour:=temp;
          inc(runsize);
          {inc(subtotal);}
        end else
          endrun;
      end;
      {end run if currently in one}
      if runsize>0 then endrun;
      blockwrite(f,linebuf^,bufsize,recsize);
    end;
    freemem(linebuf,size.x);
    t_col:=check_256val;

    blockwrite(f,t_col,1,recsize);
    for lop:=0 to 255 do with writecol do begin
      getrgb(lop,r,g,b);
      blockwrite(f,writecol,3,recsize);
    end;
  end;
  close(f);
end;

Function readPCX(filename:string;pattrib:byte):pointer;
var
  buf:bufferedblock;
  xln,yln,xpos,ypos:integer;
  tmpRGB:RGBtype;
  tmpcolref:byte;
  bmtype:byte;

  lop,chk,loadbyte:byte;
  subtotal,scanlop,xlop,palsize:word;
  oldfilepos:word;
  tmp:byteptr;

  pic:bitmaptypeptr;

begin
  buf.open(filename);
  buf.blockread(@header,sizeof(pcx_header));
  with header do begin
    xln:=1+(window.x2-window.x1);
    yln:=1+(window.y2-window.y1);
    if memavail<(((xln shr 3)*yln) *4) then begin
      buf.close;
      readpcx:=nil;
    end;

    {PCX files xoffset needs to be even}
    if xln mod 2<>0 then inc(xln);
    bmtype:=Pattrib and PAtypemask;
    case bmtype of
      PAcheckvidmode:
      if SC.colourdepth>16 then
          pic:=createBitmap(xln,yln,8,BMflat)
      else
          pic:=createBitmap(xln,yln,4,BMplanes);
      PAflat:
          pic:=createBitmap(xln,yln,8,BMflat);
      PAPlanes:
          pic:=createBitmap(xln,yln,4,BMplanes);
    end;
    SetBitmapContext(pic);

    palsize:=0;
    if (bits_per_pixel<=4) then begin
      palsize:=16;
      Getmem(LCmap,palsize);
      for lop:=0 to 15 do begin
        with Cmap[lop] do
          LCmap^[lop]:=AllocateRGB(r shr 2,g shr 2,b shr 2);
      end
    end else begin
      oldfilepos:=buf.fpos;
      buf.fseek(filesize(buf.f)-no_bytes_back);
      chk:=buf.get;
      if (chk=check_256val) then begin
        palsize:=256;
        Getmem(LCmap,palsize);
        for lop:=0 to 255 do begin
          buf.blockread(@TmpRGB,3);
          with TmpRGB do
            LCmap^[lop]:=AllocateRGB(r shr 2,g shr 2,b shr 2);
        end;
      end;
      buf.fseek(oldfilepos+1);
    end;
    {begin image decode}
    xpos:=0;
    ypos:=0;
    if bits_per_pixel=8 then begin
      for scanlop:=0 to pic^.size.y-1 do begin
        subtotal:=0;
        while subtotal<offset do begin
          chk:=buf.get;
          if ((chk and chkbits)=chkbits)and(encoding=1) then begin
            chk:=chk and maskbits;
            if (pattrib and PAcolcheck <>0) then
              t_col:=LCmap^[buf.get]
            else
              t_Col:=buf.get;
            for xpos:=xpos to xpos+chk do
              BMputpixel(xpos,ypos);
            inc(subtotal,chk);
          end else begin
            if (pattrib and PAcolcheck <>0) then
              t_col:=LCmap^[chk]
            else
              t_col:=chk;
            BMputpixel(xpos,ypos);
            inc(xpos);
            inc(subtotal);
          end;
        end;
        inc(ypos);
        xpos:=0;
      end;
    end else begin
    {begin image decode}
      {getmem(buf,offset*bitplanes);
      for scanlop:=0 to size.y-1 do begin
        for currplane:=0 to bitplanes-1 do begin
          subtotal:=0;
          while subtotal<offset do begin
            chk:=getbyte;
            if ((chk and chkbits)=chkbits)and(encoding=1) then begin
              chk:=chk and maskbits;
              loadbyte:=getbyte;
              fillchar(count[currplane]^,chk,loadbyte);
              inc(count[currplane],chk);
              inc(subtotal,chk);
            end else begin
              count[currplane]^:=chk;
              inc(subtotal);
              inc(count[currplane]);
            end;
          end;
        end;
      end;
      getmem(buf,offset*bitplanes);}
    end;
    if palsize<>0 then
      freemem(LCmap,palsize);
  end;
  buf.close;
  readPCX:=pic;
end;
end.

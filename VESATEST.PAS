program vesatest;

uses vesainfo,ttypes,crt;
var
infoblock:headerblock;
modeinfoblock:infoblocktype;
modelist:wordptr;
ch:char;
begin
getvesaheaderinfo(@infoblock);
modelist:=infoblock.modelist;
while (modelist^<>-1) and (ch<>#27) do
begin

  getvesainfo(@modeinfoblock,modelist^);
  writeln('Mode no:',modelist^);

  writeln('xres:',modeinfoblock.xresolution,' yres:',modeinfoblock.yresolution);
  writeln('bpp:',modeinfoblock.bitsperpixel);
  inc(modelist);
  ch:=readkey;
end;
end.
unit bitmap16;
{routines to write to a plainiar bitmap}
INTERFACE
uses chardef,ttypes,gbasics,tmaths;

Procedure ClearDevice;
procedure putpixel(x1,y1:integer);
function getpixel(x1,y1:integer):byte;
Procedure Qsetxy(x1,y1:integer);
Procedure Qwrite(count:word);
function Qget:byte;

IMPLEMENTATION

procedure putpixel(x1,y1:integer);assembler;



  asm
      mov cx,x1 ;mov bx,y1
      cmp cx,BC.viewport.x1 ;jl @fin                   {clipping..}
      cmp bx,BC.viewport.y1 ;jl @fin
      cmp cx,BC.viewport.x2 ;jg @fin
      cmp bx,BC.viewport.y2 ;jg @fin

      {load start offset from table}
      shl bx,1
      mov di,word ptr BC.startoffsets+bx

      {x-offset}
      mov bl,cl
      xor bh,bh
      and bl,7
      shr cx,3
      add di,cx

      mov dl,byte ptr singlepixelbitmasks+bx
      mov bx,di

      {create masks}

      mov dh,dl
      not dh
      mov ah,t_col


      @plane1:
      les di,dword ptr BC.scrptrs
      mov al,1


      test al,ah
      jz @nowrite1
        or es:[di+BX],dl
        jmp @plane2
      @nowrite1:
        and es:[di+BX],dh
      @plane2:

      shl al,1  {move bitmask along}

      les di,dword ptr BC.scrptrs+4

      test al,ah
      jz @nowrite2
        or es:[di+BX],dl
        jmp @plane3
      @nowrite2:
        and es:[di+BX],dh
      @plane3:

      shl al,1  {move bitmask along}

      les di,dword ptr BC.scrptrs+8

      test al,ah
      jz @nowrite3
        or es:[di+BX],dl
        jmp @plane4
      @nowrite3:
        and es:[di+BX],dh
      @plane4:

      shl al,1  {move bitmask along}

      les di,dword ptr BC.scrptrs+12
      test al,ah
      jz @nowrite4
        or es:[di+BX],dl
        jmp @fin
      @nowrite4:
        and es:[di+BX],dh
      @fin:



end;

function getpixel(x1,y1:integer):byte;
var adrs:byteptr;
    readbit,planelop,currbyte:byte;
    picoffset:word;
begin
  currbyte:=0;
  if (X1>=BC.viewport.x1)and(Y1>=BC.viewport.y1)and(X1<=BC.viewport.x2)and(Y1<=BC.viewport.y2) then begin

    readbit:=$80 shr (x1 and 7);
    picoffset:=(y1 * BC.offsw)+(x1 shr 3);
    for planelop:=0 to BC.bitplanes-1 do begin
      adrs:=pointer(BC.scrptrs[planelop]);
      inc(adrs,picoffset);
      if readbit and adrs^<>0 then
        inc(currbyte,1 shl planelop);
    end;
  end;
  getpixel:=currbyte;
end;

{These are generic routines for writing contingous
block fast to bitmaps. Good for loading in from files}
Procedure QSetXY(x1,y1:integer);
begin
  BC.qoffset:=y1*BC.offsw+(x1 shr 3);
  BC.qbitoffset:=x1 and 7;

end;

function Qget:byte;
var
  colour:byte;
  var planeloop:byte;
  qadrs:byteptr;
begin

  colour:=0;
  for planeloop:=0 to BC.bitplanes-1 do begin
    qadrs:=pointer(BC.scrptrs[planeloop]);
    inc(qadrs,BC.qoffset);
    if qadrs^ and BC.qbitoffset <> 0 then
      inc(colour,1 shl planeloop);
  end;
  asm
    shr bc.qbitoffset,1
    adc word ptr bc.qoffset,0
  end;
  qget:=colour;
end;

Procedure Qwrite(count:word);
var lop,oldqoff:word;
    planelop,oldqmask:byte;
    oldxpos:integer;
    adrs:^byte;
begin
  {oldqoff:=q
  oldxpos:=BC.qxpos;
  for planelop:=0 to BC.bitplanes-1 do begin
    qoff:=oldqoff;
    qmask:=oldqmask;
    BC.qxpos:=oldxpos;

    adrs:=pointer(pic[planelop]);
    inc(adrs,Qoff);
    for lop:=1 to count do begin
      if t_col and (1 shl planelop)<>0 then
        adrs^:=adrs^ or Qmask
      else
        adrs^:=adrs^ and not Qmask;
      begin
        qmask:=qmask shr 1;
        if Qmask=0 then begin
          inc(adrs);
          inc(Qoff);
          Qmask:=128;
        end;
      end;
    end;
  end;}
end;

Procedure ClearDevice;
var bitlop:byte;
begin
  for bitlop:=0 to BC.bitplanes-1 do
    fillchar(BC.scrptrs[bitlop]^,BC.pagesize,0);
end;

end.

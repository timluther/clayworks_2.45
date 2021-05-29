Unit XVGA256;
{$X+}{$a+}

{stuff to be preserved for mouse inter:
  SEQU_ADDR
  2,writemask
  GRPH_ADDR
  4,readmask
}

INTERFACE
uses Gbasics,chardef,ttypes,tmaths;

{to set a vga mode you only need to set these 29 registers}
type

vgaregstype=record
  misc:byte;
  crtc00_09:array[0..$9] of byte;{mostly horizontal res stuff}
  crtc10_17:array[0..$7] of byte;{mostly vertical res stuff}
  sequ1,sequ3,sequ4:byte;        {can define modeX with just these set to 1,0 & 6}
  grph5,grph6:byte;              {bit and bobs}
  attr10_14:array[0..4] of byte; {as above}
end;

const
X640x400data:vgaregstype=(misc:$6b;
crtc00_09:($ad,$9f,$9f,$89,$a0,$6,$bf,$1f,$0,$60);
crtc10_17:($9c,$8e,$8f,$50,$0,$96,$b9,$e3);
sequ1:$1;sequ3:$0;sequ4:$6;
grph5:$40;grph6:$5;
attr10_14:($41,$0,$f,$0,$10));

X400x600data:vgaregstype=(misc:$e7;
crtc00_09:( $70,$63,$64,$92,$65,$82,$70,$f0,$0,$60);
crtc10_17:($5b,$8c,$57,$32,$0,$58,$70,$e3);
sequ1:$1;sequ3:$0;sequ4:$6;
grph5:$40;grph6:$5;
attr10_14:($41,$0,$f,$0,$10));

X400x300data:vgaregstype=(misc:$a7;
crtc00_09:($71,$63,$64,$92,$65,$82,$46,$1f,$0,$40);
crtc10_17:($31,$80,$2b,$32,$0,$2f,$44,$e3);
sequ1:$1;sequ3:$0;sequ4:$6;
grph5:$40;grph6:$5;
attr10_14:($41,$0,$f,$0,$10));

X320x200data:vgaregstype=(misc:$63;
crtc00_09:($5f,$4f,$50,$82,$54,$80,$bf,$1f,$0,$41);
crtc10_17:($9c,$8e,$8f,$28,$0,$96,$b9,$e3);
sequ1:$1;sequ3:$0;sequ4:$6;
grph5:$40;grph6:$5;
attr10_14:($41,$0,$f,$0,$10));

X320x240data:vgaregstype=(misc:$e3;
crtc00_09:($5f,$4f,$50,$82,$54,$80,$d,$3e,$0,$41);
crtc10_17:($ea,$ac,$df,$28,$0,$e7,$6,$e3);
sequ1:$1;sequ3:$0;sequ4:$6;
grph5:$40;grph6:$5;
attr10_14:($41,$0,$f,$0,$10));

{VGA register locations}
MISC_ADDR=$3c2; MISC_READ_ADDR=$3cc;
ATTR_ADDR=$3c0; ATTR_DATA_ADDR=$3c1;
STATUS_ADDR=$3da;
SEQU_ADDR=$3c4; SEQU_DATA_ADDR=$3c5;
CRTC_ADDR=$3D4; CRTC_DATA_ADDR=$3d5;
GRPH_ADDR=$3CE; GRPH_DATA_ADDR=$3CF;
{screen modes}

mapmask_index=2;
allplanes=3841;

chainfour=$8;
oddeven=$4;
exetendedmem=$2;
alphaon=$1;


function set_mode(mode:byte):boolean;
Procedure bar(x1,y,x2,y2:integer);
Procedure GTriangle(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);
Procedure Triangle(xa,ya,xb,yb,xc,yc:integer);
Procedure Line(x1,y1,x2,y2:integer);
Procedure Hline(x1,x2,y:Integer);
Procedure Vline(x,y1,y2:Integer);
Procedure putpixel(x1,y1:Integer);
Function  getpixel(x1,y1:Integer):byte;
Procedure outtextxy(x1,y1:integer;txt:string);
Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
Procedure Drawbytes(x1,y:Integer;pic:bytearray;nbytes:byte);
Procedure Drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
Procedure cleardevice;
procedure savescreenregs;
procedure restorescreenregs;

{quick generic interface to screen -good for file loading}
Procedure QSetXY(x,y:integer);
Procedure Qwrite(count:word);
function  Qget:byte;

IMPLEMENTATION
{stuff to be preserved for mouse inter:
  SEQU_ADDR
  2,writemask
  GRPH_ADDR
  4,readmask
}
var
oldwritemask,oldreadmask:byte;
procedure savescreenregs;
begin
end;
procedure restorescreenregs;
begin
end;

{Set actual graphics mode}

function set_mode(mode:byte):boolean;
var old,lop,dummy:byte;
    regs:vgaregstype;
    installed:boolean;
begin


    {setup mode 13h}
    asm
      mov al,13h;                 {mode}
      mov ah,0;                      {function 0}
      int 10h                        {call screen interrupt}
    end;
    SC.Colourdepth:=256;
    SC.offsw:=SC.size.x shr 2;

    {set up the unchained mode screen}
    port[misc_addr]:=regs.misc and 253;
    portw[crtc_addr]:=$11;    {disable register protection}
    for lop:=0 to $9 do begin
      port[crtc_addr]:=lop;
      port[crtc_data_addr]:=regs.crtc00_09[lop];
    end;
    for lop:=$10 to $17 do begin
      port[crtc_addr]:=lop;
      port[crtc_data_addr]:=regs.crtc10_17[lop-$10];
    end;
    port[SEQU_ADDR]:=1;port[SEQU_data_ADDR]:=regs.sequ1;
    port[SEQU_ADDR]:=3;port[SEQU_data_ADDR]:=regs.sequ3;
    port[SEQU_ADDR]:=4;port[SEQU_data_ADDR]:=regs.sequ4;

    port[GRPH_ADDR]:=05;port[GRPH_data_ADDR]:=regs.grph5;
    port[GRPH_ADDR]:=06;port[GRPH_data_ADDR]:=regs.grph6;

    for lop:=$10 to $14 do begin
      dummy:=port[status_addr];
      port[attr_addr]:=lop or $20;
      port[attr_addr]:=regs.attr10_14[lop-$10];
    end;
    dummy:=port[status_addr];
    for lop:=0 to 15 do begin
      port[attr_addr]:=lop;
      port[attr_addr]:=lop;
    end;
    dummy:=port[status_addr];port[attr_addr]:=32;  {allow access to pallette}
    {allow access to screen}
    old:=port[misc_read_addr];
    port[misc_addr]:=old+2;

  set_mode:=TRUE;
  {flip default font}
  for lop:=0 to 255 do
    Flipx_font(@TCharset.typeface[lop],8,fontheight);
end;



Procedure savefontlist(filename:string;var ch:charsettype);
var lop:byte;
begin
  for lop:=0 to 255 do
    Flipx_font(@Ch.typeface[lop],8,fontheight);
  chardef.savefontlist(filename,ch);
end;

Procedure Loadfontlist(filename:string;var ch:charsettype);
var lop:byte;
begin
  chardef.Loadfontlist(filename,ch);
  for lop:=0 to 255 do
    Flipx_font(@Ch.typeface[lop],8,fontheight);
end;

Procedure FSwap(Var s,d; L:Integer);
Begin
  Inline($1e /$c5/$b6/s /$c4/$be/d /$8b/$8e/l /$fc /$26/$8a/$05
         /$86/$04 /$46 /$aa /$e2/$f7 /$1f);
End;

procedure FillWord(var Dest; Count: Word; Data: Word);
begin
  inline(
    $C4/$7E/<Dest/    (* LES   DI,Dest[BP] *)
    $8B/$4E/<Count/   (* MOV   CX,Count[BP]*)
    $8B/$46/<Data/    (* MOV   AX,Data[BP] *)
    $FC/              (* CLD               *)
    $F3/$AB);         (* REP   STOSW       *)
end;

Procedure cleardevice;assembler;
Asm
  mov dx,SEQU_ADDR ;mov ax,allplanes+1; out dx,ax
  les di,sc.scrptr
  mov al,t_fillcol
  mov ah,t_fillcol
  mov cx,word ptr SC.pagesize
  shr cx,1
  CLD
  REP STOSW
End;



Function outcode(x1,y1:integer):byte;
var return:byte;
Begin
  return:=0;
  if y1>sc.viewport.y2 then Return:=bellow else
  if y1<sc.viewport.y1 then Return:=above;
  if x1>sc.viewport.x2 then inc(Return,right) else
  if x1<sc.viewport.x1 then inc(Return,left);
  outcode:=return;
end;

function clip(var x0,y0,x1,y1:integer):boolean;
var code0,code1:byte;swapvar:integer;
Begin
  While 0=0 do begin
    code0:=outcode(x0,y0);code1:=outcode(x1,y1);
    if (code0 and code1)<>0 then begin
      clip:=false;exit;{Trivial reject}
    end else begin
      if not(code0 or code1<>0)then begin
         clip:=true;exit;{Trivial accept}
      end else If (code0=0) then begin
        swapvar:=code1;code1:=code0;code0:=swapvar;
        swapvar:=x0;x0:=x1;x1:=swapvar;
        swapvar:=y0;y0:=y1;y1:=swapvar;
      end;
      if (code0 and bellow)<>0 then begin
        inc(x0,(x1-x0)*(sc.viewport.y2-y0)div(y1-y0));
        y0:=sc.viewport.y2;
      end else if (code0 and above)<>0 then begin
        inc(x0,(x1-x0)*(sc.viewport.y1-y0)div(y1-y0));
        y0:=sc.viewport.y1;
      end else if (code0 and right)<>0 then begin
        inc(y0,(y1-y0)*(sc.viewport.x2-x0)div(x1-x0));
        x0:=sc.viewport.x2;
      end else if (code0 and left)<>0 then begin
        inc(y0,(y1-y0)*(sc.viewport.x1-x0)div(x1-x0));
        x0:=sc.viewport.x1;
      end;
    end;
  end;
end;

Procedure Line(x1,y1,x2,y2:integer);
Var dfx,dfy,d,d2,incr1,incr2,xinc:integer;
adrs:word;mask:byte;
const
  startval=1;
Begin
  if x1=x2 then vline(x1,y1,y2) else begin
    if y1=y2 then hline(x1,x2,y1) else
    if clip(x1,y1,x2,y2) then Begin
      dfx:=abs(x2-x1);dfy:=abs(y2-y1);
      asm mov es,word ptr sc.scrptr +2 end;
      if dfx>dfy then begin
        asm
          mov ax,x2  ; cmp x1,ax ; jle @no_swap
            Xchg x1,ax ; mov x2,ax
            mov ax,y2  ; Xchg y1,ax ; mov y2,ax;
          @no_swap:
        end;
        incr2:=(dfy-dfx)shl 1;
        if(y2>y1) then xinc:=SC.offsw else xinc:=-SC.offsw;
        adrs:=(y1*SC.offsw)+(x1 shr 2);
        asm
          mov dx,sequ_addr ;mov al,mapmask_index; out dx,al {get X-shift}
          inc dx

          mov bx,adrs  {get offset}
          add bx,word ptr sc.scrptr        {add screen offset}
          mov ah,t_col {load in colour}

          mov cx,x1        ;and cl,3 {get mask}
          mov al,startval  ;shl al,cl

          mov cx,dfx ;inc cx     {load in the length}
          mov si,dfy ;shl si,1   {get increment value 1}
          mov di,si  ;sub di,dfx {get 'd'}
          @Runloop:
            out dx,al
            mov es:[bx],ah

            shl al,1
            test al,16
            jz @same
              mov al,startval
              inc bx
            @same:
              cmp di,0
              jl @noinc
                add di,incr2
                add bx,xinc
                jmp @check
              @noinc:
                add di,si
            @check:
          loop @runloop
        end;
      end else begin
        d2:=dfx shl 1;
        d:=d2-dfy;
        incr2:=(dfx-dfy) shl 1;
        inc(dfy);
        {if y2>y1 then swap both X and Y}
        asm
          mov ax,y2  ; cmp y1,ax ; jle @no_swap
            Xchg y1,ax ; mov y2,ax
            mov ax,x2  ; xchg x1,ax ; mov x2,ax;
          @no_swap:
        end;
        mask:=startval shl (x1 and 3);
        adrs:=(y1*SC.offsw)+(x1 shr 2);
        asm
          mov dx,sequ_addr;mov al,mapmask_index;out dx,al;inc dx
          mov ah,t_col
          mov bx,adrs
          add bx,word ptr sc.scrptr;  {add screen offset}
          mov al,mask;out dx,al    {load up starter mask}
          mov si,d2                {inrement value 2}
          mov di,d                 {inrement value 2 - diff in Y}
          mov cx,x1; cmp cx,x2;
          jg @left                 {check if line is doing left or right}
            mov cx,dfy
            @Runloop:
              mov es:[bx],ah       {write to screen}
              add bx,SC.offsw         {increment screen address}
              cmp di,0
              jl @noinc
                add di,incr2
                shl al,1           {shift bit mask along}
                test al,16          {do check:}
                jz @noreset       {if al=16 then...}
                  mov al,1         {reload al with 1}
                  inc bx           {increment address byte}
                @noreset:
                  out dx,al        {load mapmask register with bitmap}
                jmp @check         {don't do below code}
              @noinc:
                add di,si
              @check:
            loop @runloop
            jmp @end               {leave without doing below}
         @left:
            mov cx,dfy
            @Runloopb:
              mov es:[bx],ah       {write to screen}
              add bx,SC.offsw         {increment screen address}
              cmp di,0
              jl @noincb
                add di,incr2
                shr al,1           {shift bit mask along}
                jnc @noresetb      {do check: if carried then...}
                  mov al,8         {reload al with 8}
                  dec bx           {increment address byte}
                @noresetb:
                  out dx,al        {load mapmask register with bitmap}
                jmp @checkb        {don't do below code}
              @noincb:
                add di,si
              @checkb:
            loop @runloopb
          @end:
        end;
      end;
    end;
  end;
end;

Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
begin
end;

Procedure outtextxy(x1,y1:integer;txt:string);
var txtend,ylop,txtstart,lmask,rmask,cmask,txtlop,savelop:byte;
    Adrs,decoffs,Loffsw:word;
    x2,y2,tmp:integer;
Begin
  asm
    les si,[bp+6]                  {point to string}
    mov al,es:[si]                 {get length (first byte)}
    mov txtend,al
    xor ah,ah                      {clear top byte}
    mov al,txtend                  {x2:=x1+(txtend shl 3);}
    shl ax,3
    add ax,x1
    mov x2,ax

    mov ax,y1                      {y2:=y1+Fontmax;}
    add ax,Fontmax
    mov y2,ax
  end;

  if (x1<=sc.viewport.x2)and(y1<=sc.viewport.y2)and(x2>=sc.viewport.x1)
  and(y2>=sc.viewport.y1)and(txtend<>0) then begin
    asm
      mov ax,y1 ;imul SC.offsw
      mov di,x1 ;sar di,2
      add di,word ptr sc.scrptr
      add di,ax
      mov adrs,di
    end;

    {**X - Clipping**}
    lmask:=$ff; rmask:=$ff;
    Loffsw:=SC.offsw;
    txtstart:=1;
    tmp:=(sc.viewport.x1-x1);
    if x1<sc.viewport.x1 then begin
      lmask:=lmask shl (tmp and 7);
      {HACK!!!!! -to correct an error in start position. SORT IT OUT!}
      if (tmp and 7)>3 then dec(Adrs);
      inc(adrs,tmp shr 2);
      inc(txtstart,tmp shr 3);
    end;

    tmp:=(x2-sc.viewport.x2-1);
    if x2>sc.viewport.x2 then begin
      dec(txtend,tmp shr 3);
      rmask:=rmask shr (tmp and 7);
    end;
    if txtstart=txtend+1 then exit;

    {**Y-cliping**}
    If y2>sc.viewport.y2 then ylop:=(sc.viewport.y2-y1) else ylop:=Fontmax;
    if y1<sc.viewport.y1 then begin
      y1:=sc.viewport.y1-y1;
      inc(Adrs,y1*SC.offsw);
    end else y1:=0;
    dec(ylop,y1-1);
    decoffs:=(SC.offsw*(ylop)-2);
    asm
      mov di,adrs
      mov dx,SEQU_ADDR;
      mov al,mapmask_index;out dx,al              {set up mapmask}
      inc dx

      mov bx,x1                       {value to shift right by}
      and bl,3

      mov bh,t_col

      mov cl,txtstart ;xor ch,ch;       {load text loop}
      @Textloop:
        les si,[bp+6]                  {point to string}
        mov al,cl;xor ah,ah            {get txtloop from dh into ax}
        add si,ax                      {Add to offsets the offset of the..}
        mov al,es:[si] ;xor ah,ah      {..current character..}
        test al,255                    {for null terminated strings- }
        jz @end                        {exit if zero}
        shl ax,fontshift               {..shift to get the byte offset..}
        add ax,y1                      {..of the graphic and add y to clip}

        mov es,word ptr sc.scrptr+2                 {set up screen address segment}
          lea si,tcharset              {point to character set}
          add si,ax                    {add character offset}

          mov ch,ylop                  {set up y loop (from y to ylop)}
          mov txtlop,cl                {save current char}
          {generate mask}
          mov al,255
          cmp cl,txtstart;jnz @noleft
          and al,lmask               {mask with the left?}
          @noleft:
          cmp cl,txtend;  jnz @noright
          and al,rmask               {mask with the right?}
          @noright:
          mov cmask,al

          @drawloop:
            mov al,ds:[si]             {load from pic}
            and al,cmask

            xor ah,ah                  {clear top byte}
            mov cl,bl; rol ax,cl       {shift right by bl, into ah}
            out dx,al                  {write to mapmask}
            mov es:[di],bh             {write to screen memory}
            shr al,4;out dx,al         {isolate top 4 bits, write to mapmask}
            mov es:[di+1],bh           {write to screen memory}
            mov al,ah;out dx,al        {load end mask into al, write to mapmask}
            mov es:[di+2],bh           {write to screen memory}
            mov cl,txtlop              {restore curr character}

            add di,Loffsw              {shift to next line on screen}
            inc si                     {go to next byte in pic}

            dec ch
          jnz @drawloop

        Sub di,decoffs                 {correct the screen position..}
        inc cl                         {next character}
        cmp cl,txtend                  {is it the end?}
      jle @Textloop                    {if not, do it all again}
      @end:
    end;
    {for txtlop:=1 to txtlop do begin
      currmask:=pointer(@tcharset^[ord(txt[txtlop])][y]);
      for lop:=0 to lop do begin
        hsub2(adrs,currmask^ shr dxr,currmask^ shl (8-dxr));
        inc(Adrs,offs);
        inc(currmask);
      end;
      dec(Adrs,decoffs);
    end;}

  end;
end;

Procedure Drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
begin
end;

Procedure Drawbytes(x1,y:Integer;pic:bytearray;nbytes:byte);
var lop,mask:byte; Adrs,Loffsw:word;
    x2:integer;
Begin
  loffsw:=SC.offsw;
  x2:=x1+8;
  dec(nbytes);
  if (x2>=sc.viewport.x1)and(x1<=sc.viewport.x2)and(y+nbytes>=sc.viewport.y1)and(y<=sc.viewport.y2)then begin
  asm
     mov ax,y  ;imul SC.offsw
     mov bx,x1 ;sar bx,2
     add bx,word ptr sc.scrptr
     add ax,bx
     mov adrs,ax
   end;

  {**XCliping**}
  mask:=$ff;
  if x1<sc.viewport.x1 then
    mask:=$ff shl (sc.viewport.x1-x1);
  if x2>sc.viewport.x2 then
    mask:=mask and ($ff shr (x2-sc.viewport.x2-1));

  {**YCliping**}
  If y+nbytes>sc.viewport.y2 then lop:=(sc.viewport.y2-y) else lop:=nbytes;
  if y<sc.viewport.y1 then begin
     y:=sc.viewport.y1-y;inc(Adrs,y*SC.offsw);
  end else y:=0;
  dec(lop,y);
  asm
    mov es,word ptr sc.scrptr+2  {set up screen address}
    mov di,adrs

    mov dx,SEQU_ADDR;mov al,mapmask_index;out dx,al
    inc dx
    {values to shift left and right by}
    mov cx,x1
    and cl,3

    mov bh,t_col

    mov ch,lop ;inc ch
    push ds         {save data segment}
      lds si,pic
      add si,y
      @drawloop:
        mov ah,ds:[si]       {load from pic}
        and ah,mask
        xor al,al            {clear top mask}
        rol ax,cl            {shift right by cl, into ah}

        out dx,al            {write to mapmask}
        mov es:[di+2],bh     {write to screen memory}
        mov al,ah;out dx,al  {load end mask into al, write to mapmask}
        mov es:[di],bh       {write to screen memory}
        shr al,4;out dx,al   {isolate top 4 bits, write to mapmask}
        mov es:[di+1],bh     {write to screen memory}

        add di,loffsw         {shift to next line on screen}
        inc si               {go to next byte in pic}
        dec ch
      jnz @drawloop
    pop ds
  end;

  {for lop:=ystart to lop do begin
    hsub2(Adrs,pic^[lop] shr (dx),(pic^[lop] shl (8-dx)));
    inc(Adrs,offs);
  end;}
  end;
end;

Procedure Hline(x1,x2,y:Integer);assembler;
asm
  {es -screen seg
  di -byte offset
  ax -bit masks
  cx -X length of line in bytes-1}
  mov ax,y;mov bx,x1; mov cx,x2
  {swap x1,x1 if x1>x2}
  cmp bx,cx ;jle @no_swap ; Xchg bx,cx; @no_swap:

  {is line at all visable?}
  cmp bx,sc.viewport.x2 ;jg @fin
  cmp cx,sc.viewport.x1 ;jl @fin
  cmp ax,sc.viewport.y2 ;jg  @fin
  cmp ax,sc.viewport.y1 ;jl  @fin

  {X axis clipping}
  mov dx,sc.viewport.x1 ;cmp bx,dx ; JGE @nochange_x1
    mov bx,dx
  @nochange_x1:
  mov dx,sc.viewport.x2 ;cmp cx,dx ; JLE @nochange_x2
    mov cx,dx
  @nochange_x2:

  {start of mode dependant stuff}
  {load up screen position}
  mov es,word ptr sc.scrptr+2
  inc cx ; imul SC.offsw ;add ax,word ptr sc.scrptr; mov di,ax

  {select mapmask -the two least dig bits of X are mapmask}
  mov al,mapmask_index
  mov dx,SEQU_ADDR
  out dx,al

  mov si,cx                             {save cx}
    mov ax,$ffff                        {2nd mask }
    and cl,3 ;shl ah,cl ;not ah         {1st mask  }
    mov cx,bx; and cl,3 ;shl al,cl      {save cx}
  mov cx,si

  {calculate length (in bytes-1) of line}
  shr cx,2
  shr bx,2
  sub cx,bx

  add di,bx   {add this to screen memory offset}
  mov bh,t_col

  {get register data address ready.... -sequ_data_addr}
  inc dx

  {if there are only 4 pixels then do this only}
  cmp cl,0
  jnz @more
    and ah,al
    jmp @lastbyte
  @More:

  out dx,al
  mov es:[di],bh         {first}
  inc di                 {inc byte offset}

  cmp cl,1;jz @lastbyte  {if no body then go to the last byte}

  mov al,15              {else load up for body of line}
  out dx,al
  mov si,ax              {save ax}
    mov al,bh            {load up with colour}
    mov ah,al            {fill up all of ax}
    dec cl
    shr cl,1             {get word count}
    REP STOSW            {draw words}
    adc cl,cl            {extra byte?}
    REP STOSB            {do fill}
  mov ax,si              {retore ax}

  @lastbyte:
    mov al,ah
    out dx,al
    mov es:[di],bh
  @fin:
end;

procedure putpixel(x1,y1:integer);assembler;
asm
  {clipping}
  mov ax,y1 ;mov bx,x1
  cmp bx,sc.viewport.x1 ;jl @fin; cmp ax,sc.viewport.y1 ;jl @fin
  cmp bx,sc.viewport.x2 ;jg @fin; cmp ax,sc.viewport.y2 ;jg @fin

  {load up screen position}
  mov es,word ptr sc.scrptr+2

  mov cx,bx
  imul SC.offsw; add ax,word ptr sc.scrptr; mov di,ax
  shr bx,2;   add di,bx

  {select mapmask -the two least dig bits of X are mapmask}
  mov al,mapmask_index          {function select}
  mov ah,1 ;and cl,3; shl ah,cl {1 shl (X and 3)}

  mov dx,SEQU_ADDR
  out dx,ax

  mov al,t_col
  mov es:[di],al
@fin:
{  mem[word ptr sc.scrptr+2:(offs*y)+(x shr 2)]:=t_col;}
end;


Function getpixel(x1,y1:Integer):byte;
assembler;
asm
  mov ax,y1 ;mov bx,x1
  mov es,word ptr sc.scrptr+2

  mov cx,bx
  imul SC.offsw; add ax,word ptr sc.scrptr; mov di,ax
  shr bx,2;   add di,bx

  mov al,4             {set up read mask}
  and cl,3; mov ah,cl

  mov dx,GRPH_ADDR
  out dx,ax

  mov al,es:[di]
end;

Procedure Vline(x,y1,y2:Integer);assembler;
asm
  {remember that these registers are loaded thus:}
  mov ax,y1; mov bx,y2 ;mov cx,x
  {swap y2,y1 if y1>y2}
  cmp ax,bx ;jle @no_swap ; Xchg ax,bx; @no_swap:

  {is line at all visable?}
  cmp ax,sc.viewport.y2 ;jg @fin
  cmp bx,sc.viewport.y1 ;jl @fin
  cmp cx,sc.viewport.x2 ;jg @fin
  cmp cx,sc.viewport.x1 ;jl @fin

  {Y axis clipping}
  mov dx,sc.viewport.y1 ;cmp ax,dx ; JGE @nochange_y1
    mov ax,dx
  @nochange_y1:
  mov dx,sc.viewport.y2 ;cmp bx,dx ; JLE @nochange_y2
    mov bx,dx
  @nochange_y2:

  inc bx                                  {inc y2}
  sub bx,ax                               {calc length}

  mov es,word ptr sc.scrptr+2                          {load up screen position}
  imul SC.offsw; add ax,word ptr sc.scrptr;             {(ax*SC.offsw)+word ptr sc.scrptr (calculate)}
  mov dx,cx                               {make copy of x into dx}
  shr dx,2;   add ax,dx;    mov di,ax     {(+dx shr 2(address}
  and cl,3;   mov ah,$1;    shl ah,cl     {get mask}

  mov cx,bx                               {load length into cx}
  mov bx,SC.offsw                            {load screen width}

  mov al,mapmask_index                   {function select}
  mov dx,SEQU_ADDR                       {load up register address}
  out dx,ax                              {write mask,
                                         al=mapmask mode,ah=mask}
  mov al,t_col                           {load current colour into al}
  @runloop:
    mov es:[di],al
    add di,bx
  loop @runloop
  @fin:
end;


Procedure bar(x1,y,x2,y2:integer);assembler;
asm
  mov ax,x2 ;cmp x1,ax ;jle @no_swapx ; Xchg x1,ax; mov x2,ax ; @no_swapx:
  mov ax,y2 ;cmp y,ax ;jle @no_swapy ; Xchg y,ax; mov y2,ax ; @no_swapy:
  {is bar at all visable?}
  mov ax,x1 ;cmp ax,sc.viewport.x2 ;jg @end
  mov ax,x2 ;cmp ax,sc.viewport.x1 ;jl @end
  mov ax,y  ;cmp ax,sc.viewport.y2 ;jg @end
  mov ax,y2 ;cmp ax,sc.viewport.y1 ;jl @end

  {x axis clipping}
  mov ax,sc.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
    mov x1,ax
  @nochange_x1:
  mov ax,sc.viewport.x2 ;cmp x2,ax ; JLE @nochange_x2
    mov x2,ax
  @nochange_x2:
  {Y axis clipping}
  mov ax,sc.viewport.y1 ;cmp y,ax ; JGE @nochange_y1
    mov y,ax
  @nochange_y1:
  mov ax,sc.viewport.y2 ;cmp y2,ax ; JLE @nochange_y2
    mov y2,ax
  @nochange_y2:
  inc y2;inc x2

  {start of mode dependant stuff}
  {load up screen position}

  mov es,word ptr sc.scrptr+2
  mov ax,y ;imul SC.offsw ;add ax,word ptr sc.scrptr;mov di,ax

  mov al,mapmask_index            {select mapmask -the two}
  mov dx,SEQU_ADDR                {least sig bits of X are }
  out dx,al                       {the mapmask}

  mov ax,$ffff                    {1st mask}
  mov cx,x1;
  and cl,3 ;shl al,cl

  mov cx,x2 ;and cl,3             {2nd mask}
  shl ah,cl ;not ah

  mov cx,x2 ;shr cx,2             {calculate length (in bytes-1) of line}
  mov bx,x1 ;shr bx,2
  sub cx,bx

  add di,bx                       {add this to screen memory offset}
  mov si,SC.offsw
  sub si,cx

  mov bh,t_fillcol
  mov bl,cl
  cmp bl,0; jnz @noand
    and ah,al
  @noand:

  dec bl
  {get register data address ready.... -sequ_data_addr}
  inc dx
  mov cx,y2
  sub cx,y

  {if there are only 4 pixels then do this only}
  push bp                     {save stack frame}
  push ds
  @runloop:
    mov ds,cx

      mov cl,bl ;xor ch,ch    {load up loop counter with bl}
      cmp cl,255;jz @lastbyte {if only one byte then goto @lastbyte}

      out dx,al               {first byte}
      mov es:[di],bh
      inc di                  {inc byte offset}
      mov bp,ax               {save ax}
        shr cl,1
        mov al,15;            {else load up for body of line}
        out dx,al
        mov al,bh ;mov ah,al  {load up with colour}
        REP STOSW             {do fill}
        adc cl,cl             {extra byte?}
        REP STOSB             {fill it if there}
      mov ax,bp               {restore ax}

      @lastbyte:
      mov bp,ax               {save ax}
        mov al,ah
        out dx,al             {write bitmask to mapmask reg}
        mov es:[di],bh        {write to screen}
      mov ax,bp               {restore ax}
    mov cx,ds
    ADD di,si
  loop @runloop
  pop ds
  pop bp                      {restore stack frame}
  @end:
end;

Procedure Triangle(xa,ya,xb,yb,xc,yc:integer);assembler;
const shiftby=6;
Var
lop,Lx,Rx,
Lxadd,Rxadd,yrdiff,yldiff,xoff,Lxa,Rxa,xdiff,endp:integer;
right:boolean;
scrwidthet:word;
  {sort by Y}
  asm
    {if ya>yc then swap xc,xa swap yc,ya fswap ic,ia}
    mov ax,yc
    cmp ya,ax
    jl @NoSwapY1
      xchg ya,ax; mov yc,ax
       mov ax,xc; xchg xa,ax; mov xc,ax
    @NoSwapY1:
    {if ya>yb then swap xb,xa swap yb,ya fswap ib,ia}
    mov ax,yb
    cmp ya,ax
    jl @NoSwapY2
      xchg ya,ax; mov yb,ax
       mov ax,xb; xchg xa,ax; mov xb,ax
    @NoSwapY2:
    {if yb>yc then swap xc,xb swap yc,yb fswap ic,ib}
    mov ax,yc
    cmp yb,ax
    jl @NoSwapY3
      xchg yb,ax; mov yc,ax
      mov ax,xc; xchg xb,ax; mov xc,ax
    @NoSwapY3:

    {is the cross point to the left or right?}
    mov di,yc;sub di,ya
    mov ax,yb;sub ax,yc
    mov cx,xc;sub cx,xa
    imul cx
    cmp di,0
    jz @nodiv
      idiv di
    @nodiv:
    add ax,xc
    cmp xb,ax
    mov right,true
    jle @isright
      mov right,false
    @isright:
    {get largest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jg @nodo1 ;mov bx,ax ;@nodo1:
    mov ax,xc
    cmp bx,ax; jg @nodo2 ;mov bx,ax ;@nodo2:
    {if largest off screen then exit}
    cmp bx,sc.viewport.x1;jl @triend

    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo3 ;mov bx,ax ;@nodo3:
    mov ax,xc
    cmp bx,ax; jl @nodo4 ;mov bx,ax ;@nodo4:
    {if smallest off screen then exit}
    cmp bx,sc.viewport.x2;jg @triend

    mov xoff,bx
    {sub by bx and shift left}
    sub xa,bx
    sub xb,bx
    sub xc,bx

    shl xa,shiftby
    shl xb,shiftby
    shl xc,shiftby

    {get y length}
    mov si,yc
    cmp si,sc.viewport.y2
    jle @noyclip
      mov si,sc.viewport.y2
      inc si
    @noyclip:

    mov endp,si         {exit routine if ends of tri are outside VP}
    mov si,ya
    cmp si,sc.viewport.y2  {if ya>sc.viewport then exit}
    jg @triend
    cmp si,endp         {if ya=clipped yc then exit}
    jz @triend

    {yldiff:=yb-ya;if yldiff=0 then yldiff:=1;
    Lxadd:=(xb-xa) div yldiff;}
    mov ax,xb ;sub ax,xa
    mov bx,yb ;sub bx,ya
    jz @nodiv1
      cwd
      idiv bx
      jmp @nocorrect1
    @nodiv1:
      mov bx,1
    @nocorrect1:
    mov yldiff,bx
    mov lxadd,ax
    {yrdiff:=yc-ya;if yrdiff=0 then yrdiff:=1;
    Rxadd:=(xc-xa) div yrdiff;}
    mov ax,xc ;sub ax,xa
    mov bx,yc ;sub bx,ya
    jz @nodiv2
      cwd
      idiv bx
      jmp @nocorrect2
    @nodiv2:
      mov bx,1
    @nocorrect2:
    mov yrdiff,bx
    mov rxadd,ax
    mov ax,xa
    mov Lxa,ax
    mov Rxa,ax
    {test for swap}
    test right,1
    jnz @isrightb
      mov ax,rxadd
      xchg lxadd,ax
      mov rxadd,ax
    @isrightb:

    mov es,word ptr sc.scrptr+2    {load up screen mem pos}
    mov dx,SEQU_ADDR  {ready mapmask}
    mov al,mapmask_index
    out dx,al
    mov cx,SC.offsw
    mov ax,ya ;imul cx ;add ax,word ptr sc.scrptr
    mov di,ax

    @Yloop:
      cmp si,yb
      jnz @Daltend
        {yldiff:=yc-yb;if yldiff=0 then yldiff:=1;}
        mov bx,yc ;sub bx,yb
        jnz @nocorrect; mov bx,1; @nocorrect:
        {Lxadd:=(xc-xb) div yldiff;}
        mov ax,xc; sub ax,xb
        cwd
        idiv bx
        mov bx,xb
        {test see which side these need to go in}
        test right,true
        jz @isleft
          mov lxadd,ax
          mov lxa,bx
          jmp @Daltend
        @isleft:
          mov rxadd,ax
          mov rxa,bx
      @Daltend:

      push di
      {inc x1a and x2a with the slope of line and inc offset}
      mov ax,Lxadd;add lxa,ax
      mov ax,Rxadd;add rxa,ax
      {if ylop>sc.viewport.y1 then....}
      mov ax,sc.viewport.y1 ;cmp ax,si ;jg @fin
      {convert the line to normal pixel-space}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff

      {flip- shouldn't have to but there ya go}
      cmp dx,cx ;jg @no_swap ; Xchg cx,dx; @no_swap: {if x1>x2 then swap}
      {if (x1>sc.viewport.x2)or(x2<sc.viewport.x1) then....}
      cmp cx,sc.viewport.x2 ;jg @fin
      cmp dx,sc.viewport.x1 ;jl @fin
      {X clipping}
      mov ax,sc.viewport.x1 ;cmp cx,ax ; JGE @nochange_x1
        mov cx,ax
      @nochange_x1:
      mov ax,sc.viewport.x2 ;cmp dx,ax ; JLE @nochange_x2
        mov dx,ax
      @nochange_x2:
      inc dx                   {correct dx}

      push cx                  {remeber x1}
        mov bx,$ffff
        and cl,3 ; shl bl,cl;  {1st mask }
        mov cx,dx; and cl,3;
        shl bh,cl; not bh      {2nd mask }
      pop cx                   {recall x1}

      shr cx,2;shr dx,2        {x1:=x1 shr 2; x2:=x2 shr 2}
      add di,cx                {add this to screen memory offset}
      sub dx,cx                {calc length into dx}
      mov cx,dx                {load length into cx}

      mov ah,t_fillcol

      mov dx,sequ_data_addr    {sequ data address}

      cmp cl,0
      jnz @more                {if there are only 4 pixels then do this only}
        and bh,bl
        jmp @lastbyte
      @More:

      mov al,bl ;out dx,al     {load mapmask}
      mov al,ah                {load colour}
      stosb                    {write byte}

      dec cl
      jcxz @lastbyte           {if no body then go to the last byte}

      mov al,15                {else load up for body of line}
      out dx,al                {load mapmask}
      mov al,ah                {fill up all of ax}
      shr cl,1                 {get word count}
      REP STOSW                {draw words}
      adc cl,cl
      REP STOSB                {do fill}

      @lastbyte:
        mov al,bh ;out dx,al   {load mapmask}
        mov al,ah              {load colour}
        mov es:[di],al
      @fin:
      pop di
      add di,SC.offsw             {inc address}
      inc si
      cmp si,endp
    jnz @yloop
    @TriEnd:
end;



Procedure GTriangle(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);
const shiftby=7;
Var
lop,Lx{,Rx},
endp,ylop,Lxadd,Rxadd,yrdiff,yldiff,xoff,Lxa,Rxa,li,ri,xdiff,cadd:integer;
Ri32,li32,Riadd32,liadd32,ia32,ib32,ic32:longint;
right:boolean;
scrwidth:word;

Begin
  {sort by Y}
  asm
    {if ya>yc then swap xc,xa swap yc,ya fswap ic,ia}
    mov ax,yc
    cmp ya,ax
    jl @NoSwapY1
      xchg ya,ax; mov yc,ax
       mov ax,xc; xchg xa,ax; mov xc,ax
       mov ax,ic; xchg ia,ax; mov ic,ax
    @NoSwapY1:
    {if ya>yb then swap xb,xa swap yb,ya fswap ib,ia}
    mov ax,yb
    cmp ya,ax
    jl @NoSwapY2
      xchg ya,ax; mov yb,ax
       mov ax,xb; xchg xa,ax; mov xb,ax
       mov ax,ib; xchg ia,ax; mov ib,ax
    @NoSwapY2:
    {if yb>yc then swap xc,xb swap yc,yb fswap ic,ib}
    mov ax,yc
    cmp yb,ax
    jl @NoSwapY3
       xchg yb,ax; mov yc,ax
       mov ax,xc; xchg xb,ax; mov xc,ax
       mov ax,ic; xchg ib,ax; mov ic,ax
    @NoSwapY3:
    {is the cross point to the left or right?}
    mov di,yc;sub di,ya
    mov ax,yb;sub ax,yc
    mov cx,xc;sub cx,xa
    imul cx
    cmp di,0
    jz @nodiv
      idiv di
    @nodiv:
    add ax,xc
    cmp xb,ax
    mov right,true
    jle @isright
      mov right,false
    @isright:

    {get largest x
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jg @nodo1 ;mov bx,ax ;@nodo1:
    mov ax,xc
    cmp bx,ax; jg @nodo2 ;mov bx,ax ;@nodo2:
    {if largest off screen then exit
    cmp bx,sc.viewport.x1;jl @triend

    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo3 ;mov bx,ax ;@nodo3:
    mov ax,xc
    cmp bx,ax; jl @nodo4 ;mov bx,ax ;@nodo4:
    {if smallest off screen then exit
    cmp bx,sc.viewport.x2;jg @triend}

    mov xoff,bx
    {sub by bx and shift left }
    sub xa,bx;
    sub xb,bx;
    sub xc,bx;

    sal xa,shiftby
    sal xb,shiftby
    sal xc,shiftby
  end;
  asm
    db 66h;shr word ptr ia,16;
    db 66h;shr word ptr ib,16;
    db 66h;shr word ptr ic,16;
  end;

  ylop:=ya;endp:=yc;
  if endp>sc.viewport.y2 then endp:=sc.viewport.y2+1;

  asm
    {yldiff:=yb-ya;if yldiff=0 then yldiff:=1;
    Lxadd:=(xb-xa) div yldiff;}
    mov ax,xb ;sub ax,xa
    mov bx,yb ;sub bx,ya
    jz @nodiv1
      cwd
      idiv bx
      jmp @nocorrect1
    @nodiv1:
      mov bx,1
    @nocorrect1:
    mov yldiff,bx
    mov lxadd,ax
    {yrdiff:=yc-ya;if yrdiff=0 then yrdiff:=1;
    Rxadd:=(xc-xa) div yrdiff;}
    mov ax,xc ;sub ax,xa
    mov bx,yc ;sub bx,ya
    jz @nodiv2
      cwd
      idiv bx
      jmp @nocorrect2
    @nodiv2:
      mov bx,1
    @nocorrect2:
    mov yrdiff,bx
    mov rxadd,ax
  end;
  {yrdiff:=yc-ya;if yrdiff=0 then yrdiff:=1;
  Rxadd:=(xc-xa) div yrdiff;}
  Lxa:=xa;Rxa:=xa;

  li32:=ia32;
  ri32:=ia32;
  liadd32:=(ib32-ia32)div yldiff;
  riadd32:=(ic32-ia32)div yrdiff;
  if not right then begin
    fswap(rxadd,lxadd,2);
    fswap(liadd32,riadd32,4);
  end;
  asm
    mov dx,SEQU_ADDR  {ready mapmask}
    mov al,mapmask_index
    out dx,al

    mov es,word ptr sc.scrptr+2    {load up screen mem pos}
    mov si,SC.offsw
    mov ax,ya ;imul si ;add ax,word ptr sc.scrptr
    mov scrwidth,ax
  end;
  while ylop<endp do begin
    if ylop=yb then begin
      {yldiff:=yc-yb;if yldiff=0 then yldiff:=1;}
      asm
        mov bx,yc ;sub bx,yb
        jnz @nocorrect
        mov bx,1
        @nocorrect:
        mov yldiff,bx
      end;
      if right then begin
        Lxadd:=(xc-xb) div yldiff;
        lxa:=xb;
        liadd32:=(ic32-ib32)div yldiff;
        li32:=ib32;
      end else begin
        rxadd:=(xc-xb) div yldiff;
        rxa:=xb;
        riadd32:=(ic32-ib32)div yldiff;
        ri32:=ib32;
      end;
    end;
    inc(li32,liadd32);
    inc(ri32,riadd32);
    
    li:=li32 shr 8;
    ri:=ri32 shr 8;
    {if (lxa shr shiftby)<sc.viewport.x1 then begin
       dec(li,(lxa-li) div yldiff);
    end;}
    asm
      {inc x1a and x2a with the slope of line and inc offset}
      mov ax,Lxadd;add lxa,ax
      mov ax,Rxadd;add rxa,ax
      {if ylop>sc.viewport.y1 then....}
      mov ax,sc.viewport.y1 ;cmp ax,ylop ;jg @fin
      {convert the line to normal pixel-space}
      {xa is in dx, xb is in cx}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff

      mov di,cx
      inc di
      sub di,dx                   {holds non clipped xdiff}
      {Xclipping}
      mov ax,sc.viewport.x2 ;cmp cx,ax ; JLE @nochange_x2
        mov cx,ax
      @nochange_x2:
      mov ax,sc.viewport.x1 ;cmp dx,ax ; JGE @nochange_x1
        mov dx,ax
      @nochange_x1:
      inc cx                      {correct x2}

      mov lx,dx
      sub cx,dx                   {calculate xdiff}
      jle @fin
      mov xdiff,cx                {save it}

      {generate colour interpoltaion addition}
      mov si,li                   {colour intensity start}
      mov ax,ri
      sub ax,si                   {load colour}
      CWD                         {put ax into AX:DX, with sign}
      idiv di                     {do it, baby}
      mov cadd,ax                 {load ax into erm... addi?}
      mov dx,lx
      {re-evaluate start address}
      mov di,scrwidth
      mov cx,dx                   {get the x value}
      shr cx,2                    {into byte range}
      add di,cx                   {add this to total}
      {generate start X mask}
      mov cx,dx                   {load up x value}
      and cl,3                    {get mask}
      mov al,1                    {Start mask}
      shl al,cl                   {shift in place}

      mov cx,xdiff                {xdiff is the length (xb-xa)}
      mov dx,sequ_data_addr

      push bp
      mov bp,Cadd                 {colour interpolation value}

      @drawloop:
        out dx,al            {single pixel bit mask}

        mov bx,si            {load colour}
        shr bx,8             {get it into non-fixed range}
        mov es:[di],bl       {write to screen}
        add si,bp            {add colour interpolation value}

        shl al,1             {shift pixel along}
        test al,16           {end of nibble?}
        jz @noinc            {if so then do this...}
          mov al,1           {reload bit mask at start of byte}
          inc di             {increment screen offset}
        @noinc:
      loop @drawloop
      pop bp
      @fin:
    end;
      {ci:=li;
      for lop:=Lx to Rx do begin
        t_col:=asr(ci);
        inc(ci,addi);
        putpixel(lop,ylop);
      end;}
    inc(scrwidth,SC.offsw);
    inc(ylop);
  end;
end;

{procedure Gline(xa,xb,ya,Cstrt,Cadd:integer);near;external;
procedure Gtri(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);external;}


Procedure Scrncpysub(scrnofst,ofset1,ofset2,xlen,ylen:word);assembler;
asm
  push ds
  mov es,word ptr sc.scrptr+2
  mov si,ofset1  {source pair}
  mov ds,word ptr sc.scrptr+2
  mov di,ofset2  {destination pair}
  mov ax,scrnofst
  mov cx,ylen
  mov bx,xlen
  shr bx,1
  @runloop:
    push cx
    mov cx,bx
    rep movsw
    pop cx
    add di,ax
    add si,ax
  loop @runloop
  pop ds
end;

Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
Begin
  {get all pixels}
  asm mov dx,SEQU_ADDR ;mov ax,allplanes+1; out dx,ax; end;
  if xd>sc.viewport.x2-x2 then x2:=sc.viewport.x2-xd;
  if yd>sc.viewport.y2-y2 then y2:=sc.viewport.y2-yd;
  if y2<1 then y2:=1;
  Scrncpysub(SC.offsw-x2 shr 2,
   (page1*SC.pagesize)+(y1*SC.offsw)+x1 shr 2,
   (page2*SC.pagesize)+(yd*SC.offsw)+xd shr 2,x2 shr 2,y2);
end;

Procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
var
  x2,y2:integer;
  picwidth,scrwidth,scrnpos,picpos,picseg:word;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;

  if (y1<=sc.viewport.y2) and(x1<=sc.viewport.x2)and(x2>sc.viewport.x1) and(y2>sc.viewport.y1) then begin
    picwidth:=size.x;
    scrwidth:=SC.offsw;
    picseg:=seg(flatdata^[0]);
    picpos:=ofs(flatdata^[0]);
    if x1<sc.viewport.x1 then inc(picpos,sc.viewport.x1-x1);
    if y1<sc.viewport.y1 then inc(picpos,size.x*(sc.viewport.y1-y1));
    asm
      {x clip is incremented cos we're talking width here, no cords}
      {X axis clipping}
      mov ax,sc.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
        mov x1,ax
      @nochange_x1:
      mov ax,sc.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
        mov x2,ax
      @nochange_x2:
      {Y axis clipping}
      mov ax,sc.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
        mov y1,ax
      @nochange_y1:
      mov ax,sc.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
        mov y2,ax

      @nochange_y2:

      mov es,word ptr sc.scrptr+2    {load up screen mem pos}
      mov bx,SC.offsw
      mov ax,y1 ;imul bx ;add ax,word ptr sc.scrptr
      mov bx,x1 ;shr bx,2
      add bx,ax
      mov scrnpos,bx

      mov ax,x2         {get x length}
      sub ax,x1
      mov x2,ax

      mov ax,y2         {get y length}
      sub ax,y1
      mov y2,ax

      mov dx,SEQU_ADDR  {ready mapmask}
      mov al,mapmask_index
      out dx,al
      {generate first pixel mask :1 shl (x1 and 3)}
      mov al,1
      mov cx,x1; and cl,3
      shl al,cl
      push ds           {save ds}
      mov ds,picseg

      mov bx,picwidth
      @runloop:
        mov di,scrnpos
        mov si,picpos
        mov dx,SEQU_DATA_ADDR  {ready mapmask}
        out dx,al              {single pixel bit mask}
        mov dx,scrwidth

        mov cx,y2
        @drawloop:
          mov ah,ds:[si]       {load from bitmap}
          mov es:[di],ah       {write to screen}

          add si,bx
          add di,dx
        loop @drawloop
        shl al,1               {shift pixel along}
        test al,16
        jz @noinc             {if so then do this...}
          mov al,1             {reload bit mask at start of byte}
          inc scrnpos          {increment screen offset}
        @noinc:
        inc picpos
        dec x2                 {dec scanline counter}
      jnz @runloop
      pop ds            {restore ds}
    end;
  end;
  end;
end;

Procedure putbitmapmask(x1,y1:integer;mask:byte;bitmap:bitmaptypeptr);
var
  x2,y2:integer;
  picwidth,scrwidth,scrnpos,picpos,picseg:word;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  if (y1<sc.viewport.y2) and(x1<sc.viewport.x2)and(x2>sc.viewport.x1) and(y2>sc.viewport.y1) then begin
    picwidth:=size.x;
    scrwidth:=SC.offsw;
    picpos:=ofs(flatdata^[0]);
    picseg:=seg(flatdata^[0]);
    if x1<sc.viewport.x1 then inc(picpos,sc.viewport.x1-x1);
    if y1<sc.viewport.y1 then inc(picpos,size.x*(sc.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,sc.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,sc.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,sc.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,sc.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:

      mov es,word ptr sc.scrptr+2    {load up screen mem pos}
      mov bx,SC.offsw
      mov ax,y1 ;imul bx ;add ax,word ptr sc.scrptr
      mov bx,x1 ;shr bx,2
      add bx,ax
      mov scrnpos,bx

      mov ax,x2         {get x length}
      sub ax,x1
      mov x2,ax

      mov ax,y2         {get y length}
      sub ax,y1
      mov y2,ax

      mov dx,SEQU_ADDR  {ready mapmask}
      mov al,mapmask_index
      out dx,al
      {generate first pixel mask :1 shl (x1 and 3)}
      mov al,1
      mov cx,x1; and cl,3
      shl al,cl
      push ds           {save ds}
      mov ds,picseg     {picture segment}

      mov bx,picwidth
      @runloop:
        mov di,scrnpos
        mov si,picpos
        mov dx,SEQU_DATA_ADDR  {ready mapmask}
        out dx,al              {single pixel bit mask}
        mov dx,scrwidth

        mov cx,y2
        @drawloop:
          mov ah,ds:[si]       {load from bitmap}
          cmp ah,mask
          jz @nodraw
            mov es:[di],ah       {write to screen}
          @nodraw:

          add si,bx
          add di,dx
        loop @drawloop
        shl al,1               {shift pixel along}
        test al,16           {end of nibble?}
        jz @noinc            {if so then do this...}
          mov al,1           {reload bit mask at start of byte}
          inc scrnpos        {increment screen offset}
        @noinc:
        inc picpos
        dec x2               {dec scanline counter}
      jnz @runloop
      pop ds            {restore ds}
    end;
  end;
  end;
end;

function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
var newpic:bitmaptypeptr;
  picwidth,scrwidth,scrnpos,picpos,picseg:word;
begin
  newpic:=CreateBitmap(x2,y2,8,BMflat);
  with newpic^ do begin
    picwidth:=size.x;
    scrwidth:=SC.offsw;
    picseg:=seg(flatdata^[0]);
    picpos:=ofs(flatdata^[0]);
    asm
      mov es,word ptr sc.scrptr+2    {load up screen mem pos}
      mov bx,SC.offsw
      mov ax,y1 ;imul bx ;add ax,word ptr sc.scrptr
      mov bx,x1 ;shr bx,2
      add bx,ax
      mov scrnpos,bx     {screen offset}

      mov dx,GRPH_ADDR  {ready mapmask}
      mov al,4
      out dx,al              {single pixel bit mask}

      {generate first pixel mask :1 shl (x1 and 3)}
      mov ax,x1; and al,3
      push ds           {save ds}
      mov ds,picseg

      mov bx,picwidth
      @runloop:
        mov di,scrnpos
        mov si,picpos

        mov dx,GRPH_DATA_ADDR  {ready mapmask}
        out dx,al              {single pixel bit mask}

        mov dx,scrwidth

        mov cx,y2
        @drawloop:
          mov ah,es:[di]       {read from screen}
          mov ds:[si],ah       {write to bitmap}

          add si,bx
          add di,dx
        loop @drawloop
        inc al
        cmp al,4               {end of nibble?}
        jnz @noinc              {if so then do this...}
          mov al,0             {reload bit mask at start of byte}
          inc scrnpos          {increment screen offset}
        @noinc:
        inc picpos
        dec x2               {dec scanline counter}
      jnz @runloop
      pop ds            {restore ds}
    end;
  end;
end;

Procedure QSetXY(x,y:integer);
begin
end;
Procedure Qwrite(count:word);
begin
end;

function Qget:byte;
begin
  Qget:=0;
end;


End.


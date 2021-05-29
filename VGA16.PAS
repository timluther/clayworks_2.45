Unit vga16;
{16 colour VGA driver (C) T.Lewis 1996}
{$X+}{$a+}
INTERFACE
{stuff to be preserved for mouse inter:
  GRPH_ADDR
  3,logicmode
  0,colour
  5,WriteMode (Normaly 3)
  4,ReadMask
}

uses gbasics,chardef,ttypes,tmaths;

Const



{VGA register locations}
MISC_ADDR=$3C2; MISC_READ_ADDR=$3CC;
ATTR_ADDR=$3c0; ATTR_DATA_ADDR=$3c1;
SEQU_ADDR=$3c4; SEQU_DATA_ADDR=$3c5;
CRTC_ADDR=$3D4; CRTC_DATA_ADDR=$3d5;
GRPH_ADDR=$3CE; GRPH_DATA_ADDR=$3CF;
STATUS_ADDR=$3da;

noclear=128;
allplanes=3841;

{Register masks}
data_rotate=$3;
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
{swaps two variables of arbitary length, inline into the code}
{stuff to be preserved for mouse inter:
  GRPH_ADDR
  3,logicmode
  0,colour
  5,WriteMode (Normaly 3)
  4,ReadMask
}
var
oldlogicmode,oldcolour,oldwritemode,oldreadmask:byte;

procedure savescreenregs;
begin
end;
procedure restorescreenregs;
begin
end;

function set_mode(mode:byte):boolean;
var installed:boolean;
begin
    if mode>100 then
      asm mov ax,4F02h;mov bh,01h;mov bl,mode;sub bl,100;int 10h end
    else
      asm mov al,mode;mov ah,0;int 10h end;
    asm
      {Natural state for the video mode}
      mov dx,GRPH_ADDR
      mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
      xor ax,ax;                        out dx,ax; {colour}
      mov ax,0B05h;                     out dx,ax; {writemode -3}
      mov ax,0007h;                     out dx,ax; {set colour don't care}
      mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}
      {correct oddering of the palette}
      mov cx,15
      @runloop:
        mov dx,STATUS_ADDR
        in al,dx
        mov dx,ATTR_ADDR
        mov al,cl
        out dx,al
        out dx,al
      loop @runloop
      mov dx,STATUS_ADDR
      in al,dx
      mov dx,ATTR_ADDR
      mov al,32;
      out dx,al
    end;

  set_mode:=TRUE;
  {PatternMask:=$A0000+65535;}
  {PatternAdrs:=PatternMask-8;}


end;



Procedure cleardevice;assembler;
Asm
  mov dx,GRPH_ADDR
  mov al,3;     mov ah,t_writemode; out dx,ax; {writemode}
  xor al,al;    mov ah,t_fillcol;   out dx,ax; {colour}
  mov ax,0B05h;                     out dx,ax; {writemode -3}
  mov ax,0007h;                     out dx,ax; {set colour don't care}
  mov ax,0FF08h;                    out dx,ax; {bitmask,255 func:8}

  les di,SC.scrptr
  mov ax,$ffff                   {set fill mask}
  mov cx,word ptr SC.pagesize                {byte count}
  shr cx,1                       {half that...}
  CLD                            {clear stuff}
  REP STOSW                      {write to screen}
End;

{clip a line against 'SC.viewport'}
function clip(var xas,yas,xbs,ybs:integer):boolean;
var code0,code1:byte;
var xa,ya,xb,yb:longint;
Begin
  xa:=xas;ya:=yas;xb:=xbs;yb:=ybs;

  While 0=0 do begin

    code0:=(byte(xb>SC.viewport.x2))+     {right  =$01}
           (byte(yb>SC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xb<SC.viewport.x1)shl 2)+{left   =$04}
           (byte(yb<SC.viewport.y1)shl 3) {above  =$08};

    code1:=(byte(xa>SC.viewport.x2))+     {right  =$01}
           (byte(ya>SC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xa<SC.viewport.x1)shl 2)+{left   =$04}
           (byte(ya<SC.viewport.y1)shl 3) {above  =$08};

    if boolean(code0 and code1) then begin
      clip:=false;exit;{Trivial reject}
    end else begin
      if not boolean(code0 or code1)then begin
         xas:=xa;yas:=ya;xbs:=xb;ybs:=yb;
         clip:=true;exit;{Trivial accept}
      end else If (code0=0) then begin
        fswap(code1,code0,1);
        fswap(xb,xa,4);
        fswap(yb,ya,4);
      end;
      if boolean(code0 and bellow) then begin
        inc(xb,(xa-xb)*(SC.viewport.y2-yb)div(ya-yb));
        yb:=SC.viewport.y2;
      end else if boolean(code0 and above) then begin
        inc(xb,(xa-xb)*(SC.viewport.y1-yb)div(ya-yb));
        yb:=SC.viewport.y1;
      end else if boolean(code0 and right) then begin
        inc(yb,(ya-yb)*(SC.viewport.x2-xb)div(xa-xb));
        xb:=SC.viewport.x2;
      end else if boolean(code0 and left) then begin
        inc(yb,(ya-yb)*(SC.viewport.x1-xb)div(xa-xb));
        xb:=SC.viewport.x1;
      end;
    end;
  end;
end;

{biechmans line drawing algo- bit optimization still needed}
Procedure Line(x1,y1,x2,y2:integer);
Var dfx,dfy,incr2:integer;
Begin
  if x1=x2 then vline(x1,y1,y2) else begin
    if y1=y2 then hline(x1,x2,y1) else
    if clip(x1,y1,x2,y2) then Begin
      dfx:=abs(x2-x1);dfy:=abs(y2-y1);
      asm
        mov dx,GRPH_ADDR
        mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
        xor al,al;    mov ah,t_col;       out dx,ax; {colour}
        mov ax,0B05h;                     out dx,ax; {writemode -3}
        mov ax,0007h;                     out dx,ax; {set colour don't care}
        mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}
        mov es,word ptr SC.scrptr+2

        {choose  here whether to do x or y indpendent}
        mov ax,dfx; cmp ax,dfy; jle @near_vertical   {if dfx>dfy then....}
          mov ax,x2  ; cmp x1,ax ; jle @no_swap
            Xchg x1,ax ; mov x2,ax
            mov ax,y2  ; Xchg y1,ax ; mov y2,ax;
          @no_swap:

          {get address}
          mov si,y1
          shl si,1
          mov bx,x1; shr bx,3
          add bx,word ptr Sc.startoffsets+si
          {offset now in bx}

          mov ax,dfy                    {difference in y}
          sub ax,dfx                    {subtract difference in x}
          shl ax,1                      {times by two and you've got incr2}
          mov incr2,ax                  {save it in here- goes into bp latter}

          mov dx,SC.offsw                  {load up scanline increment}
          mov ax,y1                     {is y2 less than y1?}
          cmp ax,y2
          jle @notneg; neg dx; @notneg: {then make it not negative}

          mov cx,x1  ;and cl,7          {get mask}
          mov al,128 ;shr al,cl         {get mask}

          mov cx,dfx ;inc cx            {load in the length}
          mov si,dfy ;shl si,1;         {get incr1}
          mov di,si  ;sub di,dfx        {get fractional counter}
          {mov ah,al                     {remember last drawpos}
          push bp                       {remember stack frame}
          mov bp,incr2

          {is the line stippled?}
          test maskbyte,255
          jnz @stiplinea

          @Runloopa:                     {start loop}
            and es:[bx],al              {write to screen}
            ror al,1                    {move index bit along 1}
            adc bx,0                    {increment draw offset if overflow}
            cmp di,0;jl @noinca          {new scan line?}
              add di,bp                 {update di,go to next scan line}
              add bx,dx                 {add scanline offset}
              jmp @checka
            @noinca:
              add di,si                 {update fractional part}
            @checka:
          dec cx;jnz @runloopa
          pop bp                        {recall stack frame}
          jmp @end_of_proc

          @stiplinea:
          {do stippled near horizontal line}
          @Runloopb:                     {start loop}
            test maskbyte,al
            jz @nodrawa
            and es:[bx],al              {write to screen}
            @nodrawa:
            ror al,1                    {move index bit along 1}
            adc bx,0                    {increment draw offset if overflow}
            cmp di,0;jl @noincb          {new scan line?}
              add di,bp                 {update di,go to next scan line}
              add bx,dx                 {add scanline offset}
              jmp @checkb
            @noincb:
              add di,si                 {update fractional part}
            @checkb:
          dec cx;jnz @runloopb
          pop bp                        {recall stack frame}
          jmp @end_of_proc

        @near_vertical:
          
          mov ax,y2  ; cmp y1,ax ; jle @no_swapb
            Xchg y1,ax ; mov y2,ax
            mov ax,x2  ; Xchg x1,ax ; mov x2,ax;
          @no_swapb:

          {get address}
          mov si,y1
          shl si,1
          mov bx,x1; shr bx,3
          add bx,word ptr Sc.startoffsets+si
          {offset now in bx}


          mov ax,dfx             {difference in x}
          sub ax,dfy             {subtract difference in y}
          shl ax,1               {times by two and you've got incr2}
          mov incr2,ax

          inc dfy                {add one to difference in y}
          mov dx,SC.offsw           {screen width}
          mov cx,x1  ;and cl,7   {get mask}
          mov al,$80 ;shr al,cl  {get mask}
          mov si,dfx; shl si,1   {integer increment}
          mov di,si              {copy diff in x*2}
          sub di,dfy             {(diff in X*2)-diff in y}
          mov ah,1               {stipple mask}

          mov cx,x1; cmp cx,x2;  {check if line is going..}
          jg @left               {..left or right}

          {do these loads for both directions because of the use of bp}
          mov cx,dfy             {difference in Y}
          push bp
          mov bp,incr2           {fractional increment}

          {is the line stippled?}
          test maskbyte,255
          jnz @stiplineb

          @Runloopc:
            and es:[bx],al       {Write to screen}
            add bx,dx            {next scan line}
            cmp di,0             {if no change}
            jl @noincc           {then don't do below}
              add di,bp          {do frac part}
              ror al,1           {rotate mask right}
              adc bx,0           {go to next byte on screen}
            jmp @checkc          {don't add di,si}
            @noincc:
              add di,si          {add frac part}
            @checkc:
          dec cx;jnz @runloopc
          jmp @end

          {stippled left near vertical}
          @stiplineb:
          @Runloope:
            test maskbyte,ah
            jz @nodrawb
            and es:[bx],al              {write to screen}
            @nodrawb:
            rol ah,1             {rotate stipple check mask}
            add bx,dx            {next scan line}
            cmp di,0             {if no change}
            jl @noince           {then don't do below}
              add di,bp          {do frac part}
              ror al,1           {rotate mask right}
              adc bx,0           {go to next byte on screen}
            jmp @checke          {don't add di,si}
            @noince:
              add di,si          {add frac part}
            @checke:
          dec cx;jnz @runloope
          jmp @end

          @left:
          {do these loads for both directions because of the use of bp}
          mov cx,dfy             {difference in Y}
          push bp
          mov bp,incr2           {fractional increment}
          {is the line stippled?}
          test maskbyte,255
          jnz @stiplinec

          @Runloopd:
            and es:[bx],al       {Write to screen}
            add bx,dx            {next scan line}
            cmp di,0             {if no change}
            jl @noincd           {then don't do below}
              add di,bp          {do frac part}
              rol al,1           {rotate mask left}
              sbb bx,0           {go to previous byte on screen}
            jmp @checkd          {don't add di,si}
            @noincd:
              add di,si          {add frac part}
            @checkd:
          dec cx;jnz @runloopd
          jmp @end

          {stippled right near vertical}
          @stiplinec:
          @Runloopf:
            test maskbyte,ah
            jz @nodrawc
            and es:[bx],al       {write to screen}
            @nodrawc:
            rol ah,1             {rotate stipple check mask}
            add bx,dx            {next scan line}
            cmp di,0             {if no change}
            jl @noincf           {then don't do below}
              add di,bp          {do frac part}
              rol al,1           {rotate mask left}
              sbb bx,0           {go to previous byte on screen}
            jmp @checkf          {don't add di,si}
            @noincf:
              add di,si          {add frac part}
            @checkf:
          dec cx;jnz @runloopf

        @end:
        pop bp
        @end_of_proc:
      end;
    end;
  end;
end;


{write a graphical text output to the screen.
  clipped to words and then to pixel bits}

    (*
Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
var txtend,ylop,txtstart,lmask,rmask,cmask:byte;
    Adrs,decoffs:word;
    x2,y2,tmp:integer;
Begin
  asm
    mov al,length                  {get length (first byte)}
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

  if (x1<=SC.viewport.x2)and(y1<=SC.viewport.y2)and(x2>=SC.viewport.x1)
  and(y2>=SC.viewport.y1)and(txtend<>0) then begin
    asm
      mov ax,y1 ;imul SC.offsw
      mov di,x1 ;sar di,3
      add di,word ptr SC.scrptr
      add di,ax
      mov adrs,di
    end;

    {**X - Clipping**}
    lmask:=$ff; rmask:=$ff;
    txtstart:=1;
    tmp:=(SC.viewport.x1-x1);
    if x1<SC.viewport.x1 then begin
      lmask:=lmask shr (tmp and 7);
      tmp:=tmp shr 3;
      inc(txtstart,tmp);
      inc(adrs,tmp);
    end;
    tmp:=(x2-SC.viewport.x2-1);
    if x2>SC.viewport.x2 then begin
      dec(txtend,tmp shr 3);
      rmask:=rmask shl (tmp and 7);
    end;
    if txtstart=txtend+1 then exit;

    {**Y-cliping**}
    If y2>SC.viewport.y2 then ylop:=(SC.viewport.y2-y1) else ylop:=Fontmax;
    if y1<SC.viewport.y1 then begin
      y1:=SC.viewport.y1-y1;inc(Adrs,y1*SC.offsw);
    end else y1:=0;
    dec(ylop,y1);
    decoffs:=(SC.offsw*(ylop+1)-1);
    asm
      mov dx,GRPH_ADDR
      mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
      xor al,al;    mov ah,t_col;       out dx,ax; {colour}
      mov ax,0B05h;                     out dx,ax; {writemode -3}
      mov ax,0007h;                     out dx,ax; {set colour don't care}
      mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}

      mov di,adrs                      {load offset}

      mov dx,x1                        {value to shift by}
      and dl,7

      mov bx,SC.offsw                     {load dx with screen offset}
      dec txtstart
      dec txtend
      mov dh,txtstart                  {dh is the loop counter}
      @Textloop:
        les si,txt                     {point to string}
        mov al,dh;xor ah,ah            {get txtloop from dh into ax}
        add si,ax                      {Add to offsets the offset of the..}
        mov al,es:[si] ;xor ah,ah      {..current character..}
        test al,255                    {for null terminated strings- }
        jz @end                        {exit if zero}
        shl ax,fontshift               {..shift to get the byte offset..}
        add ax,y1                      {..of the graphic and add y to clip}

        mov es,word ptr SC.scrptr+2                 {set up screen address segment}
        push ds                        {save data segment}
          lea si,tcharset              {point to character set}
          add si,ax                    {add character offset}
          mov cl,ylop ;inc cl          {set up y dec cx;jnz (from y to ylop)}
          {generate mask}
          mov al,255
          cmp dh,txtstart;jnz @noleft
            and al,lmask               {mask with the left?}
          @noleft:
          cmp dh,txtend;  jnz @noright
            and al,rmask               {mask with the right?}
          @noright:
          mov cmask,al
          mov ch,ylop ;inc ch          {set up y dec cx;jnz (from y to ylop)}
          @drawloop:
            mov al,ds:[si]             {load from pic}
            and al,cmask

            xor ah,ah                  {clear top byte}
            mov cl,dl; ror ax,cl       {shift right by dl}
            and es:[di],al             {write to screen memory}
            and es:[di+1],ah           {write overflow}

            add di,bx                  {shift to next line on screen}
            inc si                     {go to next byte in pic}
            dec ch
          jnz @drawloop
        pop ds                         {restore data segment}

        sub di,decoffs                 {correct the screen position..}
        inc dh                         {next character}
        cmp dh,txtend                  {is it the end?}
      jle @Textloop                    {if not, do it all again}
      @end:
    end;
  end;
end;*)

Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
var txtlop:byte;
Begin
  if tcharset.attrib<>CTproportional then
  for txtlop:=1 to length do begin
    drawbytes(x1,y1,@tcharset.typeface[byte(txt^)],fontheight);
    inc(x1,8);
    inc(txt);
  end else
  for txtlop:=1 to length do begin
    drawbytes(x1,y1,@tcharset.typeface[byte(txt^)],fontheight);
    inc(x1,tcharset.widths[byte(txt^)]);
    inc(txt);
  end;
end;

Procedure outtextxy(x1,y1:integer;txt:string);
Begin
  outtextxy_length(x1,y1,@txt[1],byte(txt[0]));
end;

{in the C version, replace this with a macro}

Procedure Drawbytes(x1,y:Integer;pic:bytearray;nbytes:byte);
var lop,mask:byte; Adrs:word;
    x2:integer;
Begin
  x2:=x1+8;
  dec(nbytes);
  if (x2>=SC.viewport.x1)and(x1<=SC.viewport.x2)and(y+nbytes>=SC.viewport.y1)and(y<=SC.viewport.y2)then begin

  {**XCliping**}
  mask:=$ff;
  if x1<SC.viewport.x1 then
    mask:=$ff shr (SC.viewport.x1-x1);
  if x2>SC.viewport.x2 then
    mask:=mask and ($ff shl (x2-SC.viewport.x2-1));
  asm
     mov si,y
     shl si,1
     mov bx,x1 ;sar bx,3
     add bx,word ptr SC.scrptr
     add bx,word ptr SC.startoffsets+si
     mov adrs,bx
   end;

  {**YCliping**}
  If y+nbytes>SC.viewport.y2 then lop:=(SC.viewport.y2-y) else lop:=nbytes;
  if y<SC.viewport.y1 then begin
     y:=SC.viewport.y1-y;inc(adrs,SC.offsw*y);
  end else y:=0;
  dec(lop,y);

  asm
    mov dx,GRPH_ADDR
    mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
    xor al,al;    mov ah,t_col;       out dx,ax; {colour}
    mov ax,0B05h;                     out dx,ax; {writemode -3}
    mov ax,0007h;                     out dx,ax; {set colour don't care}
    mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}

    mov es,word ptr SC.scrptr+2  {set up screen address}
    mov di,adrs

    {values to shift left and right by}
    mov cx,x1
    and cl,7
    mov bh,mask

    mov ch,lop ;inc ch  {y loop counter}
    mov dx,SC.offsw        {load dx with screen offset}
    push ds             {save data segment}
      lds si,pic
      add si,y
      @drawloop:
        mov al,ds:[si]       {load from pic}
        and al,bh            {and with mask}
        xor ah,ah
        ror ax,cl            {shift right by bl}
        and es:[di],al       {write to screen memory}
        and es:[di+1],ah

        add di,dx            {shift to next line on screen}
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

Procedure drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
var ylop,xlenclipped,lmask,rmask,cmask:byte;
    Adrs,incpicoffs,incscroffs,picseg,picofs:word;
    x2,y2,tmp:integer;
Begin
  x2:=x1+xbytes shl 3;
  y2:=y1+ybytes;
  picseg:=seg(pic^);
  picofs:=ofs(pic^);

  if (x1<=SC.viewport.x2)and(y1<=SC.viewport.y2)and(x2>=SC.viewport.x1)
  and(y2>=SC.viewport.y1)and(xbytes<>0) then begin
    asm
      mov ax,y1 ;imul SC.offsw
      mov di,x1 ;sar di,3
      add di,word ptr SC.scrptr
      add di,ax
      mov adrs,di
    end;
    {**X - Clipping**}
    lmask:=$ff;rmask:=$ff;
    xlenclipped:=xbytes;
    incpicoffs:=0;

    tmp:=(SC.viewport.x1-x1);
    if x1<SC.viewport.x1 then begin
      lmask:=lmask shr (tmp and 7);
      tmp:=tmp shr 3;
      inc(picofs,tmp);
      inc(incpicoffs,tmp);
      dec(xlenclipped,tmp);
      inc(adrs,tmp);
    end;
    if incpicoffs=xbytes then exit;
    tmp:=(x2-SC.viewport.x2-1);
    if x2>SC.viewport.x2 then begin
      rmask:=rmask shl (tmp and 7);
      tmp:=tmp shr 3;
      dec(xlenclipped,tmp);
      inc(incpicoffs,tmp);
    end;

    {**Y-cliping**}
    If y2>SC.viewport.y2 then
      ylop:=(SC.viewport.y2-y1)+1
    else
      ylop:=ybytes;

    if y1<SC.viewport.y1 then begin
      y1:=SC.viewport.y1-y1;
      inc(adrs,SC.startoffsets[y1]);
      inc(picofs,y1*xbytes);
    end else y1:=0;

    dec(ylop,y1);
    incscroffs:=(SC.offsw-xlenclipped);

    asm
      mov dx,GRPH_ADDR
      mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
      xor al,al;    mov ah,t_col;       out dx,ax; {colour}
      mov ax,0B05h;                     out dx,ax; {writemode -3}
      mov ax,0007h;                     out dx,ax; {set colour don't care}
      mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}

      mov es,word ptr SC.scrptr+2
      mov di,adrs                      {load offset}

      mov cx,x1                        {value to shift by}
      and cl,7

      mov bl,lmask
      mov bh,rmask

      mov ch,ylop

      mov si,picofs                             {load up picture adrs}
      push ds
      mov ds,picseg

      @yloop:
        mov dh,xlenclipped                  {dh is the loop counter}
        @xloop:
          mov al,ds:[si]       {load from pic}
          cmp dh,xlenclipped;jnz @noleft
            and al,bl             {mask with the left?}
          @noleft:
          cmp dh,1;  jnz @noright
            and al,bh             {mask with the right?}
          @noright:
          xor ah,ah
          ror ax,cl            {shift right by cl}
          and es:[di],al       {write to screen memory}
          and es:[di+1],ah

          inc si                          {next pic byte}
          inc di                          {next screen byte}
          dec dh
        jnz @xloop

        add di,incscroffs                    {next line on screen}
        add si,incpicoffs
        dec ch
      jg @yloop
      pop ds

   end;
  end;
end;

Procedure Hline(x1,x2,y:Integer);assembler;
asm
mov dx,GRPH_ADDR
  mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
  xor al,al;    mov ah,t_col;       out dx,ax; {colour}
  mov ax,0B05h;                     out dx,ax; {writemode -3}
  mov ax,0007h;                     out dx,ax; {set colour don't care}
  mov ah,maskbyte;mov al,8;         out dx,ax; {bitmask,maskbyte func:8}

  mov ax,y;mov bx,x1; mov cx,x2
  {swap x1,x1 if x1>x2}
  cmp bx,cx ;jle @no_swap ; Xchg bx,cx; @no_swap:

  {is line at all visable?}
  cmp bx,SC.viewport.x2 ;jg @fin
  cmp cx,SC.viewport.x1 ;jl @fin
  cmp ax,SC.viewport.y2 ;jg  @fin
  cmp ax,SC.viewport.y1 ;jl  @fin

  {X axis clipping}
  mov dx,SC.viewport.x1 ;cmp bx,dx ; JGE @nochange_x1
    mov bx,dx
  @nochange_x1:
  mov dx,SC.viewport.x2 ;cmp cx,dx ; JLE @nochange_x2
    mov cx,dx
  @nochange_x2:

  {Get starting byte to work on}

  mov si,ax
  shl si,1
  mov di,word ptr SC.startoffsets+si
  add di,word ptr SC.scrptr
  mov es,word ptr SC.scrptr+2
  inc cx

  mov dl,cl                           {save cl}
    mov ax,$ffff                      {2nd mask }
    and cl,7 ; shr ah,cl ;not ah      {x2 already loaded into cx}
    mov cl,bl; and cl,7  ;shr al,cl   {1st mask ,load x1 (in bx) into cx}

    {and ax,maskword}
  mov cl,dl                           {restore cl}

  {calculate length (in bytes-1) of line}
  shr cx,3                           {x2 in byte range}
  shr bx,3                           {x1 in byte range}
  sub cx,bx                          {get byte length}
  {shr cx,3}
  add di,bx                          {add this to screen memory offset}
  mov bx,ax                          {get masks from ax}

  {///////2 COLOUR BACKGROUND FILLED PATTERN/////////////////////////}

  test maskbackground,true
  jz @normalfill
    cmp cl,0; jnz @more1                {if there is only one byte then do only this}
      and bh,bl
    @More1:

    mov dx,GRPH_ADDR
    mov ah,$ff;mov al,8;         out dx,ax; {bitmask,$ff func:8}

    {/////////////EDGES OF SOLID PATTERN FILL////////////////}
    mov al,maskbyte
    and es:[64427],al                  {copy to top of screen memory}
    push bx
      and bl,al
      and bh,al
      cmp cx,0
      jz @lastbyteb               {if only one byte then goto @lastbyte}
        and es:[di],bl              {write to screen}
        add di,cx                      {next byte}
      @lastbyteb:
        and es:[di],bh              {write to screen}
    pop bx

    sub di,cx                  {restore di to original value}

    xor al,al;    mov ah,t_fillcol;  out dx,ax; {setup inverse colour}

    mov al,maskbyte
    not al
    and es:[64427],al                  {copy to top of screen memory}
    and bl,al
    and bh,al

    cmp cx,0
    jz @lastbytec               {if only one byte then goto @lastbyte}
      and es:[di],bl              {write to screen}
      add di,cx                   {next byte}
    @lastbytec:
      and es:[di],bh              {write to screen}

    sub di,cx                   {restore di to original value}

    cmp cl,0
    jle @fin

    {/////////////BODY OF SOLID PATTERN FILL////////////////}
    dec cl
    inc di

    mov ax,00008h;out dx,ax     {set bitmask to 0}
    and al,es:[64427]
    shr cl,1                    {word length}
    REP STOSw                   {write words}
    adc cl,cl                   {extra byte?}
    REP STOSb                   {write byte if there}

  jmp @fin
  {///////NORMAL FILL PATTERN/////////////////////////}

  @normalfill:

  cmp cl,0; jnz @more                {if there is only one byte then do only this}
    and bh,bl
    jmp @lastbyte
  @More:

  and es:[di],bl                     {first byte}
  inc di                             {inc byte offset}

  dec cl                             {one less for count}
  jcxz @lastbyte                     {if no '$ff' body then go to the last byte}
  mov ax,$ffff                       {load up for body of line}
  test maskbyte,255
  jnz @runloop
  test T_writemode,0;
  {mov ax,maskword}
  Jnz @runloop                       {if T_writmode<>0 then goto runloop}
    shr cl,1                         {get word count}
    REP stosw                        {store words}
    adc cl,cl                        {extra byte?}
    REP stosb                        {Draw if there}
  jmp @lastbyte

  @runloop:                          {Do this for checking bytes -xor putting}
    and es:[di],al
    inc di
  dec cx;jnz @runloop

  @lastbyte:
    and es:[di],bh                   {write to screen}
  @fin:
  {reset bitmask
  mov dx,GRPH_ADDR
  mov ax,0FF08h;                    out dx,ax; {bitmask,255 func:8}
end;


Procedure putpixel(x1,y1:Integer);
begin
asm
  {if dot visable?}

  mov cx,x1 ;mov bx,y1
  cmp cx,SC.viewport.x1 ;jl @fin                   {clipping..}
  cmp bx,SC.viewport.y1 ;jl @fin
  cmp cx,SC.viewport.x2 ;jg @fin
  cmp bx,SC.viewport.y2 ;jg @fin

  mov dx,GRPH_ADDR
  mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
  xor al,al;    mov ah,t_col;       out dx,ax; {colour}
  mov ax,0B05h;                     out dx,ax; {writemode -3}
  mov ax,0007h;                     out dx,ax; {set colour don't care}
  mov ax,0FF08h;                    out dx,ax; {bitmask,255 func:8}

  shl bx,1
  mov di,word ptr SC.startoffsets+bx
  add di,word ptr SC.scrptr
  mov es,word ptr SC.scrptr+2
  {x-offset}
  mov bl,cl
  xor bh,bh
  and bl,7
  shr cx,3
  add di,cx

  mov al,byte ptr singlepixelbitmasks+bx

  and es:[di],al
  @fin:
end;
end;

Function getpixel(x1,y1:Integer):byte;assembler;
asm
  mov dx,GRPH_ADDR;mov ax,5; out dx,ax

  mov ah,$0d
  xor bh,bh
  mov dx,y1
  mov cx,x1
  int $10                        {value should be returned to al}

  mov bl,al

  mov dx,GRPH_ADDR;
  mov ax,0B05h;       out dx,ax;
  mov ax,0FF08h;      out dx,ax; {bitmask}
  mov al,bl
end;

Procedure Vline(x,y1,y2:Integer);assembler;
var
height:word;
asm


  mov dx,GRPH_ADDR
  mov al,data_rotate;mov ah,t_writemode; out dx,ax; {Logical mode}
  xor al,al;    mov ah,t_col;       out dx,ax; {colour}
  mov ax,0B05h;                     out dx,ax; {writemode -3}
  mov ax,0007h;                     out dx,ax; {set colour don't care}
  mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}

  {remember that these registers are loaded thus:}
  mov ax,y1; mov bx,y2 ;mov cx,x
  {swap y2,y1 if y1>y2}
  cmp ax,bx ;jle @no_swap ; Xchg ax,bx; @no_swap:

  cmp ax,SC.viewport.y2 ;jg @fin   {is line at all visable?}
  cmp bx,SC.viewport.y1 ;jl @fin
  cmp cx,SC.viewport.x2 ;jg @fin
  cmp cx,SC.viewport.x1 ;jl @fin

  {Y axis clipping}
  mov dx,SC.viewport.y1 ;cmp ax,dx ; JGE @nochange_y1
    mov ax,dx
  @nochange_y1:
  mov dx,SC.viewport.y2 ;cmp bx,dx ; JLE @nochange_y2
    mov bx,dx
  @nochange_y2:


  inc bx                                  {inc y2}
  sub bx,ax                               {calc length}
  mov height,bx

  {could use a lookup table for start memory addresses as well, cut out the multiply}

  mov es,word ptr SC.scrptr+2                          {load up screen position}

  mov si,ax
  shl si,1

  mov di,word ptr SC.startoffsets+si
  add di,word ptr SC.scrptr;             {(ax*SC.offsw)+word ptr SC.scrptr (calculate)}

  {get bitmask}
  mov si,cx
  and si,7
  mov al,byte ptr [singlepixelbitmasks+si]
  {add xoffset}
  shr cx,3
  add di,cx

  mov cx,SC.offsw                            {load screen width}


  test maskbyte,255
  jz @runloop
  {////MASKED LINE//////}
  push di                               {save screen offset}
  mov ah,maskbyte                       {copy mask in to ah}
  mov dl,1
  @runloopmask:
    test ah,dl                           {draw the pixel if ah and dl<>0}
    jz @nodraw
      and es:[di],al                    {write to screen}
    @nodraw:
    rol dl,1                            {shift mask}
    add di,cx                           {next pixel}
    dec bx
  jnz @runloopmask
  pop di                                {restore screen offset}
  mov bx,height
  test maskbackground,true
  jz @fin
    {////MASKED LINE WITH BACKGROUND//////}
    push ax
    mov dx,GRPH_ADDR
    xor al,al;    mov ah,t_fillcol;       out dx,ax; {colour}
    pop ax
    not ah
    mov dl,1
    @runloopmaskbackground:
      test ah,dl                           {draw the pixel if ah and dl<>0}
      jz @nodrawbackground
        and es:[di],al                    {write to screen}
      @nodrawbackground:
      rol dl,1                            {shift mask}
      add di,cx                           {next pixel}
      dec bx;
    jnz @runloopmaskbackground
    jmp @fin

    {////NO PATTERN//////}
    @runloop:
      and es:[di],al                        {write to screen}
      add di,cx                             {next pixel}
      dec bx
    jnz @runloop

  @fin:

end;

Procedure bar(x1,y,x2,y2:integer);assembler;
var
scroffs:word;
xlop:word;
mask:byte;

asm
  mov ax,x2 ;cmp x1,ax ;jle @no_swapx ; Xchg x1,ax; mov x2,ax ; @no_swapx:
  mov ax,y2 ;cmp y,ax ;jle @no_swapy ; Xchg y,ax; mov y2,ax ; @no_swapy:
  {is bar at all visable?}
  mov ax,x1 ;cmp ax,SC.viewport.x2 ;jg @end
  mov ax,x2 ;cmp ax,SC.viewport.x1 ;jl @end
  mov ax,y  ;cmp ax,SC.viewport.y2 ;jg @end
  mov ax,y2 ;cmp ax,SC.viewport.y1 ;jl @end

  mov dx,GRPH_ADDR
  mov al,3;     mov ah,t_writemode; out dx,ax; {writemode}
  xor al,al;    mov ah,t_fillcol;   out dx,ax; {colour}
  mov ax,0B05h;                     out dx,ax; {writemode -3}
  mov ax,0007h;                     out dx,ax; {set colour don't care}
  mov ax,0FF08h;                    out dx,ax; {bitmask,255 func:8}

  {x axis clipping}
  mov ax,SC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
    mov x1,ax
  @nochange_x1:
  mov ax,SC.viewport.x2 ;cmp x2,ax ; JLE @nochange_x2
    mov x2,ax
  @nochange_x2:
  {Y axis clipping}
  mov ax,SC.viewport.y1 ;cmp y,ax ; JGE @nochange_y1
    mov y,ax
  @nochange_y1:
  mov ax,SC.viewport.y2 ;cmp y2,ax ; JLE @nochange_y2
    mov y2,ax
  @nochange_y2:
  inc y2;inc x2

  mov di,x1

  mov es,word ptr SC.scrptr+2                  {calculate address}
  mov si,y
  shl si,1
  mov di,x1; shr di,3
  add di,word ptr Sc.startoffsets+si


  mov ax,$ffff                    {solid middle mask}

  mov si,x1
  and si,7
  mov bl,byte ptr left_pixelbitmasks+si

  mov si,x2
  and si,7
  mov bh,byte ptr right_pixelbitmasks+si



  shr x1,3
  shr x2,3
  mov dx,x2              {calculate length (in bytes-1) of line}
  sub dx,x1              {and shove in dx}

  mov cx,y2                       {calculate height}
  sub cx,y

  mov si,dx                       {copy no of bytes}
  sub si,SC.offsw                    {calculate add offset}

  cmp dl,0; jnz @noand
    and bh,bl;                    {make one mask}
  @noand:

  dec dl                          {correct dl}

  test nullpattern,1
  jz @patternfill
  {/////////////////////// SOLID FILL -NO PATTERN ///////////////////////}
    push bp                         {save stack frame}

    @runloop:
      mov bp,cx                     {save cx}
        mov cl,dl;  xor ch,ch       {load up length}
        cmp cl,255; jz @lastbyte    {if only one byte then goto @lastbyte}
        and es:[di],bl              {write to screen}
        inc di                      {next byte}

        shr cl,1                    {word length}
        REP STOSw                   {write words}
        adc cl,cl                   {extra byte?}
        REP STOSb                   {write byte if there}

        @lastbyte:
        and es:[di],bh              {write to screen}
        sub di,si
      mov cx,bp                     {restore cx}
    dec cx;jnz @runloop
    pop bp                          {restore stack frame}
  jmp @end

  @patternfill:
    mov scroffs,si                  {si is used, use variable for screenoffset}

    mov si,y                        {calculate byte offset into bitpattern}
    and si,7

    test maskbackground,1
    jz @runloopc {jump if not background}
      {else do the code for two colour patterns}
      {the two colour pattern is first loaded into high video memory
      and a dummy read (to load the vga latches) is initialized enabling
      fast writes to the vga using a pattern. for future reference, the
      pattern could be a combination of any 16 colours}

      xor dh,dh
      mov xlop,dx                 {dx is used, must use variable to remember xlop}
      mov dx,GRPH_ADDR            {set dx for graphics registers}


      {/////////////EDGES OF SOLID PATTERN FILL////////////////}
      inc xlop                    {for speed, is deced at the end of this block}

      push cx                     {save ylop}
      push di                     {save screen offset}
      @edgeloop:
        push bx                       {save masks}
          mov al,byte ptr fillpattern+si
          and bl,al
          and bh,al

          cmp byte ptr xlop,0
          jz @lastbyteb               {if only one byte then goto @lastbyte}

          and es:[di],bl              {write to screen}
          add di,xlop                      {next byte}

          @lastbyteb:
          and es:[di],bh              {write to screen}

          sub di,scroffs
        pop bx
        inc si
        and si,7
      dec cx;jnz @edgeloop
      pop di                            {restore screen offset}
      pop cx                            {restore ylop}

      xor al,al;    mov ah,t_col;  out dx,ax; {setup inverse colour}

      mov si,y                        {calculate byte offset into bitpattern}
      and si,7

      push cx                     {save ylop}
      push di                     {save screen offset}
      @edgeloop2:
        push bx                       {save masks}
          mov al,byte ptr fillpattern+si
          not al
          and bl,al
          and bh,al

          cmp byte ptr xlop,0
          jz @lastbytec               {if only one byte then goto @lastbyte}

          and es:[di],bl              {write to screen}
          add di,xlop                      {next byte}

          @lastbytec:
          and es:[di],bh              {write to screen}

          sub di,scroffs
        pop bx
        inc si
        and si,7
      dec cx;jnz @edgeloop2
      pop di                            {restore screen offset}
      pop cx                            {restore ylop}

      dec xlop                          {restore xlop to orig value}

      cmp byte ptr xlop,0
      jle @end

      {/////////////BODY OF SOLID PATTERN FILL////////////////}

      xor al,al;    mov ah,t_fillcol;  out dx,ax; {setup inverse colour}
      {set up 2 colour 8*8 bitpattern in hight video memory}
      xor si,si                    {use si as count register, set to 0}
      @firstcolloop:
        mov al,byte ptr fillpattern+si        {copy byte pattern}
        and es:[64427+si],al                    {copy to top of screen memory}
        inc si
        cmp si,8                              {end of loop?}
      jnz @firstcolloop                       {loop it}
      xor al,al;    mov ah,t_col;  out dx,ax; {setup inverse colour}
      xor si,si                               {use si as count register, set to 0}
      @secondcolloop:
        mov al,byte ptr fillpattern+si        {copy byte pattern}
        not al                                {inverse byte pattern}
        and es:[64427+si],al                    {copy to top of screen memory}
        inc si
        cmp si,8                              {end of loop?}
      jnz @secondcolloop                      {loop it}
      xor si,si
      xor al,al;    mov ah,t_fillcol;  out dx,ax; {setup inverse colour}

      mov si,y                        {calculate byte offset into bitpattern}
      and si,7

      dec scroffs                 {fiddle these for speed}
      inc di
      mov ax,00008h;out dx,ax     {set bitmask to 0}
      @runloopb:
        push cx
          mov cx,xlop                 {load up length}
          and al,es:[64427+si]
          shr cl,1                    {word length}
          REP STOSw                   {write words}
          adc cl,cl                   {extra byte?}
          REP STOSb                   {write byte if there}
          sub di,scroffs
        pop cx
        inc si
        and si,7
      dec cx;jnz @runloopb
      jmp @end


    {////////////////TRANSPARENT PATTERN FILL////////////////}
    @runloopc:
      push bx                       {save masks}
      mov al,byte ptr fillpattern+si

      and bh,al
      and bl,al
      push cx
        mov cl,dl
        xor ch,ch                   {load up length}
        cmp cl,255
        jz @lastbyted               {if only one byte then goto @lastbyte}
        and es:[di],bl              {write to screen}
        inc di                      {next byte}

        cmp cl,0
        jz @lastbyted

        @drawlopx:
          and es:[di],al              {write to screen}
          inc di                      {next byte}
        dec cx;jnz @drawlopx

        @lastbyted:
        and es:[di],bh              {write to screen}
        sub di,scroffs
      pop cx
      pop bx
      inc si
      and si,7
    dec cx;jnz @runloopc
  @end:
end;

{l shifts.obj
Function asr(num:Longint;shiftby:byte):Longint; near; external;
Function asl(num:Longint;shiftby:byte):Longint; near; external;}

Procedure GTriangle(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);
const shiftby=7;
Var
lop,Lx{,Rx},
endp,ylop,Lxadd,Rxadd,yrdiff,yldiff,xoff,Lxa,Rxa,li,ri,xdiff,cadd:integer;
Ri32,li32,Riadd32,liadd32,ia32,ib32,ic32:longint;
right:boolean;
scroffset:word;

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
    mov right,1
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
    cmp bx,SC.viewport.x1;jl @triend

    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo3 ;mov bx,ax ;@nodo3:
    mov ax,xc
    cmp bx,ax; jl @nodo4 ;mov bx,ax ;@nodo4:
    {if smallest off screen then exit
    cmp bx,SC.viewport.x2;jg @triend}

    mov xoff,bx
    {sub by bx and shift left }
    sub xa,bx;
    sub xb,bx;
    sub xc,bx;

    sal xa,shiftby
    sal xb,shiftby
    sal xc,shiftby
  end;
  ia32:=ia * 65536 {asl(ia,16)};
  ib32:=ib * 65536 {asl(ib,16)};
  ic32:=ic * 65536 {asl(ic,16)};

  ylop:=ya;endp:=yc;
  if endp>SC.viewport.y2 then endp:=SC.viewport.y2+1;

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
    mov dx,GRPH_ADDR
    mov ax,0B05h;                     out dx,ax; {writemode -3}
    mov ax,0ff08h;                    out dx,ax; {bitmask,255 func:8}
    mov al,3;     mov ah,t_writemode; out dx,ax; {writemode}
    mov ax,0007h;                     out dx,ax; {set colour don't care}
    xor al,al;                        out dx,al; {setup for colours}
    

    mov es,word ptr SC.scrptr+2    {load up screen mem pos}
    mov si,SC.offsw
    mov ax,ya ;imul si ;add ax,word ptr SC.scrptr
    mov scroffset,ax
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
    {if (lxa shr shiftby)<SC.viewport.x1 then begin
       dec(li,(lxa-li) div yldiff);
    end;}
    asm
      {inc x1a and x2a with the slope of line and inc offset}
      mov ax,Lxadd;add lxa,ax
      mov ax,Rxadd;add rxa,ax
      {if ylop>SC.viewport.y1 then....}
      mov ax,SC.viewport.y1 ;cmp ax,ylop ;jg @fin
      {convert the line to normal pixel-space}
      {xa is in dx, xb is in cx}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff

      mov di,cx
      inc di
      sub di,dx                   {holds non clipped xdiff}
      {Xclipping}
      mov ax,SC.viewport.x2 ;cmp cx,ax ; JLE @nochange_x2
        mov cx,ax
      @nochange_x2:
      mov ax,SC.viewport.x1 ;cmp dx,ax ; JGE @nochange_x1
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
      mov di,scroffset
      mov cx,dx                   {get the x value}
      shr cx,3                    {into byte range}
      add di,cx                   {add this to total}
      {generate start X mask}
      mov cx,dx                   {load up x value}
      and cl,7                    {get mask}
      mov ah,128                  {Start mask}
      shr ah,cl                   {shift in place}

      mov cx,xdiff                {xdiff is the length (xb-xa)}
      mov dx,grph_data_addr

      push bp
      mov bp,Cadd                 {colour interpolation value}

      @drawloop:

        mov bx,si            {load colour}
        shr bx,8             {get it into non-fixed range}
        mov al,bl
        out dx,al            {Send colour}

        and es:[di],ah       {write to screen}
        add si,bp            {add colour interpolation value}

        ror ah,1             {shift pixel along}
        adc di,0
      dec cx;jnz @drawloop
      pop bp
      @fin:
    end;
      {ci:=li;
      for lop:=Lx to Rx do begin
        t_col:=asr(ci);
        inc(ci,addi);
        putpixel(lop,ylop);
      end;}
    inc(scroffset,SC.offsw);
    inc(ylop);
  end;
end;

{Procedure GTriangle(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);external;}

Procedure Triangle(xa,ya,xb,yb,xc,yc:integer);assembler;
const shiftby=6;
Var
lop,Lx,Rx,
Lxadd,Rxadd,yrdiff,yldiff,xoff,Lxa,Rxa,xdiff,endp:integer;
right:boolean;
scroffset:word;
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
    jz @nodiv                           {seems to be a div by zero error here}
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
    cmp bx,SC.viewport.x1;jl @triend

    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo3 ;mov bx,ax ;@nodo3:
    mov ax,xc
    cmp bx,ax; jl @nodo4 ;mov bx,ax ;@nodo4:
    {if smallest off screen then exit}
    cmp bx,SC.viewport.x2;jg @triend
    mov xoff,bx
    {sub by bx and shift left }
    sub xa,bx;
    sub xb,bx;
    sub xc,bx;

    shl xa,shiftby
    shl xb,shiftby
    shl xc,shiftby

    {get y length}
    mov si,yc
    cmp si,SC.viewport.y2
    jle @noyclip
      mov si,SC.viewport.y2
      inc si
    @noyclip:

    mov endp,si
    mov si,ya
    cmp si,SC.viewport.y2
    jg @triend
    cmp si,endp
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

    mov dx,GRPH_ADDR
    mov al,3;     mov ah,t_writemode; out dx,ax; {writemode}
    xor al,al;    mov ah,t_fillcol;   out dx,ax; {colour}
    mov ax,0B05h;                     out dx,ax; {writemode -3}
    mov ax,0007h;                     out dx,ax; {set colour don't care}
    mov ax,0FF08h;                    out dx,ax; {bitmask,255 func:8}

    mov es,word ptr SC.scrptr+2    {load up screen mem pos}
    mov cx,SC.offsw
    mov ax,ya ;imul cx ;add ax,word ptr SC.scrptr
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
      {if ylop>SC.viewport.y1 then....}
      mov ax,SC.viewport.y1 ;cmp ax,si ;jg @fin
      {convert the line to normal pixel-space}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff
      {flip- shouldn't have to but there ya go}
      cmp dx,cx ;jg @no_swap ; Xchg cx,dx; @no_swap: {if x1>x2 then swap}
      {if (x1>SC.viewport.x2)or(x2<SC.viewport.x1)=false then....}
      cmp cx,SC.viewport.x2 ;jg @fin
      cmp dx,SC.viewport.x1 ;jl @fin
      {X clipping}
      mov ax,SC.viewport.x1 ;cmp cx,ax ; JGE @nochange_x1
        mov cx,ax
      @nochange_x1:
      mov ax,SC.viewport.x2 ;cmp dx,ax ; JLE @nochange_x2
        mov dx,ax
      @nochange_x2:
      inc dx                   {correct x2}
        push cx                  {remeber x1}
          mov bx,$ffff
          and cl,7 ; shr bl,cl;  {1st mask }
          mov cl,dl; and cl,7;
          shr bh,cl; not bh      {2nd mask }
        pop cx                   {recall x1}
        shr cx,3;shr dx,3        {x1:=x1 shr 3; x2:=x2 shr 3}
        add di,cx                {add this to screen memory offset}
        sub dx,cx                {calc length into dx}
        mov cx,dx                {load length into cx}

        {///drawing loop///}
        {if there is only one byte then do only this}
        cmp cl,0
        jnz @more
          and bh,bl
          jmp @lastbyte
        @More:

        and es:[di],bl
        inc di

        dec cl                 {one less for count}
        jcxz @lastbyte         {if no '$ff' body then go to the last byte}
        mov ax,$FFFF
        shr cl,1               {get word count}
        REP STOSW              {store words}
        adc cl,cl              {extra byte?}
        REP STOSB              {draw if present}

        @lastbyte:
        and es:[di],bh
        @fin:
      pop di

      add di,SC.offsw             {inc address}
      inc si
      cmp si,endp
    jnz @yloop
    @TriEnd:
end;

procedure rorblock(block:pointer;xcount,ycount:word;shiftby:byte);assembler;
asm
  les di,block
  mov cl,shiftby
  @yloop:
    mov bx,xcount
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
    add di,xcount       {go to next line}
    inc di

    dec ycount
  jnz @yloop
end;

procedure rolblock(block:pointer;xcount,ycount:word;shiftby:byte);assembler;
asm
  les di,block
  mov cl,shiftby
  @yloop:
    mov bx,xcount
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
  dec ycount
  jnz @yloop
end;


Procedure adrsmode(mask:byte);assembler;
asm
  mov dx,GRPH_ADDR               {Graphics address}
  mov al,5;                      {function 5, address mode}
  mov ah,mask;                   {load mode}
  out dx,ax                      {write to port}
end;

procedure readmask(plane:byte);assembler;
asm
  mov dx,GRPH_ADDR              {Load graphics address}
  mov al,4                      {function 4-set readmask}
  mov ah,plane                  {Planes to mask}
  out dx,ax                     {write to port}
end;

function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
var newpic:bitmaptypeptr;
    lop:word;planelop:byte;
    adrs:byteptr;
begin
  newpic:=CreateBitmap(x2+8,y2+1,4,BMplanes);
  with newpic^ do begin
    adrsmode(0);
    Qbitoffset:=x1 and 7;
    for planelop:=0 to bitplanes-1 do begin
      readmask(planelop);
      adrs:=pointer(SC.scrptr);
      inc(adrs,(x1 shr 3)+(y1*SC.offsw));
      for lop:=0 to size.y-1 do begin
        move(adrs^,planedata[planelop]^[lop*xoff],xoff);
        inc(adrs,SC.offsw);
      end;
    end;
    readmask(3);
  end;
  getbitmap:=newpic;
end;

Procedure Scrncpysub(scrnofst,ofset1,ofset2,xlen,ylen:word);assembler;
asm
  push ds
  mov es,word ptr SC.scrptr+2
  mov si,ofset1  {source pair}
  mov ds,word ptr SC.scrptr+2
  mov di,ofset2  {destination pair}
  mov ax,scrnofst
  mov cx,xlen
  @runloop:
    push cx
    mov cx,xlen
    rep movsb
    pop cx
    add di,ax
    add si,ax
  dec cx;jnz @runloop
  pop ds
end;

Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
Begin
  if xd>SC.viewport.x2-x2 then x2:=SC.viewport.x2-xd;
  if yd>SC.viewport.y2-y2 then y2:=SC.viewport.y2-yd;
  if y2<1 then y2:=1;
  asm
    mov dx,GRPH_ADDR
    mov ax,261;                       out dx,ax {adrsmode=1}
    mov ax,513;                       out dx,ax {esetres=2}
    xor ax,ax;                        out dx,ax {colour=0}
    mov ax,$ff08;                     out dx,ax {bitmask=255}
  end;
  Scrncpysub(SC.offsw-x2 shr 3,
   (page1*SC.pagesize)+(y1*SC.offsw)+x1 shr 3,
   (page2*SC.pagesize)+(yd*SC.offsw)+xd shr 3,x2 shr 3,y2);
  {adrsmode(3);}
end;

Procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
var  picadrs,scradrs:^byte;
     bitoffs,lmask,rmask:byte;
     picofs,planeofs,tmp,addpicoffs,addscroffs:word;
     x2,y2,xlop,ylop:integer;
     bitlop:word;
begin
  with bitmap^ do begin
    x2:=x1+size.x;
    y2:=y1+size.y;
    if (x1<=SC.viewport.x2)and(y1<=SC.viewport.y2)and(x2>=SC.viewport.x1)and(y2>=SC.viewport.y1+1) then begin
      if bitmaptype=BMplanes then begin
        bitoffs:=(x1 and 7);
        lmask:=$ff shr bitoffs;
        rmask:=(not lmask);
        if bitoffs>qbitoffset then begin
          bitoffs:=bitoffs-qbitoffset;
          for bitlop:=0 to bitplanes-1 do begin
            picadrs:=@planedata[bitlop]^;
            rorblock(picadrs,xoff,size.y,bitoffs);
          end;

        end else if bitoffs<qbitoffset then begin
          bitoffs:=qbitoffset-bitoffs;
          for bitlop:=0 to bitplanes-1 do begin
            picadrs:=@planedata[bitlop]^;
            rolblock(picadrs,xoff,size.y,bitoffs);
          end;
        end;
        qbitoffset:=(x1 and 7);
        xlop:=xoff;
        ylop:=size.y;

        picofs:=0;
        addpicoffs:=0;
        {calculate screen offset}
        asm
          mov ax,word ptr SC.scrptr+2      {store screen offset into 'pscrn'}
          mov word ptr scradrs+2,ax

          mov si,y1
          shl si,1


          mov di,x1  ;sar di,3           {make copy of x1 into dx}
          add di,word ptr SC.scrptr                {(+dx shr 3(address}
          add di,word ptr SC.startoffsets+si

          mov word ptr scradrs,di
        end;
        {x1 clipping}
        if x1<SC.viewport.x1 then begin
          tmp:=((SC.viewport.x1-x1)+qbitoffset);
          lmask:=$ff shr (tmp and 7);
          tmp:=tmp shr 3;
          dec(xlop,tmp);
          inc(picofs,tmp);
          inc(scradrs,tmp);
        end;
        if x2>SC.viewport.x2 then begin
          tmp:=(x2-SC.viewport.x2)+(qbitoffset xor 7){-(size.x -(size.x shr 3 shl 3))};
          rmask:=$ff shl (tmp and 7);
          dec(xlop,tmp shr 3);
        end;

        {y1 clipping}
        if y1<SC.viewport.y1 then begin
          tmp:=(SC.viewport.y1-y1);
          dec(ylop,tmp);
          inc(picofs,tmp*xoff);
          inc(scradrs,tmp*SC.offsw);
        end;
        if y2>SC.viewport.y2 then begin
          tmp:=(y2-SC.viewport.y2)-1;
          dec(ylop,tmp);
        end;
        addscroffs:=SC.offsw-xlop;
        addpicoffs:=xoff-xlop;
        {update masks as well?}
        if xlop=1 then begin
          dec(addscroffs,1);
          dec(addpicoffs,1);
          lmask:=rmask and lmask;
          rmask:=0;
        end;
        Asm
          mov dx,GRPH_ADDR
          mov al,3;     mov ah,t_writemode; out dx,ax; {Logical mode}
          mov ax,05h;                       out dx,ax; {writemode -0}
          mov ax,0007h;                     out dx,ax; {set colour don't care}
          mov cx,4
          mov planeofs,12
          {dec planeofs                  { 1 less}
          {shl planeofs,2                {list of 32 pointers so times by 4 (shl 2)}

          @planeloop:
            push cx                       {save cx}
            push ds                       {save ds}
              {get address of bitplane}
              les di,bitmap                   {load up object pointer}
              add di,planeofs               {add bitplane offset}
              lds si,es:[di+offset planedata]     {load up segment}
              add si,picofs

              mov dx,SEQU_ADDR              {load Sequencer}
              mov al,2                      {function 2}
              mov ah,1;dec cl               {generate..}
              shl ah,cl                     {..pix mask}
              out dx,ax                     {write to port}

              mov bx,ylop                   {get height}
              mov cx,xlop                   {get byte width}

              les di,scradrs

              {ready bitmask}
              mov dx,GRPH_ADDR
              mov al,08h;               out dx,al {bitmask,255 func:8}
              inc dx

              @runloop:                   {start vertical loop}
                mov cx,xlop               {save screen height}

                mov al,lmask
                out dx,al
                mov ah,es:[di]
                movsb
                sub cx,2
                js @lastbyte

                mov al,$ff
                out dx,al

                shr cx,1                  {get word count}
                REP movsw                 {store words}
                adc cx,cx                 {extra byte?}
                REP movsb                 {Draw if there}

                @lastbyte:
                mov al,rmask
                out dx,al
                mov ah,es:[di]
                movsb

                add di,addscroffs         {screen update}
                add si,addpicoffs

                dec bx
              jnz @runloop
            pop ds
            pop cx
            sub planeofs,4
          dec cx;jnz @planeloop

          mov dx,SEQU_ADDR              {load Sequencer}
          mov ax,3842                   {function 2}
          out dx,ax                     {write to port}
        end;
      end else begin
        picadrs:=pointer(flatdata);
        if x1<SC.viewport.x1 then inc(picadrs,SC.viewport.x1-x1);
        if y1<SC.viewport.y1 then inc(picadrs,size.x*(SC.viewport.y1-y1));
        asm
          {x1 clip is incremented cos we're talking width here, no cords}
          {x1 axis clipping}
          mov ax,SC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
            mov x1,ax
          @nochange_x1:
          mov ax,SC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
            mov x2,ax
          @nochange_x2:
          {y1 axis clipping}
          mov ax,SC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
            mov y1,ax
          @nochange_y1:
          mov ax,SC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
            mov y2,ax
          @nochange_y2:
        end;
        xlop:=x2-x1;
        ylop:=y2-y1;
        addscroffs:=SC.offsw;
        addpicoffs:=size.x-xlop;
        scradrs:=pointer(SC.scrptr);
        inc(scradrs,(x1 shr 3)+(SC.offsw*y1));
        asm
          mov dx,GRPH_ADDR          {set bitmask up for writing}
          mov al,3;     mov ah,t_writemode; out dx,ax; {Logical mode}
          mov ax,517;   out dx,ax                 {set up mode 2}
          mov al,8;     out dx,al
          inc dx
          mov ah,128                {get start bitmask into ah}
          mov cx,x1
          and cl,7
          shr ah,cl

          push ds                   {save data segment}
          les di,scradrs
          lds si,picadrs

          @yloop:
            mov al,ah          {load starting bitmask}
            mov cx,xlop
            push di
            @xloop:
              out dx,al             {set bitmask}

              {read b4 write}
              mov bh,es:[di]
              mov bh,ds:[si]
              mov es:[di],bh
              inc si
              ror al,1            {rotate bitmask}
              adc di,0
            dec cx;jnz @xloop
            pop di

            add di,addscroffs
            add si,addpicoffs
            dec ylop
          jnz @yloop

          pop ds
        end;
      end;
    end;
  end;
end;

Procedure QSetXY(x,y:integer);
begin
end;
Procedure Qwrite(count:word);
begin
end;
function  Qget:byte;
begin
  Qget:=0;
end;


End.




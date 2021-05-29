Unit SVGA256;
INTERFACE
{Super VGA driver C. 1996 T.Lewis}

uses chardef,ttypes,gbasics,tmaths,vesainfo;
const
{VGA register locations}
MISC_ADDR=$3C2; MISC_READ_ADDR=$3CC;
ATTR_ADDR=$3c0; ATTR_DATA_ADDR=$3c1;
SEQU_ADDR=$3c4; SEQU_DATA_ADDR=$3c5;
CRTC_ADDR=$3D4; CRTC_DATA_ADDR=$3d5;
GRPH_ADDR=$3CE; GRPH_DATA_ADDR=$3CF;
STATUS_ADDR=$3da;

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
Procedure Drawbytes(x1,y1:Integer;pic:bytearray;nbytes:byte);
Procedure Drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
Procedure cleardevice;
procedure savescreenregs;
procedure restorescreenregs;

Procedure GetAreaUnderMouse(x,y:integer;buf:byteptr);
Procedure PutMouse(x,y:integer;buf:byteptr);
Procedure PutAreaUnderMouse(x,y:integer;buf:byteptr);

{quick generic interface to screen -good for file loading}
Procedure QSetXY(x,y:integer);
Procedure Qwrite(count:word);
function  Qget:byte;

var

oldscreenwindow:word;
setpagefunc:procedure;

Granularity:longint;
NumberOfSegments,currwin:word;

IMPLEMENTATION

procedure savescreenregs;assembler;
asm
  mov ax,4f05h
  mov bh,1
  xor bl,bl
  int 10h
  mov oldscreenwindow,dx
end;

procedure restorescreenregs;assembler;
asm
  mov dx,oldscreenwindow
  mov ax,4f05h;xor bx,bx;int 10h
end;

Procedure GetAreaUnderMouse(x,y:integer;buf:byteptr);
begin
end;
Procedure PutMouse(x,y:integer;buf:byteptr);
begin
end;
Procedure PutAreaUnderMouse(x,y:integer;buf:byteptr);
begin
end;


procedure setSVGA_window(win:word);assembler;
asm
  mov dx,win
  Cmp currwin,dx
  jz @nochange
    mov ax,4f05h
    xor bx,bx
    int 10h
  @nochange:
end;

function set_mode(mode:byte):boolean;

begin
    if getvesaheaderinfo(@SVGAheader)<>SVGAok then begin
      set_mode:=false;
      exit;
    end;
    if getvesainfo(@SVGAinfo,255+mode)=SVGAok then begin;
      setpagefunc:=SVGAinfo.WinFuncPtr;
    end;


{set up the video mode}
    asm

      mov ax,4F02h;
      mov bh,01h;
      mov bl,mode;
      int 10h



      mov dx,0
      mov currwin,dx
      xor bx,bx;
      call setpagefunc
    end;
  NumberOfSegments:=longint((SC.pagesize)div $ffff);

  set_mode:=TRUE;
end;

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
  mov dx,NumberOfSegments
  inc dx
  xor bx,bx
  @segloop:
    dec dx
    les di,SC.Scrptr

    call setpagefunc
    mov al,t_fillcol;mov ah,al
    mov cx,65536 shr 1
    cld
    rep stosw

    cmp dx,0
  jnz @segloop
  mov currwin,dx
End;

Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
var txtlop:byte;
Begin
  for txtlop:=1 to length do begin
    drawbytes(x1,y1,@tcharset.typeface[byte(txt^)],fontheight);
    inc(x1,tcharset.widths[byte(txt^)]);
    inc(txt);
  end;
end;

Procedure outtextxy(x1,y1:integer;txt:string);
var txtlop:byte;
Begin
  for txtlop:=1 to byte(txt[0]) do begin
    drawbytes(x1,y1,@tcharset.typeface[ord(txt[txtlop])],fontheight);
    inc(x1,tcharset.widths[ord(txt[txtlop])]);
  end;
end;

Procedure Drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
begin
end;

Procedure Drawbytes(x1,y1:Integer;pic:bytearray;nbytes:byte);
var lop,mask:byte;
    x2,yoff,xoff:integer;
    maxoffset:word;
Begin
  dec(nbytes);
  x2:=x1+8;
  if (x2>=SC.viewport.x1)and(x1<=SC.viewport.x2)and(y1+nbytes>=SC.viewport.y1)and(y1<=SC.viewport.y2)then begin
    {**XCliping**}
    mask:=$ff;
    if x1<SC.viewport.x1 then
      mask:=$ff shr (SC.viewport.x1-x1);
    if x2>SC.viewport.x2 then
      mask:=mask and ($ff shl (x2-SC.viewport.x2-1));

    {**YCliping**}
    If y1+nbytes>SC.viewport.y2 then lop:=(SC.viewport.y2-y1) else lop:=nbytes;
    if y1<SC.viewport.y1 then
      yoff:=SC.viewport.y1-y1
    else
      yoff:=0;
    inc(y1,yoff);
    dec(lop,yoff-1);
    maxoffset:=lop*SC.offsw;
    asm
      les di,SC.Scrptr                           {calculate screen pos}

      mov ax,y1
      imul SC.offsw
      add di,x1; add di,ax; adc dx,0           {add carray to dx (current SVGA window)}
      {set start svga window}


      {set start svga window}
      Cmp currwin,dx
      jz @nochange
        xor bx,bx;call setpagefunc
      @nochange:



      mov cl,lop
      xor ch,ch
      mov al,t_col

      mov bx,SC.offsw    {load dx with screen offset}
      sub bx,8
      mov xoff,bx

      cmp t_writemode,xorput
      jnz @normalput
        push ds         {save data segment}
          lds si,pic
          add si,yoff

          add di,maxoffset
          ja @withinsegment_01
            sub di,maxoffset
            @drawloop_01:
              push cx
                mov ah,ds:[si]
                and ah,mask
                mov cx,8
                @bitloop_01:
                  shl ah,1
                  jnc @nodraw_01
                    xor es:[di],al       {write to screen memory}
                  @nodraw_01:
                  inc di
                  jnz @nooverflow1_01
                    push ax
                    inc dx
                    xor bx,bx;call setpagefunc
                    pop ax
                  @nooverflow1_01:
                loop @bitloop_01

                add di,xoff            {shift to next line on screen}
                ja @nooverflow2_01
                  push ax
                  inc dx
                  xor bx,bx;call setpagefunc
                  pop ax
                @nooverflow2_01:
                inc si               {go to next byte in pic}
              pop cx
            loop @drawloop_01

          jmp @multiplesegments_01
          @withinsegment_01:
            sub di,maxoffset
            mov dx,xoff
            @drawloopb_01:
              push cx
                mov ah,ds:[si]
                and ah,mask
                mov cx,8
                @bitloopb_01:
                  shl ah,1
                  jnc @nodrawb_01
                    xor es:[di],al
                  @nodrawb_01:
                  inc di
                loop @bitloopb_01

                add di,dx
                inc si
              pop cx
            loop @drawloopb_01
          @multiplesegments_01:
        pop ds
        jmp @fin

      @normalput:
      push ds         {save data segment}
        lds si,pic
        add si,yoff

        add di,maxoffset
        ja @withinsegment
          sub di,maxoffset
          @drawloop:
            push cx
              mov ah,ds:[si]
              and ah,mask
              mov cx,8
              @bitloop:
                shl ah,1
                jnc @nodraw
                  mov es:[di],al       {write to screen memory}
                @nodraw:
                inc di
                jnz @nooverflow1
                  push ax
                  inc dx
                  xor bx,bx;call setpagefunc
                  pop ax
                @nooverflow1:
              loop @bitloop

              add di,xoff            {shift to next line on screen}
              ja @nooverflow2
                push ax
                inc dx
                xor bx,bx;call setpagefunc
                pop ax
              @nooverflow2:
              inc si               {go to next byte in pic}
            pop cx
          loop @drawloop

        jmp @multiplesegments
        @withinsegment:


          sub di,maxoffset
          mov dx,xoff
          @drawloopb:

              mov ah,ds:[si]
              and ah,mask
              test ah,128
              jz @nodraw1; mov es:[di],al; @nodraw1:
              inc di
              test ah,64
              jz @nodraw2; mov es:[di],al; @nodraw2:
              inc di
              test ah,32
              jz @nodraw3; mov es:[di],al; @nodraw3:
              inc di
              test ah,16
              jz @nodraw4; mov es:[di],al; @nodraw4:
              inc di
              test ah,8
              jz @nodraw5; mov es:[di],al; @nodraw5:
              inc di
              test ah,4
              jz @nodraw6 ;mov es:[di],al; @nodraw6:
              inc di
              test ah,2
              jz @nodraw7;  mov es:[di],al; @nodraw7:
              inc di
              test ah,1
              jz @nodraw8; mov es:[di],al; @nodraw8:
              inc di

              add di,dx
              inc si
              dec cl
          jnz @drawloopb
        @multiplesegments:
      pop ds
      @fin:

      mov currwin,dx
    end;
  end;

end;

{clip a line against 'SC.viewport'}
function clip(var xa,ya,xb,yb:integer):boolean;
var code0,code1:byte;
Begin
  While 0=0 do begin

    code0:=(byte(xb>SC.viewport.x2))+     {right  =$01}
           (byte(yb>SC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xb<SC.viewport.x1)shl 2)+{left   =$04}
           (byte(yb<SC.viewport.y1)shl 3) {above  =$08};

    code1:=(byte(xa>SC.viewport.x2))+     {right  =$01}
           (byte(ya>SC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xa<SC.viewport.x1)shl 2)+{left   =$04}
           (byte(ya<SC.viewport.y1)shl 3) {above  =$08};

    if (code0 and code1)<>0 then begin
      clip:=false;exit;{Trivial reject}
    end else begin
      if not(code0 or code1<>0)then begin
         clip:=true;exit;{Trivial accept}
      end else If (code0=0) then begin
        fswap(code1,code0,1);
        fswap(xb,xa,2);
        fswap(yb,ya,2);
      end;
      if (code0 and bellow)<>0 then begin
        inc(xb,(xa-xb)*(SC.viewport.y2-yb)div(ya-yb));
        yb:=SC.viewport.y2;
      end else if (code0 and above)<>0 then begin
        inc(xb,(xa-xb)*(SC.viewport.y1-yb)div(ya-yb));
        yb:=SC.viewport.y1;
      end else if (code0 and right)<>0 then begin
        inc(yb,(ya-yb)*(SC.viewport.x2-xb)div(xa-xb));
        xb:=SC.viewport.x2;
      end else if (code0 and left)<>0 then begin
        inc(yb,(ya-yb)*(SC.viewport.x1-xb)div(xa-xb));
        xb:=SC.viewport.x1;
      end;
    end;
  end;
end;

{biechmans line drawing algo- bit optimization still needed}
Procedure Line(x1,y1,x2,y2:integer);
Var dfx,dfy,d,d2,incr1,incr2,xinc:integer;
adrs:longint;
currentwindow:word;
Begin

  if x1=x2 then vline(x1,y1,y2) else begin
    if y1=y2 then hline(x1,x2,y1) else
    if clip(x1,y1,x2,y2) then Begin
      currentwindow:=currwin;
      dfx:=abs(x2-x1);dfy:=abs(y2-y1);

      if T_writemode<>xorput then begin

        if dfx>dfy then begin
          asm
            mov ax,x2  ; cmp x1,ax ; jle @no_swap
              Xchg x1,ax ; mov x2,ax
              mov ax,y2; Xchg y1,ax;mov y2,ax;
            @no_swap:
          end;
          adrs:=(y1*SC.offsw) +x1;
          asm
            mov dx,word ptr adrs+2
            mov currentwindow,dx
            xor bx,bx;call setpagefunc
          end;
          incr2:=(dfy-dfx)shl 1;

          {shallow lines}
          if y2>y1 then asm
            mov al,t_col
            mov dx,SC.offsw                  {get scanline offset}
            les bx,SC.Scrptr
            add bx,word ptr adrs

            mov cx,dfx ;inc cx            {load in the length}
            mov si,dfy ;shl si,1;         {get incr1}

            mov di,si  ;sub di,dfx;       {get 'd'}

            @Runloop:                     {start loop}
              mov es:[bx],al
              inc bx
              {set svga window}
              jnz @nooverflow
                {bx should already be 0}
                inc currentwindow;mov dx,currentwindow
                call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
              @nooverflow:

              cmp di,0;jl @noinc        {new scan line?}
                add di,incr2            {update di}
                add bx,dx               {add scanline offset}
                {set svga window}
                ja @nooverflow1
                  push bx
                  inc currentwindow;mov dx,currentwindow
                  xor bx,bx; call setpagefunc
                  mov dx,SC.offsw;mov al,t_col
                  pop bx
                @nooverflow1:
              jmp @check
              @noinc:
                add di,si               {update fractional part}
              @check:
            loop @runloop
          end else asm

            mov al,t_col
            mov dx,SC.offsw                  {get scanline offset}
            les bx,SC.Scrptr
            add bx,word ptr adrs

            mov cx,dfx ;inc cx            {load in the length}
            mov si,dfy ;shl si,1;         {get incr1}
            mov di,si  ;sub di,dfx;       {get 'd'}

            @Runloop:                     {start loop}
              mov es:[bx],al
              inc bx
              {set svga window}
              jnz @nooverflow
                {bx should already be 0}
                inc currentwindow;mov dx,currentwindow
                xor bx,bx;call setpagefunc
                mov dx,SC.offsw;mov al,t_col
              @nooverflow:

              cmp di,0;jl @noinc        {new scan line?}
                add di,incr2            {update di}

                sub bx,dx               {sub scanline offset}
                {set svga window}
                jnc @nooverflow1
                  push bx
                  dec currentwindow;mov dx,currentwindow
                  xor bx,bx; call setpagefunc
                  mov dx,SC.offsw;mov al,t_col
                  pop bx
                @nooverflow1:

              jmp @check
              @noinc:
                add di,si               {update fractional part}
              @check:
            loop @runloop
          end

        end else begin
          {steep lines}
          asm
            mov ax,y2  ; cmp y1,ax ; jle @no_swap
              Xchg y1,ax ; mov y2,ax
              mov ax,x2; Xchg x1,ax;mov x2,ax;
            @no_swap:
          end;
          adrs:=(y1*SC.offsw) +x1;
          d2:=dfx shl 1;
          d:=d2-dfy;
          incr1:=d2;
          incr2:=(dfx-dfy) shl 1;
          asm
            {set svga window}
            mov dx,word ptr adrs+2
            Cmp currentwindow,dx
            jz @nochange
              mov currentwindow,dx
              xor bx,bx;call setpagefunc
            @nochange:

            inc dfy                {add one to difference in y}
            mov dx,SC.offsw            {screen width}
            les bx,SC.Scrptr           {point to screen}
            add bx,word ptr adrs

            mov al,t_col           {Colour}
            mov di,d               {(diff in X*2)-diff in y}
            mov si,incr1           {integer increment}

            mov cx,x1; cmp cx,x2;
            jg @left               {check if line is doing left or right}

            {do these loads for both directions because of the use of bp}
            mov cx,dfy             {difference in Y}
            @Runloop:
              mov es:[bx],al      {Write to screen}
              add bx,dx           {next scan line}
              {set svga window}
              ja @nooverflow2
                push bx
                inc currentwindow;mov dx,currentwindow
                xor bx,bx; call setpagefunc
                mov dx,SC.offsw;mov al,t_col
                pop bx
              @nooverflow2:
              cmp di,0            {if no change}
              jl @noinc           {then don't do below}
                add di,incr2      {do frac part}
                inc bx            {go to next byte on screen}
                {set svga window}
                jnz @nooverflow3
                  {bx should already be 0}
                  inc currentwindow;mov dx,currentwindow
                  xor bx,bx; call setpagefunc
                  mov dx,SC.offsw;mov al,t_col
                @nooverflow3:
                jmp @check
              @noinc:
                add di,si         {add frac part}
              @check:
            loop @runloop
            jmp @end

            @left:

            {do these loads for both directions because of the use of bp}
            mov cx,dfy            {difference in Y}
            @Runloopb:
              mov es:[bx],al      {Write to screen}
              add bx,dx           {next scan line}
              {set svga window}
              ja @nooverflow4
                inc currentwindow;mov dx,currentwindow
                push bx

                xor bx,bx; call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
                pop bx
              @nooverflow4:
              cmp di,0            {if no change}
              jl @noincb          {then don't do below}
                add di,incr2      {do frac part}
                cmp bx,0          {are we on zero?}
                {set svga window}
                jnz @nooverflow5
                  {if so, do bank switch}
                  dec currentwindow;mov dx,currentwindow
                  {push bx}
                  xor bx,bx;call setpagefunc;
                  mov dx,SC.offsw;mov al,t_col
                  {pop bx}
                  mov bx,65535
                  jmp @checkb
                @nooverflow5:
                dec bx           {otherwise, jump as normal}
                jmp @checkb
              @noincb:
                add di,si         {add frac part}
              @checkb:
            loop @runloopb
          @end:
          end;

        end;
        currwin:=currentwindow;
      end else begin
        if dfx>dfy then begin
          asm
            mov ax,x2  ; cmp x1,ax ; jle @no_swap
              Xchg x1,ax ; mov x2,ax
              mov ax,y2; Xchg y1,ax;mov y2,ax;
            @no_swap:
          end;
          adrs:=(y1*SC.offsw) +x1;
          asm
            mov dx,word ptr adrs+2
            mov currentwindow,dx
            xor bx,bx;call setpagefunc;
          end;
          incr2:=(dfy-dfx)shl 1;

          {shallow lines}
          if y2>y1 then asm
            mov al,t_col
            mov dx,SC.offsw                  {get scanline offset}
            les bx,SC.Scrptr
            add bx,word ptr adrs

            mov cx,dfx ;inc cx            {load in the length}
            mov si,dfy ;shl si,1;         {get incr1}

            mov di,si  ;sub di,dfx;       {get 'd'}

            @Runloop:                     {start loop}
              xor es:[bx],al
              inc bx
              {set svga window}
              jnz @nooverflow
                {bx should already be 0}
                inc currentwindow;mov dx,currentwindow
                call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
              @nooverflow:

              cmp di,0;jl @noinc        {new scan line?}
                add di,incr2            {update di}
                add bx,dx               {add scanline offset}
                {set svga window}
                ja @nooverflow1
                  push bx
                  inc currentwindow;mov dx,currentwindow
                  xor bx,bx; call setpagefunc;
                  mov dx,SC.offsw;mov al,t_col
                  pop bx
                @nooverflow1:
              jmp @check
              @noinc:
                add di,si               {update fractional part}
              @check:
            loop @runloop
          end else asm

            mov al,t_col
            mov dx,SC.offsw                  {get scanline offset}
            les bx,SC.Scrptr
            add bx,word ptr adrs

            mov cx,dfx ;inc cx            {load in the length}
            mov si,dfy ;shl si,1;         {get incr1}
            mov di,si  ;sub di,dfx;       {get 'd'}

            @Runloop:                     {start loop}
              xor es:[bx],al
              inc bx
              {set svga window}
              jnz @nooverflow
                {bx should already be 0}
                inc currentwindow;mov dx,currentwindow
                xor bx,bx;call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
              @nooverflow:

              cmp di,0;jl @noinc        {new scan line?}
                add di,incr2            {update di}

                sub bx,dx               {sub scanline offset}
                {set svga window}
                jnc @nooverflow1
                  push bx
                  dec currentwindow;mov dx,currentwindow
                  xor bx,bx; call setpagefunc;
                  mov dx,SC.offsw;mov al,t_col
                  pop bx
                @nooverflow1:

              jmp @check
              @noinc:
                add di,si               {update fractional part}
              @check:
            loop @runloop
          end

        end else begin
          {steep lines}
          asm
            mov ax,y2  ; cmp y1,ax ; jle @no_swap
              Xchg y1,ax ; mov y2,ax
              mov ax,x2; Xchg x1,ax;mov x2,ax;
            @no_swap:
          end;
          adrs:=(y1*SC.offsw) +x1;
          d2:=dfx shl 1;
          d:=d2-dfy;
          incr1:=d2;
          incr2:=(dfx-dfy) shl 1;
          asm
            {set svga window}
            mov dx,word ptr adrs+2
            Cmp currentwindow,dx
            jz @nochange
              mov currentwindow,dx
              xor bx,bx;call setpagefunc;
            @nochange:

            inc dfy                {add one to difference in y}
            mov dx,SC.offsw            {screen width}
            les bx,SC.Scrptr           {point to screen}
            add bx,word ptr adrs

            mov al,t_col           {Colour}
            mov di,d               {(diff in X*2)-diff in y}
            mov si,incr1           {integer increment}

            mov cx,x1; cmp cx,x2;
            jg @left               {check if line is doing left or right}

            {do these loads for both directions because of the use of bp}
            mov cx,dfy             {difference in Y}
            @Runloop:
              xor es:[bx],al      {Write to screen}
              add bx,dx           {next scan line}
              {set svga window}
              ja @nooverflow2
                push bx
                inc currentwindow;mov dx,currentwindow
                xor bx,bx; call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
                pop bx
              @nooverflow2:
              cmp di,0            {if no change}
              jl @noinc           {then don't do below}
                add di,incr2      {do frac part}
                inc bx            {go to next byte on screen}
                {set svga window}
                jnz @nooverflow3
                  {bx should already be 0}
                  inc currentwindow;mov dx,currentwindow
                  xor bx,bx;call setpagefunc;
                  mov dx,SC.offsw;mov al,t_col
                @nooverflow3:
                jmp @check
              @noinc:
                add di,si         {add frac part}
              @check:
            loop @runloop
            jmp @end

            @left:

            {do these loads for both directions because of the use of bp}
            mov cx,dfy            {difference in Y}
            @Runloopb:
              xor es:[bx],al      {Write to screen}
              add bx,dx           {next scan line}
              {set svga window}
              ja @nooverflow4
                inc currentwindow;mov dx,currentwindow
                push bx

                xor bx,bx; call setpagefunc;
                mov dx,SC.offsw;mov al,t_col
                pop bx
              @nooverflow4:
              cmp di,0            {if no change}
              jl @noincb          {then don't do below}
                add di,incr2      {do frac part}
                cmp bx,0          {are we on zero?}
                {set svga window}
                jnz @nooverflow5
                  {if so, do bank switch}
                  dec currentwindow;mov dx,currentwindow
                  {push bx}
                  xor bx,bx; call setpagefunc;
                  mov dx,SC.offsw;mov al,t_col
                  {pop bx}
                  mov bx,65535
                  jmp @checkb
                @nooverflow5:
                dec bx           {otherwise, jump as normal}
                jmp @checkb
              @noincb:
                add di,si         {add frac part}
              @checkb:
            loop @runloopb
          @end:
          end;

        end;
        currwin:=currentwindow;
      end;
    end;
  end;
end;

Procedure Hline(x1,x2,y:Integer);assembler;
asm
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

  {calculate length (in bytes) of line}
  sub cx,bx
  inc cx
  mov x2,cx

  {start of mode dependant stuff} {load up screen position}

  les di,SC.Scrptr                           {calculate screen pos}

  imul SC.offsw
  add di,ax;add di,bx; adc dx,0          {add carray to dx (current SVGA window)}

  {set start svga window}
  Cmp currwin,dx
  jz @nochange
    xor bx,bx;call setpagefunc;
  @nochange:

  mov al,t_col;mov ah,al

  cmp t_writemode,xorput
  jnz @normalput
  add di,cx
  ja @nooverflow
     sub di,cx
     mov bx,$FFFF               {biggest word size minus segment offset}
     sub bx,di
     inc bx
     mov cx,bx
     {draw first segment of line}
     @byteloop:
       xor es:[di],al
       inc di
     loop @byteloop

     {get length of rest of line into cx}
     mov cx,x2
     sub cx,bx

     {set svga window}
     inc dx
     xor bx,bx;call setpagefunc;
     {restore al}
     mov al,t_col;mov ah,al
     mov di,0              {begining of segment}

     {draw second segment of line}
     @byteloop2:
       xor es:[di],al
       inc di
     loop @byteloop2

     {set window counter}
     mov currwin,dx

     jmp @fin
  @nooverflow:
    sub di,cx
    @byteloop3:
       xor es:[di],al
       inc di
    loop @byteloop3

    {set window counter}
    mov currwin,dx
    jmp @fin
  {does it cross a window boundry?}
  @normalput:
  add di,cx
  ja @nooverflowb
     sub di,cx
     mov bx,$FFFF               {biggest word size minus segment offset}
     sub bx,di
     inc bx
     mov cx,bx
     {draw first segment of line}
     shr cx,1                         {get word count}
     REP stosw                        {store words}
     adc cx,cx                        {extra byte?}
     REP stosb                        {Draw if there}
     {get length of rest of line into cx}
     mov cx,x2
     sub cx,bx

     {set svga window}
     inc dx
     xor bx,bx;call setpagefunc;
     {restore al}
     mov al,t_col;mov ah,al
     mov di,0              {begining of segment}

     {draw second segment of line}
     shr cx,1                         {get word count}
     REP stosw                        {store words}
     adc cx,cx                        {extra byte?}
     REP stosb                        {Draw if there}

     {set window counter}
     mov currwin,dx

     jmp @fin
  @nooverflowb:
    sub di,cx
    shr cx,1                         {get word count}
    REP stosw                        {store words}
    adc cx,cx                        {extra byte?}
    REP stosb                        {Draw if there}

    {set window counter}
    mov currwin,dx

  @fin:
end;

Procedure Vline(x,y1,y2:Integer);assembler;
asm
  mov ax,y1; mov cx,y2 ;mov bx,x
  {swap y2,y1 if y1>y2}
  cmp ax,cx ;jle @no_swap ; Xchg ax,cx; @no_swap:

  cmp ax,SC.viewport.y2 ;jg @fin   {is line at all visable?}
  cmp cx,SC.viewport.y1 ;jl @fin
  cmp bx,SC.viewport.x2 ;jg @fin
  cmp bx,SC.viewport.x1 ;jl @fin

  {Y axis clipping}
  mov dx,SC.viewport.y1 ;cmp ax,dx ; JGE @nochange_y1
    mov ax,dx
  @nochange_y1:
  mov dx,SC.viewport.y2 ;cmp cx,dx ; JLE @nochange_y2
    mov cx,dx
  @nochange_y2:

  inc cx                                  {inc y2}
  sub cx,ax                               {calc length}

  les di,SC.Scrptr                           {calculate screen pos}

  imul SC.offsw
  add di,ax;add di,bx; adc dx,0          {add carray to dx (current SVGA window)}

  {change window?}
  xor bx,bx;
  cmp currwin,dx
  jz @nochange
    call setpagefunc;
  @nochange:

  mov si,SC.offsw                             {load screen width}
  mov al,t_col

  cmp t_writemode,xorput
  jnz @runloop

  @runloopb:
    xor es:[di],al                        {write to screen}
    add di,si                             {next pixel}
    ja @nooverflowb

      inc dx
      call setpagefunc
      mov al,t_col

    @nooverflowb:
  loop @runloopb
  mov currwin,dx
  jmp @fin

  @runloop:
    mov es:[di],al                        {write to screen}
    add di,si                             {next pixel}
    ja @nooverflow
      {set svga window}
      inc dx
      call setpagefunc
      mov al,t_col
    @nooverflow:
  loop @runloop
  mov currwin,dx
  @fin:
end;


Procedure bar(x1,y,x2,y2:integer);
Begin
  if x2<x1 then asm mov ax,x2;Xchg x1,ax;mov x2,ax;end;
  if y2<y then asm mov ax,y2;xchg y,ax;mov y2,ax;end;
  if (y>SC.viewport.y2)or(y2<SC.viewport.y1)or(x1>SC.viewport.x2)or(x2<SC.viewport.x1)=false then begin
    if x1<SC.viewport.x1 then x1:=SC.viewport.x1;if y<SC.viewport.y1 then y:=SC.viewport.y1;
    if x2>SC.viewport.x2 then x2:=SC.viewport.x2;if y2>SC.viewport.y2 then y2:=SC.viewport.y2;
    asm
      les di,SC.Scrptr                           {calculate screen pos}
      mov ax,y
      imul SC.offsw
      add di,ax;add di,x1; adc dx,0          {add carray to dx (current SVGA window)}

      Cmp currwin,dx
      jz @nochange
        xor bx,bx;call setpagefunc;
      @nochange:

      mov al,t_fillcol
      mov ah,al
      mov bx,x1
      sub x2,bx                         {get length of single line}
      inc x2

      mov si,SC.offsw
      sub si,x2

      mov bx,y  {load loop count -ycnt}
      sub y2,bx
      inc y2

      @runloop:
        mov cx,x2
        add di,cx
        ja @nooverflow
           sub di,cx
           mov bx,$FFFF               {biggest word size minus segment offset}
           sub bx,di
           inc bx                    {correct length}
           mov cx,bx
           {draw first segment of line}
           shr cx,1                         {get word count}
           REP stosw                        {store words}
           adc cx,cx                        {extra byte?}
           REP stosb                        {Draw if there}
           {get length of rest of line into cx}
           mov cx,x2
           sub cx,bx

           {set svga window}
           inc dx
           xor bx,bx;call setpagefunc;
           {restore al}
           mov al,t_fillcol;mov ah,al
           xor di,di             {begining of segment}

           {draw second segment of line}
           shr cx,1                         {get word count}
           REP stosw                        {store words}
           adc cx,cx                        {extra byte?}
           REP stosb                        {Draw if there}

           jmp @overflowed
        @nooverflow:
          sub di,cx
          shr cx,1
          rep stosw
          adc cx,cx
          rep stosb
        @overflowed:
        add di,si
        ja @nooverflow2
          inc dx
          xor bx,bx;call setpagefunc;
          {restore al}
          mov al,t_fillcol;mov ah,al
        @nooverflow2:

        dec y2
      jnz @runloop
      mov currwin,dx

    end;
  end;
end;

Procedure putpixel(x1,y1:Integer);assembler;
asm
  {if dot visable?}
  mov bx,x1 ;mov ax,y1
  cmp bx,SC.viewport.x1 ;jl @fin  {clipping..}
  cmp ax,SC.viewport.y1 ;jl @fin
  cmp bx,SC.viewport.x2 ;jg @fin
  cmp ax,SC.viewport.y2 ;jg @fin

  les di,SC.Scrptr                           {calculate screen pos}
  imul SC.offsw
  add di,bx; add di,ax;adc dx,0          {add carray to dx (current SVGA window)}

  {set svga window}
  Cmp currwin,dx
  jz @nochange
    mov currwin,dx;xor bx,bx;call setpagefunc;
  @nochange:

  {mov ax,4f05h;xor bx,bx;int 10h}

  mov al,t_col
  mov es:[di],al

  @fin:
end;

Function getpixel(x1,y1:Integer):byte;
begin
(*  asm
    les di,SC.Scrptr                           {calculate screen pos}
    imul SC.offsw
    add di,bx;; add di,ax; adc dx,0          {add carray to dx (current SVGA window)}

    {set svga window}
    Cmp currwin,dx
    jz @nochange
      mov currwin,dx;mov ax,4f05h;xor bx,bx;int 10h
    @nochange:

    mov al,es:[di]
    mov @result,al
  end;*)
end;

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
    jz @nodiv
      idiv di
    @nodiv:
    add ax,xc
    cmp xb,ax
    mov right,true
    jle @isright
      mov right,false
    @isright:
    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo1 ;mov bx,ax ;@nodo1:
    mov ax,xc
    cmp bx,ax; jl @nodo2 ;mov bx,ax ;@nodo2:
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

    mov endp,si         {exit routine if ends of tri are outside VP}
    mov si,ya
    cmp si,SC.viewport.y2  {if ya>SC.viewport then exit}
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

    mov es,word ptr SC.Scrptr+2    {load up screen mem pos}
    mov cx,SC.offsw
    mov ax,ya ;imul cx ;add ax,word ptr SC.Scrptr
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
      inc dx                   {correct dx}

      add di,cx                {add this to screen memory offset}
      sub dx,cx                {calc length into dx}
      mov cx,dx                {load length into cx}

      mov al,t_fillcol
      mov ah,al

      shr cl,1                 {get word count}
      REP STOSW                {draw words}
      adc cl,cl
      REP STOSB                {do fill}

      @fin:
    pop di
    add di,SC.offsw             {inc address}
    inc si
    cmp si,endp
  jnz @yloop
  @TriEnd:
end;


Procedure GTriangle(xa,ya,xb,yb,xc,yc,ia,ib,ic:integer);
const shiftby=6;
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
    mov right,true
    jle @isright
      mov right,false
    @isright:
    {get smallest x}
    mov bx,xa;
    mov ax,xb
    cmp bx,ax; jl @nodo1 ;mov bx,ax ;@nodo1:
    mov ax,xc
    cmp bx,ax; jl @nodo2 ;mov bx,ax ;@nodo2:
    mov xoff,bx
    {sub by bx and shift left }
    sub xa,bx;
    sub xb,bx;
    sub xc,bx;

    shl xa,shiftby
    shl xb,shiftby
    shl xc,shiftby
  end;
  asm
    db 66h;shr word ptr ia,16;
    db 66h;shr word ptr ib,16;
    db 66h;shr word ptr ic,16;
  end;

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
    mov es,word ptr SC.Scrptr+2    {load up screen mem pos}
    mov si,SC.offsw
    mov ax,ya ;imul si ;add ax,word ptr SC.Scrptr
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
      {Xclipping}
      mov di,cx
      inc di
      sub di,dx
      mov ax,SC.viewport.x2 ;cmp cx,ax ; JLE @nochange_x2
        mov cx,ax
      @nochange_x2:
      mov ax,SC.viewport.x1 ;cmp dx,ax ; JGE @nochange_x1
        mov dx,ax
      @nochange_x1:
      inc cx
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
      add di,cx                   {add this to total}

      mov cx,xdiff                {xdiff is the length (xb-xa)}

      push bp
      mov bp,Cadd                 {colour interpolation value}

      @drawloop:
        mov bx,si            {load colour}
        shr bx,8             {get it into non-fixed range}
        mov es:[di],bl       {write to screen}
        add si,bp            {add colour interpolation value}
        inc di               {increment screen offset}
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
    inc(scroffset,SC.offsw);
    inc(ylop);
  end;
end;

Procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
var ylop,xlop:integer;
adrs,picadrs:byteptr;
x2,y2:integer;
cwindow:word;
Begin
  with bitmap^ do begin
    x2:=x1+size.x;
    y2:=y1+size.y;
    if (y1<=SC.viewport.y2) and(x1<=SC.viewport.x2)and(x2>SC.viewport.x1) and(y2>SC.viewport.y1) then begin
      if bitmaptype=BMflat then begin
        Cwindow:=Currwin;
        picadrs:=pointer(flatdata);
        if x1<SC.viewport.x1 then inc(picadrs,SC.viewport.x1-x1);
        if y1<SC.viewport.y1 then inc(picadrs,size.x*(SC.viewport.y1-y1));
        asm
          {x clip is incremented cos we're talking width here, no cords}
          {X axis clipping}
          mov ax,SC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
            mov x1,ax
          @nochange_x1:
          mov ax,SC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
            mov x2,ax
          @nochange_x2:
          {Y axis clipping}
          mov ax,SC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
            mov y1,ax
          @nochange_y1:
          mov ax,SC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
            mov y2,ax
          @nochange_y2:
        end;
        xlop:=size.x;
        asm
          les di,SC.Scrptr
          mov ax,y1
          imul SC.offsw
          add di,ax;add di,x1; adc dx,0          {add carray to dx (current SVGA window)}
          {setup SVGA window}
          mov cwindow,dx
          cmp currwin,dx
          jz @nochange
            xor bx,bx;call setpagefunc;
          @nochange:

          mov bx,y2         {get y length}
          sub bx,y1
          {inc bx}

          mov cx,x2         {get x length}
          sub cx,x1
          {inc cx}
          mov x2,cx

          mov dx,xlop       {width of bitmap}
          sub dx,cx         {get diff from edge of displayed bitmap}

          mov ax,SC.offsw       {width of screen}
          sub ax,cx         {get diff from edge of displayed bitmap}

          push ds           {save ds}
            lds si,picadrs
            @runloop:
              mov cx,x2                     {load up x size}
              add di,cx
              ja @nooverflow
                push bx
                sub di,cx
                mov bx,$FFFF               {biggest word size minus segment offset}
                sub bx,di
                inc bx                     {correct length}
                mov cx,bx
                {draw first segment of bitmap line}
                shr cx,1                         {get word count}
                REP movsw                        {store words}
                adc cx,cx                        {extra byte?}
                REP movsb                        {Draw if there}
                {get length of rest of line into cx}
                mov cx,x2
                sub cx,bx

                {set svga window}
                push dx;push ax
                inc cwindow; mov dx,cwindow
                xor bx,bx;call setpagefunc;
                pop ax;pop dx

                mov di,0              {begining of segment}

                {draw second segment of bitmap line}
                shr cx,1                         {get word count}
                REP movsw                        {store words}
                adc cx,cx                        {extra byte?}
                REP movsb                        {Draw if there}

                pop bx
                jmp @overflowed
              @nooverflow:
                sub di,cx
                shr cx,1      {get word count}
                REP movsw     {store words}
                adc cx,cx     {extra byte?}
                REP movsb     {Draw if there}
              @overflowed:
              add di,ax     {screen update}
              ja @nooverflow2
                push dx;push ax;push bx;
                inc cwindow; mov dx,cwindow
                xor bx,bx;call setpagefunc;
                pop bx;pop ax;pop dx
              @nooverflow2:
              add si,dx     {picture update}
              dec bx
            jnz @runloop
          pop ds            {restore ds}
        end;
        currwin:=cwindow;
      end;
    end;
  end;

end;

Procedure putbitmapmask(x1,y1:integer;mask:byte;bitmap:bitmaptypeptr);
var ylop,xlop:integer;
    adrs,picadrs:bytearray;
    x2,y2:integer;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  if (y1<SC.viewport.y2) and(x1<SC.viewport.x2)and(x2>SC.viewport.x1) and(y2>SC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<SC.viewport.x1 then inc(picadrs,SC.viewport.x1-x1);
    if y1<SC.viewport.y1 then inc(picadrs,size.x*(SC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,SC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,SC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,SC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,SC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=SC.Scrptr;
    inc(SC.Scrptr,x1+(SC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}

      mov ax,SC.offsw          {Screen width}
      sub ax,cx             {Correct screen width}

      les di,adrs
      push bp               {save bp}
        push ds             {save ds}
          lds si,picadrs    {load in pic address}
          push ax           {save screen width}
            mov al,mask     {load mask b4 lost with bp}
          pop bp            {restore into bp}
          @runloop:
            push cx
              @scanloop:
                mov ah,[si]
                cmp ah,al
                jz @nodraw
                  mov es:[di],ah
                @nodraw:

                inc si
                inc di
              loop @scanloop
            pop cx

            add si,dx       {picture update}
            add di,bp       {screen update}

            dec bx
          jnz @runloop
        pop ds            {restore bp}
      pop bp            {restore ds}
    end;
  end;
  end;
end;

function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
var newpic:bitmaptypeptr;
    xlop,ylop:integer;
    currbyte:^byte;
begin
  newpic:=CreateBitmap(x2,y2,8,BMflat);
  {with newpic^ do begin
    currbyte:=pointer(flatdata);
    for ylop:=y1 to y1+size.y-1 do
      for xlop:=x1 to x1+size.x-1 do begin
        currbyte^:=getpixel(xlop,ylop);
        inc(currbyte);
      end;
  end;}
end;

Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
begin
end;

{quick screen interface}
Procedure QSetXY(x,y:integer);
begin
  SC.Qoffset:=(y*SC.offsw)+x;
end;

Function Qget:byte;
begin
  Qget:=bytearray(SC.Scrptr)^[SC.qoffset];
  inc(SC.Qoffset);
end;

Procedure Qwrite(count:word);assembler;
asm
  mov al,t_col                  {colour for write}
  les di,SC.Scrptr
  add di,word ptr SC.qoffset                   {add current Quick Offset}
  mov cx,count                  {get count}
  add word ptr SC.qoffset,cx
  REP STOSB                     {draw words}
end;
end.











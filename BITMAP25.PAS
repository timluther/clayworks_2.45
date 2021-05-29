Unit BITMAP25;
{$R-}
INTERFACE
uses chardef,ttypes,gbasics,tmaths;
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
Procedure putbitmapmask(x1,y1:integer;mask:byte;bitmap:bitmaptypeptr);
Procedure putbitmaptintshade(x1,y1:integer;rangestart,rangesize:byte;bitmap:bitmaptypeptr);
Procedure putbitmaptintshademask(x1,y1:integer;rangestart,rangesize:byte;bitmap:bitmaptypeptr);
Procedure putbitmapshade(x1,y1:integer;rangesize:byte;bitmap:bitmaptypeptr);
procedure scanedge(x1,y1,x2,y2:integer;offset:byte);
function getbitmap(x1,y1,x2,y2:integer):bitmaptypeptr;
procedure drawhlines(ytop,ybottom:integer);
procedure ConvexPolygon(points:pointtypearray;numpoints:integer);
Procedure cleardevice;
procedure savescreenregs;
procedure restorescreenregs;

{quick generic interface to screen -good for file loading}
Procedure QSetXY(x,y:integer);
Procedure Qwrite(count:word);
function  Qget:byte;

type dword=longint;

IMPLEMENTATION
procedure savescreenregs;
begin
end;
procedure restorescreenregs;
begin
end;

function set_mode(mode:byte):boolean;
begin
  {set up the video mode}
  if mode=$13 then asm
    xor ax,ax
    mov al,mode                   {mode}
    int 10h                        {call screen interrupt}
  end else asm
    mov ax,4F02h
    mov bh,64
    mov bl,mode
    int 10h

    mov AX,800h
    int 31h
  end;
  set_mode:=true;
end;


(*function set_mode(mode:byte):boolean;
var installed:boolean;
begin
  installed:=true;
  with BC.size do
  case mode of
    vga320x200x256:begin x:=320;y:=200;end;
    else installed:=false;
  end;
  if installed then begin
    {set up the video mode}
    asm
      mov al,mode;                   {mode}
      mov ah,0;                      {function 0}
      int 10h                        {call screen interrupt}
    end;
    ColourDepth:=256;
    BC.offsw:=BC.size.x;
  end;
  set_mode:=installed;
end;*)

Procedure cleardevice;assembler;
Asm
  les di,BC.scrptr
  mov al,t_fillcol
  mov ah,t_fillcol
  mov cx,word ptr BC.Pagesize
  shr cx,1
  cld
  rep stosw
End;

const
base:byte=0;



var
HlineList:array[0..319] of hlinetype;
deltax,px:longint;

procedure scanedge(x1,y1,x2,y2:integer;offset:byte);
var

chval:integerptr;
const
multby=1 shl 16;
hlinesize=sizeof(hlinetype);
begin
  {slow due to 16 bit stuff; needs multiplies, 32bit shift would be good}
  px:=x1 * multby;
  dec(y2);
  if y2<=y1 then exit;

    deltax:=((x2  * multby)-px) div (y2-y1);


  chval:=@HLineList[y1];
  inc(chval,offset);
  asm
    {create counter}
    mov cx,y2
    sub cx,y1

    {setup gradient fixed point longword in bx/dx}
    mov bx,word ptr deltax
    mov dx,word ptr deltax+2

    {put current fixed point x position in si/ax}
    mov si,word ptr px
    mov ax,word ptr px+2
    les di,chval       {points to current hline value}
    mov es:[di],ax   {grab the integer bit and shove into memory}
    @yloop:

      add di,hlinesize {needs to move along by sizeof hlinetype bytes}
      add si,bx        {add fixed point gradiant longword }
      adc ax,dx
      mov es:[di],ax   {grab the integer bit and shove into memory}
      dec cx           {next itteration}

    jnz @yloop
  end;


end;

procedure drawhlines(ytop,ybottom:integer);
var
chline:^hlinetype;
ylop:integer;
begin
     chline:=@Hlinelist[ytop];
     for ylop:=ytop to ybottom-1 do begin
       hline(chline^.x1,chline^.x2,ylop);
       inc(chline);
     end;

end;


procedure ConvexPolygon(points:pointtypearray;numpoints:integer);

var top_y,bottom_y,top_idx,l_idx_start,r_idx_start:integer;
    i:integer;
    dir:shortint;
    cpoint,nxtpoint:pointtypeptr;

ignorefirst:boolean; {if the top left and right values have the same x position, ignore}

function IDX_FWRD(var index:integer):integer;
begin
  IDX_FWRD:=(index+1) mod numpoints;
end;

function IDX_BAKWRD(var index:integer):integer;
begin
  IDX_BAKWRD:=(index-1+numpoints) mod numpoints;
end;

function IDX_MOVE(var index:integer;dir:byte):integer;
begin
  if (dir>0) then
    IDX_MOVE:=(index-1+numpoints) mod numpoints
  else
    IDX_MOVE:=(index-1+numpoints) mod numpoints;
end;

begin
   if numpoints<3 then exit;
   top_y:=32767;
   bottom_y:=-32767;
   cpoint:=pointtypeptr(points);


   {determine the top and bottom of the list}
   for i:=0 to numpoints-1 do begin
     if cpoint^.y<top_y then begin
       top_y:=cpoint^.y;
       top_idx:=i;
     end;

     if cpoint^.y>bottom_y then bottom_y:=cpoint^.y;
     inc(cpoint);
   end;
   if top_y=bottom_y then exit;
   {figure out starting positions for left and right sides of the list}
   i:=top_idx;
   cpoint:=@points^[top_idx];

   while points^[i].x=cpoint^.x do begin
     i:=idx_bakwrd(i);
   end;
   i:=idx_fwrd(i);
   l_idx_start:=i;

   i:=top_idx;
   while points^[i].x=cpoint^.x do begin
     i:=idx_fwrd(i);
   end;
   i:=idx_bakwrd(i);

   r_idx_start:=i;
   i:=idx_fwrd(i);
   if points^[i].x<points^[l_idx_start].x then
     fswap(r_idx_start,l_idx_start,sizeof(integer));


   i:=R_idx_start;
   cpoint:=@pointtypearray(points)^[r_idx_start];
   nxtpoint:=cpoint;
   while (nxtpoint^.y<>bottom_y) do begin
     cpoint:=@pointtypearray(points)^[i];
     i:=idx_fwrd(i);
     nxtpoint:=@pointtypearray(points)^[i];
     scanedge(cpoint^.x,cpoint^.y,nxtpoint^.x,nxtpoint^.y,1);
   end;

   i:=L_idx_start;
   cpoint:=@pointtypearray(points)^[L_idx_start];
   nxtpoint:=cpoint;
   while (nxtpoint^.y<>bottom_y) do begin
     cpoint:=@pointtypearray(points)^[i];
     i:=idx_bakwrd(i);
     nxtpoint:=@pointtypearray(points)^[i];
     scanedge(cpoint^.x,cpoint^.y,nxtpoint^.x,nxtpoint^.y,0);
   end;
   drawhlines(top_y,bottom_y);
   




end;



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
(*
Procedure outtextxy_length(x1,y1:integer;txt:pchar;length:byte);
var txtend,ylop,txtstart,lmask,rmask:byte;
    Adrs,decoffs:word;
    x2,y2,tmp:integer;
Begin
  txtend:=length;
  x2:=x1+(txtend shl 3);
  y2:=y1+fontmax;
  if (x1<=BC.viewport.x2)and(y1<=BC.viewport.y2)and(x2>=BC.viewport.x1)
  and(y2>=BC.viewport.y1)and(txtend<>0) then begin

    {**Y-cliping**}
    If y2>BC.viewport.y2 then ylop:=(BC.viewport.y2-y1) else ylop:=fontmax;
    if y1<BC.viewport.y1 then begin
      tmp:=BC.viewport.y1-y1;      {number ofpixels off screen}
      y1:=BC.viewport.y1
    end else tmp:=0;
    dec(ylop,tmp);
    asm
      mov ax,y1 ;imul BC.offsw
      add ax,x1
      add ax,word ptr BC.scrptr
      mov adrs,ax
    end;
    y1:=tmp;

    {**X - Clipping**}
    lmask:=$ff; rmask:=$ff;
    txtstart:=1;
    tmp:=(BC.viewport.x1-x1);
    if x1<BC.viewport.x1 then begin
      lmask:=lmask shr (tmp and 7);
      tmp:=tmp shr 3;
      inc(txtstart,tmp);
      inc(adrs,(tmp shl 3));
    end;
    tmp:=(x2-BC.viewport.x2-1);
    if x2>BC.viewport.x2 then begin
      dec(txtend,tmp shr 3);
      rmask:=rmask shl (tmp and 7);
    end;
    if txtstart=txtend+1 then exit;

    
    decoffs:=(BC.offsw*(ylop+1)-8);
    asm
      mov di,adrs                      {load offset}

      mov dl,t_col
      mov bx,BC.offsw                     {load dx with screen offset}
      sub bx,8

      mov dh,txtstart                  {dh is the loop counter}
      @Textloop:
        les si,[bp+6]                  {point to string}
        mov al,dh;xor ah,ah            {get txtloop from dh into ax}
        add si,ax                      {Add to offset the offset of the..}
        mov al,es:[si] ;xor ah,ah      {..current character..}
        shl ax,fontshift               {..shift to get the byte offset..}
        add ax,y1                      {..of the graphic and add y to clip}

        mov es,word ptr BC.scrptr+2                 {set up screen address segment}

          lea si,tcharset              {point to character set}
          add si,ax                    {add character offset}
          mov cl,ylop ;inc cl          {set up y loop (from y to ylop)}

          @drawloop:
              push cx                  {save @drawloop}
                mov cx,8
                mov ah,ds:[si]

                cmp dh,txtstart;jnz @noleft
                and ah,lmask               {mask with the left?}
                @noleft:
                cmp dh,txtend;  jnz @noright
                and ah,rmask               {mask with the right?}
                @noright:

                @bitloop:
                  shl ah,1
                  jnc @nodraw
                    mov es:[di],dl
                  @nodraw:
                  inc di
                loop @bitloop
                add di,bx              {shift to next line on screen}
                inc si                 {go to next byte in pic}
              pop cx
            loop @drawloop

        sub di,decoffs                 {correct the screen position..}
        inc dh                         {next character}
        cmp dh,txtend                  {is it the end?}
      jle @Textloop                    {if not, do it all again}
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

Procedure outtextxy(x1,y1:integer;txt:string);
var txtend,ylop,txtstart,lmask,rmask:byte;
    Adrs,decoffs:word;
    x2,y2,tmp:integer;
Begin
  txtend:=byte(txt[0]);
  x2:=x1+(txtend shl 3);
  y2:=y1+fontmax;
  if (x1<=BC.viewport.x2)and(y1<=BC.viewport.y2)and(x2>=BC.viewport.x1)
  and(y2>=BC.viewport.y1)and(txtend<>0) then begin

    {**Y-cliping**}
    If y2>BC.viewport.y2 then ylop:=(BC.viewport.y2-y1) else ylop:=fontmax;
    if y1<BC.viewport.y1 then begin
      tmp:=BC.viewport.y1-y1;      {number ofpixels off screen}
      y1:=BC.viewport.y1
    end else tmp:=0;
    dec(ylop,tmp);
    asm
      mov ax,y1 ;imul BC.offsw
      add ax,x1
      add ax,word ptr BC.scrptr
      mov adrs,ax
    end;
    y1:=tmp;

    {**X - Clipping**}
    lmask:=$ff; rmask:=$ff;
    txtstart:=1;
    tmp:=(BC.viewport.x1-x1);
    if x1<BC.viewport.x1 then begin
      lmask:=lmask shr (tmp and 7);
      tmp:=tmp shr 3;
      inc(txtstart,tmp);
      inc(adrs,(tmp shl 3));
    end;
    tmp:=(x2-BC.viewport.x2-1);
    if x2>BC.viewport.x2 then begin
      dec(txtend,tmp shr 3);
      rmask:=rmask shl (tmp and 7);
    end;
    if txtstart=txtend+1 then exit;

    
    decoffs:=(BC.offsw*(ylop+1)-8);
    asm
      mov di,adrs                      {load offset}

      mov dl,t_col
      mov bx,BC.offsw                     {load dx with screen offset}
      sub bx,8

      mov dh,txtstart                  {dh is the loop counter}
      @Textloop:
        les si,[bp+6]                  {point to string}
        mov al,dh;xor ah,ah            {get txtloop from dh into ax}
        add si,ax                      {Add to offset the offset of the..}
        mov al,es:[si] ;xor ah,ah      {..current character..}
        shl ax,fontshift               {..shift to get the byte offset..}
        add ax,y1                      {..of the graphic and add y to clip}

        mov es,word ptr BC.scrptr+2                 {set up screen address segment}

          lea si,tcharset              {point to character set}
          add si,ax                    {add character offset}
          mov cl,ylop ;inc cl          {set up y loop (from y to ylop)}

          @drawloop:
              push cx                  {save @drawloop}
                mov cx,8
                mov ah,ds:[si]

                cmp dh,txtstart;jnz @noleft
                and ah,lmask               {mask with the left?}
                @noleft:
                cmp dh,txtend;  jnz @noright
                and ah,rmask               {mask with the right?}
                @noright:

                @bitloop:
                  shl ah,1
                  jnc @nodraw
                    mov es:[di],dl
                  @nodraw:
                  inc di
                loop @bitloop
                add di,bx              {shift to next line on screen}
                inc si                 {go to next byte in pic}
              pop cx
            loop @drawloop

        sub di,decoffs                 {correct the screen position..}
        inc dh                         {next character}
        cmp dh,txtend                  {is it the end?}
      jle @Textloop                    {if not, do it all again}
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
*)
Procedure Drawbytesxy(x1,y1:Integer;pic:bytearray;xbytes,ybytes:byte);
begin
end;

Procedure Drawbytes(x1,y1:Integer;pic:bytearray;nbytes:byte);
var lop,mask:byte; Adrs:word;
    x2:integer;
Begin
  x2:=x1+8;
  dec(nbytes);
  if (x2>=BC.viewport.x1)and(x1<=BC.viewport.x2)and(y1+nbytes>=BC.viewport.y1)and(y1<=BC.viewport.y2)then begin
  Adrs:=(y1*BC.offsw)+x1;

  {**XCliping**}
  mask:=$ff;
  if x1<BC.viewport.x1 then
    mask:=$ff shr (BC.viewport.x1-x1);
  if x2>BC.viewport.x2 then
    mask:=mask and ($ff shl (x2-BC.viewport.x2-1));

  {**YCliping**}
  If y1+nbytes>BC.viewport.y2 then lop:=(BC.viewport.y2-y1) else lop:=nbytes;
  if y1<BC.viewport.y1 then begin
     y1:=BC.viewport.y1-y1;inc(Adrs,y1*BC.offsw);
  end else y1:=0;
  dec(lop,y1-1);
  asm
    mov es,word ptr BC.scrptr+2  {set up screen address}
    mov di,adrs
    add di,word ptr BC.scrptr

    mov cl,lop
    xor ch,ch
    mov al,t_col

    mov dx,BC.offsw    {load dx with screen offset}
    sub dx,8

    push ds         {save data segment}
      lds si,pic
      add si,y1
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
            inc di;
          loop @bitloop

          add di,dx            {shift to next line on screen}
          inc si               {go to next byte in pic}
        pop cx
      loop @drawloop
    pop ds
  end;

  {for lop:=ystart to lop do begin
    hsub2(Adrs,pic^[lop] shr (dx),(pic^[lop] shl (8-dx)));
    inc(Adrs,offs);
  end;}
end;

end;

{clipping subroutine for line drawing}
Function outcode(x1,y1:integer):byte;
var return:byte;
Begin
  return:=0;
  if y1>BC.viewport.y2 then Return:=bellow else
  if y1<BC.viewport.y1 then Return:=above;
  if x1>BC.viewport.x2 then inc(Return,right) else
  if x1<BC.viewport.x1 then inc(Return,left);
  outcode:=return;
end;

function clip(var xa,ya,xb,yb:integer):boolean;
var code0,code1:byte;
Begin
  While 0=0 do begin

    code0:=(byte(xb>BC.viewport.x2))+     {right  =$01}
           (byte(yb>BC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xb<BC.viewport.x1)shl 2)+{left   =$04}
           (byte(yb<BC.viewport.y1)shl 3) {above  =$08};

    code1:=(byte(xa>BC.viewport.x2))+     {right  =$01}
           (byte(ya>BC.viewport.y2)shl 1)+{bellow =$02}
           (byte(xa<BC.viewport.x1)shl 2)+{left   =$04}
           (byte(ya<BC.viewport.y1)shl 3) {above  =$08};

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
        inc(xb,(xa-xb)*(BC.viewport.y2-yb)div(ya-yb));
        yb:=BC.viewport.y2;
      end else if (code0 and above)<>0 then begin
        inc(xb,(xa-xb)*(BC.viewport.y1-yb)div(ya-yb));
        yb:=BC.viewport.y1;
      end else if (code0 and right)<>0 then begin
        inc(yb,(ya-yb)*(BC.viewport.x2-xb)div(xa-xb));
        xb:=BC.viewport.x2;
      end else if (code0 and left)<>0 then begin
        inc(yb,(ya-yb)*(BC.viewport.x1-xb)div(xa-xb));
        xb:=BC.viewport.x1;
      end;
    end;
  end;
end;

{biechmans line drawing algo- bit optimization still needed}
Procedure Line(x1,y1,x2,y2:integer);
Var dfx,dfy,d,d2,incr1,incr2,xinc:integer;
adrs:word;
Begin
  if x1=x2 then vline(x1,y1,y2) else begin
    if y1=y2 then hline(x1,x2,y1) else
    if clip(x1,y1,x2,y2) then Begin
      dfx:=abs(x2-x1);dfy:=abs(y2-y1);
      asm mov es,word ptr BC.scrptr+2 end;
      if dfx>dfy then begin
        asm
          mov ax,x2  ; cmp x1,ax ; jle @no_swap
            Xchg x1,ax ; mov x2,ax
            mov ax,y2; Xchg y1,ax;mov y2,ax;
          @no_swap:

          mov ax,y1; imul BC.offsw ;add ax,word ptr BC.scrptr;  {sort out address:}
          mov bx,x1; add ax,bx                   {adrs:=(y1*BC.offsw)+(x1 shr 3)+word ptr BC.scrptr;}
          mov adrs,ax
        end;

        incr2:=(dfy-dfx)shl 1;
        if(y2>y1) then xinc:=BC.offsw else xinc:=-BC.offsw;

        asm
          mov al,t_col
          mov dx,xinc                   {get scanline offset}
          mov bx,adrs                   {get offset}

          mov cx,dfx ;inc cx            {load in the length}
          mov si,dfy ;shl si,1;         {get incr1}
          mov di,si  ;sub di,dfx;       {get 'd'}
          push bp                       {remember stack frame}
          mov bp,incr2

          @Runloop:                     {start loop}
            mov es:[bx],al
            inc bx
            cmp di,0;jl @noinc        {new scan line?}
              add di,bp               {update di}
              add bx,dx               {add scanline offset}
            jmp @check
            @noinc:
              add di,si               {update fractional part}
            @check:
          loop @runloop
          pop bp                        {recall stack frame}
        end;
      end else begin
        asm
          mov ax,y2  ; cmp y1,ax ; jle @no_swap
            Xchg y1,ax ; mov y2,ax
            mov ax,x2; Xchg x1,ax;mov x2,ax;
          @no_swap:
          mov ax,y1; imul BC.offsw ;add ax,word ptr BC.scrptr; {sort out address:}
          mov bx,x1; add ax,bx                  {adrs:=(y1*BC.offsw)+(x1 shr 3)+word ptr BC.scrptr;}
          mov adrs,ax
        end;
        d2:=dfx shl 1;
        d:=d2-dfy;
        incr1:=d2;
        incr2:=(dfx-dfy) shl 1;
        asm
          inc dfy                {add one to difference in y}
          mov dx,BC.offsw            {screen width}
          mov bx,adrs            {screen address}
          mov al,t_col           {Colour}
          mov di,d               {(diff in X*2)-diff in y}
          mov si,incr1           {integer increment}

          mov cx,x1; cmp cx,x2;
          jg @left               {check if line is doing left or right}

          {do these loads for both directions because of the use of bp}
          mov cx,dfy             {difference in Y}
          push bp
          mov bp,incr2           {fractional increment}
          @Runloop:
            mov es:[bx],al      {Write to screen}
            add bx,dx           {next scan line}
            cmp di,0            {if no change}
            jl @noinc           {then don't do below}
              add di,bp         {do frac part}
              inc bx            {go to next byte on screen}
              jmp @check
            @noinc:
              add di,si         {add frac part}
            @check:
          loop @runloop
          jmp @end

          @left:
          {do these loads for both directions because of the use of bp}
          mov cx,dfy            {difference in Y}
          push bp
          mov bp,incr2          {fractional increment}
          @Runloopb:
            mov es:[bx],al      {Write to screen}
            add bx,dx           {next scan line}
            cmp di,0            {if no change}
            jl @noincb          {then don't do below}
              add di,bp         {do frac part}
              dec bx
              jmp @checkb
            @noincb:
              add di,si         {add frac part}
            @checkb:
          loop @runloopb
        @end:
        pop bp
        end;
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
  cmp bx,BC.viewport.x2 ;jg @fin
  cmp cx,BC.viewport.x1 ;jl @fin
  cmp ax,BC.viewport.y2 ;jg  @fin
  cmp ax,BC.viewport.y1 ;jl  @fin

  {X axis clipping}
  mov dx,BC.viewport.x1 ;cmp bx,dx ; JGE @nochange_x1
    mov bx,dx
  @nochange_x1:
  mov dx,BC.viewport.x2 ;cmp cx,dx ; JLE @nochange_x2
    mov cx,dx
  @nochange_x2:

  {start of mode dependant stuff} {load up screen position}
  mov es,word ptr BC.scrptr+2
  inc cx ;imul BC.offsw ;add ax,word ptr BC.scrptr; mov di,ax {load up screen pos}

  {calculate length (in bytes-1) of line}
  sub cx,bx                        {get byte length}
  add di,bx                        {add this to screen memory offset}

  mov al,t_col
  mov ah,al

  shr cx,1                         {get word count}
  REP stosw                        {store words}
  adc cx,cx                        {extra byte?}
  REP stosb                        {Draw if there}

  @fin:
end;


Procedure bar(x1,y,x2,y2:integer);
var adrs:word;
Begin
  if x2<x1 then asm mov ax,x2;Xchg x1,ax;mov x2,ax;end;
  if y2<y then asm mov ax,y2;xchg y,ax;mov y2,ax;end;
  if (y>BC.viewport.y2)or(y2<BC.viewport.y1)or(x1>BC.viewport.x2)or(x2<BC.viewport.x1)=false then begin
    if x1<BC.viewport.x1 then x1:=BC.viewport.x1;if y<BC.viewport.y1 then y:=BC.viewport.y1;
    if x2>BC.viewport.x2 then x2:=BC.viewport.x2;if y2>BC.viewport.y2 then y2:=BC.viewport.y2;
    inc(x2);inc(y2);
    adrs:=(y*BC.offsw)+x1;
    asm
      mov es,word ptr BC.scrptr+2
      mov di,adrs {address}
      add di,word ptr BC.scrptr
      mov ax,BC.offsw
      mov si,ax {load offset}
      mov al,t_fillcol
      mov bx,x2
      sub bx,x1
      mov cx,y2  {load loop count -ycnt}
      sub cx,y
      mov dx,BC.offsw
      sub dx,bx
      @runloop:
        push cx
        mov cx,bx
        rep stosb
        pop cx
        add di,dx
      loop @runloop
    end;
  end;
end;

Procedure Vline(x,y1,y2:Integer);assembler;
asm
  {es -screen seg
   di -byte offset
   al -byte mask
   cx -Y length of line}
  {remember that these registers are loaded thus:}
  mov ax,y1; mov cx,y2 ;mov bx,x
  {swap y2,y1 if y1>y2}
  cmp ax,cx ;jle @no_swap ; Xchg ax,cx; @no_swap:

  cmp ax,BC.viewport.y2 ;jg @fin   {is line at all visable?}
  cmp cx,BC.viewport.y1 ;jl @fin
  cmp bx,BC.viewport.x2 ;jg @fin
  cmp bx,BC.viewport.x1 ;jl @fin

  {Y axis clipping}
  mov dx,BC.viewport.y1 ;cmp ax,dx ; JGE @nochange_y1
    mov ax,dx
  @nochange_y1:
  mov dx,BC.viewport.y2 ;cmp cx,dx ; JLE @nochange_y2
    mov cx,dx
  @nochange_y2:

  inc cx                                  {inc y2}
  sub cx,ax                               {calc length}

  les di,BC.scrptr                             {load up screen position}
  imul BC.offsw;
  add di,ax; add di,bx;                    {add di, y*BC.offsw +xposition}
  {result of imul is stored (thank God)  in ax-dx, perfect for svga}

  mov bx,BC.offsw                             {load screen width}
  mov al,t_col

  @runloop:
    mov es:[di],al                        {write to screen}
    add di,bx                             {next pixel}
  loop @runloop
  @fin:
end;

Procedure putpixel(x1,y1:Integer);assembler;
asm
  {if dot visable?}
  mov bx,x1 ;mov ax,y1
  cmp bx,BC.viewport.x1 ;jl @fin  {clipping..}
  cmp ax,BC.viewport.y1 ;jl @fin
  cmp bx,BC.viewport.x2 ;jg @fin
  cmp ax,BC.viewport.y2 ;jg @fin

  mov es,word ptr BC.scrptr+2
  imul BC.offsw; add ax,word ptr BC.scrptr
  add ax,bx; mov di,ax         {load up screen pos}

  mov al,t_col

  mov es:[di],al
  @fin:
end;

Function getpixel(x1,y1:Integer):byte;
begin asm
    mov es,word ptr BC.scrptr+2
    imul BC.offsw; add ax,word ptr BC.scrptr
    add ax,bx; mov di,ax         {load up screen pos}

    mov al,es:[di]
    mov @result,al
  end;
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
    cmp si,BC.viewport.y2
    jle @noyclip
      mov si,BC.viewport.y2
      inc si
    @noyclip:

    mov endp,si         {exit routine if ends of tri are outside VP}
    mov si,ya
    cmp si,BC.viewport.y2  {if ya>BC.viewport then exit}
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

    mov es,word ptr BC.scrptr+2    {load up screen mem pos}
    mov cx,BC.offsw
    mov ax,ya ;imul cx ;add ax,word ptr BC.scrptr
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
      {if ylop>BC.viewport.y1 then....}
      mov ax,BC.viewport.y1 ;cmp ax,si ;jg @fin
      {convert the line to normal pixel-space}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff

      {flip- shouldn't have to but there ya go}
      cmp dx,cx ;jg @no_swap ; Xchg cx,dx; @no_swap: {if x1>x2 then swap}
      {if (x1>BC.viewport.x2)or(x2<BC.viewport.x1)=false then....}
      cmp cx,BC.viewport.x2 ;jg @fin
      cmp dx,BC.viewport.x1 ;jl @fin
      {X clipping}
      mov ax,BC.viewport.x1 ;cmp cx,ax ; JGE @nochange_x1
        mov cx,ax
      @nochange_x1:
      mov ax,BC.viewport.x2 ;cmp dx,ax ; JLE @nochange_x2
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
    add di,BC.offsw             {inc address}
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
  if endp>BC.viewport.y2 then endp:=BC.viewport.y2+1;

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
    mov es,word ptr BC.scrptr+2    {load up screen mem pos}
    mov si,BC.offsw
    mov ax,ya ;imul si ;add ax,word ptr BC.scrptr
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
      {if ylop>BC.viewport.y1 then....}
      mov ax,BC.viewport.y1 ;cmp ax,ylop ;jg @fin
      {convert the line to normal pixel-space}
      {xa is in dx, xb is in cx}
      mov cx,rxa ;shr cx,shiftby ;add cx,xoff
      mov dx,lxa ;shr dx,shiftby ;add dx,xoff
      {Xclipping}
      mov di,cx
      inc di
      sub di,dx
      mov ax,BC.viewport.x2 ;cmp cx,ax ; JLE @nochange_x2
        mov cx,ax
      @nochange_x2:
      mov ax,BC.viewport.x1 ;cmp dx,ax ; JGE @nochange_x1
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
    inc(scroffset,BC.offsw);
    inc(ylop);
  end;
end;

Procedure Screencopy(x1,y1,x2,y2,xd,yd:integer;page1,page2:byte);
begin
end;

Procedure putbitmap(x1,y1:integer;bitmap:bitmaptypeptr);
var ylop,xlop:integer;
    adrs,picadrs:byteptr;
    x2,y2:integer;
Begin
  with bitmap^ do begin
    x2:=x1+size.x;
    y2:=y1+size.y;
    if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin
      if bitmaptype=BMflat then begin
        picadrs:=pointer(flatdata);
        if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
        if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
        asm
           {x clip is incremented cos we're talking width here, no cords}
           {X axis clipping}
           mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
             mov x1,ax
           @nochange_x1:
           mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
             mov x2,ax
           @nochange_x2:
           {Y axis clipping}
           mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
             mov y1,ax
           @nochange_y1:
           mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
             mov y2,ax
           @nochange_y2:
        end;
        xlop:=size.x;
        asm
          les di,BC.scrptr       {point to screen}
          mov ax,y1
          mov cx,BC.offsw
          imul cx
          add ax,x1
          add di,ax

          mov bx,y2         {get y length}
          sub bx,y1
          {dec bx}

          mov cx,x2         {get x length}
          sub cx,x1


          mov dx,xlop       {width of bitmap}
          sub dx,cx         {get diff from edge of displayed bitmap}

          mov ax,BC.offsw       {width of screen}
          sub ax,cx         {get diff from edge of displayed bitmap}

          push ds           {save ds}
          push bp
            lds si,picadrs
            @runloop:
              mov bp,cx     {save cx}
              shr cx,1      {get word count}
              REP movsw     {store words}
              adc cx,cx     {extra byte?}
              REP movsb     {Draw if there}
              mov cx,bp     {recall cx}

              add si,dx     {picture update}
              add di,ax     {screen update}

              dec bx
            jnz @runloop
          pop bp
          pop ds            {restore ds}
        end;
      end;
    end;
  end;
end;

Procedure putbitmapshade(x1,y1:integer;rangesize:byte;bitmap:bitmaptypeptr);
var ylop,xlop,xwidth,scrofs,picofs:integer;
    adrs,picadrs:bytearray;
    x2,y2:integer;
    rangestart:byte;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
    if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=BC.scrptr;
    inc(adrs,x1+(BC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1
      mov xwidth,cx

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}
      mov picofs,dx

      mov ax,BC.offsw          {Screen width}
      sub ax,cx             {Correct screen width}
      mov scrofs,ax
      mov dl,rangesize
      mov dh,dl
      inc dh

      les di,adrs
      push ds             {save ds}
        lds si,picadrs    {load in pic address}
        @runloop:
           mov cx,xwidth
           push bx
            @scanloop:
              mov al,ds:[si]    {get picture data}
              and al,dl         {get into range}

              mov ah,es:[di]    {get screen data}
              mov bh,ah         {remember screen data}
              and ah,dl         {get intorange}

              add al,ah
              cmp al,63
              jl @nooverflow
                mov al,63
              @nooverflow:

              shr bh,6          {get base colour}
              shl bh,6
              add al,bh

              mov es:[di],al

              inc si
              inc di
            loop @scanloop

          add si,picofs       {picture update}
          add di,scrofs    {screen update}
          pop bx
          dec bx
        jnz @runloop
      pop ds            {restore bp}
    end;
  end;
  end;
end;

Procedure putbitmapshademask(x1,y1:integer;rangesize:byte;bitmap:bitmaptypeptr);
var ylop,xlop,xwidth,scrofs,picofs:integer;
    adrs,picadrs:bytearray;
    x2,y2:integer;
    rangestart:byte;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
    if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=BC.scrptr;
    inc(adrs,x1+(BC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1
      mov xwidth,cx

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}
      mov picofs,dx

      mov ax,BC.offsw          {Screen width}
      sub ax,cx             {Correct screen width}
      mov scrofs,ax
      mov dl,rangesize

      les di,adrs
      push ds             {save ds}
        lds si,picadrs    {load in pic address}
        @runloop:
           mov cx,xwidth
            @scanloop:
              mov al,ds:[si]
              cmp al,0
              jz @nodraw
              and al,dl

              mov ah,es:[di]
              and ah,dl
              add al,ah
              mov ah,es:[di]

              shr ah,6
              shl ah,6

              add al,ah
              jno @nooverflow
                mov al,255
              @nooverflow:

              add ah,dl

              cmp al,ah
              jle @norangecorrect
                mov al,ah
              @norangecorrect:

              mov es:[di],al
              @nodraw:
              inc si
              inc di
            loop @scanloop

          add si,picofs       {picture update}
          add di,scrofs    {screen update}

          dec bx
        jnz @runloop
      pop ds            {restore bp}
    end;
  end;
  end;
end;

Procedure putbitmaptintshade(x1,y1:integer;rangestart,rangesize:byte;bitmap:bitmaptypeptr);
var ylop,xlop,xwidth,scrofs:integer;
    adrs,picadrs:bytearray;
    shiftby:byte;
    x2,y2:integer;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  {shiftby:=1 shl rangesize;}
  if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
    if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=BC.scrptr;
    inc(adrs,x1+(BC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1
      mov xwidth,cx

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}

      mov ax,BC.offsw          {Screen width}
      sub ax,cx             {Correct screen width}
      mov scrofs,ax

      les di,adrs
      push ds             {save ds}
        lds si,picadrs    {load in pic address}
        @runloop:
           mov cx,xwidth
            @scanloop:
              mov al,ds:[si]
              and al,rangesize
              mov ah,es:[di]
              and ah,rangesize
              add al,ah
              cmp al,rangesize
              jle @norangecorrect
                mov al,rangesize
              @norangecorrect:
              add al,rangestart
              mov es:[di],al
              inc si
              inc di
            loop @scanloop

          add si,dx       {picture update}
          add di,scrofs    {screen update}

          dec bx
        jnz @runloop
      pop ds            {restore bp}
    end;
  end;
  end;
end;

Procedure putbitmaptintshademask(x1,y1:integer;rangestart,rangesize:byte;bitmap:bitmaptypeptr);
var ylop,xlop,xwidth,scrofs:integer;
    adrs,picadrs:bytearray;
    shiftby:byte;
    x2,y2:integer;
Begin
  with bitmap^ do begin
  x2:=x1+size.x;
  y2:=y1+size.y;
  {shiftby:=1 shl rangesize;}
  if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
    if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=BC.scrptr;
    inc(adrs,x1+(BC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1
      mov xwidth,cx

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}

      mov ax,BC.offsw          {Screen width}
      sub ax,cx             {Correct screen width}
      mov scrofs,ax

      les di,adrs
      push ds             {save ds}
        lds si,picadrs    {load in pic address}
        @runloop:
           mov cx,xwidth
            @scanloop:
              mov al,ds:[si]
              cmp al,0
              jz @nodraw
              and al,rangesize
              mov ah,es:[di]
              and ah,rangesize
              add al,ah
              cmp al,rangesize
              jle @norangecorrect
                mov al,rangesize
              @norangecorrect:
              add al,rangestart
              mov es:[di],al
              @nodraw:
              inc si
              inc di
            loop @scanloop

          add si,dx       {picture update}
          add di,scrofs    {screen update}

          dec bx
        jnz @runloop
      pop ds            {restore bp}
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
  if (y1<BC.viewport.y2) and(x1<BC.viewport.x2)and(x2>BC.viewport.x1) and(y2>BC.viewport.y1) then begin

    picadrs:=pointer(flatdata);
    if x1<BC.viewport.x1 then inc(picadrs,BC.viewport.x1-x1);
    if y1<BC.viewport.y1 then inc(picadrs,size.x*(BC.viewport.y1-y1));
    asm
       {x clip is incremented cos we're talking width here, no cords}
       {X axis clipping}
       mov ax,BC.viewport.x1 ;cmp x1,ax ; JGE @nochange_x1
         mov x1,ax
       @nochange_x1:
       mov ax,BC.viewport.x2 ;inc ax;cmp x2,ax ; JLE @nochange_x2
         mov x2,ax
       @nochange_x2:
       {Y axis clipping}
       mov ax,BC.viewport.y1 ;cmp y1,ax ; JGE @nochange_y1
         mov y1,ax
       @nochange_y1:
       mov ax,BC.viewport.y2 ;inc ax;cmp y2,ax ; JLE @nochange_y2
         mov y2,ax
       @nochange_y2:
    end;
    xlop:=size.x;
    adrs:=BC.scrptr;
    inc(dword(BC.scrptr),x1+(BC.offsw*y1));
    asm
      mov bx,y2         {get y length}
      sub bx,y1

      mov cx,x2         {get x length}
      sub cx,x1

      mov dx,xlop       {width of bitmap}
      sub dx,cx         {get diff from edge of displayed bitmap}

      mov ax,BC.offsw          {Screen width}
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

{quick screen interface}
Procedure QSetXY(x,y:integer);
begin
  BC.qoffset:=(y*BC.offsw)+x;
end;

Function Qget:byte;
begin
  Qget:=bytearray(BC.scrptr)^[BC.qoffset];
  inc(BC.qoffset);
end;

Procedure Qwrite(count:word);assembler;
asm
  mov al,t_col                  {colour for write}
  les di,BC.scrptr
  add di,word ptr BC.qoffset                   {add current Quick Offset}
  mov cx,count                  {get count}
  add word ptr BC.qoffset,cx
  REP STOSB                     {draw words}
end;

End.

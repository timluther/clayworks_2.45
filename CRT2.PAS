UNIT crt2;


INTERFACE
procedure gotoxy(x,y:byte);
procedure clrscr;
function readkey:char;
function keypressed:boolean;
procedure delay(time:integer);
procedure nosound;
procedure sound(pitch:integer);
procedure writecon(text:pchar);

const
  smLEFTSHIFT=2;
  smLEFTCTRL=4;
  smLEFTALT=8;
  smRIGHTSHIFT=1;
  smSCANMASK=15;



  tabkey=#9;
  whitespace=' ';
  rightkey=77;
  rightkeyctrl=116;
  leftkey=75;
  leftkeyctrl=115;
  upkey=72;
  downkey=80;
  pageupkey=73;
  pagedownkey=81;
  homekey=71;
  delkey=83;
  endkey=79;
  backspacekey=chr(8);
  escapekey=chr(27);
  returnkey=chr(13);
var

textscr:^byte;


scan:byte Absolute $40:$17;
timer:word Absolute $40:$6c;

scancode:byte;
charcode:char;

IMPLEMENTATION

procedure clrscr;assembler;
asm
  les di,textscr;
  mov cx,80*25
  mov ax,0
  rep stosw
end;

function readkey:char;assembler;
asm
  mov ah,0
  int $16
  mov scancode,ah
  mov charcode,al
  cmp scan,smSCANMASK
  jnz @fin
    mov charcode,0
  @fin:
end;

function keypressed:boolean;assembler;
asm
  mov ah,1
  int $16
  jnz @setz
  mov al,0
  jmp @end
  @setz:
  mov al,1
  @end:


end;


procedure sound(pitch:integer);
begin
end;

procedure nosound;
begin
end;

procedure delay(time:integer);
begin
end;

procedure writecon(text:pchar);assembler;
asm
  push ds
  lds dx,text                {reload start of string}
  mov ah,9                   {DOS print string function}
  int 21h                    {display text}
  pop ds
end;

procedure writeln(text:string);assembler;
asm
  push ds
  lds dx,text                {reload start of string}
  mov ah,9                   {DOS print string function}
  int 21h                    {display text}
  pop ds
end;

procedure gotoxy(x,y:byte);assembler;
asm
  mov ax,$02

  int $10

end;

begin
  textscr:=ptr($b800,000);
END.
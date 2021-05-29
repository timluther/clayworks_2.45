Unit diskop;
{$X+}{$a+}

INTERFACE

uses dos,tmaths,ttypes;
const
maxbuff=20000;

type
fragtype=(D,P,N,E);
bufferedblock=object
  f:file;
  fsize:longint;
  blockpos,blocksize,blockmax:word;
  buffer,bufferpos:^byte;
  eof:boolean;

  function open(filename:string):boolean;
  function fpos:longint;
  procedure fseek(pos:longint);
  procedure fskip(pos:longint);
  procedure blockread(buf:byteptr;count:word);
  function get:byte;
  procedure close;
end;

Function cd(path:string):string;
Function fragname(path:string;frag:fragtype):string;
Function gtdir:string;
Function numoffiles(path,filter:string;attrfilter:word):integer;
Function NumOfDrives:byte;
Function CurrentDrive:byte;
Function Truncatepath(path:string):string;
Function fexist(path:string):boolean;
Function Pexist(path:string):boolean;
Function instring(name:string;testchar:char):boolean;
{Function readkey:char;
Function keypressed:boolean;}

IMPLEMENTATION

Function CurrentDrive:byte;assembler;
asm
  mov ah,19h
  int 21h
end;

function NumOfDrives:byte;assembler;
asm
  mov ah,19h                {get current disk handle}
  int 21
  mov dl,ah                 {load this into next function}
  mov ah,0Eh
  int 21h                    {call interrupt}
end;


function bufferedblock.open(filename:string):boolean;
var maxavailable:longint;
    var recsize:word;
begin
  if (not fexist(filename)) then begin open:=false;exit;end;
  recsize:=1;
  assign(f,filename);
  reset(f,recsize);
  fsize:=filesize(f);
  maxavailable:=maxavail;
  {keep within 16bit range}
  if maxavailable>maxbuff then maxavailable:=maxbuff;
  {if filesize is smaller, fine}
  blocksize:=smaller(maxavailable,fsize);
  getmem(buffer,blocksize);
  bufferpos:=buffer;
  blockmax:=blocksize;
  blockpos:=blockmax;
  eof:=false;
  open:=true;
end;

function bufferedblock.get;
var recsize:word;
begin
  recsize:=1;
  {if end of block and not end of file....}
  if (fsize>1)and(not eof) then begin
    if blockpos=blockmax then begin
      blockmax:=smaller(fsize,blocksize);
      system.blockread(f,buffer^,blockmax,recsize);
      blockpos:=1;
      bufferpos:=buffer;
    end else begin
      inc(blockpos);
      inc(bufferpos);
    end;
    dec(fsize);
    get:=bufferpos^;
  end else begin
    {end of file, set flag and exit}
    get:=0;
    eof:=true;
  end;
  {writeln(eof);}
end;

procedure bufferedblock.close;
begin
  freemem(buffer,blocksize);
  system.close(f);
end;

function bufferedblock.fpos:longint;
begin
  fpos:=filepos(f)+blockpos-blockmax-1;
end;

procedure bufferedblock.blockread(buf:byteptr;count:word);
var lop:word;
begin
  for lop:=1 to count do begin
    buf^:=get;
    inc(buf)
  end;
end;

procedure bufferedblock.fseek(pos:longint);
var lop:longint;
    recsize:word;
begin
  recsize:=1;
  Seek(f,pos);
  fsize:=filesize(f)-pos;
  blockmax:=smaller(fsize,blocksize);
  blockpos:=blockmax;
  bufferpos:=buffer;
  eof:=false;
end;

procedure bufferedblock.fskip(pos:longint);
begin
  fseek(filepos(f)+blockpos-blockmax-1+pos);
end;

{Function readkey:char;
var out:char;
Begin
  asm
    mov ah,0
    int 16h
    mov out,al
    cmp al,0
    jnz @end
    mov out,ah
    @end:
  end;
  readkey:=out;
end;

Function keypressed:boolean;
Begin
  keypressed:=port[$60]<>0;
end;}

Function fexist(path:string):boolean;
var f:file;
Begin

  (*{$I-}
  Assign(f,path);
  reset(f);

  close(f);

  {$I+}
  FExist := (IOResult = 0);*)
  Fexist:=(fsearch(path,'')<>'');
end;

Function Pexist(path:string):boolean;
var dirinfo:searchrec;
Begin
  {$I-}
  FindFirst(path+'*.*', anyfile, DirInfo);
  {$I+}
  PExist := (IOResult = 0) and (path <> '');
end;

Function cd(path:string):string;
Begin
  if (copy(path,length(path),1)='\') and (length(path)<>3) then
    path:=copy(path,1,length(path)-1);
  {$I-};
  chdir(path);
  {$I+};
  if ioresult=0 then path:=gtdir
  else path:='nil';
  cd:=path;
end;

Function gtdir:string;
var temp:string;
Begin
  getdir(0,temp);
  if temp[length(temp)]<>'\' then
  temp:=temp+'\';
  gtdir:=temp;
end;

Function Truncatepath(path:string):string;
Var lop:byte;
Temp:string;
Begin
  lop:=Length(path);

  Path:=copy(path,1,length(path)-1);
  While (path[lop]<>'\') and (lop>0) do
    dec(lop);
  truncatepath:=copy(path,1,lop);
End;

Function fragname(path:string;frag:fragtype):string;
Var Dir: DirStr;Name: NameStr;Ext: ExtStr;
Begin
  fsplit(path,dir,name,ext);
  case frag of
    d:fragname:=copy(dir,1,3);
    p:fragname:=dir;
    n:fragname:=name;
    e:fragname:=ext
  end;
end;

Function instring(name:string;testchar:char):boolean;
var lop:byte;out:boolean;
Begin
  out:=false;lop:=1;
  while (lop<=length(name))and(out=false) do begin
    out:=name[lop]=testchar;
    inc(lop);
  end;
  instring:=out;
end;

Function numoffiles(path,filter:string;attrfilter:word):integer;
var count:word;dirinfo:searchrec;
Begin
  count:=0;
  FindFirst(path+filter, attrfilter, DirInfo);
  while DosError=0 do
  begin
    if (dirinfo.attr=attrfilter)or((attrfilter=anyfile)and(dirinfo.attr
    <>directory){and(DirInfo.Name<>'.')and(DirInfo.Name<>'..')}) then
    inc(count);
    FindNext(DirInfo);
  end;
  numoffiles:=count;
end;

{Procedure inputdrives(var disks:menutype);
Var lop,count:byte;
Begin
  count:=0;
  For lop:=0 to 25 do
    if disksize(lop)<>-1 then inc(count);
  with disks do
  Begin
  maxopts:=count;maxylen:=4;
  getmem(attrib,1+maxopts);getmem(info,(1+maxopts)*21);
  count:=0;
  For lop:=0 to 25 do
    if disksize(lop)<>-1 then
    Begin
      disks.info^[count]:='Drive '+chr(65+count);
      disks.attrib^[count]:=0;
      inc(count);
    end;
end;
end;}
End.


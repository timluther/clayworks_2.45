unit dialogs;

INTERFACE
uses crt2,gbasics,views,twinb,ggraph,dos,diskop,
     twindraw,chardef,msmouse,lcd,tmaths,strings,sincos,ttypes,emsunit,colour;

CONST
ceditorsid        =100;
CMDfileOK         =400;
CMDfileCancel     =401;
CMDCreatecoledit  =402;
CMDcolourchanged  =403;
CMDcalleditpal    =404;

type


Colourgridtype=^Colourgridtype_;

Coloureditor=^Coloureditor_;
Coloureditor_=object(tgroup_)
  Cgrid:colourgridtype;
  Rbar,gbar,bbar:slidertype;

  HSVbutton,RGBbutton:TextButton;
  colour,mode:byte;
  oldpal:RGBarray;
  change:boolean;
  Constructor create(xa,ya:integer;colour_:byte;Cgrid_:colourgridtype);
  Destructor done;virtual;
  Procedure handlevent(var event:tevent);virtual;
  Procedure setcolour(colour_:byte);
  Procedure Draw;virtual;
end;

Colourgridtype_=object(tview_)
  CEditor:coloureditor;
  Desktop:tgroup;
  size:bytepointtype;

  fgcol,bgcol:byteptr;
  xsize,ysize,offset:integer;

  Constructor create(x,y,xsize_,ysize_:integer;xlen_,ylen_:byte;fgcol_,bgcol_:byteptr;desktop_:tgroup);
  procedure draw;virtual;
  procedure handlevent(var event:tevent);virtual;
end;

chartype=record
  ch:char;
  at:byte;
end;

screenptr=^screentype;
screentype=array[0..24]of textline;

textpage=^textpage_;
textpage_=object(delta_)
  screen:screenptr;
  Constructor make(page:screenptr);
  procedure draw;virtual;
end;

colourwindow=^colourwindow_;
colourwindow_=object(delta_)
  procedure draw;virtual;
end;

bitmapwindow=^bitmapwindow_;
bitmapwindow_=object(delta_)
  destroypic:boolean;
  pic:bitmaptypeptr;
  Constructor make(piccy:bitmaptypeptr;dpic:boolean);
  Destructor done;virtual;
  procedure draw;virtual;
end;

InfoDialog=^InfoDialog_;
InfoDialog_=object(tgroup_)
  deltext:boolean;
  xbar,ybar:bartype;
  ActionWindow:Delta;
  Constructor create(xa,ya,xb,yb:integer;text:pchar;deltext_:boolean);
  procedure handlevent(var event:tevent);virtual;
end;



InfoDialogb=^InfoDialogb_;
InfoDialogb_=object(tgroup_)
  xbar,ybar:bartype;
  ActionWindow:Delta;
  Constructor create(xa,ya,xb,yb:integer;text:pchar);
  procedure handlevent(var event:tevent);virtual;
end;

timetype=record
  hour,min,sec,nsec:word;
end;

clock=^clock_;
clock_=object(tview_)
  drawmode,alarmon:boolean;
  currtime,oldtime,alarm:timetype;

  procedure update;

  Constructor make;
  procedure draw;virtual;
end;

Analogclock=^Analogclock_;
Analogclock_=object(tview_)
  drawmode,alarmon:boolean;
  currtime,oldtime,alarm:timetype;

  procedure update;
  Constructor create(x1_,y1_,x2_,y2_:integer);
  procedure setalarm(switch:boolean;hrs,min:word);
  procedure draw;virtual;
end;

digitwindow=^digitwindow_;
digitwindow_=object(delta_)
  procedure draw;virtual;
end;

background=^background_;
background_=object(tview_)
  fgcol,bgcol:byte;
  pattern:fillpatterntype;

  constructor create(x1_,y1_,x2_,y2_:integer;fgcol_,bgcol_:byte;pattern_:fillpatterntype);
  procedure draw;virtual;
end;

backpic=^backpic_;
backpic_=object(tview_)
  pic:bitmaptypeptr;

  constructor create(x1_,y1_,x2_,y2_:integer;pic_:bitmaptypeptr);
  procedure draw;virtual;
end;

{starback=^starback_;
starback_=object(tview_)
  starfall:startype;
  procedure update;
  constructor create(xa,ya,xb,yb:integer);
  procedure draw;virtual;
end;}


MoveTitle=^Movetitle_;
MoveTitle_=object(Tgroup_)
  Constructor Create(xa,ya,xb,yb:integer;Name:string);
  Procedure Handlevent(var Event:Tevent);virtual;
end;

statusviewb=^statusviewb_;
statusviewb_=object(tview_)
  val1:^byte;oldval1:byte;


  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
  procedure update;
end;


statusview=^statusview_;
statusview_=object(tview_)
  oldcharcode:char;oldscancode,oldscan:byte;
  MemoryLeft:longint;
  oldioresult:word;
  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
  procedure update;
end;

listWbar=^listWbar_;
listWbar_=object(tgroup_)
  list:listtype;
  bar:slidertype;
  constructor create(x,y,x2_,y2_:integer;info_:stringarray;maxopts_,offset:integer;destroyold_:boolean);
  Procedure Handlevent(var Event:Tevent);virtual;
  Procedure setlist(info_:stringarray;maxopts_:integer);
end;

File_dialog=^File_dialog_;
File_dialog_=object(tgroup_)
  Ok,cancel:word;
  SDir: DirStr;SName: NameStr;SExt: ExtStr;
  StdFilter:string[11];
  files,paths:listwbar;
  texteditbox:edittexttype;
  Handler:tview;

  Procedure load_files;
  Procedure load_path;
  Constructor create(x,y:integer;Cancel_,Ok_:word;name_,path,filter:string;handler_:tview);
  Procedure handlevent(var event:tevent);virtual;
  Procedure Draw;virtual;
end;

desktoptype=^desktoptype_;
desktoptype_=object(tgroup_)
  procedure handlevent(var event:tevent);virtual;
end;

procedure AddMessage(Cancel,Ok:word;message:pchar;pid_:word;group:tgroup);
function loadtext(filename:string):pchar;
function inputdir(path,filter:string;attrfilter:word;var count:integer):stringarray;

IMPLEMENTATION

Procedure UpCaseStr(var text:string);
var lop:byte;
begin
  for lop:=1 to byte(text[0]) do
    text[lop]:=upcase(text[lop]);
end;


Procedure Sortarray(data:stringarray;datasize:word;maxelem:integer);
var lop2,lop:byte;
    {dataptr1,dataptr2:^stdstring;}

Begin
  {dataptr1:=data;
  dataptr2:=data;}
  For lop:=1 to maxelem do begin
    {inc(dataptr1,datasize);}
    For lop2:=lop to maxelem do begin
      {inc(dataptr2,datasize);
      if dataptr2^<dataptr1^ then}
      if data^[lop2]<data^[lop] then
        fswap(data^[lop2],data^[lop],datasize)
        {fswap(dataptr1^,dataptr2^,datasize);}
    end;
  end;
end;

function inputdir(path,filter:string;attrfilter:word;var count:integer):stringarray;
var DirInfo:SearchRec;
    info:stringarray;
    maxopts:integer;

Begin
  maxopts:=numoffiles(path,filter,attrfilter);
  {if attrfilter=directory then inc(maxopts,2);}
  getmem(info,(1+maxopts)*21);
  count:=0;
  if attrfilter=anyfile then
    info^[0]:='No files'
  else begin
    info^[0]:='No dirs';
    {info^[count+1]:='[.]';
    inc(count);
    info^[count+1]:='[..]';
    inc(count);}
  end;

  {if dirs then inc(count);}
  {oldcount:=count;}
  FindFirst(path+filter, attrfilter, DirInfo);
  while DosError=0 do begin
    if(dirinfo.attr=attrfilter)or
    ((attrfilter=anyfile)and(dirinfo.attr<>directory))
    and(count<255)  then begin
      if DirInfo.attr=directory then
        info^[count+1]:=DirInfo.Name
      else
        info^[count+1]:=DirInfo.Name;
      inc(count);
    end;
    FindNext(DirInfo);
  end;
  sortarray(info,stringsize+1,maxopts);
  inputdir:=info;
End;

constructor listWbar_.create(x,y,x2_,y2_:integer;info_:stringarray;maxopts_,offset:integer;destroyold_:boolean);
var temp:integer;
begin
  inherited create(x,y,x+x2_+offset+scrollbar_size,y+y2_);
  options:=options or ofkeygrab+ofnooverlap+OfTabCycleSelect;
  list:=new(listtype,create(x,y,x2_,y2_,info_,maxopts_,destroyold_));
  list^.growmode:=TGgrowx2+TGgrowy2;
  with list^ do temp:=maxopts-maxylen;
  if temp<0 then temp:=0;
  insert(list);
  insert(new(bartype,create(x+x2_+offset,y,scrollbar_size,y2_,1,1+temp,1,ybardir)));
  bar:=slidertype(tgroup(first)^.last);
  bar^.growmode:=TGdragx2+TGgrowally;
end;

Procedure listWbar_.Handlevent(var Event:Tevent);
begin
  inherited handlevent(event);
  with event do
  if what=EvCommand then case command of
    CMDoffsetchanged:
      bar^.setval(list^.off);
    CMDvalchanged:begin
      list^.handlevent(event);
      EvCallBack(command);
    end else
      EvCallBack(command);
  end;
end;

{load up a new list, modify the list isteslf and the bar}
Procedure ListWbar_.setlist(info_:stringarray;maxopts_:integer);
var temp:integer;
begin
  list^.setlist(info_,maxopts_);
  with list^ do temp:=maxopts-maxylen;
  if temp<0 then temp:=0;
  bar^.setrange(1,1+temp,1);
end;

{procedure listWbar_.setlist(list_:stringarray;maxopts:integer);
begin
  list^.info:=
end;}
const
PIDfiles=100;
PIDpaths=101;


Constructor file_dialog_.create(x,y:integer;Cancel_,Ok_:word;name_,path,filter:string;handler_:tview);
const
W=300; H=220+(fontheight shl 1);
var
list:stringarray;
listcount:integer;

temp:integer;
begin
  inherited create(x,y,x+W,y+H);
  Cancel:=Cancel_;
  Ok:=Ok_;
  Stdfilter:=filter;
  Handler:=Handler_;
  {chdir(path);}
  options:=options or (ofnooverlap+ofkeygrab+oftopselect+OfTabCycleSelect);

  texteditbox:=new(edittexttype,create(x1+10,y1+vbord+fontheight+4,path+filter,100,20));
  texteditbox^.growmode:=TGdragx1+TGdragy1;
  insert(texteditbox);

  fsplit(texteditbox^.txt,sdir,sname,sext);
  list:=inputdir(Sdir,filter,anyfile,listcount);

  files:=new(listwbar,create(x1+10,y2-168,110,117,list,listcount,3,true));
  files^.growmode:=TGgrowallx+TGgrowally;
  files^.pid:=PIDfiles;
  insert(files);

  list:=inputdir(Sdir,'*.*',directory,listcount);

  paths:=new(listwbar,create(x1+150,y2-168,110,101,list,listcount,3,true));
  paths^.growmode:=TGgrowallx+TGgrowally;
  paths^.pid:=PIDpaths;
  insert(paths);

  insert(new(listtype,create(x1+10,y2-15-Fontheight,50,4+Fontheight,list,0,true)));
  first^.growmode:=TGdragx1+TGdragy2;
  add_title(@self,name_);
  {insert(new(dialogback,create(x1,y1+vbord+1,x2,y2)));}
  insert(new(textbutton,create(x2-140,y2-30,60,20,midcol,1,BM_releaseaction,1,OK,'Ok')));
  first^.growmode:=TGdragx2+TGdragy2;
  insert(new(textbutton,create(x2-70,y2-30,60,20,midcol,1,BM_releaseaction,1,Cancel,'Cancel')));
  first^.growmode:=TGdragx2+TGdragy2;

  growmode:=TGdragx2+TGdragy2;
  

end;

procedure file_dialog_.load_path;
var temp:integer;
    list:stringarray;
    listcount:integer;
begin
  list:=inputdir(Sdir,'*.*',directory,listcount);
  paths^.setlist(list,listcount);
end;

procedure file_dialog_.load_files;
var temp:integer;
    list:stringarray;
    listcount:integer;
begin
  list:=inputdir(Sdir,Sname+Sext,anyfile,listcount);
  files^.setlist(list,listcount);
end;

procedure file_dialog_.handlevent(var event:tevent);
{Const
  files=1;paths=2;
var
  currbar:slidertype;
  currlist:listtype;
  currblock:byte;}

var
ID:word;

procedure loadlists;
var ODir: DirStr;
begin
  if texteditbox^.txt<>sdir+sname+sext then begin
    Odir:=Sdir;
    fsplit(texteditbox^.txt,sdir,sname,sext);
    if (sname='')and(sext='') then begin
      texteditbox^.settext(gtdir+stdfilter);
      fsplit(texteditbox^.txt,sdir,sname,sext);
    end;
    if Odir<>Sdir then begin
      load_path;
    end;
    if (instring(sname,'*'))or(instring(sext,'*')) then begin
      load_files;
    end else begin
      upcasestr(texteditbox^.txt);
      SendCommand(Ok,Handler,@self);delete;
    end;
  end;
end;

begin
  inherited handlevent(event);
  with event do
  case what of
    evcommand:begin
      {if (infoptr=filebar)or(infoptr=filelist) then begin
        currlist:=filelist;currbar:=filebar;
        currblock:=files;
      end else if (infoptr=pathbar)or(infoptr=pathlist) then begin
        currlist:=pathlist;currbar:=pathbar;
        currblock:=paths;
      end;}
      id:=tview(infoptr)^.pid;
      case command of
        CMDEditReturnPressed:loadlists;
        CMDmoveparent:dragview(1,owner^,150,170,1000,1000);
        CMDitemDclicked:if id=PIDfiles then begin
          upcasestr(texteditbox^.txt);
          SendCommand(Ok,Handler,@self);delete;
        end else begin
          with paths^.list^ do begin
            chdir(sdir);
            chdir(info^[sel]){copy(info^[sel],2,length(info^[sel])-2))};
          end;
          texteditbox^.settext(gtdir+stdfilter);
          loadlists;
        end;
        CMDselectedchanged:begin
          if ID=PIDfiles then
            with Files^.list^ do texteditbox^.settext(Sdir+info^[sel])
        end;
        else if (command=ok)or (command=cancel)then begin
          SendCommand(command,Handler,@self);delete;
        end;
      end;
    end;
    EvKeyDown:if scancode<>0 then begin
      what:=0;
      case scancode of
        49:texteditbox^.select;
        25:paths^.list^.select;
        33:files^.list^.select;
        else what:=EvKeyDown;
      end;
    end;
  end;
  
end;

Procedure File_dialog_.draw;
begin
  outbox(x1,y1+vbord+1,x2,y2);
  t_col:=disabledcol;
  with TextEditBox^ do
    outtextxyU(x1,y1-fontheight-1,'Name',1);
  with Files^ do
    outtextxyU(x1,y1-fontheight-1,'Files',1);
  with Paths^ do
    outtextxyU(x1,y1-fontheight-1,'Paths',1);
  inherited draw;
end;

{----****Colour editing dialog****----}
Constructor colourgridtype_.create(x,y,xsize_,ysize_:integer;xlen_,ylen_:byte;fgcol_,bgcol_:byteptr;desktop_:tgroup);
 begin
  inherited create(x,y,x+(xsize_*xlen_)-1,y+(ysize_*ylen_)+1);
  desktop:=desktop_;
  fgcol:=fgcol_;
  bgcol:=bgcol_;
  Ceditor:=nil;
  size.x:=xlen_;
  size.y:=ylen_;
  xsize:=xsize_;
  ysize:=ysize_;
  offset:=0;
end;

procedure colourgridtype_.draw;
var x,y:integer;
    xpos,ypos:integer;
begin
  t_col:=lightcol;
  hline(x1,x2,y1);
  colourgrid(x1,y1+1,xsize,ysize,size.x,size.y,offset*size.x);
  t_col:=darkcol;
  hline(x1,x2,y2);
  t_writemode:=xorput;
  xpos:=(fgcol^ mod size.x);
  ypos:=((fgcol^-xpos) div size.x);
  x:=1+x1;y:=1+y1;
  outtextxy(x+(xpos*xsize),y-(offset*ysize)+(ypos*ysize),'F');
  xpos:=(bgcol^ mod size.x);
  ypos:=((bgcol^-xpos) div size.x);
  outtextxy(x+(xpos*xsize),y-(offset*ysize)+(ypos*ysize),'B');
  t_writemode:=0;
end;

procedure colourgridtype_.handlevent(var event:tevent);
var colour:byte;
begin
  inherited handlevent(event);
  with event do begin
    if what and Evmouse<>0 then begin
      if zm<>0 then begin
        colour:=(((xm-x1-1)div xsize)+((ym-y1-1)div ysize)*size.x)+(offset*size.x);
        if ((colour<>fgcol^)and(zm=1))or((colour<>bgcol^)and(zm=2)) then begin
          if zm=1 then
            fgcol^:=colour
          else
            bgcol^:=colour;
          if Ceditor<>nil then Ceditor^.setcolour(colour);
          drawview;
          EvCallBack(CMDcolourchanged);
        end;
      end;
      if (ms_doubleclicked) then with desktop^ do begin
        if add_and_draw(new(coloureditor,create(x1+100,y1+100,fgcol^,@self)),VPcentre,ceditorsid)<>nil then
          ceditor:=pointer(first);
      end;
    end;
    if (what=evcommand)then case command of
    CMDvalchanged:begin
      offset:=valuetype(infoptr)^.val^;
      drawview;
    end;
    CMDcalleditpal:with desktop^ do begin
      if add_and_draw(new(coloureditor,create(x1+100,y1+100,fgcol^,@self)),VPcentre,ceditorsid)<>nil then
          ceditor:=pointer(first);
    end;
    end;
  end;
end;

const
CMDok=300;
CMDCancel=301;
CMDGrad=302;
CMDCopy=303;
CMDSwap=304;
CMDRGB=305;
CMDHSV=306;

mdHSV=1;
mdRGB=0;

Constructor Coloureditor_.create(xa,ya:integer;colour_:byte;Cgrid_:Colourgridtype);
const
  w=170;h=230;
var
r,g,b:byte;
begin
  inherited create(xa,ya,xa+w,ya+h);
  cgrid:=cgrid_;
  change:=false;
  getmem(oldpal,SC.colourdepth*sizeof(rgbtype));
  getpal(oldpal);
  colour:=colour_;
  mode:=mdRGB;
  getrgb(colour,r,g,b);
  options:=options or (ofnooverlap+ofkeygrab+oftopselect+OfTabCycleSelect);
  insert(new(bartype,create(x1+5,y1+43,scrollbar_size,147,-63,0,-r,ybardir)));
  Rbar:=slidertype(tgroup(first)^.last);
  insert(new(bartype,create(x1+25,y1+43,scrollbar_size,147,-63,0,-g,ybardir)));
  Gbar:=slidertype(tgroup(first)^.last);
  insert(new(bartype,create(x1+45,y1+43,scrollbar_size,147,-63,0,-b,ybardir)));
  Bbar:=slidertype(tgroup(first)^.last);
  insert(new(Textbutton,create(x2-50,y1+40,40,20,titlecol,1,BM_releaseaction,1,CMDgrad,'Fade')));
  insert(new(Textbutton,create(x2-50,y1+65,40,20,titlecol,1,BM_releaseaction,1,CMDswap,'Swap')));
  insert(new(Textbutton,create(x2-50,y1+90,40,20,titlecol,1,BM_releaseaction,2,CMDcopy,'Copy')));
  RGBbutton:=new(Textbutton,create(x2-50,y1+115,40,20,titlecol,1,BM_ToggleAction,1,CMDrgb,'RGB'));
  insert(RGBbutton);
  RGBbutton^.dstate:=1;
  HSVbutton:=new(Textbutton,create(x2-50,y1+140,40,20,titlecol,1,BM_toggleAction,1,CMDhsv,'HSV'));
  insert(HSVbutton);

  insert(new(Textbutton,create(x2-65,y2-55,55,20,midcol,1,BM_ReleaseAction,1,CMDok,'Ok')));
  insert(new(Textbutton,create(x2-65,y2-30,55,20,midcol,1,BM_ReleaseAction,1,CMDCancel,'Cancel')));

  add_title(@self,'Colour editor');
end;

Procedure Coloureditor_.setcolour(colour_:byte);
var r,g,b:byte;
begin
  colour:=colour_;
  if mode=mdRGB then
    getrgb(colour,r,g,b)
  else
    gethsv(colour,r,g,b);

  change:=true;
  rbar^.setval(-r);
  gbar^.setval(-g);
  bbar^.setval(-b);
  drawview;
  change:=false;
end;

Procedure Coloureditor_.handlevent(var event:tevent);
var othercolour:byte;
    cliprect,oldvp:trect;
begin
  inherited handlevent(event);
  with event do begin
    if what=Evcommand then begin
      oldvp:=SC.viewport;
      cliprect.rassign(x1+10,y1+vbord+1,x1+58,y1+42);
      case command of
      CMDmoveparent:dragview(1,owner^,130,100,1000,1000);
      CMDvalchanged:if not change then
        if mode=mdRGB then
          setrgb(colour,-rbar^.offs,-gbar^.offs,-bbar^.offs)
        else
          sethsv(colour,-rbar^.offs,-gbar^.offs,-bbar^.offs);
      CMDrgb:if mode=mdHSV then begin
        mode:=mdRGB;
        setcolour(colour);
        HSVbutton^.dstate:=0;
        HSVbutton^.drawview;
        SC.viewport:=cliprect;
        drawview;
        SC.viewport:=oldvp;
      end;
      CMDhsv:if mode=mdRGB then begin
        mode:=mdHSV;
        setcolour(colour);
        RGBbutton^.dstate:=0;
        RGBbutton^.drawview;
        SC.viewport:=cliprect;
        drawview;
        SC.viewport:=oldvp;
      end;
      CMDgrad,CMDswap,CMDcopy:if Cgrid<>nil then begin
        setmouseshape(8,15,pointto);
        while ((not cgrid^.inview(xm,ym)) or (not ms_clicked))and(not keypressed ) do
          mpos;
        if not keypressed then begin
        mouseoff;othercolour:=getpixel(xm,ym);mouseon;
        if colour<>othercolour then case command of
          CMDgrad:grad(colour,othercolour);
          CMDcopy:copycol(colour,othercolour);
          CMDswap:swapcol(colour,othercolour);
        end;
        setcolour(colour);
        end;
        setmouseshape(0,0,arrow);
      end;
      CMDok:begin
        if Cgrid<>nil then Cgrid^.Ceditor:=nil;
        delete;
      end;
      CMDcancel:begin
        if Cgrid<>nil then Cgrid^.Ceditor:=nil;
        setpal(oldpal,0,SC.colourdepth);
        delete;
      end;
      end;
    end;
    if what=evkeydown then case scancode of
      19:Rbar^.owner^.select;
      34:Gbar^.owner^.select;
      48:Bbar^.owner^.select;
    end;
  end;
end;

Procedure Coloureditor_.draw;
var precalc:integer;
begin
  inc(y1,vbord+1);
  if not change then begin
    precalc:=y1+3;
    outbox(x1,y1,x2,y2);
    t_col:=disabledcol;
    if mode=mdRGB then begin
      outtextxy(x1+10,precalc,'R');
      outtextxy(x1+30,precalc,'G');
      outtextxy(x1+50,precalc,'B');
    end else begin
      outtextxy(x1+10,precalc,'H');
      outtextxy(x1+30,precalc,'S');
      outtextxy(x1+50,precalc,'V');
    end;
    t_col:=Darkcol;
    rectangle(x2-90,y1+18,x2-55,y1+87);
    inherited draw;
  end;
  T_fillcol:=colour;
  bar(x2-89,y1+19,x2-56,y1+86);
  dec(y1,vbord+1);
end;

Destructor ColourEditor_.done;
begin
  Freemem(oldpal,SC.colourdepth*sizeof(RGBtype));
  Inherited done;
end;

Procedure textpage_.draw;
var ylop,ypos,stpx,stpy:integer;
    currline:textlineptr;
Begin
  stpy:=25;
  stpx:=80;
  ypos:=y1-yoff;
  t_col:=15;
  currline:=pointer(screen);
  For ylop:=0 to stpy do begin
    {outtextline(x1-xoff,ypos,stpx,currline);}
    inc(ypos,Fontheight);
    inc(currline);
  end;
End;

Constructor textpage_.make(page:screenptr);
begin
  inherited make(0,0,639,(Fontheight * 25)-1);
  screen:=page;
end;

constructor background_.create(x1_,y1_,x2_,y2_:integer;fgcol_,bgcol_:byte;pattern_:fillpatterntype);
begin
  inherited create(x1_,y1_,x2_,y2_);
  pattern:=pattern_;
  fgcol:=fgcol_;
  bgcol:=bgcol_;
end;

const
colrange=512;
colstart=0;
procedure background_.draw;
begin
  {stipcolourgridb(x1,y1,width+1,1+height div colrange,1,colrange,colstart);}
  t_col:=fgcol;
  setfillpattern(pattern,true);
  t_fillcol:=bgcol;
  bar(x1,y1,x2,y2);
  setsolidfill;
end;

constructor backpic_.create(x1_,y1_,x2_,y2_:integer;pic_:bitmaptypeptr);
begin
  inherited create(x1_,y1_,x2_,y2_);
  pic:=pic_;
end;

procedure backpic_.draw;
var xlop,ylop:integer;
begin
  for ylop:=0 to (y2 div pic^.size.y) do
    for xlop:=0 to (x2 div pic^.size.x) do
      putbitmap(x1+(xlop*pic^.size.x),y1+(ylop*pic^.size.y),pic);
end;

Constructor bitmapwindow_.make(piccy:bitmaptypeptr;dpic:boolean);
begin
  with piccy^ do
  inherited make(0,0,size.x-1,size.y-1);
  pic:=piccy;
  destroypic:=dpic;
end;

Destructor bitmapwindow_.done;
begin
  if destroypic then
    DestroyBitmap(pic);
  inherited done;
end;

procedure bitmapwindow_.draw;
begin
  t_fillcol:=3;
  putbitmap(x1-xoff,y1-yoff,pic);
end;

procedure digitwindow_.draw;
begin
  t_fillcol:=3;
  bar(x1,y1,x2,y2);
  drawdigit(x1+30,y1+30,digits[1],bigLCD);
end;

procedure colourwindow_.draw;
begin
  colourgrid(x1,y1,(x2-x1)div 10,(y2-y1)div 10,10,10,0);
end;

constructor clock_.make;
begin
  inherited make;
  drawmode:=false;
end;

procedure clock_.draw;
var x:integer;
begin
  x:=10;
  with currtime do begin
    x:=10;
    t_fillcol:=0;
    if not drawmode then
      bar(x1,y1,x2,y2);
    if (oldtime.hour<>hour)or(not drawmode) then
    lcd_num(x1+x,y1+10,hour mod 12,BigLcd,true);
    inc(x,biglcd.size+2*(biglcd.width+20));

    if (oldtime.min<>min)or(not drawmode) then
    lcd_num(x1+x,y1+10,min,BigLcd,false);
    inc(x,2*(biglcd.width+10));

    if (oldtime.sec<>sec)or(not drawmode) then
    lcd_num(x1+x,y1+10,sec,SmallLcd,true);
    inc(x,smalllcd.size+2*(smalllcd.width+10));

    if (oldtime.nsec<>nsec)or(not drawmode) then
    lcd_num(x1+x,y1+10,nsec,SmallLcd,false);
  end;
end;

Procedure clock_.update;
begin
  drawmode:=true;
  oldtime:=currtime;
  with currtime do
    gettime(hour,min,sec,nsec);
  drawview;
  drawmode:=false;
end;

{Analog Clock}
constructor Analogclock_.create(x1_,y1_,x2_,y2_:integer);
begin
  inherited create(x1_,y1_,x2_,y2_);
  DrawMode:=false;
  alarmon:=false;
end;

procedure Analogclock_.draw;
const size=3;
      Offset=10;

Var timelop:byte;AngleCount:word;
    hlfx,hlfy:integer;precalc:real;
    px,py:integer;
    Hourhandsize:integer;
    Minutehandsize:integer;
    secondshandsize:integer;

function GetAngle(time,stepsize:integer):real;
begin
  GetAngle:=(pi/2)+(time*(2*pi))/stepsize;
end;

Procedure DrawHand(time,Stepsize:integer;col:byte;size:integer;width:integer);
var precalc,precalcb:real;
    p1,p2,p3,p4:pointtype;

begin
  T_col:=col;
  T_fillcol:=col;
  precalc:=GetAngle(time,stepsize);
  p1.x:=round(hlfx+cos(precalc));
  p1.y:=round(hlfy+sin(precalc));
  precalcb:=(precalc+pi);
  p2.x:=round(hlfx+cos(precalcb)*size);
  p2.y:=round(hlfy+sin(precalcb)*size);
  precalcb:=(precalc+offset);
  p3.x:=round(hlfx+cos(precalcb)*width);
  p3.y:=round(hlfy+sin(precalcb)*width);
  precalcb:=(precalc-offset);
  p4.x:=round(hlfx+cos(precalcb)*width);
  p4.y:=round(hlfy+sin(precalcb)*width);

  {triangle(p1.x,p1.y,p3.x,p3.y,p2.x,p2.y);
  triangle(p1.x,p1.y,p4.x,p4.y,p2.x,p2.y);}
  line(p1.x,p1.y,p3.x,p3.y);
  line(p3.x,p3.y,p2.x,p2.y);
  line(p2.x,p2.y,p4.x,p4.y);
  line(p4.x,p4.y,p1.x,p1.y);
end;

begin
  hlfx:=halfx+x1;
  hlfy:=halfy+y1;
  hourhandsize:=(width shr 2) +2;
  minutehandsize:=(width shr 1) -12;
  secondshandsize:=(width shr 1) -12;

  if not Drawmode then with currtime do begin
    outbox(x1,y1,x2,y2);

    for timelop:=1 to 12 do begin
      precalc:=GetAngle(timelop,12);
      px:=hlfx+round(cos(precalc)*(width shr 1 -6));
      py:=hlfy+round(sin(precalc)*(height shr 1 -6));
      if timelop mod 3=0 then begin
        T_fillcol:=12;
        outboxcol(px-3,py-3,px+3,py+3);
      end else
        outbox(px+1,py+1,px-1,py-1);
    end;
    DrawHand(currtime.hour,720,darkblue,hourhandsize,8);
    DrawHand(currtime.min,60,darkblue,minutehandsize,4);
    DrawHand(currtime.sec,60,red,secondshandsize,1);
  end else with oldtime do begin
    if hour<>currtime.hour then
      DrawHand(hour,720,midcol,hourhandsize,8);
    if min<>currtime.min then
      DrawHand(min,60,midcol,minutehandsize,4);
    if sec<>currtime.sec then
      DrawHand(sec,60,midcol,secondshandsize,1);

    DrawHand(currtime.hour,720,darkblue,hourhandsize,8);
    DrawHand(currtime.min,60,darkblue,minutehandsize,4);
    DrawHand(currtime.sec,60,red,secondshandsize,1);
  end;
end;

Procedure Analogclock_.update;
begin
  oldtime:=currtime;
  with currtime do begin
    gettime(hour,min,sec,nsec);
    hour:=(hour mod 12)* 60 + min;
  end;
  if oldtime.sec<>currtime.sec then begin
    drawmode:=true;
    drawview;
    drawmode:=false;
  end;
  if (alarmon) then
    if (alarm.hour=currtime.hour)and(alarm.min=currtime.min) then begin
      sound(100);delay(10);nosound;
    end;
end;

procedure Analogclock_.setalarm(switch:boolean;hrs,min:word);
begin
  alarm.hour:=(hrs mod 12)* 60 + min;
  alarm.min:=min;
  alarmon:=switch;
end;

{Constructor starback_.create(xa,ya,xb,yb:integer);
begin
  inherited create(xa,ya,xb,yb);
  starfall.init;
  starfall.move(0);
  xoff:=halfx;
  yoff:=halfy;
end;

procedure starback_.draw;
begin
  t_fillcol:=0;
  bar(x1,y1,x2,y2);
  starfall.draw;
end;

procedure starback_.update;
begin
  starfall.move(-5);
  drawview;
end;}


Constructor infodialog_.create(xa,ya,xb,yb:integer;text:pchar;deltext_:boolean);
var  loader:trect;
w,h:integer;
begin
  inherited create(xa,ya,xb,yb);
  options:=options or OfTopSelect;
  w:=xb-xa;
  h:=yb-ya;
  insert(new(dialogback,create(x1,y1,x2,y2)));
  actionwindow:=
  new(textobject,make(text,TOintextbox,deltext_));
  insert(actionwindow);

  insert(new(bartype,create(x2-20,y1+9,15,h-38,0,0,0,ybardir)));
  actionwindow^.ybar:=slidertype(tgroup(first)^.last);
  insert(new(bartype,create(x1+5,y2-44,W-27,15,0,0,0,xbardir)));
  actionwindow^.xbar:=slidertype(tgroup(first)^.last);
  insert(new(textbutton,create(x2-45,y2-25,40,20,midcol,1,BM_releaseaction,
         1,CMDdismisview,'OK')));
  loader.rassign(x1+5,y1+5,x2-25,y2-49);
  actionwindow^.changebounds(loader);
end;



procedure infodialog_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do

  if what=EvCommand then begin
    case command of
      CMDdismisview:begin
        if deltext=true then with textobject(actionwindow)^ do
          freemem(txt,strlen(txt));
        delete;
      end;
      CMDvalchanged:begin
        with actionwindow^ do
        if infoptr=xbar then
          setoffsets(xbar^.offs,yoff)
        else
          setoffsets(xoff,ybar^.offs);
      end;
    end;
    
  end;
end;

Constructor infodialogb_.create(xa,ya,xb,yb:integer;text:pchar);
var  loader:trect;
begin
  inherited create(xa,ya,xb,yb);
  actionwindow:=
  new(textobject,make(text,TOintextbox,false));
  insert(actionwindow);

  insert(new(bartype,create(x2-15,y1,15,height-16,0,0,0,ybardir)));
  actionwindow^.ybar:=slidertype(tgroup(first)^.last);
  insert(new(bartype,create(x1,y2-15,width-16,15,0,0,0,xbardir)));
  actionwindow^.xbar:=slidertype(tgroup(first)^.last);
  loader.rassign(x1,y1,x2-16,y2-16);
  actionwindow^.changebounds(loader);
end;

procedure infodialogb_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do
  if what=EvCommand then case command of
    CMDdismisview:delete;
    CMDvalchanged:begin
      with actionwindow^ do
      if infoptr=xbar then
        setoffsets(xbar^.offs,yoff)
      else
        setoffsets(xoff,ybar^.offs);
    end;
  end;
end;

function loadtext(filename:string):pchar;
var lastchar,textfile:pchar;
    recsize:word;
    f:file;
begin
  recsize:=1;
  assign(f,filename);
  reset(f,recsize);
  getmem(textfile,filesize(f));
  blockread(f,textfile^,filesize(f),recsize);
  lastchar:=textfile;
  inc(lastchar,filesize(f));
  LastChar^:=chr(0);
  close(f);
  loadtext:=textfile;
  
end;

Constructor MoveTitle_.Create(xa,ya,xb,yb:integer;Name:string);
begin
  inherited create(xa,ya,xb,yb);
  options:=options or (OfNoOverlap+Oftopselect);
  add_title(@self,name);
end;

Procedure MoveTitle_.Handlevent(var event:Tevent);
begin
  inherited Handlevent(event);
  with event do
  if what=EvCommand then if Command=CMDmoveparent then
    dragview(1,owner^,50,50,1000,1000);
end;

Procedure Statusview_.handlevent(var event:tevent);
begin
  Inherited handlevent(event);
  if event.what and EvMouseDown<>0 then
    dragview(1,owner^,0,0,1000,1000);
end;

Procedure statusview_.update;
begin
  if memavail<>memoryleft then begin
    memoryleft:=memavail;
    drawview;
  end else
  if oldscan<>scan then begin
    oldscan:=scan;
    drawview;
  end else
  if oldscancode<>scancode then begin
    oldscancode:=scancode;
    drawview;
  end else
  if oldcharcode<>charcode then begin
    oldcharcode:=charcode;
    drawview;
  end;
  if oldioresult<>ioresult then begin
    oldioresult:=ioresult;
    drawview;
  end;

end;

Procedure statusview_.draw;
begin
  draw3dborder(x1,y1,x2,y2,false);
  draw3dborder(x1+1,y1+1,x2-1,y2-1,true);
  t_fillcol:=midcol;
  bar(x1+2,y1+2,x2-2,y2-2);
  t_col:=textcol;
  outtextxy3d(x1+4,y1+4,               'key  :'+charcode);
  outtextxy3d(x1+4,y1+4+(fontheight),  'ord  :'+itoa(ord(charcode)));
  outtextxy3d(x1+4,y1+4+(fontheight*2),'scode:'+itoa(scancode));
  outtextxy3d(x1+4,y1+4+(fontheight*3),'mem  :'+itoa(memavail));
  outtextxy3d(x1+4,y1+4+(fontheight*4),'scan :'+itoa(scan));
  outtextxy3d(x1+4,y1+4+(fontheight*5),'io   :'+itoa(ioresult));
end;

Procedure Statusviewb_.handlevent(var event:tevent);
begin
  Inherited handlevent(event);
  if event.what and EvMouseDown<>0 then
    dragview(1,owner^,0,0,1000,1000);
end;

Procedure statusviewb_.update;
begin
  if val1^<>oldval1 then begin

    oldval1:=val1^;
    drawview;
  end;

end;

Procedure statusviewb_.draw;
begin
  draw3dborder(x1,y1,x2,y2,false);
  draw3dborder(x1+1,y1+1,x2-1,y2-1,true);
  t_fillcol:=midcol;
  bar(x1+2,y1+2,x2-2,y2-2);
  t_col:=textcol;
  outtextxy3d(x1+4,y1+4,'val1  :'+ftoa(val1^,3,3));

end;

procedure AddMessage(Cancel,Ok:word;message:Pchar;pid_:word;group:tgroup);
var p:tview;
begin
  with group^ do begin
    if (cancel=0) then
      p:=new(Messagebox,create(0,0,ok,message))
    else
      p:=new(Choicebox,create(0,0,cancel,ok,message));
    tgroup(add_and_draw(p,VPcentre,pid_))^.last^.select;
  end;
end;

Procedure Desktoptype_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do begin
    if (what=EvCommand) then
      if owner<>nil then
        owner^.handlevent(event);
 end;
end;




end.

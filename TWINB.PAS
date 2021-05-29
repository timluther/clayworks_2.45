Unit twinb;
{$X+}{$a+}{$R-}
INTERFACE
{This is my standard widget set -including the basic window frame
and delta view, which needs the window or something similar.
If you aren't me and you want to shive 'deltas' in your own views
then look carefully how I initialize them -the two 'bartypes' must be
given pointers but these aren't parameters because only the delta's
imeditate owner needs to set them}

uses crt2,msmouse,gbasics,ggraph,
     twindraw,diskop,dos,ttypes,
     chardef,views,Tmenust,tmaths,strings;

{some handy keyboard constants -stop you forgeting all the time}
var
warningsign:bitmaptypeptr;
const

tabtoplefthighlight:array[0..7] of byte=(7,24,32,64,64,128,128,128);
tabtopleftbody:array[0..7] of byte=(0,7,31,63,63,127,127,127);

tabtoprightbody:array[0..7] of byte=(192,224,240,248,248,248,252,252);
tabtoprightshadow1:array[0..7] of byte=(32,16,8,0,4,4,0,0);
tabtoprightshadow2:array[0..7] of byte=(16,8,4,4,2,2,2,2);




CMDzoomwindow                =1;
CMDwindowmenu                =2;
CMDmoveparent                =3;
CMDresizeparent              =4;
CMDdecval                    =5;
CMDincval                    =6;
CMDselectedchanged           =7;
CMDoffsetchanged             =8;
{used in listtype}
CMDitemdclicked              =9;
CMDvalchanged                =10;
{these are used in valuetype objects}
CMDsetval                    =11;
CMDdismisview                =12;
{used for delta}
CMDcentredelta               =13;
{used in edittexttype}
CMDEditReturnPressed         =14;
CMDEditstringaltered         =15;
CMDcentrewindow              =16;

{for windows}
hbord=15;      {title border -horizontal size}
vbord=20;      {title border -vertical size}
scrollbar_size=15; {size of the scrolling bars that line windows, optional}
xbord=3;       {multi-directional resize gadget size}
Wdeltax=1+scrollbar_size+(xbord*2); {Wdeltax -size of a delta window in x}
Wdeltay=2+scrollbar_size+vbord+(xbord*2); {Wdeltax -size of a delta window in x}

edit_indentX  =14;
edit_indentY  =3;
edit_textindentY=edit_indenty-1;

{icon panel constants}
icon_offsetout=1;
icon_offsetin=3;

{Icon types -shift the attrib^[n] byte 4 to the right to get these}
statemask=1;
oneon=  2;
nostick=4;
onoff=8;

TOjustifyMask=2;
TObordermask=24;
TOleftjustify=1;
TOrightjustify=2;
TOcentre=3;
TOwordwrap=4;
TOinborder=8;
TOinTextBox=16;
TOinbox=24;

ToBold=1;
ToItalic=2;
ToUnderlined=4;

DaNoscale=0;
DaScale=1;
DaNoDraw=2;

sliderblob:array[0..3] of byte=(48,120,120,48);
leftarrowb:array[0..7] of byte=(8,24,56,120,56,24,8,0);
rightarrowb:array[0..7] of byte=(32,48,56,60,56,48,32,0);

arrow:array[1..16]of word=(16383,8191,4095,2047,1023,511,255,127,63,127,511,4351,45311,63615,63615,64767);
arrowshape:array[1..16]of word=
(0,16384,24576,28672,30720,31744,32256,32512,32640,31744,27648,17920,1536,768,768,0);
PointTo:array[1..16]of word=(33155,1,0,32784,49680,49680,49664,49664,49921,58371,64575,61455,61455,63519,64575,65151);
PointToshape:array[1..16]of word=(0,32380,32510,6342,6342,6342,6342,6398,6268,0,384,384,2016,960,384,0);
Hourglass:array[1..16]of word=
(49155,49155,49155,49155,57351,61455,63519,64575,64575,63519,61455,61455,57351,49155,49155,49155);
Hourglassshape:array[1..16]of word=(0,8184,8088,0,3088,1568,832,384,0,832,1568,3616,3088,8184,7832,0);

Scancodes:array['0'..'Z']of byte=(129,120,121,122,123,124,125,126,127,128,
0,0,0,0,0,0,0,
30,48,46,32,18,33,34,35,23,36,37,
38,50,49,24,25,16,19,31,20,22,47,17,45,21,44);

{0- option}{1- remark}{2- tick}{3- Title}
type
fillpatternarray=^fillpatternarray_;
fillpatternarray_=array[0..0]of array[0..7] of byte;

const
{button modes}
BM_ClickAction=1;
BM_ReleaseAction=2;
BM_PeriodAction=3;
BM_toggleAction=4;

TextcentreY=1;
TextcentreX=2;
Textcentreall=3;
type

Namebox=^Namebox_;
Namebox_=object(tview_)
  align,ylines:byte;
  name:pchar;
  Constructor create(xa,ya,xb,yb:integer;align_:byte;name_:pchar);
  procedure draw;virtual;
end;

const
{internal}
BAdrawonlyborder=2;
BAstatechange=2;
{setable}
BAdown=1;
BAhighlightedborder=2;

type

bigfillarray=^bigfillarray_;
bigfillarray_=array[0..0]of array[0..31] of byte;

Tbutton=^tbutton_;
Tbutton_=object(tview_)
  bkcol,borderstate,action,dstate:byte;
  Docommand:word;
  Hotkeycode:byte;
  constructor create(_x1,_y1,w,h:integer;_bkcol,_borderstate,action_:byte;command_:word;hotkey:byte);
  destructor done;virtual;
  procedure handlevent(var event:tevent);virtual;
  Procedure Draw;virtual;
  procedure SetState(Astate:word;Enable:boolean);virtual;

end;

Textbutton=^Textbutton_;
Textbutton_=object(Tbutton_)
  hotkey:byte;
  name:string[20];
  constructor create(_x1,_y1,w,h:integer;_bkcol,_borderstate,mode_:byte;_hotkey:byte;command_:word;_name:string);
  Procedure Draw;virtual;
end;

Tpicbutton=^Tpicbutton_;
Tpicbutton_=object(Tbutton_)
  Pic:byteptr;
  Procedure Draw;virtual;
  constructor create(_x1,_y1,w,h:integer;_bkcol,_borderstate,mode_:byte;command_:word;hotkey:byte;_pic:byteptr);
end;

Tbitmapbutton=^Tbitmapbutton_;
Tbitmapbutton_=object(Tbutton_)
  inpic,outpic:bitmaptypeptr;
  Procedure Draw;virtual;
  constructor create(_x1,_y1:integer;borderstate_,mode_:byte;command_:word;hotkey:byte;
              inpic_,outpic_:bitmaptypeptr);
end;

Iconpaneltype=^Iconpaneltype_;
Iconpaneltype_=object(Tview_)
  maxx,maxy:byte;
  icons:bigfillarray;
  attrib:bytearray;
  Commands:wordarray;
  xsize,ysize:byte;
  curicon:byte;
  dicon:integer;

  Constructor Create(x,y:integer;maxx_,maxy_,xsize_,ysize_:byte;
                     icons_:bigfillarray;attrib_:bytearray;
                     commands_:wordarray);
  Procedure draw;virtual;
  Procedure seticonstate(icon:byte;on:boolean);
  Procedure seticon(icon:byte);
  Procedure handlevent(var event:tevent);virtual;
  Procedure Drawicon(X,Y:byte);
end;

listtype=^listtype_;
listtype_=object(tview_)
  maxopts,maxylen,oldsel,sel,off:integer;
  drawmode:byte;
  destroyold,changed:boolean;
  info:stringarray;

  Constructor create(x,y,x2_,y2_:integer;info_:stringarray;maxopts_:integer;destroyold_:boolean);
  destructor done;virtual;
  procedure makelist(nopts:integer;list:stringarray);
  Procedure setlist(info_:stringarray;maxopts_:integer);
  procedure killist;
  procedure setval(val_:integer);
  Procedure drawitem(itemno:integer);
  procedure SetState(AState: Word; Enable: Boolean); virtual;
  Procedure draw;virtual;
  Procedure handlevent(var event:tevent);virtual;
End;

Edittexttype=^Edittexttype_;
Edittexttype_=object(tview_)
  {private}
  public
  changed:boolean;
  curspos,curslen:integer;
  off,maxcpos,xlen:byte;
  txt:string;
  constructor create(x,y:integer;txt_:string;maxcpos_,xlen_:byte);
  procedure draw;virtual;
  procedure handlevent(var event:tevent);virtual;
  procedure setstate(Astate:word;Enable:boolean);virtual;
  procedure setcurs(pos:integer;followtail:boolean);
  procedure settext(txt_:string);
  {procedure update;}
end;

const
barminsize=15;
xbardir=true;
ybardir=false;

type
valuetype=^valuetype_;
valuetype_=object(tview_)
  minval,maxval:integer;
  val:^integer;

  constructor make(min,max:integer;val_:pointer);
  procedure setval(val_:integer);
  procedure initvals(min,max,val_:integer);
  procedure setrange(min,max,val_:integer);virtual;
end;

slidertype=^slidertype_;
slidertype_=object(valuetype_)
  s1,s2,offs:integer;
  xorient:boolean;

  Constructor create(x,y,w,h:integer;minval_,maxval_,val_:integer;orient:boolean);
  Procedure draw;virtual;
  procedure handlevent(var event:tevent);virtual;
  procedure changebounds(var bounds:trect);virtual;
  Procedure setrange(min,max,val_:integer);virtual;
  {private}
  procedure getsrect(var srect:trect);
  procedure calcslidepos;
End;

numbox=^numbox_;
numbox_=object(valuetype_)
  constructor create(x1_,y1_,x2_,y2_:integer;min_,max_:integer;val_:pointer);

  procedure setrange(min,max,val_:integer);virtual;
   destructor done;virtual;
  procedure draw;virtual;
end;

numsel=^numsel_;
numsel_=object(tgroup_)
  Constructor create(x1_,y1_,W,H,bwidth,min,max:integer;val:pointer);
  procedure handlevent(var event:tevent);virtual;
end;

bartype=^bartype_;
bartype_=object(tgroup_)
  Constructor create(x,y,w,h:integer;minval_,maxval_,val_:integer;orient:boolean);
  procedure handlevent(var event:tevent);virtual;
end;

bordertype=^bordertype_;
bordertype_=object(tview_)
  size:byte;
  Constructor create(xa,ya,xb,yb:integer;size_:byte);
  Procedure draw;virtual;
end;

Dialogback=^Dialogback_;
Dialogback_=object(tgroup_)
  {Constructor create(xa,ya,xb,yb:integer);}
  Procedure draw;virtual;
end;


type

Delta=^Delta_;
Delta_=object(Tview_)
  xbar,ybar:slidertype;
  xoff,yoff:integer;
  world:trect;
  constructor make(x1b,y1b,x2b,y2b:integer);

  procedure changeworld(var bounds:trect);virtual;
  procedure changebounds(var bounds:trect);virtual;
  procedure setoffsets(xoff_,yoff_:integer);virtual;
  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
end;

Windowtype=^Windowtype_;
Windowtype_=object(tgroup_)
  menu:tpopupmenu;
  oldbounds:pointtype;
  maximized:boolean;
  maximizegadget:tpicbutton;
  deltaview:delta;
  Constructor create(x,y,W,H:integer;tname:string;action_window:delta;menu_:tpopupmenu);
  procedure handlevent(var event:tevent);virtual;
  function changeworld(var bounds:trect):boolean;
  procedure changebounds(var bounds:trect);virtual;
  {procedure SetState(AState: Word; Enable: Boolean); virtual;}
End;

Messagebox=^Messagebox_;
Messagebox_=object(tgroup_)
  OkC:word;
  Constructor create(x,y:integer;Ok:word;txt:pchar);
  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
end;

Choicebox=^choicebox_;
Choicebox_=object(tgroup_)
  CancelC,OkC:word;
  Constructor create(x,y:integer;Cancel,Ok:word;txt:pchar);
  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
end;

TextColourList=^TextColourList_;
TextColourList_=record
  colour:byte;
  maxnames:word;
  text:stringarray;
  next:TextColourList;
end;

TextObject=^TextObject_;
TextObject_=object(delta_)
  deltext:boolean;
  TOoptions:byte;
  Txt,txtstart:pchar;
  maxxlen,maxylen:word;
  {namelist:TextColourList;}

  private
    ystart:integer;
    startcol:byte;
    startattrib:byte;
  public
  Constructor make(txt_:pchar;TOoptions_:byte;deltext_:boolean);
  Destructor done;virtual;
  Procedure handlevent(var event:tevent);virtual;
  Procedure Draw;virtual;
  procedure changebounds(var bounds:trect);virtual;
  procedure getpcharxy(var maxwidth,maxheight:word);
  procedure setoffsets(xoff_,yoff_:integer);virtual;
  procedure settext(txt_:pchar);
end;

tabpage=^tabpage_;
tabgroup=^tabgroup_;
tabgroup_=object(tgroup_)
  lastx:integer;
  tabheight:integer;
  drawpagetab:tabpage;

  Constructor Create(x1_,y1_,x2_,y2_,tabheight_:integer);

  procedure addtabpage(page:tabpage);
  Procedure handlevent(var event:tevent);virtual;
  Procedure Draw;virtual;


end;


tabpage_=object(tgroup_)
  pos:hlinetype;
  name:string[20];
  icon:bitmaptypeptr;

  constructor make(name_:string;icon_:bitmaptypeptr);
  procedure draw;virtual;
end;


procedure add_title(group:tgroup;tname:string);
{const

pic:array[0..3,0..159]of byte=((0,0,0,0,115,0,3,128,0,6,0,6,0,0,71,0,4,0,0,0,0,
13,128,0,114,0,9,144,0,126,0,19,232,0,60,0,19,216,0,6,0,
39,252,0,126,0,5,232,0,6,0,15,252,0,11,0,13,180,0,126,0,
31,254,0,0,0,29,187,0,126,0,63,255,128,26,0,63,253,128,1,0,
127,255,128,22,0,127,254,192,118,0,255,254,192,126,0,253,189,96,91,1,
253,186,224,0,1,255,212,48,9,3,253,170,176,62,3,235,216,24,52,5,
84,42,24,11,2,131,192,12,70,5,83,192,12,139,0,131,192,6,254,32,
0,0,6,1,85,255,255,255,0,255,255,255,255,0,1,127,181,0,255),
(0,2,0,0,6,0,7,192,0,48,0,6,160,0,126,0,12,96,0,70,0,
13,176,0,0,0,25,176,0,3,0,19,248,0,60,0,59,248,0,22,0,
62,124,0,126,0,86,60,0,0,0,60,62,0,0,0,172,62,0,0,0,
126,127,0,114,1,94,126,0,127,0,252,63,0,0,0,188,63,0,11,3,
252,63,192,119,3,124,63,128,9,7,254,126,224,8,6,252,61,192,6,15,
254,122,240,58,13,254,116,96,3,31,252,42,184,70,27,235,216,48,70,61,
84,42,28,10,58,128,0,24,100,117,80,0,14,0,112,128,0,12,86,248,
0,0,7,139,255,255,255,254,242,255,255,255,254,0,126,128,74,254,70),
(255,255,255,255,141,255,255,255,255,215,255,255,255,255,150,255,255,255,255,128,255,
255,255,255,253,255,255,239,255,246,255,255,215,255,176,255,255,231,255,208,255,
254,99,255,128,255,254,115,255,128,255,254,113,255,150,255,254,121,255,154,255,
252,56,255,139,255,252,60,255,248,255,252,60,127,222,255,252,62,127,128,255,
252,62,63,153,255,252,63,63,253,255,252,63,31,134,255,254,127,159,233,255,
254,127,143,242,255,254,127,207,254,255,254,127,199,255,255,254,127,231,128,255,
255,255,227,128,255,254,127,243,255,255,252,63,241,12,255,254,127,249,70,223,
255,255,248,138,170,0,0,0,80,0,0,0,0,22,128,0,0,1,154),
(0,3,128,0,13,0,4,64,0,87,0,1,224,0,87,0,11,224,0,0,0,
2,112,0,74,0,22,112,0,1,0,12,56,0,67,0,44,56,0,62,0,
24,28,0,6,0,120,24,0,109,0,112,12,0,71,0,240,12,0,0,0,
224,6,0,0,1,224,6,0,126,1,192,3,0,114,1,192,3,0,6,3,
128,1,128,71,3,128,1,128,0,7,0,1,192,60,7,0,2,192,83,14,
0,5,96,126,14,0,11,224,121,28,2,85,112,126,28,20,39,240,10,58,
171,213,248,48,61,124,63,248,119,122,172,63,252,254,127,124,63,252,138,255,
255,255,254,228,255,255,255,254,154,255,255,255,254,139,0,0,0,0,182)
);


warningsign:bitmaptype=(size.x:32;ylen:32;planesize:160;bitmaptype:BMplanes;memallocated:false;xoff:5;bitplanes:4;
Planedata:(@pic[0],@pic[1],@pic[2],@pic[3]);bitoffset:0);}


IMPLEMENTATION
function strequals(str1,str2:string):boolean;
var lop:byte;
begin
  for lop:=1 to byte(str1[0]) do
    str1[lop]:=upcase(str1[lop]);
  strequals:=(str1=str2);
end;

{*===================================*}
{*         -*Text Object*-           *}
{*===================================*}

Constructor textobject_.make(txt_:pchar;TOoptions_:byte;deltext_:boolean);
begin
  inherited make(0,0,0,0);
  {namelist:=namelist_;}
  deltext:=deltext_;
  TOoptions:=TOoptions_;
  txt:=txt_;
  txtstart:=txt;
  getpcharxy(maxxlen,maxylen);
  world.rassign(0,0,(maxxlen shl 3)-1,(maxylen*Fontheight)-1);
  ystart:=y1;
  startcol:=textcol;
end;

Destructor textobject_.done;
begin
  if (deltext) and (txt<>nil) then
  {freemem(txt,strlen(txt));}
  inherited done;
end;

procedure textobject_.getpcharxy(var maxwidth,maxheight:word);
var textwidth:word;
    txtlop:pchar;
    txtpos:word;
begin
  textwidth:=0;
  maxwidth:=0;
  maxheight:=2;
  txtlop:=txt;
  txtpos:=0;
  while txtlop^<>chr(0) do begin
    if{((TOoptions and TOwordwrap =0) and }(txtlop^=returnkey) {or
      ((TOoptions and TOwordwrap<>0) and ((textwidth * 8)>(x2-x1)))} then begin
      if textwidth>maxwidth then maxwidth:=textwidth;
      textwidth:=0;
      inc(maxheight);
    end else if txtlop^<>'^' then
      inc(textwidth)
    else
      dec(textwidth);
    inc(txtlop);
    inc(txtpos);
  end;
  if textwidth>maxwidth then maxwidth:=textwidth;
  inc(maxwidth);
  inc(maxheight);
end;

procedure textobject_.settext(txt_:pchar);
var wbounds:trect;
begin
  txt:=txt_;
  getpcharxy(maxxlen,maxylen);
  wbounds.rassign(0,0,(maxxlen shl 3)-1,(maxylen*Fontheight)-1);
  state:=state and not sfvisible;
  changeworld(wbounds);
  state:=state or sfvisible;
  drawview;
end;

procedure textobject_.draw;
var x,y:integer;
    Lx,Wx:integer;
    CurrAttrib,lastcurrwidth,currwidth:byte;
    txtlop:pchar;
    currchar:char;
    oldvp:trect;
    temp:byte;
    currnamelist:TextColourList;
begin

  case TOoptions and TObordermask of
    TOinTextBox:begin
      t_fillcol:=textboxcol;
      bar(x1+2,y1+2,x2-2,y2-2);
      textbox(x1,y1,x2,y2);
    end;
    TOinBox:inbox(x1,y1,x2,y2);
  end;

  oldvp:=SC.viewport;
  SC.viewport:=self;
  SC.viewport.intersect(SC.screenport);
  SC.viewport.rgrow(-2,-2);
  SC.viewport.intersect(oldvp);

  txtlop:=txtstart;
  x:=x1-xoff;
  Wx:=x;
  y:=ystart;

  CurrAttrib:=0;
  t_col:=startcol;

  lastcurrwidth:=0;
  while (y<y2) do begin
    currchar:=txtlop^;
    currwidth:=tcharset.widths[ord(currchar)];
    case currchar of
      '^':begin
        inc(txtlop);
        currchar:=txtlop^;
        case currchar of
          'L':begin
            x:=x1-xoff-currwidth;
            inc(y,fontheight);
            temp:=t_col;
            t_col:=15;
            hline3d(x1+2,x2-2,y+fontheight shr 1);
            t_col:=temp;
          end;
          'U','u':begin
             if boolean(CurrAttrib and ToUnderlined) then begin
               Hline(x+4,lx+4,y+fontheight);
               if currchar='U' then
                 Hline(x+4,lx+4,y+fontheight+2)
             end else
               lx:=x;
             CurrAttrib:=CurrAttrib xor ToUnderlined;
          end;
          'B','b':CurrAttrib:=CurrAttrib xor ToBold;
          'I','i':CurrAttrib:=CurrAttrib xor ToItalic;
          'C','c':begin
            inc(Txtlop);
            t_col:=ord(txtlop^)-ord('A');
          end;
        end;
        dec(x,lastcurrwidth);
      end;
      ' ':;
      chr(10):dec(x,lastcurrwidth);
      returnkey,chr(0):begin
        if (txtlop^=returnkey)and(TOoptions and TOwordwrap=0) then begin
          x:=x1-xoff-currwidth;
          {need to draw line if end of page}
          if Currattrib and ToUnderlined<>0 then begin
            hline(lx+4,x+4,y+fontheight);
            lx:=x;
          end;
          inc(y,Fontheight);
        end;
      end;
      else begin
        drawbytes(x+4,y+4,@Tcharset.typeface[ord(currchar)],fontheight);
        if Currattrib and ToBold<>0 then drawbytes(x+5,y+4,@Tcharset.typeface[ord(currchar)],fontheight);
      end;
    end;
    if txtlop^=chr(0) then exit;
    inc(x,currwidth);
    lastcurrwidth:=currwidth;
    inc(txtlop);
  end;
  SC.viewport:=oldvp;
end;

procedure textobject_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
end;

procedure textobject_.changebounds(var bounds:trect);
begin
  {if not equals(bounds) then begin
    getpcharxy(maxxlen,maxylen);
    world.rassign(0,0,(maxxlen shl 3)-1,(maxylen*Fontheight)-1);
  end;}
  inherited changebounds(bounds);
end;

procedure textobject_.setoffsets(xoff_,yoff_:integer);
begin
  ystart:=y1-yoff_;
  txtstart:=txt;
  startcol:=textcol;
  while ystart<(y1-Fontheight) do begin
    case txtstart^ of
      chr(13):inc(ystart,Fontheight);
      {'^':begin
        inc(txtstart);
        case txtstart^ of
          'C','c':begin
            inc(Txtstart);
            startcol:=ord(txtstart^);
          end;
        end;
        inc(txtstart);
      end;}
    end;
    inc(txtstart);
  end;
  inherited setoffsets(xoff_,yoff_);
end;



function getline(var txt:pchar;maxlinewidth:byte):byte;
var length,lastwordpos:byte;
    lastwordchar:pchar;
begin
  length:=0;
  lastwordpos:=0;
  while (txt^<>#0)and (length<=maxlinewidth) do begin
    if txt^=' ' then begin
      lastwordpos:=length;
      lastwordchar:=txt;
    end;
    inc(length);
    inc(txt)
  end;
  if (txt^=' ') or (txt^=#0) then
    getline:=length
  else begin
    txt:=lastwordchar;
    getline:=lastwordpos;
  end;
end;

{*===================================*}
{*          -*NameBox*-              *}
{*===================================*}

function GetHeight(text:pchar;width:integer):integer;
var ylines:integer;
begin

  ylines:=0;
  while text^<>#0 do begin
    getline(text,(width shr 3)-1);
    inc(ylines,fontheight);
  end;
  GetHeight:=ylines;
end;

Constructor Namebox_.Create(xa,ya,xb,yb:integer;align_:byte;name_:pchar);
begin
  inherited create(xa,ya,xb,yb);
  align:=align_;
  name:=name_;
  ylines:=0;
  while name_^<>#0 do begin
    getline(name_,(width shr 3)-1);
    inc(ylines);
  end;
end;

Procedure Namebox_.draw;
const
offset=3;
var xindent,yindent:integer;
    strlength:byte;
    oldchar,currchar:pchar;

begin
  t_col:=textcol;
  currchar:=name;
  if align and TextCentreY<>0 then
    Yindent:=y1+1+(halfy-((Fontheight*ylines) shr 1))
  else
    Yindent:=y1+offset;
  while currchar^<>#0 do begin
    oldchar:=currchar;
    strlength:=getline(currchar,(width shr 3)-1);
    if align and TextCentreX<>0 then
      Xindent:=x1+1+halfx-(strlength shl 3)shr 1
    else
      Xindent:=x1+offset;
    outtextxy_length(Xindent,Yindent,oldchar,strlength);
    inc(Yindent,fontheight);
  end;
end;

{*===================================*}
{*          -*Tbutton*-              *}
{*===================================*}

constructor Tbutton_.create(_x1,_y1,w,h:integer;_bkcol,_borderstate,action_:byte;command_:word;hotkey:byte);
begin
  inherited create(_x1,_y1,_x1+w,_y1+h);
  options:=options or ofkeygrab+ofautoraise+oftabcycleselect;
  hotkeycode:=hotkey;
  bkcol:=_bkcol;
  docommand:=command_;
  action:=action_;
  borderstate:=_borderstate;
  dstate:=0; {not depressed}
end;

destructor Tbutton_.done;
Begin
end;

Procedure tbutton_.handlevent(var event:tevent);
var Mcount:word;
const
  threshold=2;
begin
inherited handlevent(event);
  with event do
  if what and evmousepressed<>0 then begin
    dstate:=dstate xor BAdown;
    drawview;
    case action of
      BM_toggleaction:begin Evcallback(doCommand);whilemousein;end;
      BM_ClickAction:Evcallback(doCommand);
      BM_ReleaseAction:while (inview(xm,ym))and(not ms_released) do
        mpos;
      BM_PeriodAction:begin
        Evcallback(doCommand);
        mcount:=timer;
        while (inview(xm,ym))and(not ms_released) do begin
          mpos;
          if (timer-mcount)>threshold then
            evcallback(doCommand);
          delay(6);
        end;
      end;
    end;
    if action<>BM_toggleaction then begin
      dstate:=dstate xor BAdown;
      drawview;
    end;
    if (action=BM_ReleaseAction)and(inview(xm,ym))and(ms_released) then
      evcallback(doCommand);
    what:=0;
  end;
  with event do
  if what=EvKeyDown then begin
    if (scancode=hotkeycode)and(scancode<>0)or((state and sfselected<>0)and
    (charcode=#13)) then begin
      if action=BM_toggleaction then begin
        dstate:=dstate xor BAdown;
        drawview;
      end;
      Evcallback(doCommand);
      what:=0;
    end;
  end;
end;

Procedure Tbutton_.draw;
Begin
  if borderstate>0 then begin
    if State and sfselected <> 0 then
      t_col:=red
    else
      t_col:=grey2;
    thickrectangle(x1,y1,x2,y2,borderstate);
  end;
  if dstate and BAdrawonlyborder=0 then begin
  t_fillcol:=bkcol;
  if dstate=0 then
    outboxcol(x1+borderstate,y1+borderstate,x2-borderstate,y2-borderstate)
  else
    inboxcol(x1+borderstate,y1+borderstate,x2-borderstate,y2-borderstate);
  end;
end;

procedure Tbutton_.setstate(Astate:word;Enable:boolean);
begin

  inherited setstate(Astate,Enable);
  if (astate and sfselected)<>0 then begin
    dstate:=dstate or Badrawonlyborder;
    drawview;
    dstate:=dstate xor BAdrawonlyborder;
  end;
end;

{*===================================*}
{*         -*TextButton*-            *}
{*===================================*}

constructor Textbutton_.create(_x1,_y1,w,h:integer;_bkcol,_borderstate,mode_:byte;_hotkey:byte;command_:word;_name:string);
begin
  name:=_name;
  hotkey:=_hotkey;
  inherited create(_x1,_y1,w,h,_bkcol,_borderstate,mode_,command_,
                   scancodes[upcase(name[hotkey])]);
end;

Procedure Textbutton_.draw;
var dofs:byte;
xoffs,yoffs:integer;
begin
  inherited draw;
  if dstate and BAdrawonlyborder=0 then begin
    if dState and Badown<>0 then dofs:=2 else dofs:=0;
    t_col:=(textcol);
    xoffs:=dofs+x1+halfx-((TStrlen(name,@tcharset))shr 1);
    yoffs:=dofs+y1+halfy;
    OuttextxyU(xoffs,yoffs-(Fontsizey shr 1),name,hotkey);
  end;
end;

{*===================================*}
{*         -*Pic Button*-            *}
{*===================================*}

constructor Tpicbutton_.create(_x1,_y1,w,h:integer;_bkcol,_borderstate,mode_:byte;command_:word;hotkey:byte;_pic:byteptr);
begin
  inherited create(_x1,_y1,w,h,_bkcol,_borderstate,mode_,command_,hotkey);
  pic:=_pic;
end;

Procedure Tpicbutton_.draw;
var dofs:byte;
begin
  inherited draw;
  if dstate and BAdrawonlyborder=0 then begin
    if dState and BAdown<>0 then dofs:=3 else dofs:=1;
    t_col:=(grey5);
    drawbytes(dofs+x1+halfx-3,dofs+y1+halfy-3,pointer(pic),8);
    {if dState and BAdown<>0 then t_col:=biege else }t_col:=(grey1);
    drawbytes(dofs+x1+halfx-4,dofs+y1+halfy-4,pointer(pic),8);
  end;
end;

Procedure Tbitmapbutton_.Draw;
begin
  if borderstate>0 then begin
    if State and sfselected <> 0 then
      t_col:=red
    else
      t_col:=grey2;
    thickrectangle(x1,y1,x2,y2,borderstate);
  end;
  if dstate and BAdrawonlyborder=0 then
    if dstate=0 then
      putbitmap(x1,y1,outpic)
    else
      putbitmap(x1,y1,inpic)
end;

constructor Tbitmapbutton_.create(_x1,_y1:integer;borderstate_,mode_:byte;command_:word;hotkey:byte;
            inpic_,outpic_:bitmaptypeptr);
begin
  with outpic_^ do
  inherited create(_x1,_y1,size.x-1,size.y-1,0,borderstate_,mode_,command_,hotkey);
  inpic:=inpic_;
  outpic:=outpic_;
end;

{*===================================*}
{*         -*Icon Panel*-            *}
{*===================================*}

Constructor Iconpaneltype_.Create(x,y:integer;maxx_,maxy_,xsize_,ysize_:byte;
                                  icons_:bigfillarray;attrib_:bytearray;
                                  commands_:wordarray);
Begin
  icons:=icons_;  attrib:=attrib_;
  commands:=commands_;
  maxx:=maxx_;    maxy:=maxy_;
  xsize:=xsize_;  ysize:=ysize_;
  inherited create(x,y,x+(maxx*xsize)-1,y+(maxy*ysize)-1);
  curicon:=0;
  dicon:=-1;
end;

{draws the icon given at the x,y position on the grid in its current state}
Procedure Iconpaneltype_.drawicon(X,Y:byte);
var xoffs,yoffs:integer;
begin
  xoffs:=x*xsize+x1;
  yoffs:=y*ysize+y1;
  if attrib^[x+(y*maxx)]and statemask<>0 then begin
    inbox(xoffs,yoffs,xoffs+xsize-2,yoffs+ysize-2);
    t_col:=grey5;
    drawbytesxy(xoffs+icon_offsetin,yoffs+icon_offsetin,pointer(@icons^[(y*maxx)+x]),2,16);
    t_col:=darkcol;
    hline(xoffs,xoffs+xsize-1,yoffs+ysize-1);
    vline(xoffs+xsize-1,yoffs,yoffs+ysize-1);
  end else begin
    outbox(xoffs,yoffs,xoffs+xsize-1,yoffs+ysize-1);
    t_col:=grey6;drawbytesxy(xoffs+icon_offsetout,yoffs+icon_offsetout,pointer(@icons^[(y*maxx)+x]),2,16);
  end;
end;

Procedure Iconpaneltype_.draw;
var xlop,ylop:byte;
Begin
  if dicon=-1 then begin
  For ylop:=0 to maxy-1 do
    For xlop:=0 to maxx-1 do
      drawicon(xlop,ylop);
  end else begin
    xlop:=dicon mod maxx;
    ylop:=(dicon-xlop) div maxx;
    drawicon(xlop,ylop);
  end;
end;

Procedure Iconpaneltype_.seticonstate(icon:byte;on:boolean);
var
  attr:byte;
begin
  dicon:=icon;

  attr:=attrib^[icon];
  if on then begin
    case attrib^[icon] and not statemask of
      nostick:begin
        attrib^[icon]:=attrib^[icon] or statemask;
        drawview;
        evcallback(commands^[icon]);
        whilemousein;
        attrib^[icon]:=attrib^[icon] xor statemask;
        drawview;
      end;
      onoff:attr:=attr xor statemask;
      oneon:attr:=attr or statemask;
    end;
  end else if (attr and not statemask=oneon)and(icon<>curicon) then
    attr:=attr and not statemask;
  if attr<>attrib^[icon] then begin
    attrib^[icon]:=attr;
    drawview;
    if on then
      evcallback(commands^[icon]);
    if attrib^[icon] and onoff<>0 then whilemousein;
  end;
  dicon:=-1;
end;

{The attrib array is in bytes. The last 4 bits are used to donate the
mode of the icon (onoff -a toggler, oneon -switches off when another mode
is selected and nostick -icon dosent stay depressed}

Procedure Iconpaneltype_.seticon(icon:byte);
var oldicon:byte;
begin
  oldicon:=curicon;
  curicon:=icon;
  seticonstate(curicon,true);
  if attrib^[oldicon] and oneon<>0 then
  seticonstate(oldicon,false);
end;

Procedure Iconpaneltype_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  if event.what and Evmousepressed<>0 then begin
    seticon(((xm-x1-1)div xsize)+((ym-y1-1)div ysize)*maxx);
  end;
end;

{*===================================*}
{*         -*Value Type*-            *}
{*===================================*}

constructor valuetype_.make(min,max:integer;val_:pointer);
begin
  {call the root setrange -No event calling here}
  inherited make;
  val:=val_;
  valuetype_.initvals(min,max,val^);
end;

Procedure valuetype_.setval(val_:integer);
begin
  setrange(minval,maxval,val_);
end;

Procedure valuetype_.initvals(min,max,val_:integer);
var tmp:longint;
begin
  maxval:=max;
  minval:=min;
  if val_>maxval then val_:=maxval else
  if val_<minval then val_:=minval;
  val^:=val_;
end;

{this is overridden by inheiritors objects}
Procedure valuetype_.setrange(min,max,val_:integer);
begin
  initvals(min,max,val_);
end;

{*===================================*}
{*          -*SliderBar*-            *}
{*===================================*}

Constructor bartype_.create(x,y,w,h:integer;minval_,maxval_,val_:integer;orient:boolean);
begin
  inherited create(x,y,x+w,y+h);
  options:=options or ofnooverlap+Ofautoraise+OfKeyGrab;
  if orient=xbardir then begin
    growmode:=TGgrowallX+TGdragy2;
    insert(new(slidertype,create(x1+h+1,y1,w-h-h-2,h,minval_,maxval_,val_,orient)));
    first^.growmode:=growmode;
    insert(new(Tpicbutton,create(x1,y1,h,h,midcol,0,BM_PeriodAction,CMDdecval,leftkey,@leftarrow)));
    first^.growmode:=TGdragx1+TGgrowally;
    insert(new(Tpicbutton,create(x2-h,y1,h,h,midcol,0,BM_PeriodAction,CMDincval,rightkey,@rightarrow)));
    first^.growmode:=TGdragx2+TGgrowally;
  end else begin
    growmode:=TGdragx2+TGgrowally;
    insert(new(slidertype,create(x1,y1+w+1,w,h-w-w-2,minval_,maxval_,val_,orient)));
    first^.growmode:=growmode;
    insert(new(Tpicbutton,create(x1,y1,w,w,midcol,0,BM_PeriodAction,CMDdecval,upkey,@uparrow)));
    first^.growmode:=TGdragy1+TGgrowallx;
    insert(new(Tpicbutton,create(x1,y2-w,w,w,midcol,0,BM_PeriodAction,CMDincval,downkey,@downarrow)));
    first^.growmode:=TGdragy2+TGgrowallx;
  end;
end;

procedure bartype_.handlevent(var event:tevent);
var moveby:byte;
begin
  inherited handlevent(event);
  with slidertype(last)^,event do begin
    if (what and EVcommand <> 0) then begin
      if scan and (leftshiftkey+rightshiftkey)<>0 then
        moveby:=10
      else
        moveby:=1;
      case command of
        CMDincval:setval(val^+moveby);
        CMDdecval:setval(val^-moveby);
        CMDsetval:setval(infoint);
      end;
    end;
    if (what=EvKeyDown) and (scancode<>0) then begin
      what:=0;
      if xorient then
      case scancode of
        rightkeyctrl,endkey:setval(maxval);
        leftkeyctrl:setval(minval);
        {stop key event here..}
        rightkey,leftkey:;
        else what:=EvKeyDown;
      end else
      case scancode of
        PageUpKey:setval(minval);
        PageDownKey:setval(maxval);
        {stop key event here..}
        upkey,downkey:;
        else what:=EvKeyDown;
      end;
    end;
  end;
end;

{*===================================*}
{*         -*SliderType*-            *}
{*===================================*}

Constructor slidertype_.create(x,y,w,h:integer;minval_,maxval_,val_:integer;orient:boolean);
begin
  offs:=val_;
  valuetype_.make(minval_,maxval_,@offs);
  xorient:=orient;
  rassign(x,y,x+w,y+h);
  calcslidepos;
end;

Procedure slidertype_.handlevent(var event:tevent);
var diff,range,offset:integer;
    incby:longint;
    srect:trect;
Begin
  inherited handlevent(event);
  with event do
  if what and EvMousePressed+Evmousemove<>0 then begin
    getsrect(srect);
    if (srect.contains(xm,ym))and(zm>0) then begin
      if xorient then offset:=xm-srect.x1 else offset:=ym-srect.y1;
      if xorient then begin
        setmouserect(x1+offset,ym,x2-(s2-s1-offset),ym);
        diff:=x2-x1;
      end else begin
        setmouserect(xm,y1+offset,xm,y2-(s2-s1-offset));
        diff:=y2-y1;
      end;
      dec(diff,barminsize);
      if diff=0 then diff:=1;
      range:=maxval-minval;

      while not ms_released do begin
        mpos;
        if ms_moved then begin
          if xorient then incby:=xm-x1 else incby:=ym-y1;
          dec(incby,offset);
          if range>=diff then
            incby:=(incby * range) div diff;
          inc(incby,minval);
          setval(incby);
        end;
      end;
      with SC.screenport do setmouserect(x1,y1,x2,y2);
    end;
    what:=0;
  end; {else if what=EvKeyDown then
    owner^.handlevent(Event);}
end;

Procedure slidertype_.setrange(min,max,val_:integer);
var oldvp,tmp:trect;
    oldval:integer;
    changed:boolean;
begin
  oldval:=offs;
  if (max-min)<0 then begin
    min:=0;max:=0;
  end;
  changed:=(min<>minval)or(max<>maxval);
  initvals(min,max,val_);
  if (offs<>oldval)or changed then begin
    if state and sfvisible<>0 then begin
      oldvp:=SC.viewport;
      getsrect(SC.viewport);
      calcslidepos;
      getsrect(tmp);
      SC.viewport.union(tmp);
      SC.viewport.intersect(oldvp);
      drawview;
      SC.viewport:=oldvp;
    end else
      calcslidepos;
    {send out message to parent}
    sendcommand(CMDvalchanged,owner^.owner,@self);
  end;
end;

Procedure slidertype_.draw;
Begin
  T_fillcol:=scrollcol;
  if xorient then begin
    bar(x1,y1+1,x2,y2-1);
    t_col:=lightcol;    hline(x1,x2,y1);
    t_col:=scrollhighlight; hline(x1+1,x2-1,y1+1+halfy);
    T_col:=mid_darkcol; hline(x1,x2,y2-1);
    t_col:=darkcol;     hline(x1,x2,y1+halfy);
                        hline(x1,x2,y2);
    outbox(x1+s1,y1+2,x1+s2,y2-2);
    t_col:=lightcol;
    drawbytes(x1+s1+((s2-s1) shr 1)-2,(y1+(y2-y1) shr 1)-1,@sliderblob,4);
    t_col:=mid_darkcol;
    drawbytes(x1+s1+((s2-s1) shr 1)-3,(y1+(y2-y1) shr 1)-2,@sliderblob,4);
  end else begin
    bar(x1+1,y1,x2-1,y2);
    t_col:=lightcol;    vline(x1,y1,y2);
    t_col:=scrollhighlight;          vline(x1+1+halfx,y1+1,y2-1);
    T_col:=mid_darkcol; vline(x2-1,y1,y2);
    t_col:=darkcol;     vline(x1+halfx,y1,y2);
                        vline(x2,y1,y2);
    outbox(x1+2,y1+s1,x2-2,y1+s2);
    t_col:=lightcol;
    drawbytes((x1+(x2-x1) shr 1)-2,y1+s1+((s2-s1) shr 1)-1,@sliderblob,4);
    t_col:=mid_darkcol;
    drawbytes((x1+(x2-x1) shr 1)-3,y1+s1+((s2-s1) shr 1)-2,@sliderblob,4);
  end;
end;

procedure slidertype_.calcslidepos;
var diff,valdiff:integer;
docalc:longint;
size:integer;
begin
  if xorient then
    diff:=x2-x1
  else
    diff:=y2-y1;
  valdiff:=maxval-minval;
  if valdiff<(diff-barminsize) then
    size:=diff-valdiff
  else
    size:=barminsize;
  if valdiff<>0 then begin
    docalc:=offs-minval;
    s1:=(docalc*(diff-size)) div valdiff;
  end else begin
    s1:=0;
    size:=diff;
  end;
  s2:=s1+size;
end;

procedure slidertype_.changebounds(var bounds:trect);
begin
  inherited changebounds(bounds);
  calcslidepos;
end;

procedure slidertype_.getsrect(var srect:trect);
begin
  if xorient then
    srect.rassign(x1+s1,y1+2,x1+s2,y2-2)
  else
    srect.rassign(x1+2,y1+s1,x2-2,y1+s2);
end;

{*===================================*}
{*        -*Edit text type*-         *}
{*===================================*}
constructor Edittexttype_.create(x,y:integer;txt_:string;maxcpos_,xlen_:byte);
begin
  changed:=false;
  txt:=txt_;
  xlen:=xlen_;
  maxcpos:=maxcpos_;
  curspos:=1;
  curslen:=1;
  off:=1;
  inherited create(x,y,
                   x+((edit_indentX shl 1)+xlen shl 3)-1,
                   y+Fontheight+(edit_indentY shl 1));
  options:=options or OfAutoRaise+OfTabCycleSelect;
end;

procedure Edittexttype_.settext(txt_:string);
begin
  if txt_<>txt then begin
    txt:=txt_;
    if curspos>byte(txt[0]) then curspos:=byte(txt[0]);
    curslen:=curspos;
    drawview;
  end;
end;

procedure Edittexttype_.setcurs(pos:integer;followtail:boolean);
var oldoff:integer;
begin
  if pos<1 then pos:=1;
  if pos>byte(txt[0])+1 then pos:=byte(txt[0])+1;
  if (pos<>curspos) then begin
    oldoff:=off;
    curspos:=pos;
    if curspos>off+xlen then
      off:=curspos-xlen;
    if curspos<=off then
      off:=curspos;
    if followtail then
      Curslen:=Curspos;
    if oldoff<>off then begin
      drawview;
    end else begin
      drawview;
    end;
  end;
end;
{
Procedure edittextype_.update;
const lasttime:word=0;
      onoff:boolean=false;
var
      oldmode:byte;
begin
  if timmer-lasttime>100 then begin
    onoff:=onoff xor true;
    oldmode:=drawmode;
    drawmode:=

  end;
end;}

Procedure Edittexttype_.draw;
var poff,cp1,cp2:integer;
    c1,c2:byte;
    oldvp,usevp:trect;
Begin
  oldvp:=SC.viewport;
  SC.viewport:=self;
  SC.viewport.rgrow(-edit_indentX,-2);
  usevp:=SC.viewport;
  SC.viewport.intersect(oldvp);
  c1:=curspos;
  c2:=curslen;
  poff:=TStrlen(copy(txt,1,off-1),@tcharset);
  if c1>c2 then fswap(c1,c2,1);
  cp1:=TStrLen_at(txt,c1,@tcharset)-poff;
  cp2:=TStrLen_at(txt,c2,@tcharset)-poff;
  with usevp do begin
    t_fillcol:=textboxcol;
    t_col:=textcol;
    bar(x1-poff,y1,x1+cp1,y2);
    bar(x1+cp2,y1,x2,y2);
    if c1<>c2 then begin
      if state and sfselected<>0 then
        t_fillcol:=menuselcolback;
      bar(x1+cp1,y1,x1+cp2,y2);
      outtextxy(x1-poff,y1+edit_textindenty,copy(txt,1,c1-1));
      outtextxy(x1+cp2,y1+edit_textindenty,copy(txt,c2,1+byte(txt[0])-c2));
      t_col:=menuselcolfore;
      outtextxy(x1+cp1,y1+edit_textindenty,copy(txt,c1,c2-c1));
      t_fillcol:=lightcol;
    end else
      outtextxy(x1-TStrLen_at(txt,off,@tcharset),y1+edit_textindenty,txt);
  end;
  SC.viewport:=oldvp;
  bar(x1+2,y1+2,x1+13,y2-2);
  bar(x2-2,y1+2,x2-13,y2-2);
  if state and sfselected<>0 then begin
    t_col:=textcol;
    textcurs(x1+edit_indentX+TStrlen_at(txt,1+curspos-off,@tcharset),y1+3,y2-y1-5);
  end;
  t_col:=menuselcolfore;
  if (byte(txt[0])-off)>xlen then
    drawbytes(x2-10,y1+(halfy-4),pointer(@rightarrow),8);
  if off>1 then
    drawbytes(x1+2,y1+(halfy-4),pointer(@leftarrow),8);
  textbox(x1,y1,x2,y2);
end;

Procedure Edittexttype_.handlevent(var event:tevent);
var followtail:boolean;
    c1,c2:byte;
Begin
  inherited handlevent(event);
  with event do
  if what and EvMousePressed<>0 then begin
    setcurs(off+getindex(txt,xm-edit_indentX-x1,@tcharset),true);
    while not ms_released do begin
      mpos;
      setcurs(off+getindex(txt,xm-edit_indentX-x1,@tcharset),false)
    end;
    what:=0;
  end;
  with event do begin
    if what=EvKeyDown then begin
      what:=0;
      case charcode of
        backspacekey:if curspos>1 then begin
          if curspos=2 then
            txt:=copy(txt,2,byte(txt[0]))
          else if curspos=byte(txt[0])+1 then
            txt:=copy(txt,1,byte(txt[0])-1)
          else
            txt:=copy(txt,1,curspos-2)+copy(txt,curspos,byte(txt[0]));
          setcurs(curspos-1,true);
        end;
        escapekey:;
        returnkey:EvCallBack(CMDEditReturnPressed);
        chr(32)..chr(126):begin
          if scan and insertkey<>0 then
            txt:=copy(txt,0,curspos-1)+charcode+(copy(txt,curspos,byte(txt[0])))
          else if curspos>byte(txt[0]) then
            txt:=txt+charcode
          else
            txt[curspos]:=charcode;
          setcurs(curspos+1,true);
        end;
        else what:=EvKeyDown;
      end;
      followtail:=scan and (LeftShiftKey+RightShiftKey)=0;
      if charcode=chr(0) then begin
        what:=0;
        case scancode of
          homekey,leftkeyctrl:setcurs(1,followtail);
          endkey,rightkeyctrl:setcurs(byte(txt[0])+1,followtail);
          rightkey:setcurs(curspos+1,followtail);
          leftkey:setcurs(curspos-1,followtail);
          delkey:if (curspos<=byte(txt[0]))or(curspos<>curslen) then begin
            c1:=curspos;c2:=curslen;
            if c1>c2 then fswap(c1,c2,1);
            if (c2=curslen)and(curspos<>curslen) then dec(c2);
            txt:=copy(txt,1,c1-1)+copy(txt,c2+1,byte(txt[0]));
            if curspos=c1 then begin
              curslen:=curspos;
              drawview;
            end else
             setcurs(c1,true);
          end;
          else what:=evkeydown;
        end;
      end;
      if what=0 then Evcallback(CMDEditstringaltered);
    end;
  end;
end;

procedure EditTextType_.setstate(Astate:word;Enable:boolean);
begin
  inherited setstate(Astate,Enable);
  if Astate and sfselected <> 0 then
    drawview;
end;

{*===================================*}
{*        -*Number box type*-        *}
{*===================================*}

constructor numbox_.create(x1_,y1_,x2_,y2_:integer;min_,max_:integer;val_:pointer);
begin
  inherited make(min_,max_,val_);
  rassign(x1_,y1_,x2_,y2_);
end;

destructor numbox_.done;
Begin
end;

Procedure numbox_.draw;
var numstr:string;
Begin
  {Outbox(x1,y1,x2,y2)}
  {Outbox(x2-5,y2-5,x1+5,y1+5);}
  textboxfilled(x1,y1,x2,y2);
  t_col:=(textcol);
  numstr:=itoa(val^);
  Outtextxy(x1+halfx-(TStrLen(numstr,@tcharset))shr 1,y1+1+(halfy-(Fontsizey shr 1)),numstr);
end;

procedure numbox_.setrange(min,max,val_:integer);
var oldvp:trect;
    oldval:integer;
begin
  oldval:=val^;
  inherited initvals(min,max,val_);
  if (val^<>oldval) then begin
    drawview;
    sendcommand(CMDvalchanged,owner^.owner,@self);
  end;
end;

{*===================================*}
{*     -*Number select type*-        *}
{*===================================*}

Constructor numsel_.create(x1_,y1_,W,H,bwidth,min,max:integer;val:pointer);
begin
  inherited create(x1_,y1_,x1_+W,y1_+H);
  options:=options or Ofnooverlap+OfKeyGrab+Ofautoraise;
  insert(new(numbox,create(x1+bwidth+1,y1,x2-bwidth-1,y2,min,max,val)));
  first^.growmode:=TGgrowx2+TGgrowally;
  insert(new(tpicbutton,create(x2-bwidth,y1,bwidth,y2-y1,midcol,0,BM_PeriodAction,CMDincval,rightkey,@rightarrowb)));
  first^.growmode:=TGgrowy1+TGdragx1;
  insert(new(tpicbutton,create(x1,y1,bwidth,y2-y1,midcol,0,BM_PeriodAction,CMDdecval,leftkey,@leftarrowb)));
  first^.growmode:=TGgrowy2+TGdragx1;
end;

procedure numsel_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with slidertype(last)^,event do begin
  if event.what=EVcommand then
    case event.command of
      CMDincval:setval(val^+1);
      CMDdecval:setval(val^-1);
    end;
    if (what=EvKeyDown)and(scancode<>0)then begin
      what:=0;
      case scancode of
        PageUpKey:setval(maxval);
        PageDownKey:setval(minval);
        {stop key event here..}
        upkey,downkey:;
        else what:=EvKeyDown;
      end;
    end;
  end;
end;

{*===================================*}
{*          -*List type*-            *}
{*===================================*}
const
listdrawall=1;
listdrawchange=2;
listdrawselected=3;

constructor listtype_.create(x,y,x2_,y2_:integer;info_:stringarray;maxopts_:integer;destroyold_:boolean);
begin
  inherited create(x,y,x+x2_,y+y2_);
  options:=options or ofautoraise+OfTabCycleSelect;
  drawmode:=listdrawall;
  destroyold:={(info_=nil) or }(destroyold_);
  makelist(maxopts_,info_);

  maxylen:=(y2-y1)div Fontheight;
  info^[0]:='';
end;

{set a list to a new list and redraw}
Procedure listtype_.setlist(info_:stringarray;maxopts_:integer);
begin
  state:=state and not sfvisible;
  killist;
  state:=state or sfvisible;
  makelist(maxopts_,info_);
  drawview;
end;

procedure listtype_.makelist(nopts:integer;list:stringarray);
begin
  maxopts:=nopts;
  if list<>nil then
    info:=list
  else
    getmem(info,(1+maxopts)*21);
  changed:=false;
  sel:=1;off:=1;oldsel:=1;
end;

procedure listtype_.killist;
Begin
  if (maxopts>0)and(destroyold) then
    freemem(info,(1+maxopts)*21);
  maxopts:=0;
end;

destructor listtype_.done;
begin
  killist;
  inherited done;
end;

Procedure listtype_.drawitem(itemno:integer);
var yoff:integer;
Begin
  if (itemno>=off)and(itemno<=maxopts)then begin
    yoff:=4+y1+(itemno-off)*Fontheight;
    t_fillcol:=textboxcol;
    if itemno=sel then begin
      if state and sfselected<>0 then
        t_fillcol:=menuselcolback;
      t_col:=menuselcolfore;
    end else begin
      t_col:=textcol;
    end;
    if (itemno=oldsel) or (itemno=sel) then
      bar(x1+4,yoff,x2-4,yoff+Fontmax);
    outtextxy(4+x1,yoff+1,info^[itemno]);
  end;
End;

Procedure listtype_.draw;
var lop:integer;
begin
  case drawmode of
    listdrawall:begin
      t_fillcol:=textboxcol;
      bar(x1+2,y1+2,x2-2,y2-2);
      Textbox(x1,y1,x2,y2);
      maxylen:=(y2-y1)div Fontheight;
      if maxopts=0 then begin
        t_col:=textcol;
        outtextxy(x1+4,y1+4,info^[0])
      end else For lop:=off to off+maxylen do
        drawitem(lop);
    end;
    listdrawchange:begin
      Drawitem(oldsel);Drawitem(sel);
    end;
    listdrawselected:Drawitem(sel);
  end;
  Textbox(x1,y1,x2,y2);
end;

procedure listtype_.setval(val_:integer);
var oldoff:integer;
begin
  if val_<1 then val_:=1;
  if val_>maxopts then val_:=maxopts;
  if (sel<>val_)or(not changed) then begin
    changed:=true;
    maxylen:=(y2-y1)div Fontheight;

    oldoff:=off;
    oldsel:=sel;
    sel:=val_;
    if sel>=off+maxylen then
      off:=1+sel-maxylen;
    if sel<=off then
      off:=sel;
    if oldoff<>off then begin
      drawview;
      evcallback(CMDoffsetchanged);
    end else begin
      drawmode:=listdrawchange;
      drawview;
      drawmode:=listdrawall;
    end;

    evcallback(CMDselectedchanged);
  end;
end;

Procedure listtype_.handlevent(var event:tevent);
Var oldoff,listlop:byte;
Begin
  inherited handlevent(event);
  if maxopts>0 then
  with event do begin
    if what and evmousepressed<>0 then begin
      while zm<>0 do begin
        mpos;
        setval(off+(ym-y1-4) div Fontheight);
      end;
      if (ms_doubleclicked) then begin
        evcallback(CMDitemDclicked);
      end;
      what:=0;
    end;
    if what = EvKeyDown then begin
      case scancode of
        upkey,downkey,pageupkey,pagedownkey:what:=0;
      end;
      case scancode of
        upkey:setval(sel-1);
        downkey:setval(sel+1);
        pageupkey:setval(0);
        pagedownkey:setval(maxopts);
      end;
      case charcode of
        #13:begin
          evcallback(CMDitemDclicked);
          what:=0;
        end;
        'A'..'z':begin
          listlop:=0;
          while ((listlop<=maxopts)and(info^[listlop][1]<>charcode))do
            inc(listlop);
          if (listlop<maxopts+1)then
            setval(listlop);
          what:=0;
        end;
      end;
    end;
    if what = evcommand then
      case event.command of
        CMDvalchanged:begin
          oldoff:=off;
          off:=valuetype(event.infoptr)^.val^;
          if oldoff<>off then
            drawview;
        end;
      end;
  end;
End;

procedure listtype_.SetState(AState: Word; Enable: Boolean);
begin
  inherited setstate(Astate,enable);
  if (Astate and sfselected<>0) then begin
    drawmode:=listdrawselected;
    drawview;
    drawmode:=listdrawall;
  end;
end;

Procedure Sortarray(menu:listtype);
var lop2,lop:byte;
Begin
with menu^ do
For lop:=1 to maxopts do
  For lop2:=lop to maxopts do begin
    if info^[lop2]<info^[lop] then
      fswap(info^[lop],info^[lop2],stringsize);
  end;
end;

{*===================================*}
{*          -*Delta type*-           *}
{*===================================*}
{This View must be owned by a tgroup that changes it's bounds to suit
itself and makes sure that xbar and ybar point to two valuetypes}


Constructor delta_.make(x1b,y1b,x2b,y2b:integer);
begin
  inherited make;
  options:=options or (ofkeygrab+ofautoraise);
  xbar:=nil;ybar:=nil;
  xoff:=0;yoff:=0;
  world.rassign(x1b,y1b,x2b,y2b);
end;

Procedure delta_.draw;
begin
  t_fillcol:=backcol;
  bar(x1,y1,x2,y2);
end;

procedure delta_.setoffsets(xoff_,yoff_:integer);
begin
  if (xoff<>xoff_) or (yoff<>yoff_) then begin
    with xbar^ do state:=state or sfmute;
    with ybar^ do state:=state or sfmute;
    xoff:=xoff_;
    yoff:=yoff_;
    xbar^.setval(xoff);
    ybar^.setval(yoff);
    with xbar^ do state:=state xor sfmute;
    with ybar^ do state:=state xor sfmute;
    drawview;
  end;
end;

procedure delta_.changeworld(var bounds:trect);
var add,sub:integer;
    loader:trect;
    resize:boolean;
begin
  world:=bounds;
  if world.x1=0 then begin
    add:=0;sub:=x2-x1;
  end else begin
    add:=halfx;sub:=add;
  end;
  {disable out events from the bars to prevent 'setoffsets' being
   called too many times}
  with xbar^ do state:=state or sfmute;
  with ybar^ do state:=state or sfmute;
  xbar^.setrange(world.x1+add,world.x2-sub,xbar^.offs);
  if world.y1=0 then begin
    add:=0;sub:=y2-y1;
  end else begin
    add:=halfy;sub:=add;
  end;
  ybar^.setrange(world.y1+add,world.y2-sub,ybar^.offs);
  with xbar^ do state:=state xor sfmute;
  with ybar^ do state:=state xor sfmute;
  {now you call setoffsets}
  setoffsets(xbar^.offs,ybar^.offs);
end;

procedure delta_.changebounds(var bounds:trect);
begin
  inherited changebounds(bounds);
  if (xbar<>nil)and(ybar<>nil)then begin
  with xbar^ do state:=state and not sfvisible;
  with ybar^ do state:=state and not sfvisible;
  state:=state xor sfvisible;
  changeworld(world);
  with xbar^ do state:=state or sfvisible;
  with ybar^ do state:=state or sfvisible;
  state:=state or sfvisible;
  end;
end;

procedure delta_.handlevent(var event:tevent);
var oldx,oldy:integer;
begin
  inherited handlevent(event);
  with event do
  if ((what=EvCommand)and(command=CMDcentrewindow))
  or ((what=EvKeyDown)and(ScanCode=Homekey)) then begin
    what:=0;
    oldx:=xbar^.offs;oldy:=ybar^.offs;
    state:=state and not sfvisible;
    xbar^.setval(0);
    ybar^.setval(0);
    state:=state or sfvisible;
    if (xbar^.offs<>oldx)or(ybar^.offs<>oldy) then
      drawview;
  end;
end;

{*===================================*}
{*         -*Border type*-           *}
{*===================================*}

Constructor bordertype_.create(xa,ya,xb,yb:integer;size_:byte);
begin
  inherited create(xa,ya,xb,yb);
  size:=size_-1;
end;

procedure bordertype_.draw;
begin
  draw3dborder(x1,y1,x2,y2,false);
  t_col:=midcol;
  Thickrectangle(x1+1,y1+1,x2-1,y2-1,size-1);
  draw3dborder(x1+size,y1+size,x2-size,y2-size,true)
end;

{*===================================*}
{*         -*Dialog Back*-           *}
{*===================================*}

procedure Dialogback_.draw;
begin
  outbox(x1,y1,x2,y2);
  inherited draw;
end;

{*===================================*}
{*      -*Add title procedure*-      *}
{*===================================*}

procedure add_title(group:tgroup;tname:string);
var w,h:integer;
begin
  with group^ do begin
    w:=x2-x1;
    h:=y2-y1;
    insert(new(Textbutton,
               create(x1+hbord+1,y1,w-(hbord shl 1)-2,vbord,titlecol,0,BM_clickaction,0,CMDmoveparent,tname)));
    first^.growmode:=TGgrowallx+TGdragy1;
    first^.options:=first^.options and not oftabcycleselect;
    insert(new(Tpicbutton,create(x1,y1,hbord,vbord,midcol,0,BM_clickAction,CMDwindowmenu,200,@closegadget)));
    first^.growmode:=TGdragx1+TGdragy1;
    first^.options:=first^.options and not oftabcycleselect;
    insert(new(Tpicbutton,create(x2-hbord,y1,hbord,vbord,midcol,0,BM_ReleaseAction,CMDzoomwindow,0,@updownarrow)));
    first^.growmode:=TGdragx2+TGdragy1;
    first^.options:=first^.options and not oftabcycleselect;
  end;
end;

{*===================================*}
{*         -*Window type*-           *}
{*===================================*}

Constructor windowtype_.create(x,y,W,H:integer;tname:string;action_window:delta;menu_:tpopupmenu);
const
barsegs=300;
var
loader:trect;
min,max:integer;
begin
  inc(x,xbord);inc(y,xbord);dec(W,xbord);dec(H,xbord);
  inherited create(x,y,x+W,y+H);
  growmode:=0;
  options:=options or (ofnooverlap + oftopselect);
  loader.rassign(x1,y1+vbord+1,x2-scrollbar_size-1,y2-scrollbar_size-1);
  deltaview:=action_window;

  insert(deltaview);
  add_title(@self,tname);
  maximizegadget:=pointer(first);

  insert(new(bartype,create(x2-scrollbar_size,y1+vbord+1,scrollbar_size,
                            H-scrollbar_size-vbord-2,0,0,0,ybardir)));
  action_window^.ybar:=slidertype(tgroup(first)^.last);
  insert(new(bartype,create(x1,y2-scrollbar_size,w-scrollbar_size-1,
                            scrollbar_size,0,0,0,xbardir)));
  action_window^.xbar:=slidertype(tgroup(first)^.last);

  insert(new(tpicbutton,create(x2-scrollbar_size,y2-scrollbar_size,scrollbar_size,scrollbar_size,
                               midcol,0,BM_ClickAction,CMDresizeparent,0,@resizegadget)));
  first^.growmode:=TGdragx2+TGdragy2;
  {reform action window -it is safe to do so now}
  with deltaview^ do begin
    changebounds(loader);
    if ((world.x2-world.x1)<(x2-x1))or
       ((world.y2-world.y1)<(y2-y1)) then with world do begin
         loader.rassign(x+x1,y+y1,x+x2+scrollbar_size+1,y+y2+vbord+scrollbar_size+2);
         self.changebounds(loader);
    end;
  end;

  dec(x1,xbord);dec(y1,xbord);inc(x2,xbord);inc(y2,xbord);
  insert(new(bordertype,create(x1,y1,x2,y2,xbord)));
  menu:=menu_;
  oldbounds.x:=x2-x1;
  oldbounds.y:=y2-y1;
  maximized:=false;
end;

procedure windowtype_.handlevent(var event:tevent);
var loader:trect;
begin
  inherited handlevent(event);
  with event do
  if what=Evcommand then
    case command of
      CMDmoveparent:
        dragview(1,owner^,-32000,-32000,32000,32000);
      CMDresizeparent:with deltaview^ do
        self.dragview(0,SC.screenport,130,170,
        wdeltax+(world.x2-world.x1),wdeltay+(world.y2-world.y1));
      CMDvalchanged:begin
        with deltaview^ do
        if infoptr=xbar then
          setoffsets(xbar^.offs,yoff)
        else
          setoffsets(xoff,ybar^.offs);
      end;
      CMDzoomwindow:begin
        if maximized then begin
          loader.rassign(x1,y1,x1+oldbounds.x,y1+oldbounds.y);
          reposview(loader);
        end else begin
          oldbounds.x:=x2-x1;
          oldbounds.y:=y2-y1;
          with deltaview^ do
            loader.rassign(self.x1,self.y1,self.x1+wdeltax+(world.x2-world.x1),self.y1+wdeltay+(world.y2-world.y1));
          if ((owner^.x2-owner^.x1)<(loader.x2-loader.x1)) then begin
            loader.x1:=owner^.x1;loader.x2:=owner^.x2;
          end;
          if ((owner^.y2-owner^.y1)<(loader.y2-loader.y1)) then begin
            loader.y1:=owner^.y1;loader.y2:=owner^.y2;
          end;
          reposview(loader);
        end;
        maximized:=maximized xor true;
      end;
      CMDwindowmenu:if menu<>nil then begin
        event.what:=evmousepressed;
        menu^.doevent(x1+xbord,y1+vbord+xbord+1,event,menu,@self);
      end;
      else last^.handlevent(event);
    end;
end;

function Windowtype_.changeworld(var bounds:trect):boolean;
var tmprect:trect;
    winwidth,winheight:integer;
const xdiff=(xbord shl 1)+scrollbar_size+1;
      ydiff=(xbord shl 1)+vbord+scrollbar_size+2;
begin
  with bounds do if ((x2-x1)>=(126-xdiff))and((y2-y1)>=(170-ydiff)) then begin
    changeworld:=true;
    with DeltaView^ do begin
      state:=state and not SfVisible;

      ChangeWorld(bounds);
      state:=state or SfVisible;
      if ((bounds.x2-bounds.x1)<(x2-x1)) then
        winwidth:=self.x1+(bounds.width)+xdiff
      else
        winwidth:=x2;
      if ((bounds.height)<(y2-y1)) then
        winheight:=self.y1+(bounds.height)+ydiff
      else
        winheight:=y2;
      if (winheight<>y2)or(winwidth<>x2) then
        with bounds do begin
           tmprect.rassign(self.x1,self.y1,winwidth,winheight);
           owner^.reposview(tmprect);
        end else begin
          Drawview;
        end;
    end;
  end else changeworld:=false;
end;

procedure Windowtype_.changebounds(var bounds:trect);
var diff:pointtype;
begin
  with deltaview^.world do begin
    diff.x:=(x2-x1)+Wdeltax;
    diff.y:=(y2-y1)+Wdeltay;
  end;
  if (bounds.x2-bounds.x1)>diff.x then bounds.x2:=bounds.x1+diff.x;
  if (bounds.y2-bounds.y1)>diff.y then bounds.y2:=bounds.y1+diff.y;
  inherited changebounds(bounds);
end;

{procedure windowtype_.SetState(AState: Word; Enable: Boolean);
var title:tbutton;
begin
  if (astate and sfselected<>0) then begin
    title:=tbutton(last^.prev);
    if Enable then begin
      title^.bkcol:=1;
    end else begin
      title^.bkcol:=titlecol;
    end;
    title^.drawview;
  end;
  inherited SetState(Astate,Enable);
end;}

{*===================================*}
{*          -*Choice Box*-           *}
{*===================================*}
{these are used for making decisions -'cancel' and 'ok' are command events
sent to the owner}
Constructor choicebox_.create(x,y:integer;cancel,ok:word;txt:pchar);
const
W=200;
begin
  inherited create(x,y,x+W,y+GetHeight(txt,w)+90);
  CancelC:=cancel;
  Okc:=Ok;
  options:=options or (ofnooverlap+ofkeygrab+oftopselect+oftabcycleselect);
  insert(new(textbutton,create(x1+30,y2-30,60,20,midcol,1,BM_releaseaction,1,okC,'Ok')));
  first^.growmode:=TGdragx2+TGdragy2;
  insert(new(textbutton,create(x2-90,y2-30,60,20,midcol,1,BM_releaseaction,1,cancelC,'Cancel')));
  first^.growmode:=TGdragx1+TGdragy2;
  insert(new(namebox,create(x1+40,y1+vbord+1,x2-8,y2-30,3,txt)));
  growmode:=TGdragx2+TGdragy2;
  add_title(@self,'System message');
end;

Procedure choicebox_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do case what of
    evcommand:case command of
      CMDmoveparent:dragview(1,owner^,0,0,32000,32000);
      else
      if (command=OkC)or(command=CancelC) then begin
        EvCallback(command);
        delete;
      end;
    end;
    {evkeydown:if charcode=#9 then selected^.next^.select;}
  end;
end;

procedure choicebox_.draw;
begin
  outbox(x1,y1+vbord+1,x2,y2);
  if warningsign<>nil then
  putbitmap(x1+8,vbord+y1+20,warningsign);
  inherited draw;
end;

{*===================================*}
{*         -*Message Box*-           *}
{*===================================*}


{Simple message -'ok' can send an event if you want it to (set it to zero
as always, if you do not}
Constructor messagebox_.create(x,y:integer;ok:word;txt:pchar);
const
W=200;
begin
  inherited create(x,y,x+W,y+GetHeight(txt,w)+90);
  Okc:=Ok;
  options:=options or (ofnooverlap+ofkeygrab+oftopselect);
  insert(new(textbutton,create(x1+halfx-30,y2-30,60,20,midcol,1,BM_releaseaction,1,okC,'Ok')));
  first^.growmode:=TGdragx2+TGdragy2;
  insert(new(namebox,create(x1+40,y1+vbord+1,x2-8,y2-30,3,txt)));
  growmode:=TGdragx2+TGdragy2;
  add_title(@self,'System message');
end;

Procedure messagebox_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do case what of
    evcommand:case command of
      CMDmoveparent:dragview(1,owner^,0,0,32000,32000);
    else if command=OkC then begin
      EvCallback(command);
      delete;
      end;
    end;
    {evkeydown:if charcode=#13 then begin
      EvCallback(Okc);
      delete;
    end;}
  end;
end;

procedure messagebox_.draw;
begin
  outbox(x1,y1+vbord+1,x2,y2);
  if warningsign<>nil then
  putbitmap(x1+8,vbord+y1+20,warningsign);
  inherited draw;
end;

{tabgroup=^_tabgroup;
_tabgroup=object(tgroup_)
  tabheight:integer;
  drawmode:byte;}
Constructor tabgroup_.Create(x1_,y1_,x2_,y2_,tabheight_:integer);
begin
  inherited create(x1_,y1_,x2_,y2_);
  tabheight:=tabheight_;
  lastx:=0;
  drawpagetab:=nil;

end;


procedure drawtab(x1,y1,x2,y2:integer;coffs:byte);
begin
  t_col:=lightcol-coffs;
  drawbytes(x1,y1,@tabtoplefthighlight,8);
  hline(x1+8,x2-8,y1);
  vline(x1,y1+8,y2);
  t_col:=midcol-coffs;
  t_fillcol:=t_col;
  drawbytes(x1,y1,@tabtopleftbody,8);
  drawbytes(x2-8,y1,@tabtoprightbody,8);
  bar(x1+8,y1+1,x2-9,y2);
  bar(x1+1,y1+8,x1+8,y2);
  bar(x2-8,y1+8,x2-3,y2);
  dec(t_col,1+coffs);

  drawbytes(x2-8,y1,@tabtoprightshadow1,8);
  vline(x2-2,y1+8,y2);

  t_col:=mid_darkcol;
  drawbytes(x2-8,y1,@tabtoprightshadow2,8);
end;


procedure tabgroup_.addtabpage(page:tabpage);
var
cpage:tabpage;


begin
  insert(page);
  cpage:=tabpage(first);


  page^.pos.x1:=lastx;

  page^.pos.x2:=lastx+tstrlen(page^.name,@tcharset)+8;
  lastx:=page^.pos.x2+1;

  page^.rassign(x1,y1+tabheight,x2,y2);
end;

Procedure tabgroup_.handlevent(var event:tevent);
var
cpage:tabpage;
begin
  inherited handlevent(event);
  with event do begin
    if what and evmousepressed<>0 then begin
      cpage:=tabpage(first);

      while cpage<>nil do begin
        if insiderect(x1+cpage^.pos.x1,y1,x1+cpage^.pos.x2,y1+tabheight,xm,ym) then
        if cpage<>tabpage(selected) then begin
          drawpagetab:=tabpage(selected);
          cpage^.select;
          selected:=cpage;
          if drawpagetab<>nil then
          drawview;
          drawpagetab:=cpage;
          drawview;
          drawpagetab:=nil;
        end;
        cpage:=tabpage(cpage^.next);
      end;
    end;
  end;
end;

Procedure tabgroup_.Draw;
var cpage:tabpage;
begin
  if drawpagetab<>nil then begin
    cpage:=drawpagetab;
    if cpage=tabpage(selected) then
      drawtab(x1+cpage^.pos.x1,y1,x1+cpage^.pos.x2,y1+tabheight,0)
    else
    drawtab(x1+cpage^.pos.x1,y1,x1+cpage^.pos.x2,y1+tabheight,1);
    t_col:=textcol;
    outtextxy(x1+4+cpage^.pos.x1,y1+2,cpage^.name);
    {drawtab(}
  end else begin
  t_fillcol:=grey2;
  bar(x1,y1,x2,y2);



  cpage:=tabpage(first);
  while(cpage<>nil) do begin
    if cpage=tabpage(selected) then
      drawtab(x1+cpage^.pos.x1,y1,x1+cpage^.pos.x2,y1+tabheight,0)
    else
      drawtab(x1+cpage^.pos.x1,y1,x1+cpage^.pos.x2,y1+tabheight,1);

    t_col:=textcol;
    outtextxy(x1+4+cpage^.pos.x1,y1+2,cpage^.name);
    cpage:=tabpage(cpage^.next);
  end;
  end;

  inherited draw;
end;

constructor tabpage_.make(name_:string;icon_:bitmaptypeptr);
begin
  name:=name_;
  icon_:=icon;
  inherited make;
  options:=options or oftopselect;
end;
procedure tabpage_.draw;
begin
  outbox(x1,y1,x2,y2);
  if (owner^.selected=tview(@self)) then begin
    t_col:=midcol;
    hline(pos.x1,pos.x2,y1);

  end;

  inherited draw;

end;


end.


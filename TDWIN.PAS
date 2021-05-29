Unit Tdwin;

INTERFACE

uses
    ttypes,crt2,tmaths,msmouse,SinCos,
    gbasics,ggraph,vectfont,
    twinb,twindraw,views,gadgets,dialogs,
    Basic3d,tdb,tdeditb;

const
ZOOMKEYS=smLEFTSHIFT or smLEFTCTRL;

{Rotation sensitivity}
sensi=100;
{Grid modes}
GMflat=1;
GMsine=2;
GMheightmap=3;
{ID numbers}
memmessagePID=423;
fontmessagePID=424;
notyetimpPID=12;
selectmessagePID=425;
fileerrorPID=15;

CMDredrawobject3d =328;

{Drawing modes}
CMDeditselect          =6140;
CMDeditsquare          =6141;
CMDeditcube            =6142;
CMDeditDot             =6143;
CMDeditLiner           =6144;
CMDeditcone            =6145;
CMDeditCircle          =6146;
CMDeditCylinder        =6147;
CMDeditSphere          =6148;
CMDeditRotate          =6149;
CMDeditgrid            =6150;
CMDedittext            =6151;
{extended internal drawingmodes}

RANGEextcomSTART       =7152;
RANGEextcomEND         =7310;

{these make changes to the existing database
(deletion or transformation)}

RANGEchangecomSTART    =7152;
RANGEchangecomEND      =7165;

CMDundo                =7152;
CMDtransformselection  =7153;
CMDmovenode            =7154;
CMDselectclear         =7155;
CMDmerge               =7156;
CMDdeleteselect        =7157;
CMDflipx               =7158;
CMDflipy               =7159;
CMDflipz               =7160;
CMDQuadDivide          =7161;
CMDTriangulate         =7162;
CMDSplit               =7163;
CMDnew                 =7164;
CMDdeletelines         =7165;

RANGEchangeselectSTART =7200;
RANGEchangeselectEND   =7201;
CMDselectall           =7200;
CMDnewselection        =7201;

{these add to the existing database, making no changes}
RANGEaddcomSTART       =7250;
RANGEaddcomEND         =7255;

CMDautocopyselected    =7250;
CMDcopyselection       =7251;
CMDaddpolygon          =7252;
CMDrotatedformX        =7253;
CMDrotatedformY        =7254;
CMDrotatedformZ        =7255;

{these change polygon attributes}
RANGEpolychangeSTART   =7300;
RANGEpolychangeEND     =7310;

CMDmkDoublesided       =7300;
CMDmkSinglesided       =7301;
CMDmksmooth            =7302;
CMDmkFlat              =7303;
CMDmkSolid             =7304;
CMDmkOutlined          =7305;
CMDflipnorms           =7306;
CMDApplycolour         =7307;
CMDApplyAttrib         =7308;
CMDapplyAttribandColour=7309;
CMDdeletepolys         =7310;


{load and save commands}
CMDsave3dfile          =400;
CMDload3dfile          =401;
CMDappend3dfile        =402;

{file modes}
CMDfilemode_start=1279;
CMDfilemode_end=1289;

CMD3dfile              =1279;
CMDRWfile              =1280;
CMDPOVfile             =1281;
CMDOBJfile             =1282;
CMDGEOfile             =1283;
CMDVRMLfile            =1284;
CMDPLGfile             =1285;
CMD3dsfile             =1286;
CMDgorfile             =1287;
CMDTrueSpaceFile       =1288;
CMDJavaFile       =1289;


{window commands}
CMDrotate              =202;
CMDreset3dvalues       =200;
CMDsavewin             =201;
CMDsetcoords           =1086;

CMDloadfontdialog      =1059;

CMDselectedittext      =2004;

worldsize=1000;         {extent of scroller bars}

draw_back=32;            {draw back rectangle}
draw_orthnodes=16;       {draw the edit window nodes}
draw_orthlines=8;        {draw the edit window lines}
draw_orth=draw_orthnodes+draw_orthlines;
draw_Perspective=4;      {draw the 3d display window}
draw_3dstuff=draw_orth+Draw_perspective;         {draw the object}
draw_boundingboxstuff=2; {draw the bounding box}
draw_cursorstuff=64;     {draw 3d cursor}
draw_all=255;

what_to_draw:byte=draw_all;
last_twodwindow:byte=4;

{is extruding on or off?}
extrude:boolean=false;
currattrib:byte=PaConnected;


drawallnodes:boolean=true;
drawing_mode:word=CMDeditselect;
conesize:integer=10;
circsize:integer=10;
cylindersize:integer=10;
spheresize:pointtype=(x:10;y:10);
RotSize:integer=10;
DivisionSize:integer=1;                  {global permitations between two extruded surfaces}
GridX:integer=10;
GridY:integer=10;
gridmode:byte=GMflat;
Checkornot:boolean=false;
divsizez:byte=10;
grid_on:boolean=false;
gridlock:boolean=false;
gridsize:pointtype=(x:10;y:10);
SMbegin=160;
SMend=162;
SMresize_repos=160;
SMrotate=161;
SMdeform=162;
SMnodal=163;
SMobjects=164;
Selected_mode:word=SMresize_repos;
selectmodelevel:byte=SMnodal;
stickymouse:boolean=FALSE;


xorRed=red xor backcol;xorgreen=linecolour xor backcol;

type

Creationstruct = record
  v1,v2:vectorreal;
  angle:real;
  segments:word
end;

CoordArray=array[0..29] of vectorreal;

Tcube=^Tcube_;
Tcube_=record
  a,b:vectorreal;
end;

delta_orth=^delta_orth_;
delta_orth_=object(delta_)
  orientation:byte;
  transmat:matrix3x4type_;
  editobject:edit_objtype;

  constructor make(orient:byte;obj:edit_objtype);
  procedure draw;virtual;
  Procedure LocalSpace(var x,y:integer);
  Procedure GlobalSpace(var x,y:integer);
  {procedure draw_precalc;virtual;}
  procedure draw_boundingbox(xp,yp:integer);
  procedure handlevent(var event:tevent);virtual;
  procedure docommand(command:word;params:pointer;divsize:integer);

  Procedure do2d_3d(xp,yp:integer;filter:VectorReal;var dot:VectorReal);
  Procedure do3d_2d(dot:VectorReal;var x,y:integer);
end;

delta_3d=^delta_3d_;
delta_3d_=object(delta_)
  {obspos,obsrot:vectorint;
  drawmode:byte;}
  CurrentRotation:vectorreal;
  editobject:edit_objtype;
  boundcube:edit_objtype;
  cursor:edit_objtype;
  constructor make(obj:edit_objtype);
  destructor done;virtual;
  procedure draw;virtual;
  Procedure handlevent(var event:tevent); virtual;
  procedure setoffsets(xoff_,yoff_:integer);virtual;
  {procedure draw_precalc;virtual;}
end;

var
gridpic:bitmaptypeptr;
{****-----Desktop Needs to be set to send messages to---****}
desktop:desktoptype;

{check to see if font is loaded, value altered by main prog}
vfontin:boolean;
autocopymatrix:matrix3x4type_;
step:integer;
Vfont:font_type;
EditString:string;
Edviews:array[0..3]of delta;

procedure Drawobject;
procedure Draworth;
procedure setscale(scaleval:real);

IMPLEMENTATION

procedure Drawobject;
var lop:byte;
begin
  for lop:=0 to 3 do
    edviews[lop]^.drawview;
end;

procedure Draworth;
var lop:byte;
begin
  for lop:=0 to 2 do
    edviews[lop]^.drawview;
end;

{---------------------****Windowing stuff****-----------------------}

constructor delta_3d_.make(obj:edit_objtype);
const
cs=7;
begin
  inherited make(-worldsize,-worldsize,worldsize,worldsize);
  editobject:=obj;
  xoff:=0;yoff:=0;
  currentrotation.moveto(0,0,0);
  fgtexture:=xorred;
  new(boundcube,create(8,12,6));
  boundcube^.mkcube(0,0,0,1,1,1,PaOutLined+PaConnected);
  new(cursor,create(6,3,0));
  with cursor^ do begin
    addvector(-cs,0,0); addvector(cs,0,0);
    addvector(0,-cs,0); addvector(0,cs,0);
    addvector(0,0,-cs); addvector(0,0,cs);
    
    addjoin(0,1);
    addjoin(2,3);
    addjoin(4,5);
  end;
  {drawmode:=CMDlines;}
  fgtexture:=5;
end;

destructor delta_3d_.done;
begin
  dispose(boundcube,done);
  dispose(cursor,done);
  inherited done;
end;

Procedure delta_3d_.draw;
const
  bs=3;
  base:byte=0;
var
  lop:byte;
begin

  with editobject^ do begin
    if what_to_draw and Draw_perspective<>0 then
    if maxpoints>0 then begin
      if state and sfdrawnonce=0 then begin
        do3d(x1+halfx,y1+halfy);
        {sound(200);delay(50);nosound;}
        waitvbl;
      end;
    end;
    if what_to_draw and draw_back<>0 then begin
      t_fillcol:=backcol;
      bar(x1,y1,x2,y2);
    end;
    if what_to_draw and draw_perspective<>0 then if maxpoints>0 then begin
      T_col:=linecolour;
      case render_mode of
        CMDlines:if maxjoins>0 then liner;
        CMDdots:dotter;
        CMDhlines..CMDgouraud:if maxpolys>0 then filler(render_mode);
      End;

    end;
    if what_to_draw and draw_boundingboxstuff<>0 then
      If (maxselect>0)and(maxpoints>0) then with editobject^ do Begin
        t_writemode:=(xorput);t_col:=(xorRed);
        if state and sfdrawnonce=0 then begin

          boundcube^.thred^[0].moveto(min.x-bs,min.y-bs,min.z-bs);
          boundcube^.thred^[base+1].moveto(max.x+bs,min.y-bs,min.z-bs);
          boundcube^.thred^[base+2].moveto(max.x+bs,max.y+bs,min.z-bs);
          boundcube^.thred^[base+3].moveto(min.x-bs,max.y+bs,min.z-bs);

          boundcube^.thred^[base+4].moveto(min.x-bs,min.y-bs,max.z+bs);
          boundcube^.thred^[base+5].moveto(max.x+bs,min.y-bs,max.z+bs);
          boundcube^.thred^[base+6].moveto(max.x+bs,max.y+bs,max.z+bs);
          boundcube^.thred^[base+7].moveto(min.x-bs,max.y+bs,max.z+bs);

          boundcube^.do3d(x1+halfx,y1+halfy);
        end;
        boundcube^.liner;
        t_writemode:=(0);
      End;
  End;
  if (what_to_draw and draw_cursorstuff<>0)
   then with cursor^ do begin
    t_writemode:=(xorput);t_col:=(xorRed);
    if state and sfdrawnonce=0 then begin
      for lop:=0 to 5 do
        thred^[lop].add(crs.x,crs.y,crs.z);
      do3d(x1+halfx,y1+halfy);
      for lop:=0 to 5 do
        thred^[lop].sub(crs.x,crs.y,crs.z);
    end;
    liner;
    t_writemode:=(0);
  end;
  t_col:=15;
  outtextxy(x1+2,y1+2,'Rotation:'+ftoa(currentrotation.x,1,1)+','+
  ftoa(currentrotation.z,1,1)+','+ftoa(currentrotation.z,1,1));


End;

procedure delta_3d_.setoffsets(xoff_,yoff_:integer);
begin
  obspos.x:=xoff_;
  obspos.y:=yoff_;
  inherited setoffsets(xoff_,yoff_);
end;

procedure delta_3d_.handlevent(var event:tevent);


var px,py:integer;
    dontdraw:boolean;
begin
  inherited handlevent(event);
  dontdraw:=true;
  with event,editobject^ do begin
    if what and EvMousePressed<>0 then begin
      SC.viewport.intersect(self);
      SC.viewport.intersect(SC.screenport);
      SC.viewport.intersect(owner^.owner^);
      px:=xm;py:=ym;
      mouseoff;
      While zm<>0 do begin
        Case zm of
        2:obmat.p.z:=obmat.p.z+(py-ym);
        1:begin
            obmat.p.x:=obmat.p.x+xm-px;
            obmat.p.y:=obmat.p.y+ym-py;
          End;
        3:with CurrentRotation do begin
            x:=x+((py shr 1)-(ym shr 1))/sensi;
            y:=y+((px shr 1)-(xm shr 1))/sensi;
            LmRotTrans(@obmat,x,y,z,obmat.p.x,obmat.p.y,obmat.p.z);
          End;
        End;{of case}
        boundcube^.obmat:=obmat;
        cursor^.obmat:=obmat;
        if (px<>xm) or(py<>ym) then
          draw;
        mpos;
        if (px<>xm) or(py<>ym) then setmousepos(px,py);
      End;{of while}
      mouseon;
      SC.viewport:=SC.screenport;
    end;
    if what=EvKeyDown then with editobject^ do begin
      dontdraw:=false;
      case charcode of
        #9:Begin
          LmUnit(@obmat);
          BoundCube^.obmat:=obmat;
          Cursor^.obmat:=obmat;
          CurrentRotation.moveto(0,0,0);
        end;
        '1':Render_mode:=CMDdots;
        '2':Render_mode:=CMDlines;
        '3':Render_mode:=CMDHlines;
        '4':Render_mode:=CMDLsource;
        '5':Render_mode:=CMDGouraud;
        '6':Render_mode:=CMDCpolygons;
        ',','.','a','z','x','c','s','S':with CurrentRotation do begin
          case charcode of
            ',':y:=y+step;
            '.':y:=y-step;
            'a':x:=x+step;
            'z':x:=x-step;
            'x':z:=z+step;
            'c':z:=z-step;
          end;
          LmRotTrans(@obmat,x,y,z,obmat.p.x,obmat.p.y,obmat.p.z);
          BoundCube^.obmat:=obmat;
          Cursor^.obmat:=obmat;
        end;
        's':inc(step,1);
        'S':dec(step,1);
        else dontdraw:=true;
      end;

    end;
    if what=EvCommand then begin
      dontdraw:=false;
      case command of
        CMDrotate:begin
          with VectorRealPtr(infoptr)^ do
            CurrentRotation.add(x,y,z);
          with CurrentRotation do
            LmRotTrans(@obmat,x,y,z,obmat.p.x,obmat.p.y,obmat.p.z);
          BoundCube^.obmat:=obmat;
          Cursor^.obmat:=obmat;
        end;
        CMDredrawobject3d:drawview;
        CMDdots..CMDgouraud:render_mode:=command;
        CMDreset3dvalues:begin
          LmUnit(@obmat);
          BoundCube^.obmat:=obmat;
          Cursor^.obmat:=obmat;
          CurrentRotation.moveto(0,0,0);
        end;
        else dontdraw:=true;
      end;
    end;
    if not dontdraw then drawview;
  end;
end;

Procedure drawcircle(x,y:integer;w,h:integer;stp:integer;start_angle:real);
Var lop:integer;
    Ccos,Csin,oldsin,oldcos:integer;
    cindex,cadd:real;
begin

  cindex:=0;
  cadd:=(2*pi) / stp;
  For lop:=0 to stp do begin
    oldsin:=Csin;
    oldcos:=Ccos;
    Csin:=x+round(sin(start_angle+cindex)*w);
    Ccos:=y+round(cos(start_angle+cindex)*h);
    if lop>0 then
      line(Csin,Ccos,oldsin,oldcos);
    cindex:=cindex+cadd;
  End;
End;

function CheckClicked(altmethod:boolean;zm:byte):boolean;
begin
  altmethod:=altmethod and stickymouse;
  checkclicked:=((zm=1) and not(altmethod))or((altmethod) and (zm=0));
end;


Function resizebounds(var x1,y1,x2,y2:integer;numcopies:word):shortint;
const
innerborder=border-halfgadget;
Var a:shortint;xa,ya,xb,yb,offx,offy:integer;
oldvp:trect;
r:trect;
altmethod:boolean;
oldxm,oldym:integer;

Begin
  oldxm:=gridxm;
  oldym:=gridym;
  r.rassign(x1,y1,x2,y2);
  a:=0;
  xa:=x1-maxborder;ya:=y1-maxborder;xb:=x2+innerborder;yb:=y2+innerborder;
  offx:=((x2-x1) shr 1)-halfgadget;
  offy:=((y2-y1) shr 1)-halfgadget;

  if chkicon(xb,yb,gadgetsize,gadgetsize)>0 then a:=bellow_right else
  if chkicon(xa,yb,gadgetsize,gadgetsize)>0 then a:=bellow_left else
  if chkicon(xa,ya,gadgetsize,gadgetsize)>0 then a:=above_left else
  if chkicon(xb,ya,gadgetsize,gadgetsize)>0 then a:=above_right else

  if chkicon(offx  + x1,yb, gadgetsize,gadgetsize)>0 then a:=bellow else {_}
  if chkicon(xb,offy + y1, gadgetsize,gadgetsize)>0 then a:=right  else {>}
  if chkicon(offx  + x1,ya, gadgetsize,gadgetsize)>0 then a:=above else {~}
  if chkicon(xa,offy + y1, gadgetsize,gadgetsize)>0 then a:=left  else {<}
  if chkicon(x1-border,y1-border,(border shl 1)+(x2-x1),(border shl 1)+
  (y2-y1))>0 then a:=middle;{move}

  if a<>0 then begin
    oldvp:=SC.viewport;
    SC.viewport:=SC.screenport;
    what_to_draw:=draw_boundingboxstuff;
    drawobject;
    what_to_draw:=draw_all;
    SC.viewport:=oldvp;
    t_writemode:=(xorput);t_col:=(xorRed);
    altmethod:=false;

    While checkclicked(altmethod,zm) do Begin
      mpos;
      mouseoff;Drawboundmulti(r.x1,r.y1,r.x2,r.y2,x1,y1,x2,y2,numcopies,true);mouseon;
      while (not ms_gridmoved) and (zm=byte(altmethod)xor 1) do mbutton;

      Mouseoff;Drawboundmulti(r.x1,r.y1,r.x2,r.y2,x1,y1,x2,y2,numcopies,true);mouseon;
      ms_xdiff:=gridxm-oldgridxm;
      ms_ydiff:=gridym-oldgridym;

      if (zm=0)and(oldxm=gridxm)and(oldym=gridym) then altmethod:=stickymouse;

      if a and left <> 0  then begin
        inc(x1,ms_xdiff);
        if scan and smLEFTSHIFT<>0 then dec(x2,ms_xdiff);
      end;
      if a and above <> 0 then begin
        inc(y1,ms_ydiff);
        if scan and smLEFTSHIFT<>0 then dec(y2,ms_ydiff);
      end;
      if a and right <> 0 then begin
        inc(x2,ms_xdiff);
        if scan and smLEFTSHIFT<>0 then dec(x1,ms_xdiff);
      end;
      if a and bellow <> 0 then begin
        inc(y2,ms_ydiff);
        if scan and smLEFTSHIFT<>0 then dec(y1,ms_ydiff);
      end;

    End;
    {if (oldx=xm)and(oldy=ym) then a:=-1;}
  End;
  resizebounds:=a;
  {inc(x1,border);inc(y1,border);dec(x2,border);dec(y2,border);}
End;{of function}

function rotatesquare(x1,y1,x2,y2,cx,cy:integer;var angle:real;numcopies:word):shortint;
var oldx:integer;
    oldvp:trect;
    oldangle:real;
begin

  oldx:=xm;
  if chkicon(x1-border,y1-border,(border shl 1)+x2-x1,(border shl 1)+y2-y1)>0 then begin
    oldvp:=SC.viewport;
    oldangle:=0;
    SC.viewport:=SC.screenport;
    what_to_draw:=draw_boundingboxstuff;
    drawobject;
    what_to_draw:=draw_all;
    SC.viewport:=oldvp;
    t_writemode:=(xorput);t_col:=(xorRed);
    rotatesquare:=1;
    angle:=0;

    while zm=1 do begin
      mpos;
      angle:=((xm-oldx)/ sensi);
      mouseoff;rectangle_rotatedmulti(x1,y1,x2,y2,cx,cy,angle,oldangle,numcopies,true);mouseon;
      while not (ms_moved)and(zm=1) do mpos;
      mouseoff;rectangle_rotatedmulti(x1,y1,x2,y2,cx,cy,angle,oldangle,numcopies,true);mouseon;
    end;

  end else rotatesquare:=-1;
end;


Procedure getsquare(R:prect;win:delta_orth);
var currcol:byte;
    altmethod:boolean;
Begin
  currcol:=t_col;
  with R^ do begin
  x1:=Gridxm;y1:=Gridym;

  altmethod:=false;
  while checkclicked(altmethod,zm) do Begin
    mpos;
    t_writemode:=0;
    if scan and smLEFTSHIFT <>0 then setmousepos(gridxm,y1+(gridxm-x1));
    win^.sendCommand(CMDsetcoords,root,win);
    t_writemode:=(xorput);
    t_col:=currcol;
    mouseoff;rectangle(x1,y1,oldgridxm,oldgridym);mouseon;
    while (not ms_gridmoved ) and (zm=byte(altmethod)xor 1)  do
      mbutton;
    mouseoff;rectangle(x1,y1,oldgridxm,oldgridym);mouseon;

    if (zm=0)and(gridxm=x1)and(gridym=y1) then altmethod:=stickymouse;

  End;
  x2:=Gridxm;y2:=Gridym;
  {make sure that  0 size squares are not possible}
  if x2=x1 then inc(x2,1);
  if y2=y1 then inc(y2,1);
  if x1>x2 then fswap(x1,x2,2);if y1>y2 then fswap(y1,y2,2);
  end;
  t_writemode:=(0);
End;

{this routine is crap (hehe) and always behaves like 'sticky mouse'}
function getline(points:pointtypearray;maxpoints:word;win:delta_orth):integer;
var currcol:byte;
    linecount:byte;
    x1,y1:integer;
    altmethod,endsame:boolean;
    firstrect:trect;
Begin
  currcol:=t_col;
  x1:=Gridxm;y1:=Gridym;
  linecount:=0;
  points^[0].x:=x1;
  points^[0].y:=y1;
  firstrect.rassign(x1-3,y1-3,x1+3,y1+3);
  altmethod:=false;
  endsame:=false;
  mpos;
  while (not ms_doubleclicked)and(linecount<maxpoints)and(not endsame)and(not keypressed) do begin
    while ((zm=1) and not(altmethod))or((altmethod) and (zm=0))and(not keypressed) do Begin
      mpos;
      t_writemode:=0;
      if scan and smLEFTSHIFT<>0 then setmousepos(xm,y1+(Gridxm-x1));
      win^.sendCommand(CMDsetcoords,root,win);
      t_writemode:=(xorput);
      t_col:=currcol;
      mouseoff;line(x1,y1,oldgridxm,oldgridym);mouseon;
      while (not ms_gridmoved) and (zm=byte(altmethod)xor 1) do
        mpos;
      mouseoff;line(x1,y1,oldgridxm,oldgridym);mouseon;
      if (zm=0)and(Gridxm=x1)and(Gridym=y1) then altmethod:=true;
    end;
    endsame:=firstrect.contains(gridxm,gridym);
    if not endsame then begin
      inc(linecount);
      points^[linecount].x:=Gridxm;
      points^[linecount].y:=Gridym;
      if not (ms_doubleclicked)and(not keypressed) then begin
        mouseoff;
          t_writemode:=0;
          t_col:=t_col xor backcol;
          line(x1,y1,Gridxm,Gridym);
          t_writemode:=xorput;
          t_col:=t_col xor backcol;
        mouseon;
        x1:=Gridxm;
        y1:=Gridym;
      end;
      stoprepeat;
      altmethod:=true;
    end;
  end;
  t_writemode:=(0);
  getline:=linecount+1+(byte(endsame) shl 8);
End;

Procedure getcircle(R:prect;stp:integer;var angle:real;win:delta_orth);

var

    currcol:byte;
    altmethod:boolean;
    ydiff,xdiff:real;


Begin
  currcol:=t_col;
  angle:=0;
  t_writemode:=(xorput);
  with R^ do begin
  x1:=gridxm;y1:=gridym;
  x2:=1;y2:=1;
  altmethod:=false;
  while checkclicked(altmethod,zm) do Begin
    mpos;
    t_writemode:=0;


    win^.sendCommand(CMDsetcoords,root,win);
    t_writemode:=(xorput);
    t_col:=currcol;

    if scan and smLEFTCTRL<>0 then
      angle:=angle+(ms_xdiff / sensi)
    else if scan and smLEFTSHIFT <>0 then begin
      inc(x2,ms_xdiff);
      inc(y2,ms_xdiff);
    end else begin
      inc(x2,ms_xdiff);
      inc(y2,ms_ydiff);
    end;
    mouseoff;drawcircle(x1,y1,x2,y2,stp,angle);mouseon;

    while (not ms_gridmoved) and (zm=byte(altmethod)xor 1)  do
      mbutton;
    mouseoff;drawcircle(x1,y1,x2,y2,stp,angle);mouseon;

    if (zm=0)and(gridxm=x1)and(gridym=y1) then altmethod:=stickymouse;

  End;
  x1:=abs(x1);
  x2:=abs(x2);
  {make sure that  0 size squares are not possible}
  if gridxm=x1 then inc(x2,2);
  if gridym=y1 then inc(y2,2);
  end;
  t_writemode:=(0);
End;

constructor delta_orth_.make(orient:byte;obj:edit_objtype);
begin
  inherited make(-worldsize,-worldsize,worldsize,worldsize);
  case orient of
    {spin around -90ø's in the Yaxis to get into position}
    Xaxis:LmAxisRotate(@transmat,0,1,0,pi/2);
    {YRotate(@transmat,pi/2);}
    {spin around 90ø's in the Xaxis to get into position}
    Yaxis:LmXrotate(@transmat,-pi/2);
    Zaxis:LmUnit(@transmat);
  end;
  editobject:=obj;
  orientation:=orient;
  xoff:=0;yoff:=0;
end;

procedure delta_orth_.localspace(var x,y:integer);
begin
  dec(x,x1+halfx-xoff);
  dec(y,y1+halfy-yoff);
end;

procedure delta_orth_.Globalspace(var x,y:integer);
begin
  inc(x,x1+halfx-xoff);
  inc(y,y1+halfy-yoff);
end;

Procedure delta_orth_.do2d_3d(xp,yp:integer;filter:VectorReal;var dot:VectorReal);begin
  localspace(xp,yp);
  conv2d_3d(orientation,xp,yp,@filter,@dot);
end;

Procedure delta_orth_.do3d_2d(dot:VectorReal;var x,y:integer);begin
  conv3d_2d(orientation,@dot,x,y);
  globalspace(x,y);
end;

procedure delta_orth_.draw_boundingbox(xp,yp:integer);
var minx,miny,maxx,maxy:integer;
Begin
  with editobject^ do begin
    conv3d_2d(orientation,@min,minx,miny);
    conv3d_2d(orientation,@max,maxx,maxy);
  end;
  case selected_mode of
    SMresize_repos:drawbound(xp+minx,yp+miny,xp+maxx,yp+maxy);
    SMrotate:rectangle_rotated(xp+minx,yp+miny,xp+maxx,yp+maxy,xp,yp,0);
    SMdeform:begin end;
  end;
end;

{Procedure delta_orth_.draw_precalc;
begin
  with editobject^ do begin
    if maxpoints>0 then
      load_orthview(orientation,x1+halfx+xoff,y1+halfy+yoff,scale);
  end;
end;}

Procedure delta_orth_.draw;
var lop:integer;xp,yp:integer;
    gx,gy:integer;
begin
  xp:=x1+halfx-xoff;yp:=y1+halfy-yoff;
  with editobject^ do begin
    if what_to_draw and draw_back<>0 then begin
      t_fillcol:=backcol;
      bar(x1,y1,x2,y2);
      if (grid_on)and(scale>0.4) then begin
        t_col:=15;{(gridcol);}
        {hline(x1,x2,y1+halfy);}
        gx:=round(gridsize.x*scale);
        if (gx=0) then gx:=1;
        gy:=round(gridsize.y*scale);
        if (gy=0) then gy:=1;
        dotgrid(x1+((halfx-xoff) mod gx),
                y1+((halfy-yoff) mod gy),
                gx,gy,1+(x2-x1) div gx,1+(y2-y1)div gy);
      End;
      t_col:=(red);
      Drawx(xp,yp);
    end;

    if (maxpoints>0) and (what_to_draw and draw_orth <>0 )then begin
      if state and sfdrawnonce=0 then
        doorth(orientation,xp,yp,scale);
      if (what_to_draw and draw_orthlines<>0) then begin
        t_col:=linecolour;
        liner;
      end;
      if (what_to_draw and draw_orthnodes<>0) then begin
        noder(drawallnodes);
      end;
    end;
    if what_to_draw and draw_boundingboxstuff<>0 then
      If (maxselect>0)and(maxpoints>0) then Begin
        t_writemode:=(xorput);t_col:=(xorRed);
        draw_boundingbox(xp,yp);
        t_writemode:=(0);
      End;

    if what_to_draw and draw_cursorstuff<>0 then begin
      t_writemode:=(xorput);t_col:=(xorRed);
      conv3d_2d(orientation,@crs,gx,gy);
      drawcursor(xp+gx,yp+gy);
      t_writemode:=(0);
    end;
  End;
end;

procedure setscale(scaleval:real);
begin
  if scaleval<>0 then
     scale:=scaleval;
  draworth;
end;

var
    angle:real;

Procedure delta_orth_.docommand(command:word;params:pointer;divsize:integer);
const
  LastMatrixOp:matrix3x4type_=(m00:1;m01:0;m02:0;
                               m10:0;m11:1;m12:0;
                               m20:0;m21:0;m22:1;
                               p:(x:0;y:0;z:0));
var lop:word;
    tmpobj:edit_objtype;
    Snormal:VectorReal;
    selectmode:byte;

begin
  with editobject^ do begin
    if command<>CMDundo then begin
      oldmaxpoints:=maxpoints;
      oldmaxjoins:=maxjoins;
      oldmaxpolys:=maxpolys;
    end;
    setmouseshape(1,1,hourglass);
    {execute the command}
    case command of
      RANGEchangeselectSTART..RANGEchangeselectEND,CMDautocopyselected:
      if (drawallnodes)and(maxselect>0) then begin
        what_to_draw:=draw_boundingboxstuff;
        drawobject;
        what_to_draw:=draw_all;
      end;
    end;
    case Command of
      CMDcopyselection,CMDautocopyselected:if maxselect>0 then begin
        lop:=0;
        while (lop<maxpolys) and (not polys^[lop].allselected(@thred)) do
          inc(lop);
        dec(lop);
        if lop<maxpolys then
          with polys^[lop] do begin
            CalcSurfNormal(thred^[p[1]],thred^[p[0]],thred^[p[2]],Snormal);
            Snormal.multiply(divsize*5);
          with Snormal do
            LmTrans(@autocopymatrix,x,-y,z);
          end
        else
          LmTrans(@autocopymatrix,5,5,5);
        autocopymatrix.Multiply(@LastMatrixOp,mtpostconcat);

        for lop:=1 to divsize do begin
          if (lop=divsize)or not(extrude) then
            copyobj(CMall,extrude,true)
          else
            copyobj(CMjoins,extrude,true);
          multmatrix(matrix3x4type(params))
        end;
      end else
        ErrorLevel:=ERRnotselected;
      CMDtransformselection:begin
        multmatrix(matrix3x4type(params));
        lastmatrixop:=matrix3x4type(params)^;
        lastmatrixop.invert;
      end;
      CMDmovenode:with Tcube(params)^ do begin
        thred^[divsize].moveto(a.x,a.y,a.z);
        getmaxmin;
      end;
      CMDQuadDivide:QuadDivideSelected;
      CMDTriangulate:TriangulateSelected;
      CMDSplit:SplitPolygons;
      CMDload3dfile,CMDappend3dfile:begin
        if command=CMDload3dfile then
           maxselect:=0;
        case divsize of
          CMDrwfile:readRW(stringptr(params)^);
          CMDgeofile:readGEO(stringptr(params)^);
          CMD3dfile:read3d(stringptr(params)^,command=CMDappend3dfile);
          CMDobjfile:readOBJ(stringptr(params)^);
          CMDgorfile:readgor(stringptr(params)^,command=CMDappend3dfile);
        end;
      end;
      CMDsave3dfile:begin
        case divsize of
          CMDgorfile:writegor(stringptr(params)^);
          CMD3dfile:write3d(stringptr(params)^);
          CMDRWfile:writeRW(stringptr(params)^);
          CMDPOVfile:writePOV(stringptr(params)^);
          CMDOBJfile:writeOBJ(stringptr(params)^);
          CMDPLGfile:writePLG(stringptr(params)^);
          CMD3dsfile:write3DSasc(stringptr(params)^);
          CMDGEOfile:writeGEO(stringptr(params)^);
          CMDVRMLfile:writeVRML(stringptr(params)^);
          CMDJAVAfile:writeJAVA(stringptr(params)^);
          CMDTrueSpaceFile:writeCOBasc(stringptr(params)^);
        end;
      end
      else begin
        CTM:=@transMat;
        with Tcube(params)^ do case Command of
          CMDedittext : if editstring='' then
            addmessage(0,CMDselectedittext,
            'You must enter a text string in the grey box at the top of the screen.',fontmessagePID,desktop)
          else
            mktext(a.x,a.y,a.z,EditString,vfont);
          CMDeditLiner:if lo(divsize)>1 then begin
            if boolean(hi(divsize))then
              addpolygon(maxpoints,lo(divsize),PaDoubleSided+PAconnected,PCall)
            else
              addpolygon(maxpoints,lo(divsize),PaDoubleSided+PaOutlined,PCall);
            for lop:=0 to lo(divsize)-1 do with vectorrealarray(params)^[lop] do
              addvector(x,y,z);
          end;
          CMDeditsquare:mksquare(a.x,a.y,b.x,b.y,a.z,Currattrib or (PaDoubleSided+PaClockWise));
          CMDeditcube:mkcube(a.x,a.y,a.z,b.x,b.y,b.z,currattrib);
          CMDeditDot:addvector(a.x,a.y,a.z);
          CMDeditCircle:mkcircle(a.x,a.y,b.x,b.y,a.z,divsize,angle,PCall,Currattrib or (PaDoubleSided+PaClockWise));
          CMDeditcone:mkcone(a.x,a.y,b.x,b.y,a.z,b.z,divsize,angle,currattrib);
          CMDeditCylinder:mkcylinder(a.x,a.y,b.x,b.y,b.x,b.y,a.z,b.z,divsize,angle,currattrib);
          CMDeditSphere:mksphere(a.x,a.y,a.z,b.x,b.y,b.z,divsize,divsizez,angle,CurrAttrib);
          CMDeditgrid:
            case gridmode of
              GMheightmap:if gridpic<>nil then
                mkgridfrompic(a.x,a.y,b.x,b.y,a.z,gridpic,checkornot,currattrib or PaDoubleSided);
              {else
                gridmode:=GMflat;}
              GMflat:mkgrid(a.x,a.y,b.x,b.y,a.z,GridX,GridY,false,checkornot,currattrib or PaDoubleSided);
              GMsine:mkgrid(a.x,a.y,b.x,b.y,a.z,GridX,GridY,true,checkornot,currattrib or PaDoubleSided);
            end;

          CMDeditrotate:begin
            tmpobj:=new(edit_objtype,create(30,30,30));
            tmpobj^.mkcircle(a.x,a.y,b.x,b.y,a.z,divsize,angle,PCall,0);
            extrudepath(tmpobj,CurrAttrib,Extrude);
            dispose(tmpobj,done);
          end;
          CMDRotatedformX:rotateobj(Xaxis,rotsize,CurrAttrib);
          CMDRotatedformY:rotateobj(Yaxis,rotsize,CurrAttrib);
          CMDRotatedformZ:rotateobj(Zaxis,rotsize,CurrAttrib);
          CMDselectclear:if maxselect>0 then begin
            what_to_draw:=draw_boundingboxstuff;
            drawobject;
            clearselection;

          end else
            ErrorLevel:=ERRnotselected;
          CMDnew:begin
            reset3d;
            crs.moveto(0,0,0);
            setscale(1);
          end;
          CMDmerge:merge;
          CMDflipx:flip(Xaxis);
          CMDflipy:flip(Yaxis);
          CMDflipz:flip(Zaxis);
          CMDselectall:selectall;
          CMDnewselection:begin
            if selectmodelevel=SMnodal then begin


              if scan and smLEFTCTRL<>0 then
                selectmode:=SMintersect
              else if scan and smLEFTALT<>0 then
                selectmode:=SMaddtolist
              else
                selectmode:=SMnewlist;


              getselectlist(orientation,prect(params)^,selectmode)
            end
            else
              getselectlistconnected(orientation,prect(params)^);
          end;

          CMDdeleteselect:delete_select(DMall);
          CMDdeletepolys:delete_select(DMpolys);
          CMDdeletelines:delete_select(DMjoins);

          CMDaddpolygon:addpolygonbyref(select,maxselect,currattrib or PaDoubleSided+PaClockWise,
                        PCall or PCchecklines or PCcheckpolys);
          CMDflipnorms:FlipSelectedNormals;

          CMDmkDoublesided:SetSelectedattrib(PaDoublesided,PAmodeTRUE);
          CMDmkSinglesided:SetSelectedattrib(PaDoublesided,PAmodeFALSE);
          CMDmkSmooth:SetSelectedattrib(PaSmooth,PAmodeTRUE);
          CMDmkFlat:SetSelectedattrib(PaSmooth,PAmodeFALSE);
          CMDmkOutlined:SetSelectedattrib(PaOutlined,PAmodeTRUE);
          CMDmkSolid:SetSelectedattrib(PaOutlined,PAmodeFALSE);
          CMDapplyColour:SetSelectedTexture(fgtexture);
          CMDapplyattrib:SetSelectedattrib(CurrAttrib,PAmodeABS);
          CMDapplyattribandcolour:begin
            SetSelectedTexture(fgtexture);
            SetSelectedattrib(CurrAttrib,PAmodeABS);
          end;
          CMDundo:begin
            maxselect:=0;
            fswap(maxpoints,oldmaxpoints,2);
            fswap(maxjoins,oldmaxjoins,2);
            fswap(maxpolys,oldmaxpolys,2);
          end;
        end;
      end;
    end; {end of command list}
    {if there was an error then do this}
    case ErrorLevel of
      {if no errors were detected, draw the changes}
      ERRnone:begin
        {how to draw the changes}
        case command of
          {redraw whole object}
          RANGEchangeselectSTART..RANGEchangeselectEND:begin
            if (drawallnodes) then
              what_to_draw:=draw_boundingboxstuff;
            drawobject;
            LmUnit(@LastMatrixOp);

          end;
          RANGEchangecomSTART..RANGEchangecomEND,CMDload3dfile:drawobject;
          {only redraw the 3d window and even then under conditions}
          RANGEpolychangeSTART..RANGEpolychangeEND:
            if render_mode>=CMDhlines then edviews[3]^.drawview;
          else if (oldmaxpoints<>maxpoints)or(oldmaxjoins<>maxjoins)or(oldmaxpolys<>maxpolys) then begin
            {draw each view, remove and replace 'xor' stuff}
            if ((command=CMDautocopyselected)or(command=CMDcopyselection))and(not drawallnodes) then
              drawobject
            else begin
              if (command<>CMDaddpolygon)and((command<>CMDcopyselection)and not(extrude)) then
                draw_points_offset:=oldmaxpoints;
              draw_lines_offset:=oldmaxjoins;
              draw_polys_offset:=oldmaxpolys;

              for lop:=0 to 3 do begin
                if (Command<>CMDcopyselection)and(Command<>CMDautocopyselected) then
                  what_to_draw:=draw_cursorstuff+draw_boundingboxstuff
                else
                  what_to_draw:=draw_cursorstuff;

                edviews[lop]^.drawview;
                what_to_draw:=draw_3dstuff;
                edviews[lop]^.drawview;
                what_to_draw:=draw_cursorstuff+draw_boundingboxstuff;
                edviews[lop]^.drawview;
              end;
            end;
          end;
        end;
      end;
      ERRnovectors..ERRnopolys:begin
        {out of memory undo}
        maxpoints:=oldmaxpoints;
        maxjoins:=oldmaxjoins;
        maxpolys:=oldmaxpolys;
        addmessage(0,0,'Sorry, object too large: out of memory.',memmessagePID,desktop);
      end;
      ERRnotselected:begin
        addmessage(0,0,'Select some points using the select tool (the arrow).',selectmessagePID,desktop);

      end;
      ERRoneselected:begin
        addmessage(0,0,'You must select two or more points.',selectmessagePID,desktop);
      end;
      ERRparseerror:begin
        addmessage(0,0,'Parse Error in 3d file.',selectmessagePID,desktop);
      end;
      ERRfileerror:begin AddMessage(0,0,'The file format is not understood.',fileerrorPID,desktop);
      end;
    end;
    ErrorLevel:=Errnone;
    {CMDDeleteJoins,CMDdeleteSelect,CMDmerge,CMDquaddivide,CMDtriangulate:begin
      oldmaxpoints:=maxpoints;
      oldmaxjoins:=maxjoins;
      oldmaxpolys:=maxpolys;
    end;}

    draw_points_offset:=0;
    draw_lines_offset:=0;
    draw_polys_offset:=0;
    what_to_draw:=draw_all;
    setmouseshape(1,1,arrow);
    CTM:=@unitmatrix;
  end;
end;


var
oldx,oldy:integer;

Procedure Delta_orth_.handlevent(var event:tevent);
var pointslist:array[0..29] of pointtype;
    points:trect absolute pointslist;
    oldvp:trect;
    oldcrs:VectorReal;
    boundcode:shortint;
    newmin,newmax:VectorReal;
    CoordsList:CoordArray;
    CoordsCube:Tcube_ absolute CoordsList;
    tmpz:real;
    temp:word;
    ccirc:integer;
    lop:byte;
    Transmatrix:matrix3x4type_;
    olddrawing_mode:word;
    dot:integer;
    px,py:integer;

    g:pointtype;

{***************************************************************}
{loads up values that will later be used in transformations & does
selection code (calls the correct redraws in that section)}
procedure handle_repos;
var x,y,maxotherdot:integer;rotation:real;
    lop:integer;
    otherdot:array[0..30] of word;
    tmpmatb:matrix3x4type_;
    oldbounds:trect;

    {when moving a single node}
    procedure drawotherdots(x,y:integer);
    var lop:integer;
        xb,yb:integer;
    begin
      mouseoff;
      {if editobject^.thred^[dot].Nattrib and NAselected<>0 then
        t_col:=nodeselectedcolour xor backcol
      else}
        t_col:=nodecolour xor backcol;

      drawbytes(x-3,y-2,@nodepatt,5);
      t_col:=(xorGreen);
      if maxotherdot>0 then
      For lop:=0 to maxotherdot-1 do Begin
        do3d_2d(editobject^.thred^[otherdot[lop]],xb,yb);
        line(x,y,xb,yb);
      end;
      mouseon;
    end;

begin
  with editobject^,points do begin
    x1:=xm;y1:=ym;
    localSpace(x1,y1);
    dot:=getnode(orientation,x1,y1,not drawallnodes);

    {if you are moving a node then do this....}
    if dot>-1 then begin
      maxotherdot:=0;
      lop:=0;
      if maxjoins>0 then
        while (lop<maxjoins)and(maxotherdot<30) do with jointo^[lop] do begin
          if (f=dot) then begin
            otherdot[maxotherdot]:=t;
            inc(maxotherdot);
          end;
          if (t=dot) then begin
            otherdot[maxotherdot]:=f;
            inc(maxotherdot);
          end;
          inc(lop);
        end;
      t_writemode:=xorput;
      do3d_2d(thred^[dot],x,y);
      drawotherdots(x,y);
      if (xgrid_size<=1)or(ygrid_size<=1) then begin
        dec(x,gridxm);dec(y,gridym);
      end else begin
        x:=0;y:=0; {grid is on, don't use the offsets}
      end;

      while zm<>0 do begin
        mpos;
        drawotherdots(oldgridxm+x,oldgridym+y);
        while (not (ms_gridmoved))and(zm<>0) do mpos;
        drawotherdots(oldgridxm+x,oldgridym+y);
      end;
      {load up 'points.x1' and 'points.x2' with new xy position}
      x1:=gridxm+x;
      y1:=gridym+y;

      t_writemode:=0;
      drawing_mode:=CMDmovenode;
    end else begin
      {do selected group stuff}
      do3d_2d(min,x1,y1);
      do3d_2d(max,x2,y2);

      {do you resize/move or rotate? load up 'transmat in this block'}
      if (scan and smLEFTCTRL=0)and(scan and smLEFTALT=0) then
      case selected_mode of
        SMresize_repos:begin
          oldbounds:=points;
          if maxselect>0 then
            boundcode:=resizebounds(x1,y1,x2,y2,divisionsize)
          else
            boundcode:=0;
          if (boundcode>0) then begin
            do2d_3d(x1,y1,min,newmin);
            do2d_3d(x2,y2,max,newmax);
            {if just moving, not resizin or rotaing}
            if boundcode=middle then with min do begin
              newmin.sub(x,y,z);
              with newmin do LmTrans(@transmatrix,x,y,z);
            end else
              {else here, load matrix to stretch}
              LmStretch(@transmatrix,min,max,newmin,newmax);
            if zm=3 then begin
              LmUnit(@tmpmatb);
              transmatrix.sub(@tmpmatb);
              transmatrix.divide(divisionsize);
              transmatrix.add(@tmpmatb);
            end;
          end;
        end;
        SMrotate:begin
          {rotateSquare will return 0 if there is no rotation}
          if maxselect>0 then begin
            do3d_2d(crs,g.x,g.y);

            boundcode:=rotatesquare(x1,y1,x2,y2,g.x,g.y,
            rotation,divisionsize);
          end else boundcode:=0;
          if (boundcode>0) then begin
            if zm=3 then
              rotation:=rotation / divisionsize;
            case orientation of
              Xaxis:LmRotateAround(@transmatrix,rotation,0,0,crs);
              Yaxis:LmRotateAround(@transmatrix,0,rotation,0,crs);
              Zaxis:LmRotateAround(@transmatrix,0,0,-rotation,crs);
            end;
          end;
        end;
        SMdeform:begin
          LmUnit(@TransMatrix);
        end;
      end;
      {'transmatix' now loaded with relevant information}
      {user select with mouse}
      {if no moving of single node or click in bounding box then...}
      if (boundcode<=0)or(scan and smLEFTCTRL<>0)or(scan and smLEFTALT<>0) then begin
        t_col:=backcol xor red;T_writemode:=xorput;
        getsquare(@points,@self);
        t_writemode:=0;
        if zm<>3 then begin
          SC.viewport:=oldvp;
          localSpace(points.x1,points.y1);
          localSpace(points.x2,points.y2);
          docommand(CMDnewselection,@points,0);
        end;
        stoprepeat;
      end else begin
        {set up move mode}
        if zm=3 then
          drawing_mode:=CMDcopyselection
        else
          drawing_mode:=CMDtransformselection;
        t_writemode:=0;
      end;
    end;
  end;
end;

{***************************************************************}

var mousepoint:vectorreal;
newscale:real;

begin
  inherited handlevent(event);
  edit_orientation:=orientation;
  olddrawing_mode:=drawing_mode;
  with event do begin
  if what and EvMousepressed<>0 then begin
    if what and Evmousemove<>0 then
      sendCommand(CMDsetcoords,root,@self);
    {this defines the direction in which polygon points are defined}
    if gridlock then Begin
      Xgrid_size:=round(gridsize.x*scale);Ygrid_size:=round(gridsize.y*scale);
      if (ygrid_size=0) then ygrid_size:=1;
      if (xgrid_size=0) then xgrid_size:=1;
      Xgrid_corner:=x1+((xoff+halfx) mod Xgrid_size);
      Ygrid_corner:=y1+((yoff+halfy) mod Ygrid_size);
      mpos;
    End;
    with points do case zm of
      1,3:begin
        {clip to SC.viewport}
        oldvp:=SC.viewport;
        SC.viewport.intersect(self);
        SC.viewport.intersect(owner^.owner^);
        t_col:={fgcol xor backcol}xorgreen;
        {get 2d input from user}
        case drawing_mode of
          CMDeditsquare,CMDeditcube,CMDeditgrid,CMDedittext:begin
            getsquare(@points,@self);
            localspace(x1,y1);
            localspace(x2,y2);
          end;
          CMDeditselect:with editobject^ do begin
            {selection/copying is a special case.}
            {all these handles are the same for drawn objects}
            handle_repos;
          end;
          CMDeditliner:begin
            ccirc:=getline(@pointslist,29,@self);
            for lop:=0 to lo(ccirc)-1 do with pointslist[lop] do
              localspace(x,y);
          end;
          CMDeditdot:begin
            x1:=xm;y1:=ym;
            localspace(x1,y1);
          end;
          CMDeditcone,CMDeditcircle,CMDeditcylinder,CMDeditsphere,CMDeditrotate:begin
            case drawing_mode of
              CMDeditcone:ccirc:=conesize;
              CMDeditcircle:ccirc:=circsize;
              CMDeditcylinder:ccirc:=cylindersize;
              CMDeditsphere:begin ccirc:=spheresize.x;divsizez:=spheresize.y;end;
              CMDeditrotate:ccirc:=rotsize;
            end;
            getcircle(@points,ccirc,angle,@self);


            localspace(x1,y1);
          end;
        end;
        {un clip}
        SC.viewport:=oldvp;
        if (drawing_mode<>CMDeditselect) then
        if ((zm<>3) or (drawing_mode=CMDcopyselection)) then begin
          with CoordsCube do begin
            {covert to 3d object space {scaling, cursor positioning}
            case orientation of
              Xaxis:tmpz:=-crs.x;
              Yaxis:tmpz:=-crs.y;
              Zaxis:tmpz:=crs.z;
            end;
            if drawing_mode=CMDeditliner then begin
              for lop:=0 to lo(ccirc)-1 do with pointslist[lop] do
                coordslist[lop].moveto(x/scale,y/scale,tmpz);
            end else begin
              a.moveto(x1/scale,y1/scale,tmpz);
              b.moveto(x2/scale,y2/scale,tmpz);
              {setup parameters for 'docommand'}
              case drawing_mode of
                CMDmovenode:begin
                  ccirc:=dot;
                  do2d_3d(points.x1,points.y1,editobject^.thred^[dot],a);
                end;
                {set z position for corners}
                CMDeditcube:begin
                  tmpz:=((a.x-b.x)+(a.y-b.y))/4;
                  a.z:=a.z-tmpz;
                  b.z:=b.z+tmpz;
                end;
                {set radius of sphere}
                CMDeditsphere:b.z:=(b.x+b.y)/2;
                {set z start and end positions}
                CMDeditcone,CMDeditcylinder:begin
                  tmpz:=(b.x+b.y)/2;
                  a.z:=a.z-tmpz;
                  b.z:=b.z+tmpz;
                end;
              end;
            end;
          end;{with coords cube}
          {--All changes to the 3d database occur in this section--}

          {case statement for different paramaters}
          case drawing_mode of
            CMDcopyselection,CMDtransformselection:docommand(drawing_mode,@transmatrix,divisionsize);
            else begin
              docommand(drawing_mode,@CoordsCube,ccirc);
            end;
          end;
        end;{if zm<>3}
        stoprepeat;
      end;
      2:if (oldx<>xm)or(oldy<>ym) then begin
          oldx:=xm;
          oldy:=ym;
          what_to_draw:=draw_cursorstuff;
          drawobject;
          with points do begin
            x1:=gridxm;y1:=gridym;
            do2d_3d(x1,y1,crs,crs);
          end;
          drawobject;
        end;
      end;
    end else
    if what and Evmousemove<>0 then begin
      px:=xm;py:=ym;

      if (scan and ZOOMKEYS<>0) and (scan and ZOOMKEYS<>smLEFTCTRL)then begin
        mouseoff;
        while scan and ZOOMKEYS<>0 do begin
          mpos;
          if (px<>xm) or(py<>ym) then begin
            if scan and ZOOMKEYS=ZOOMKEYS then
            begin
              newscale:=(ms_ydiff*scale)/100;
              state:=state and not sfvisible;

              setoffsets(xoff,yoff);
              state:=state or sfvisible;
              setscale(scale+newscale);
            end
            else if scan and ZOOMKEYS=smLEFTSHIFT then
              setoffsets(xoff-ms_xdiff,yoff-ms_ydiff);
            if (px<>xm) or(py<>ym) then setmousepos(px,py);
          end;
        end;
        mouseon;
      end;
    end;
    what_to_draw:=draw_all;
    if gridlock then Begin
      Xgrid_size:=0;Ygrid_size:=0;
    End;
    drawing_mode:=olddrawing_mode;

  end;
end;




end.

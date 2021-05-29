{All files in this project are copyright 2000 (c) Tim Lewis}
{Please feel free to use this code as you see fit but please do not release}
{a new version of clayworks without my consent.}
{If you decide to host the source code on your server, please include all of}
{the files, as they are.}

program CLAYCP;
uses
  ttypes,crt2,dos,tmaths,msmouse,SinCos,chardef,diskop,strings,
  gbasics,ggraph,vectfont,colour,stdpal,
  Basic3d,tdb,tdeditb,
  twinb,twindraw,views,gadgets,dialogs,tdwin,tmenust,pcx256;

const
VersionStr='2.45';

{With debug 'writes'
fixedusage=150928;}
fixedusage=150848;
minmem=200000;

defaultfont='simp.chr';

CMDxrot                =1000;
CMDyrot                =1001;
CMDzrot                =1002;

CMDexitbox             =1004;
CMDnewbox              =1005;
CMDloaddialog          =1007;

CMDsaveasdialog        =1008;
CMDappend              =1009;
CMDprint               =1010;
CMDexit                =1011;

CMDrefresh             =1012;
CMDinfo                =1013;
CMDredrawobject        =1014;
CMDgetobjectinfo       =1015;

CMDdeleteselectdialog  =1018;

CMDTogglegridFROMICON  =1051;
CMDsetwinbig           =1052;
{CMDTilewindows         =1025;
CMDCascade             =1026;}
CMDcallwindowmenu      =1053;
CMDtogglegrid          =1054;
CMDsetdefaultpal       =1055;

CMDrotateopts          =1056;
CMDzoomin              =1057;
CMDzoomout             =1058;
CMDselectCircChanger   =1061;

{file ops}
CMDloadfont            =1064;
CMDCancel              =1065;
CMDsave3dfileornot     =1066;
CMDapplytextstring     =1067;

CMDToggleExtrude       =1073;
CMDToggleConnect       =1074;
CMDtoggleSine          =1075;
CMDcallhelp            =1076;
CMDtogglecheck         =1077;

CMDtogglenodes         =1078;
CMDtoggleDoubleSided   =1087;
CMDtoggleSmooth        =1088;
CMDtoggleAbsolute      =1089;
CMDtoggleOutline       =1090;
CMDToggleNodesFROMICON =1094;
CMDcallsurfacedialog   =1095;
CMDsavepal             =2000;
CMDsavepaldialog       =2001;
CMDtoggleflat          =2002;
CMDtoggleheightmap     =2003;
CMDloadheightmapdialog =2004;
CMDloadheightmap       =2005;
CMDstickymouse         =2006;

type

Lgroup=^Lgroup_;
Lgroup_=object(tgroup_)
  name:string[20];
  xoffset:integer;
  Constructor create(name_:string);
  procedure draw;virtual;
end;

Coordbox=^Coordbox_;
Coordbox_=object(tview_)
  coord:vectorreal;
  procedure draw;virtual;
end;

Clay=^Clay_;
Clay_=object(tgroup_)
  Coords:Coordbox;
  ModeOptions:Tgroup;
  ModeOptionsPtrs:array[0..11]of Lgroup;
  iconpanel,subpanel:iconpaneltype;


  Constructor create(xa,ya,xb,yb:integer);
  Procedure handlevent(var event:tevent);virtual;
  procedure Draw;virtual;
end;

RotationControl=^RotationControl_;
RotationControl_=object(tgroup_)
  constructor create(xa,ya:integer);
  procedure handlevent(var event:tevent);virtual;
end;

TextEditdialog=^TextEditdialog_;
TextEditdialog_=object(Lgroup_)
  TextEditBox:edittexttype;
  constructor create;
  procedure handlevent(var event:tevent);virtual;
end;

SelectOptions=^SelectOptions_;
SelectOptions_=object(Lgroup_)
  seliconpanel,selmodeiconpanel:iconpaneltype;
  constructor create;
  procedure handlevent(var event:tevent);virtual;
  procedure draw;virtual;
end;

CircOptions=^CircOptions_;
CircOptions_=object(Lgroup_)
  Constructor create(name_:string;data:pointer);
  Procedure Handlevent(var event:tevent);virtual;
  Procedure draw;virtual;
end;

SphereOptions=^SphereOptions_;
SphereOptions_=object(Lgroup_)
  Constructor create(size:pointtypeptr);
  Procedure Handlevent(var event:tevent);virtual;
  Procedure draw;virtual;
end;

RotateOptions=^RotateOptions_;
RotateOptions_=object(lgroup_)
  Constructor create(name_:string;data:pointer);
  Procedure Handlevent(var event:tevent);virtual;
  Procedure draw;virtual;
end;

GridOptions=^GridOptions_;
GridOptions_=object(Lgroup_)
  Xval,Yval:Valuetype;
  Constructor create;
  Procedure Handlevent(var event:tevent);virtual;
  Procedure draw;virtual;
end;

CopyRightBox=^CopyRightBox_;
CopyRightBox_=object(Tview_)
  Constructor create;
  Procedure HandlEvent(var event:tevent);virtual;
  Procedure Draw;virtual;
end;

SurfaceDialog=^SurfaceDialog_;
SurfaceDialog_=object(tgroup_)
  colourgridptr:colourgridtype;
  Constructor create(xa,ya:integer);
  Procedure HandlEvent(var event:tevent);virtual;
  Procedure Draw;virtual;
end;


{****----Predeclared Global Variables----****}
var
flipmenu,FileTypeMenu,PolyFunctions,PolyAttribFunctions,
miscmenu,filemenu,editmenu,selectmenu,textmenu,
Windowmenu,stdwinmenu,winmenu3d,rendermenu:Tpopupmenu_;

Const
backpattern:fillpatterntype=(226,193,163,119,46,28,58,119);

Flipinfo:array[0..2] of tmenuitem_=(
(name:'üýX';attrib:moptbutton;keycode:0;command:CMDflipx;submenu:nil),
(name:'üýY';attrib:moptbutton;keycode:0;command:CMDflipY;submenu:nil),
(name:'üýZ';attrib:moptbutton;keycode:0;command:CMDflipZ;submenu:nil));

FileTypeinfo:array[0..9] of tmenuitem_=(
(name:'3d'; attrib:moptbutton+Moptcentre;keycode:0;command:CMD3dfile;submenu:nil),
(name:'POV'; attrib:moptbutton+Moptcentre;keycode:0;command:CMDPOVfile;submenu:nil),
(name:'RWX'; attrib:moptbutton+Moptcentre;keycode:0;command:CMDRWfile;submenu:nil),
(name:'OBJ'; attrib:moptbutton+Moptcentre;keycode:0;command:CMDOBJfile;submenu:nil),
(name:'PLG'; attrib:moptbutton+Moptcentre;keycode:0;command:CMDPLGfile;submenu:nil),
(name:'GEO'; attrib:moptbutton+Moptcentre;keycode:0;command:CMDGEOfile;submenu:nil),
(name:'VRML';attrib:moptbutton+Moptcentre;keycode:0;command:CMDVRMLfile;submenu:nil),
(name:'3ds';attrib:moptbutton+Moptcentre;keycode:0;command:CMD3dsfile;submenu:nil),
(name:'GOR';attrib:moptbutton+Moptcentre;keycode:0;command:CMDgorfile;submenu:nil),
(name:'JAVA';attrib:moptbutton+Moptcentre;keycode:0;command:CMDJAVAfile;submenu:nil));
miscinfo:array[0..3] of tmenuitem_=(
(name:'About';attrib:0;keycode:0;command:CMDinfo;submenu:nil),
(name:'Refresh display';attrib:0;keycode:0;command:CMDrefresh;submenu:nil),
(name:'Object information';attrib:0;keycode:0;command:CMDgetobjectinfo;submenu:nil;extratext:''),
(name:'Help!';attrib:0;keycode:0;command:CMDcallhelp;submenu:nil;extratext:'F1'));


Fileinfo:array[0..7] of tmenuitem_=(
(name:'New..     ';attrib:0;keycode:0;command:CMDnewbox;submenu:nil;extratext:'þÿF1'),
(name:'Load..    ';attrib:0;keycode:0;command:CMDloaddialog;submenu:@filetypemenu;extratext:'þÿF2'),
(name:'Save      ';attrib:0;keycode:0;command:CMDsave3dfile;submenu:nil;extratext:'þÿF5'),
(name:'Save as.. ';attrib:0;keycode:0;command:CMDsaveasdialog;submenu:@filetypemenu;extratext:'þÿF3'),
(name:'Append..  ';attrib:0;keycode:0;command:CMDappend;submenu:@filetypemenu;extratext:'þÿF6'),
(name:'';attrib:moptseperator;keycode:0;command:0;submenu:nil),
(name:'Print..';attrib:MoptDisabled;keycode:0;command:CMDprint;submenu:nil),
(name:'Exit      ';attrib:0;keycode:0;command:CMDexitbox;submenu:nil;extratext:'þÿF4'));

Editinfo:array[0..13] of tmenuitem_=(
(name:'Undo     ';  attrib:0;keycode:0;  command:CMDundo;  submenu:nil;extratext:'üýU'),
(name:'';  attrib:moptseperator;keycode:0;  command:CMDeditselect;  submenu:nil),
(name:'Select   ';  attrib:0;keycode:0;  command:CMDeditselect;  submenu:nil;extratext:'üýS'),
(name:'Square   ';  attrib:0;keycode:0;  command:CMDeditsquare;  submenu:nil;extratext:'üýQ'),
(name:'Cube     ';    attrib:0;keycode:0;  command:CMDeditcube;    submenu:nil;extratext:'üýC'),
(name:'Dot      ';     attrib:0;keycode:0;  command:CMDeditdot;     submenu:nil;extratext:'üýD'),
(name:'Liner    ';   attrib:0;keycode:0;  command:CMDeditliner;   submenu:nil;extratext:'üýL'),
(name:'Cone     ';    attrib:0;keycode:0;  command:CMDeditcone;    submenu:nil;extratext:'üýO'),
(name:'Circle   ';  attrib:0;keycode:0;  command:CMDeditcircle;  submenu:nil;extratext:'üýI'),
(name:'Cylinder ';attrib:0;keycode:0;  command:CMDeditcylinder;submenu:nil;extratext:'üýR'),
(name:'Sphere   ';  attrib:0;keycode:0;  command:CMDeditsphere;  submenu:nil;extratext:'üýP'),
(name:'Rotate   ';  attrib:0;keycode:0;  command:CMDeditrotate;  submenu:nil;extratext:'üýF'),
(name:'Text     ';    attrib:0;keycode:0;  command:CMDedittext;    submenu:nil;extratext:'üýT'),
(name:'Grid     ';    attrib:0;keycode:0;  command:CMDeditgrid;    submenu:nil;extratext:'üýG'));

textinfo:array[0..0] of tmenuitem_=(
(name:'Load font';attrib:0;keycode:0;command:CMDloadfontdialog;submenu:nil));

PolyFunctionsinfo:array[0..6] of tmenuitem_=(
(name:'QuadDivide   þÿQ';attrib:0;keycode:0;command:CMDQuadDivide   ;submenu:nil),
(name:'Triangulate  þÿT';attrib:0;keycode:0;command:CMDtriangulate  ;submenu:nil),
(name:'Split        þÿD';attrib:0;keycode:0;command:CMDsplit        ;submenu:nil),
(name:'Flip normals þÿF';attrib:0;keycode:0;command:CMDflipnorms    ;submenu:nil),
(name:'Add          þÿY';attrib:0;keycode:0;command:CMDaddpolygon   ;submenu:nil),
(name:'Delete     BKSPC';attrib:0;keycode:0;command:CMDdeletepolys  ;submenu:nil),
(name:'Set Attributes >';attrib:0;keycode:0;command:0 ;submenu:@PolyAttribfunctions));

PolyAttribFunctionsinfo:array[0..5] of tmenuitem_=(
(name:'Double sided ';attrib:0;keycode:0;command:CMDmkDoublesided;submenu:nil;extratext:'þÿB'),
(name:'Single sided ';attrib:0;keycode:0;command:CMDmkSinglesided;submenu:nil;extratext:'þÿS'),
(name:'Smooth       ';attrib:0;keycode:0;command:CMDmkSmooth     ;submenu:nil;extratext:'þÿV'),
(name:'Flat         ';attrib:0;keycode:0;command:CMDmkFlat       ;submenu:nil;extratext:'þÿO'),
(name:'Outline      ';attrib:0;keycode:0;command:CMDmkOutlined     ;submenu:nil;extratext:''),
(name:'Solid        ';attrib:0;keycode:0;command:CMDmkSolid       ;submenu:nil;extratext:''));

Selectinfo:array[0..8] of tmenuitem_=(
(name:'Select all     ';attrib:0;keycode:0;command:CMDselectall;submenu:nil;extratext:'þÿJ'),
(name:'Show All Nodes ';attrib:mopttoggler;keycode:0;command:CMDtogglenodes;submenu:nil;extratext:'þÿN';
toggleref:@drawallnodes),
(name:'Sticky mouse ';attrib:mopttoggler;keycode:0;command:CMDstickymouse;submenu:nil;extratext:'þÿN';toggleref:@stickymouse),
(name:'Copy           ';attrib:0;keycode:0;command:CMDautocopyselected;submenu:nil;extratext:'þÿC'),
(name:'Clear          ';attrib:0;keycode:0;command:CMDselectclear;submenu:nil;extratext:'þÿL'),
(name:'Delete         ';attrib:0;keycode:0;command:CMDdeleteselectdialog;submenu:nil;extratext:'del'),
(name:'Merge          ';attrib:0;keycode:0;command:CMDmerge;submenu:nil;extratext:'þÿM'),
{(name:'Rotated Form      >';attrib:0;keycode:0;command:0;submenu:@rotatemenu),}
(name:'Flip object       ';attrib:0;keycode:0;command:0;submenu:@flipmenu;extratext:'>'),
(name:'Polygons          ';attrib:0;keycode:0;command:0;submenu:@PolyFunctions;extratext:'>'));

Windowinfo:array[0..2] of tmenuitem_=(
({name:'Tile';attrib:0;keycode:0;command:CMDtilewindows;submenu:nil),
(name:'Cascade';attrib:0;keycode:0;command:CMDcascade;submenu:nil),}
 name:'Grid    ';attrib:MoptToggler;keycode:0;command:CMDtogglegrid;submenu:nil;extratext:'þÿG ';toggleref:@grid_on),
(name:'Default pal';attrib:0;keycode:0;command:CMDsetdefaultpal;submenu:nil),
(name:'Save pal...';attrib:0;keycode:0;command:CMDsavepaldialog;submenu:nil));

Renderinfo:array[0..5] of tmenuitem_=(
(name:'Dots            ';attrib:0;keycode:0;command:CMDDots;submenu:nil;extratext:'[1]'),
(name:'Lines           ';attrib:0;keycode:0;command:CMDlines;submenu:nil;extratext:'[2]'),
(name:'Hidden lines    ';attrib:0;keycode:0;command:CMDHlines;submenu:nil;extratext:'[3]'),
(name:'Flat shaded     ';attrib:0;keycode:0;command:CMDlsource;submenu:nil;extratext:'[4]'),
(name:'Smooth shaded   ';attrib:0;keycode:0;command:CMDgouraud;submenu:nil;extratext:'[5]'),
(name:'By Attribute    ';attrib:0;keycode:0;command:CMDCpolygons;submenu:nil;extratext:'[6]'));

StdWindowinfo:array[0..2]of tmenuitem_=(
(name:'Centre [Home]';attrib:0;keycode:0;command:CMDcentrewindow;submenu:nil),
(name:'';attrib:moptseperator;keycode:0;command:0;submenu:nil),
(name:'Save Window';attrib:0;keycode:0;command:CMDsavewin;submenu:nil));

windowinfo3d:array[0..3] of tmenuitem_=(
(name:'Centre   [Home]';attrib:0;keycode:0;command:CMDcentrewindow;submenu:nil),
(name:'Reset 3d  [TAB]';attrib:0;keycode:0;command:CMDreset3dvalues;submenu:nil),
(name:'';attrib:moptseperator;keycode:0;command:0;submenu:nil),
(name:'Render depth  >';attrib:0;keycode:0;command:CMDredrawobject3d;submenu:@rendermenu));

titleinfo:array[0..5] of tmenuitem_=(
(name:chr(9);attrib:0;keycode:0;command:0;submenu:@miscmenu),
(name:'File';attrib:0;keycode:0;command:0;submenu:@filemenu),
(name:'Draw';attrib:0;keycode:0;command:0;submenu:@editmenu),
(name:'Select';attrib:0;keycode:0;command:0;submenu:@selectmenu),
(name:'Text';attrib:0;keycode:0;command:0;submenu:@textmenu),
(name:'Window';attrib:0;keycode:0;command:0;submenu:@windowmenu));

Extentions:array[0..10]of string[5]=('*.3D','*.RWX','*.POV','*.OBJ','*.GEO','*.WRL','*.PLG','*.ASC','*.GOR','*.COB','*.JAV');


icons:array[0..11,0..31]of byte=(
(0,0,8,0,12,0,14,0,15,0,15,128,15,192,15,224,15,240,15,248,15,128,13,192,8,192,0,96,0,96,0,0),
(0,0,0,0,63,252,32,4,32,4,32,4,32,4,32,4,32,4,32,4,32,4,32,4,32,4,32,4,63,252,0,0),
(0,128,3,224,15,248,63,254,127,175,127,93,94,177,107,193,85,129,106,129,85,129,42,129,85,134,10,152,5,224,0,128),
(0,0,0,0,0,0,0,0,0,0,0,0,3,192,2,64,2,64,3,192,0,0,0,0,0,0,0,0,0,0,0,0),
(0,0,0,30,0,18,0,18,0,30,0,32,0,64,0,128,1,0,2,0,4,0,120,0,72,0,72,0,120,0,0,0),
(0,128,1,64,1,192,3,32,2,160,7,16,6,144,15,8,14,136,29,4,30,132,61,2,62,130,63,4,30,152,3,224),
(0,0,0,0,3,192,12,48,16,8,32,4,32,4,64,2,64,2,64,2,32,4,32,4,16,8,12,48,3,192,0,0),
(7,240,24,12,32,2,56,14,63,242,61,2,62,2,61,2,62,2,61,2,62,2,61,2,62,2,61,4,30,24,7,240),
(0,0,7,240,31,184,63,196,127,234,127,194,255,169,255,192,191,169,213,0,170,161,64,0,74,2,32,4,24,8,6,160),
(0,0,1,0,10,0,21,0,26,64,31,96,31,240,31,248,31,252,31,254,31,252,15,248,7,240,0,96,0,64,0,0),
(0,0,0,0,63,254,36,146,36,146,63,254,36,146,36,146,63,254,36,146,36,146,63,254,36,146,36,146,63,254,0,0),
(0,0,0,0,127,254,97,134,65,130,1,128,1,128,1,128,1,128,1,128,1,128,1,128,1,128,1,128,7,224,0,0)
);

iconsattr:array[0..11] of byte=(oneon+1,oneon,oneon,oneon,oneon,oneon,oneon,oneon,oneon,oneon,oneon,oneon);
iconscommands:array[0..11] of word=(
CMDeditselect,CMDeditsquare,CMDeditcube,
CMDeditDot,CMDeditLiner,CMDeditcone,CMDeditCircle,CMDeditCylinder,
CMDeditSphere,CMDeditRotate,CMDeditgrid,CMDedittext);

Icons2:array[0..5,0..31] of byte=(
(0,0,7,128,8,64,22,32,20,32,16,32,16,32,8,96,7,240,0,56,12,28,12,14,63,6,63,0,12,0,12,0),
(0,0,7,128,8,64,22,32,20,32,16,32,16,32,8,96,7,240,0,56,0,28,0,14,63,6,63,0,0,0,0,0),
(0,0,169,98,173,85,171,85,73,98,0,0,0,0,6,0,12,0,31,210,63,232,31,210,12,0,6,0,0,0,0,0),
(0,0,3,192,7,224,14,112,12,48,12,48,12,48,31,248,31,0,30,136,31,0,30,136,31,0,30,136,31,240,0,0),
(0,0,3,192,3,192,7,224,0,0,0,0,3,192,2,64,2,64,3,192,0,0,0,0,0,0,3,192,7,224,0,0),
(0,0,96,6,112,14,56,30,28,60,6,112,3,192,1,128,3,192,6,96,12,48,28,24,56,12,112,14,48,6,0,0));
icons2attr:array[0..5] of byte=(nostick,nostick,nostick,onoff,1+onoff,nostick);
icons2commands:array[0..5] of word=(CMDzoomin,CMDzoomout,CMDundo,CMDtogglegridFROMICON,CMDtoggleNodesFROMICON,CMDnewbox);



altletters:array[0..31]of byte=(0,127,128,146,170,170,170,186,170,171,128,127,0,0,0,0,0,
                                252,2,58,18,18,18,18,18,210,2,252,0,0,0,0);
ctrlletters:array[0..31]of byte=(0,127,128,159,162,162,162,162,162,154,128,127,0,0,0,0,0,
                                254,1,201,169,169,201,169,169,173,1,254,0,0,0,0);

fin:boolean=false;
{Loadobject_dialog:file_dialog=nil;
Saveobject_dialog:file_dialog=nil;
appendobject_dialog:file_dialog=nil;
loadfont_dialog:file_dialog=nil;}
loadobjectPID=1;
saveobjectPID=2;
appendobjectPID=3;
loadfontPID=4;
quitPID=5;
destroyPID=6;
infoPID=7;
helpPID=8;
dselectPID=9;
selectsomePID=10;
overwritePID=11;
notyetimpPID=12;
filenotfoundPID=14;
copyrightPID=16;
PerspectivePID=1534;
SurfacePID=1535;
PIDambient=1536;
PIDdiffuse=1537;
PIDspecular=1538;
PIDtransparency=1539;
PIDcolourbar=1640;

filemode:word=CMD3dfile;

{****----Global Variables----****}
var

lgroupoffset:integer; {for the start of the right angle in l groups}
GraphInstalled:boolean;
dorth:delta_orth;
PerspectiveINT:longint;
font_path,clay_dir:string[80];
textfile,helpfile,registerfile,objectinfo:pchar;
varFontpath,varobjectpath,exepath:string;
lop:word;
draw_object:edit_objtype;
application:Clay;
backview:tview;
status:statusviewb;

function getobjectinfo:pchar;

begin

   objectinfo^:=#0;
   tstrcat_pascal(objectinfo,'Polygon count:');

   pitoa(draw_object^.maxpolys,objectinfo);
   charcat(objectinfo,#13);
   tstrcat_pascal(objectinfo,'vertex count:');
   pitoa(draw_object^.maxpoints,objectinfo);

   charcat(objectinfo,#13);
   tstrcat_pascal(objectinfo,'Join count:');
   pitoa(draw_object^.maxjoins,objectinfo);

   charcat(objectinfo,#13);
   tstrcat_pascal(objectinfo,'Selected vertex count:');
   pitoa(draw_object^.maxselect,objectinfo);
   
   
   {strcat(objectinfo,pitoa(200,tmp));
   strcat(objectinfo,#13);}

   getobjectinfo:=objectinfo;
end;

constructor Clay_.create(xa,ya,xb,yb:integer);
var
  lop:byte;
  xsize,ysize:integer;
begin
  inherited create(xa,ya,xb,yb);

  flipmenu.create(0,0,@flipinfo,3,3,menupopup);
  {rotatemenu.create(0,0,@rotateinfo,3,3,menupopup);}
  FileTypeMenu.create(0,0,@FileTypeinfo,10,3,menupopup);
  miscmenu.create(0,0,@miscinfo,4,3,menupopup);
  filemenu.create(0,0,@fileinfo,8,3,menupopup);
  editmenu.create(0,0,@editinfo,14,3,menupopup);
  selectmenu.create(0,0,@selectinfo,9,3,menupopup);
  textmenu.create(0,0,@textinfo,1,3,menupopup);
  windowmenu.create(0,0,@windowinfo,3,3,menupopup);

  stdwinmenu.create(0,0,@stdwindowinfo,3,3,menupopup);
  winmenu3d.create(0,0,@windowinfo3d,4,3,menupopup);
  rendermenu.create(0,0,@renderinfo,6,3,menupopup);
  PolyFunctions.create(0,0,@PolyFunctionsinfo,7,3,menupopup);
  PolyAttribFunctions.create(0,0,@PolyAttribFunctionsInfo,6,3,menupopup);

  for lop:=0 to 2 do
    edviews[lop]:=new(delta_orth,make(lop,draw_object));
  edviews[3]:=new(delta_3d,make(draw_object));
  dorth:=pointer(edviews[0]);

  desktop:=new(Desktoptype,create(60,vbord+fontheight+10,x2,y2));
  with desktop^ do begin
    options:=options or OfKeyGrab ;
    insert(new(background,create(x1,y1,x2,y2,darkblue,15,midgreyfill)));
    {insert(new(backpic,create(x1,y1,x2,y2,readpcx('c:\bitmap\pics\pcx\webb.pcx'))));}
    backview:=pointer(first);
    status:=new(statusviewb,create(80,60,200,160));
    status^.val1:=@scan;
    insert(status);
    {insert(new(RotationControl,create(100,100)));}
    xsize:=halfx-(vpindent shl 1);
    ysize:=halfy-(vpindent shl 1);

    insert(new(windowtype,create(x1+vpindent,y1+vpindent,xsize,ysize, 'Front',
    edviews[zaxis],@stdwinmenu)));
    insert(new(windowtype,create(vpindent+x2-halfx,y1+vpindent,xsize,ysize,'Side',
    edviews[xaxis],@stdwinmenu)));
    insert(new(windowtype,create(x1+vpindent,y1+(vpindent shl 1)+halfy-3,xsize,ysize,'Plan',
    edviews[yaxis],@stdwinmenu)));
    insert(new(windowtype,create(vpindent+x2-halfx,y1+(vpindent shl 1)+halfy-3,xsize,ysize,'Perspective',
    edviews[view_3d],@winmenu3d)));
    {insert(new(surfacedialog,create(60,60)));}
  end;
  options:=options or (ofnooverlap+ofkeygrab);
  insert(desktop);
  insert(new(tmenubar,create(0,0,@Titleinfo,6,2,menuxorient)));
  lgroupoffset:=first^.width-59;

  ModeOptionsPtrs[0]:=New(SelectOptions,create);
  ModeOptionsPtrs[1]:=New(Lgroup,create('Square'));
  ModeOptionsPtrs[2]:=New(Lgroup,create('Cube'));
  ModeOptionsPtrs[3]:=New(Lgroup,create('Dot'));
  ModeOptionsPtrs[4]:=New(Lgroup,create('Line'));
  ModeOptionsPtrs[5]:=New(CircOptions,create('Cone',@conesize));
  ModeOptionsPtrs[6]:=New(CircOptions,create('Circle',@circsize));
  ModeOptionsPtrs[7]:=New(CircOptions,create('Cylinder',@cylindersize));
  ModeOptionsPtrs[8]:=New(SphereOptions,create(@spheresize));
  ModeOptionsPtrs[9]:=New(RotateOptions,create('Rotated form',@rotsize));
  ModeOptionsPtrs[10]:=New(GridOptions,create);
  ModeOptionsPtrs[11]:=New(TextEditDialog,create);
  ModeOptions:=new(Tgroup,create(60,0,x2,vbord+25));
  with ModeOptions^ do begin
    Options:=Options or  (OfKeyGrab);
    for lop:=11 downto 0 do
      insert(ModeOptionsPtrs[lop]);
  end;


  insert(ModeOptions);
  insert(new(Textbutton,create(x1+5,y1+210,50,20,13,1,BM_releaseaction,1,CMDCallSurfaceDialog,'Poly>')));
  iconpanel:=new(iconpaneltype,Create(0,48,3,4,20,20,@icons,@iconsattr,@iconscommands));
  insert(iconpanel);
  subpanel:=new(iconpaneltype,Create(0,140,3,2,20,20,@icons2,@icons2attr,@icons2commands));
  coords:=new(coordbox,create(3,y2-46,55,y2-5));
  coords^.coord:=crs;
  insert(coords);

  insert(subpanel);
  insert(new(RotationControl,create(3,y2-200)));
end;

procedure clay_.handlevent(var event:tevent);
var filenotfound:boolean;
    send_command:word;
    tmprect:trect;
    transmatrix:matrix3x4type_;
    tx,ty:integer;
    Coordval:vectorreal;

begin
  inherited handlevent(event);
  with event,draw_object^ do
  case what of
    EvCommand:begin
      filenotfound:=false;
      case command of
        {**********-----Creation/editing commands-----***********}
        CMDautocopyselected:dorth^.DoCommand(command,@autocopymatrix,divisionsize);
        RANGEextcomSTART..RANGEextcomEND:Dorth^.DoCommand(command,nil,0);
        CMDload3dfile,CMDappend3dfile:with file_dialog(infoptr)^,texteditbox^ do begin
          varobjectpath:=Sdir;
          if fexist(txt) then
            dorth^.docommand(command,@txt,filemode)
          else
            filenotfound:=true;
        end;
        CMDsave3dfile:if name<>'' then
          dorth^.docommand(command,@name,filemode)
        else first^.evcallback(CMDsaveasdialog);
        {**********-----desktop commands-----***********}
        CMDeditselect..CMDedittext:begin
          drawing_mode:=command;
          dec(drawing_mode,CMDeditselect);
          {set new drawing mode, change dialog bar at top of screen}
          if drawing_mode<=11 then begin
            with ModeOptionsptrs[drawing_mode]^ do
              putinfrontof(owner^.first);
            {make sure this doesn't recall this code}
            if (command=CMDedittext) and (not vfontin) then
              addmessage(0,CMDloadfontdialog,'You must load in a Font before using this tool.',fontmessagePID,desktop);
            with IconPanel^ do begin
              state:=state or sfmute;
              iconpanel^.seticon(drawing_mode);
              state:=state xor sfmute;
            end;
          end;
          inc(drawing_mode,CMDeditselect);
        end;
        CMDcallsurfacedialog:
          desktop^.add_and_draw(new(surfacedialog,create(0,0)),VPcentre,surfacePID);
        CMDtogglenodesFROMICON:begin
          drawallnodes:=drawallnodes xor true;
          if drawallnodes=true then
            what_to_draw:=draw_orthnodes;
          draworth;
          what_to_draw:=draw_all;
        end;
        CMDtogglenodes:begin
          {make sure this doesn't recall this code}
          with SubPanel^ do begin
            state:=state or sfmute;
            seticon(4);
            state:=state xor sfmute;
          end;
          drawallnodes:=drawallnodes xor true;
          if drawallnodes=true then
            what_to_draw:=draw_orthnodes;
          draworth;

          what_to_draw:=draw_all;
        end;
        CMDstickymouse:
          stickymouse:=stickymouse xor true;

        CMDdeleteselectdialog:
            AddMessage(CMDcancel,CMDdeleteselect,'Are you sure want to delete that selection?',dselectPID,desktop);

        CMDtogglegrid:begin
          {make sure this doesn't recall this code}
          with SubPanel^ do begin
            state:=state or sfmute;
            seticon(3);
            state:=state xor sfmute;
          end;
          grid_on:=grid_on xor true;
          gridlock:=gridlock xor true;
          draworth;
        end;
        CMDtogglegridFROMICON:begin
          grid_on:=grid_on xor true;
          gridlock:=gridlock xor true;
          draworth;
        end;
        CMDgetobjectinfo:
          desktop^.add_and_draw(new(infodialog,create(0,0,300,300,getobjectinfo,false)),VPcentre,infoPID);
        CMDinfo:
          desktop^.add_and_draw(new(infodialog,create(0,0,300,300,textfile,false)),VPcentre,infoPID);
        CMDcallhelp:begin
           helpfile:=loadtext(clay_dir+'help.txt');
           desktop^.add_and_draw(new(infodialog,create(0,0,400,270,helpfile,true)),VPcentre,helpPID);
        end;

        CMDnewbox:if maxpoints>0 then
          AddMessage(CMDcancel,CMDnew,'Are you sure you want to destroy the Object?',destroyPID,desktop);
        CMDfilemode_start..CMDfilemode_end:FileMode:=Command;
        CMDsave3dfileornot:begin
          varobjectpath:=file_dialog(infoptr)^.Sdir;
          name:=file_dialog(infoptr)^.texteditbox^.txt;
          if fexist(name) then
            Addmessage(CMDcancel,CMDsave3dfile,'Are you sure you want to overwrite the file?',overwritePID,desktop)
          else
            sendCommand(CMDsave3dfile,@self,nil);
        end;

        CMDloadfont:with file_dialog(infoptr)^,texteditbox^ do begin
          varfontpath:=Sdir;
          if fexist(txt) then begin
            vfontin:=vfont.load(txt);
            if not vfontin then
              AddMessage(0,0,'Error in file.',fileerrorPID,desktop);
          end else
            filenotfound:=true;
          if (vfontin) and (drawing_mode=CMDedittext) then
            SendCommand(CMDedittext,@self,nil);
        end;
        CMDloadheightmap:
          with file_dialog(infoptr)^,texteditbox^ do begin
           if fexist(txt) then begin
            if gridpic<>nil then
              destroybitmap(gridpic);
            gridpic:=readpcx(txt,PAflat);
          end else
            filenotfound:=true;
          end;

        CMDloadfontDialog:
          desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDloadfont,
          'Load font',varfontpath,'*.chr',application)),VPcentre,loadfontPID);
        CMDappend:
          desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDappend3dfile,
          'Append 3d file',varobjectpath,'*.3d',application)),VPcentre,appendobjectPID);
        CMDloaddialog:if (filemode<>CMDPOVfile) and
                         (filemode<>CMDVRMLfile) and (filemode<>CMDPLGfile) then
          desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDload3dfile,
          'Load 3d file',varobjectpath,Extentions[FileMode-CMD3dfile],application)),VPcentre,loadobjectPID)

        else
          AddMessage(0,0,'Sorry, Not yet implemented.',notyetimpPID,desktop);
        CMDsaveasdialog:
          desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDsave3dfileornot,
          'save 3d file',varobjectpath,Extentions[FileMode-CMD3dfile],application)),VPcentre,saveobjectPID);


        CMDrefresh:begin t_fillcol:=0;cleardevice;drawview;end;
        CMDexitbox:AddMessage(CMDcancel,CMDexit,'Are you sure you want to Leave?',quitPID,desktop);
        CMDexit:fin:=true;
        CMDzoomin: setscale(scale*1.05);
        CMDzoomout: setscale(scale/1.05);
        CMDsetdefaultpal:setpal(@pal16,0,15);
        CMDsavepaldialog:desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDsavepal,
          'Save Colour Palette',gtdir,'*.pal',application)),VPcentre,loadfontPID);
        CMDsavepal:with file_dialog(infoptr)^,texteditbox^ do begin
          {getpal(claypal);
          savepalpas(txt,claypal);}
        end;
        CMDselectedittext:begin
          TextEditdialog(ModeOptionsPtrs[11])^.TextEditBox^.Select;
          stoprepeat;
        end;
        {for the drawn coordinates}
        CMDsetcoords:begin
          with delta_orth(infoptr)^ do begin
            tx:=xm;ty:=ym;
            localspace(tx,ty);
            conv2d_3d(orientation,tx,ty,@crs,@coords^.coord);
            coords^.drawview;
          end;
        end;



        {CMDtilewindows,CMDcascade,CMDprint,CMDsavewin:AddMessage(CurrMessage,0,0,'Not yet implemented.');}
      end;
      if filenotfound then
        AddMessage(0,0,'Sorry, the file was not found.',filenotfoundPID,desktop);

    end;

    evkeydown:begin
      case charcode of
        '+':SendCommand(CMDzoomin,@self,nil);
        '-':SendCommand(CMDzoomout,@self,nil);
        #242:Addmessage(0,0,'ClayWorks V2.45, C T.Lewis 1993-1995',copyrightPID,desktop);
        #8:SendCommand(CMDdeletepolys,@self,nil);
        #127:SendCommand(CMDdeletelines,@self,nil);
      end;
      if boolean(scan and smLEFTCTRL) then case charcode of
        {'s','S':RotationStepSel^.drawview;}
        #19:SendCommand(CMDeditselect,@self,nil);
        #17:SendCommand(CMDeditsquare,@self,nil);
        #3:SendCommand(CMDeditcube,@self,nil);
        #4:SendCommand(CMDeditdot,@self,nil);
        #12:SendCommand(CMDeditliner,@self,nil);
        #15:SendCommand(CMDeditcone,@self,nil);
        #9:SendCommand(CMDeditcircle,@self,nil);
        #18:SendCommand(CMDeditcylinder,@self,nil);
        #16:SendCommand(CMDeditSphere,@self,nil);
        {'H','h':SendCommand(CMDeditrotate,@self,nil);}
        #7:SendCommand(CMDeditgrid,@self,nil);
        #20:SendCommand(CMDedittext,@self,nil);
        #21:SendCommand(CMDundo,@self,nil);
        #24:SendCommand(CMDFlipX,@self,nil);
        #25:SendCommand(CMDFlipY,@self,nil);
        #26:SendCommand(CMDFlipZ,@self,nil);
      end;
      case scancode of
        36:SendCommand(CMDselectall,@self,nil);
        20:SendCommand(CMDTriangulate,@self,nil);
        16:SendCommand(CMDQuadDivide,@self,nil);
        46:SendCommand(CMDautocopyselected,@self,nil);
        38:SendCommand(CMDselectclear,@self,nil);
        49:SendCommand(CMDtogglenodes,@self,nil);
        30:SendCommand(CMDapplyColour,@self,nil);
        21:SendCommand(CMDaddpolygon,@self,nil);
        31:SendCommand(CMDmksinglesided,@self,nil);
        33:SendCommand(CMDflipnorms,@self,nil);
        47:SendCommand(CMDmksmooth,@self,nil);
        24:SendCommand(CMDmkflat,@self,nil);
        48:SendCommand(CMDmkDoublesided,@self,nil);
        59:SendCommand(CMDcallhelp,@self,nil);
        107:SendCommand(CMDexitbox,@self,nil);
        106:SendCommand(CMDsaveasdialog,@self,nil);
        104:SendCommand(CMDnew,@self,nil);
        105:SendCommand(CMDloaddialog,@self,nil);
        108:SendCommand(CMDsave3dfile,@self,nil);
        109:SendCommand(CMDappend,@self,nil);
        34:subpanel^.seticon(3);
        130:subpanel^.seticon(0);
        131:subpanel^.seticon(1);
        83:SendCommand(CMDdeleteselectdialog,@self,nil);

        50:Sendcommand(CMDMerge,@self,nil);
      end;
    end;
  end;
end;

procedure clay_.draw;
begin
  {insert(new(panelback,create(0,20,59,y2)));}
  outbox(x1,y1+vbord+5,x1+59,y1+47);
  Outtextxy3d(x1+5,y1+30,'Shapes');
  inbox(x1,y1+127,x1+59,y1+139);
  inbox(x1,y1+179,x1+59,y2);
  t_col:=darkcol;
  vline(x1+59,y1+20,y2);
  outtextxy3d(x1+5,y2-64,'Coords');
  inherited draw;
end;

procedure coordbox_.draw;
begin
  textboxfilled(x1,y1,x2,y2);
  t_col:=textcol;
  outtextxy(x1+2,y1+2,ftoa(coord.x,1,1));
  outtextxy(x1+2,y1+14,ftoa(coord.y,1,1));
  outtextxy(x1+2,y1+26,ftoa(coord.z,1,1));
end;

Constructor SurfaceDialog_.create(xa,ya:integer);
begin
  inherited create(xa,ya,xa+250,ya+220);
  options:=options or (ofnooverlap+ofkeygrab+oftopselect);
  inc(y1,vbord);
  insert(new(Tbutton,create(x1+5,y1+10,8,8,midcol,1,BM_toggleaction,CMDtoggleAbsolute,0)));
  insert(new(Tbutton,create(x1+halfx,y1+10,8,8,midcol,1,BM_toggleaction,CMDtoggleoutline,0)));
  insert(new(Tbutton,create(x1+5,y1+30,8,8,midcol,1,BM_toggleaction,CMDtogglesmooth,0)));
  insert(new(Tbutton,create(x1+halfx,y1+30,8,8,midcol,1,BM_toggleaction,CMDtoggledoubleSided,0)));
  insert(new(Textbutton,create(x2-65,y1+45,60,20,midcol,1,BM_releaseaction,2,CMDApplyAttrib,'Apply')));
  insert(new(Textbutton,create(x2-65,y2-25,60,20,midcol,1,BM_releaseaction,1,CMDdismisview,'Dismis')));
  insert(new(Textbutton,create(x2-66,y2-55,61,20,midcol,1,BM_releaseaction,1,CMDApplyColour,'Apply')));
  insert(new(Textbutton,create(x2-150,y2-25,80,20,midcol,1,BM_releaseaction,4,CMDApplyAttribandColour,'Apply All')));

  insert(new(colourgridtype,create(x2-65,y2-120,11,15,4,4,@fgtexture,@bktexture,desktop)));
  colourgridptr:=colourgridtype(first);
  insert(new(bartype,create(x2-21,y2-120,scrollbar_size,61,0,252,0,ybardir)));
  tgroup(first)^.last^.PID:=PIDcolourbar;
  insert(new(bartype,create(x1+100,y2-120,scrollbar_size,61,0,63,0,ybardir)));
  tgroup(first)^.last^.PID:=PIDdiffuse;
  insert(new(bartype,create(x1+120,y2-120,scrollbar_size,61,0,63,0,ybardir)));
  tgroup(first)^.last^.PID:=PIDambient;
  insert(new(bartype,create(x1+140,y2-120,scrollbar_size,61,0,63,0,ybardir)));
  tgroup(first)^.last^.PID:=PIDspecular;
  insert(new(bartype,create(x1+160,y2-120,scrollbar_size,61,0,63,0,ybardir)));
  tgroup(first)^.last^.PID:=PIDtransparency;
  dec(y1,vbord);
  add_title(@self,'Surface Attributes');
end;

Procedure SurfaceDialog_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do
  case what of
    EVcommand:
    case command of
      CMDdismisview:delete;
      CMDmoveparent:dragview(1,owner^,0,0,1000,1000);
      CMDtoggleDoubleSided:CurrAttrib:=CurrAttrib xor PaDoubleSided;
      CMDtoggleSmooth:CurrAttrib:=CurrAttrib xor PaSmooth;
      CMDtoggleOutline:CurrAttrib:=CurrAttrib xor PaOutlined;
      CMDtoggleAbsolute:CurrAttrib:=CurrAttrib xor PaAbsolute;
      CMDvalchanged:begin
        case infotview^.PID of
          PIDcolourbar:colourgridptr^.handlevent(event);
          PIDtransparency:;
        end;
      end;
      CMDcolourchanged:begin
        fgtexture:=colourgridptr^.fgcol^;
        bktexture:=colourgridptr^.bgcol^;
      end;
      CMDapplyattrib,CMDapplycolour,CMDapplyattribandColour:
        dorth^.docommand(Command,nil,0);
    end;
    EVkeydown:;
  end;
end;

procedure SurfaceDialog_.draw;
begin
  inc(y1,vbord);
  outbox(x1,y1,x2,y2);
  t_col:=disabledcol;
  outtextxy(x1+17,y1+7,'Abs. Colour');
  outtextxy(x1+17,y1+27,'Smooth Shaded');
  outtextxy(x1+halfx+13,y1+7,'OutLined');
  outtextxy(x1+halfx+12,y1+27,'Double Sided');
  outtextxy(x1+102,y2-55,'D');
  outtextxy(x1+122,y2-55,'A');
  outtextxy(x1+142,y2-55,'S');
  outtextxy(x1+162,y2-55,'O');

  t_col:=lightcol;
  vline(x2-66,y2-120,y2-59);
  hline3d(x1+5,x2-5,y1+68);
  t_col:=lightcol;
  hline3d(x1+5,x2-5,y2-30);
  dec(y1,vbord);
  inherited draw;
end;

{destructor Surfacedialog_.done;
begin

end;}




constructor RotationControl_.create(xa,ya:integer);
const bsize=3;
      ynumsel=28;

var ytotal,ysize,xsize:integer;
begin
  inherited create(xa,ya,xa+54,ya+90);
  step:=3;
  options:=options or (oftopselect+ofnooverlap);

  insert(new(bordertype,create(x1,y1,x2,y2,bsize)));
  inc(x1,bsize);inc(y1,bsize);dec(x2,bsize);dec(y2,bsize);
  ysize:=((y2-y1-vbord-ynumsel)div 2)-1;
  ytotal:=y1;
  xsize:=(x2-x1);

  {insert(new(textbutton,create(x1,ytotal,xsize,vbord,
             titlecol,0,BM_periodaction,0,CMDmoveparent,'3d')));
  inc(ytotal,vbord+1);}
  insert(new(textbutton,create(x1,ytotal,xsize,ysize,
             midcol,0,BM_periodaction,1,CMDxrot,'X Rot')));
  inc(ytotal,ysize+1);
  insert(new(textbutton,create(x1,ytotal,xsize,ysize,
             midcol,0,BM_periodaction,1,CMDyrot,'Y Rot')));
  inc(ytotal,ysize+1);
  insert(new(textbutton,create(x1,ytotal,xsize,ysize,
             midcol,0,BM_periodaction,1,CMDzrot,'Z Rot')));
  {inc(ytotal,ysize+1);
  insert(new(numsel,create(x1,ytotal,xsize,ysize,11,
             100,1000,@perspectiveINT)));
  set the 'numbox' to have that PID
  tgroup(first)^.last^.PID:=PerspectivePID;}
  inc(ytotal,ysize+1);
  insert(new(numsel,create(x1,ytotal,xsize,y2-ytotal,8,
             -64,64,@step)));

  dec(x1,bsize);dec(y1,bsize);inc(x2,bsize);inc(y2,bsize);
end;

procedure RotationControl_.handlevent(var event:tevent);
var
rotateby:vectorreal;
val:real;
begin
  inherited handlevent(event);
  val:=step;
  with event do
    case what of
    Evcommand:
      with draw_object^ do case command of
        CMDmoveparent:dragview(1,owner^,0,0,1000,1000);
        CMDxrot,CMDyrot,CMDzrot: begin
          case command of
            CMDxrot:rotateby.moveto(val/180,0,0);
            CMDyrot:rotateby.moveto(0,val/180,0);
            CMDzrot:rotateby.moveto(0,0,val/180);
          end;
          SendCommand(CMDrotate,edviews[3],@rotateby);
        end;
        {CMDvalchanged:if infotgroup^.last^.PID=PerspectivePID then begin
          pers:=perspectiveINT;
          edviews[3]^.drawview
        end;}
      end;
    end;
end;

Constructor TextEditDialog_.create;
const W=270;H=Vbord+10+Fontheight+(edit_indentY shl 1);
begin
  inherited create('3d Text');
  options:=options or (ofnooverlap+oftopselect);
  texteditbox:=new(edittexttype,create(x1+185,y1+5,editstring,255,28));
  insert(texteditbox);
end;

Procedure TextEditDialog_.handlevent(var event:tevent);
begin
  if @self=owner^.first then begin
    inherited handlevent(event);
    with event do
    case what of
      EvCommand:
      case command of
        CMDEditstringaltered:
          EditString:=Texteditbox^.txt;
      end;
      EvKeyDown:
      if scancode=20 then texteditbox^.select;
    end;
  end;
end;

var
selectmodes:tpopupmenu_;

Constructor SelectOptions_.create;
const
{selectmodestitleinfo:array[0..0] of tmenuitem_=(
(name:'Manip. Modes '+chr(25);  attrib:moptbutton;keycode:0;  command:0;  submenu:@selectmodes));
selectmodesinfo:array[0..1] of tmenuitem_=(
(name:'Move/Resize  ';  attrib:0;keycode:0;  command:SMresize_repos;  submenu:nil),
(name:'Rotate       ';       attrib:0;keycode:0;  command:SMrotate;  submenu:nil)
);}


selmodeicons:array[0..1,0..31] of byte=((1,0,1,0,1,0,1,0,1,0,7,192,4,64,4,126,4,64,7,192,8,0,16,0,32,0,64,0,0,0,0,0),
(0,0,24,112,24,136,37,68,37,164,67,20,66,12,131,28,130,168,102,72,26,72,2,72,1,80,0,224,0,64,0,0));

selmodeiconsattr:array[0..1] of byte=(oneon+1,oneon);
selmodeiconscommands:array[0..1] of word=(SMnodal,SMobjects);
selicons:array[0..2,0..31] of byte=
((0,0,0,128,1,192,3,224,1,192,1,64,17,68,63,126,120,15,63,126,17,68,1,64,1,192,3,224,1,192,0,128),
(0,0,3,192,15,240,31,248,60,60,56,28,112,14,112,14,112,14,113,14,57,156,63,200,31,224,15,192,1,128,1,0),
(0,0,3,128,7,192,2,128,1,0,7,192,3,128,3,128,3,128,3,128,6,128,12,128,8,128,8,128,24,192,0,0)
);
seliconsattr:array[0..2] of byte=(oneon+1,oneon,oneon);
seliconscommands:array[0..2] of word=(SMresize_repos,SMrotate,SMdeform);

extrudeicons:array[0..0,0..31] of byte=(
(0,0,0,0,3,254,4,6,8,10,16,18,63,226,32,34,32,34,32,34,32,34,32,36,32,40,32,48,63,224,0,0));
extrudeiconsattr:array[0..0] of byte=(onoff);
extrudeiconscommands:array[0..0] of word=(CMDToggleExtrude);

begin
  inherited create('Select: Move/Resize');
  options:=options or (ofnooverlap+oftopselect);

  {{files:=new(listwbar,create(x1+10,y2-168,110,117,list,listcount,3,true));}
  {selectmodes.create(0,0,@selectmodesinfo,2,2,0);
  insert(new(tmenubar,create(x1+183,y1+2,@selectmodestitleinfo,1,2,menuindent+menuxorient)));
  insert(new(textbutton,create(x1+308,y1+5,76,20,titlecol,1,BM_toggleaction,1,CMDToggleExtrude,'Extrude')));
  tbutton(first)^.dstate:=byte(Extrude);}
  insert(new(iconpaneltype,Create(x1+187,y1+6,3,1,20,20,@selicons,@seliconsattr,@seliconscommands)));

  insert(new(iconpaneltype,Create(x1+287,y1+6,2,1,20,20,@selmodeicons,@selmodeiconsattr,@selmodeiconscommands)));
  insert(new(iconpaneltype,Create(x1+256,y1+6,1,1,20,20,@extrudeicons,@extrudeiconsattr,@extrudeiconscommands)));
  insert(new(numsel,create(x1+389,y1+6,55,16,8,1,30,@DivisionSize)));
end;

Procedure SelectOptions_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  with event do
  case what of
    EvCommand:
    case command of
      CMDToggleExtrude:Extrude:=Extrude xor true;
      {CMDToggleConnect:PolyConnect:=PolyConnect xor true;}
      SMnodal,SMobjects:selectmodelevel:=command;


      SMbegin..SMend:begin
        if selected_mode<>command then begin
          what_to_draw:=draw_boundingboxstuff;
          drawobject;
          selected_mode:=command;
          drawobject;
          what_to_draw:=draw_all;
          case command of
            SMresize_repos:name:='Select: Move/Resize';
            SMrotate:name:='Select: Rotate';
            SMdeform:name:='Select: Deform';
          end;
          SC.viewport.rassign(x1+69,y1,x1+160,y2);
          drawview;
          SC.viewport:=SC.screenport;
        end;
      end;
    end;
  end;
end;

Procedure SelectOptions_.draw;
begin
  inherited draw;
  t_col:=disabledcol;
  outtextxy(x1+392,y1+26,'Copies');
end;

Constructor SphereOptions_.create(size:pointtypeptr);
begin
  inherited create('Sphere');
  insert(new(numsel,create(x1+193,y1+18,56,16,8,3,60,@size^.x)));
  insert(new(numsel,create(x1+252,y1+18,56,16,8,3,60,@size^.y)));
end;

Procedure SphereOptions_.draw;
begin
  inherited draw;
  t_col:=disabledcol;
  outtextxy(x1+193,y1+2,'Number of Segments');
end;

Procedure SphereOptions_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  {with event do
  case what of
    EvCommand:
    case command of
    end;
  end;}
end;


Constructor CircOptions_.create(name_:string;data:pointer);
begin
  inherited create(name_);
  insert(new(numsel,create(x1+193,y1+18,56,16,8,3,60,data)));
end;

Procedure CircOptions_.draw;
begin
  inherited draw;
  t_col:=disabledcol;
  outtextxy(x1+193,y1+2,'Number of Segments:');
end;

Procedure CircOptions_.handlevent(var event:tevent);
begin
  inherited handlevent(event);
  {with event do
  case what of
    EvCommand:
    case command of
    end;
  end;}
end;

Constructor RotateOptions_.create(name_:string;data:pointer);
begin
  inherited create(name_);
  insert(new(numsel,create(x1+193,y1+18,56,16,8,3,30,data)));
  insert(new(textbutton,create(x1+270,y1+18,20,20,midcol,1,BM_releaseaction,1,CMDrotatedformX,'X')));
  insert(new(textbutton,create(x1+292,y1+18,20,20,midcol,1,BM_releaseaction,1,CMDrotatedformY,'Y')));
  insert(new(textbutton,create(x1+314,y1+18,20,20,midcol,1,BM_releaseaction,1,CMDrotatedformZ,'Z')));
end;

Procedure RotateOptions_.draw;
begin
  inherited draw;
  t_col:=disabledcol;
  outtextxy(x1+193,y1+2,'Side(s)');
  outtextxy(x1+270,y1+2,'Rotate Around....');
end;

Procedure RotateOptions_.handlevent(var event:tevent);
begin
  if @self=owner^.first then with event do begin
    inherited handlevent(event);
    if what=EvCommand then
    case command of
      CMDrotatedformX,CMDrotatedformY,CMDrotatedformz:dorth^.docommand(command,nil,0);
    end;
  end;
end;
var
gridmodemenu:Tpopupmenu_;
Constructor GridOptions_.create;

const
gridmodeinfo:array[0..2] of tmenuitem_=(
(name:'Flat';attrib:0;keycode:0;command:CMDtoggleflat;submenu:nil),
(name:'Sine Wave';attrib:0;keycode:0;command:CMDtogglesine;submenu:nil),
(name:'Heightmap';attrib:0;keycode:0;command:CMDtoggleheightmap;submenu:nil));
gridtitleinfo:tmenuitem_=
(name:'Flat     ';attrib:moptchangename+moptbutton;keycode:0;command:0;submenu:@gridmodemenu);

begin
  inherited create('Grid');
  insert(new(numsel,create(x1+183,y1+2,55,16,8,3,30,@GridX)));
  xval:=ValueType(tgroup(first)^.last);
  insert(new(numsel,create(x1+240,y1+2,55,16,8,3,30,@GridY)));
  yval:=ValueType(tgroup(first)^.last);

  insert(new(textbutton,create(x1+320,y1+2,85,18,titlecol,1,BM_toggleaction,1,CMDToggleCheck,'Checkered')));
  insert(new(textbutton,create(x1+320,y1+22,85,18,titlecol,1,BM_releaseaction,1,CMDloadheightmapdialog,'Load Map')));
  insert(new(tmenubar,create(x1+420,y1+2,@gridtitleinfo,1,2,menuxorient)));
  gridmodemenu.create(0,0,@gridmodeinfo,3,2,menupopup);

end;

Procedure GridOptions_.draw;
begin
  inherited draw;
  t_col:=disabledcol;
  Outtextxy(x1+209,y1+21,'X');
  Outtextxy(x1+266,y1+21,'Y');
end;
Procedure GridOptions_.handlevent(var event:tevent);
begin
  if @self=owner^.first then begin
  inherited handlevent(event);
  with event do
  case what of
    EvCommand:
    case command of
      CMDToggleSine:begin GridMode:=GMSine;end;
      CMDToggleHeightmap:begin GridMode:=GMheightmap;end;
      CMDToggleFlat:begin GridMode:=gmflat;end;
      CmdToggleCheck:CheckOrNot:=CheckOrNot xor true;
      CMDloadHeightmapDialog:
          desktop^.add_and_draw(new(file_dialog,create(0,0,CMDcancel,CMDloadHeightmap,
          'Load Heightmap',varfontpath,'*.pcx',application)),VPcentre,loadfontPID);

    end;
  end;
  end;
end;

Constructor Lgroup_.create(name_:string);
begin
  inherited create(60,0,SC.screenport.x2,vbord+25);
  xoffset:=lgroupoffset;
  options:=options or (OfKeyGrab+OfNoOverlap);
  name:=name_;
end;

Procedure Lgroup_.draw;
begin
  t_fillcol:=midcol;
  t_col:=purple;
  setfillpattern(midgreyfill,true);
  bar(x1+1,y1+vbord+6,x2-1,y2-1);
  bar(x1+xoffset+1,y1+1,x2-1,y1+vbord+7);
  setsolidfill;

  t_col:=lightcol;
  hline(x1+xoffset,x2,y1);
  hline(x1,x1+xoffset-1,y1+vbord+5);
  vline(x1+xoffset,y1,y1+vbord+5);
  vline(x1,y1+vbord+5,y2-1);

  t_col:=mid_darkcol;
  hline(x1,x2,y2-1);

  t_col:=darkcol;
  hline(x1,x2,y2);
  outtextxy3d(x1+5,y2-fontheight-1,name);
  inherited draw;
end;

Constructor CopyRightBox_.create;
begin
  inherited create(0,0,330,55);
  options:=options or ofkeygrab;
end;

Procedure CopyRightBox_.handlevent(var event:Tevent);
begin
  inherited handlevent(event);
  if (event.what=EvKeyDown)and(charcode=#27) then
    delete;
end;

Procedure CopyRightBox_.draw;
begin
  Outbox(x1,y1,x2,y2);
  T_col:=Textcol;
  Outtextxy(x1+4,y1+4,'This software is Copyright 1995, T.Lewis');
  Outtextxy(x1+4,y1+4+fontheight,
                      'It''s sale or distribution without the ');
  Outtextxy(x1+4,y1+4+(fontheight shl 1),'authors consent is forbidden.');
end;

function strippath(pstr:string):string;
var i,lastindx:byte;
retstr:string;
begin
  for i:=1 to length(pstr) do begin
    if pstr[i]='\' then
      lastindx:=i;
  end;
  retstr:=copy(pstr,0,lastindx);
  strippath:=retstr;
end;

begin
  {mem1:=memavail;
  writeln(memavail);
  writeln(memavail+fixedusage);
          }

  PerspectiveINT:=PersStart;
  if memavail<longint(minmem) then begin
    writecon('Not Enough Memory, you need '+' bytes.$'+chr(13));{+itoa(minmem+fixedusage)+}
    writecon(' bytes are available.$'+chr(13));{itoa(fixedusage+memavail)}
    exit;
  end;

  {if resetmouse=false then begin
    writeln('You need a mouse and/or a mouse driver.');
    exit;
  end;}

  clay_dir:=getenv('CLAY_dir');
  font_path:=getenv('TWIN_fontdir');
  if (clay_dir='')or(font_path='') then begin
    writecon('Please set the "CLAY_dir" & "TWIN_fontdir" env. variables, press a key.$'+chr(13));
    readkey;

  end;

  {fillchar(blackpal,sizeof(blackpal),0);
  correct_ordering;
  {getpal(currpal);
  fadepal(currpal,blackpal,16,false);}
  exepath:=strippath(paramstr(0));

  if clay_dir<>'' then
    clay_dir:=clay_dir+'\'
  else
    clay_dir:=exepath;
  varfontpath:=gtdir;
  varobjectpath:=gtdir;
  if (font_path='') then begin
    font_path:=exepath+'sansf16b.fnt';
  end;



  if copy(paramstr(1),1,1)='v' then begin
    case atoi(copy(paramstr(1),2,system.length(paramstr(1))-1)) of
      1:GraphInstalled:=initgraph(VGA640x480x16);
      2:GraphInstalled:=initgraph(SVGA800x600x16);
      3:GraphInstalled:=initgraph(SVGA640x480x256);
      4:GraphInstalled:=initgraph(SVGA800x600x256);
      5:GraphInstalled:=initgraph(SVGA1024x768x256);
      6:GraphInstalled:=initgraph(xVGA400x300x256);
    end;
    if not GraphInstalled then begin
      Writecon('I can not use that graphics mode$'+chr(13));
      exit;
    end;
  end else
    GraphInstalled:=initgraph(VGA640x480x16);

  usecolours(0,16);

  if fexist(font_path) then
    loadfontlist(font_path, tcharset)
  else begin
    writeln('Font file not found, please place the file sans16b.fnt in the program file''s directory');
    exit;
  end;
  move(altletters,mem[seg(tcharset):ofs(tcharset)+(254 shl 4)],32);
  move(ctrlletters,mem[seg(tcharset):ofs(tcharset)+(252 shl 4)],32);
  tcharset.widths[252]:=8;
  tcharset.widths[253]:=9;
  tcharset.widths[254]:=8;
  tcharset.widths[255]:=9;

  tcharset.attrib:=1;

  new(draw_object,create(4900,4200,4200));

  if fexist(clay_dir+defaultfont) then begin
    Vfontin:=vfont.load(defaultfont);
  end else
    Vfontin:=false;

  if fexist(clay_dir+'info.txt') then
    textfile:=loadtext(clay_dir+'info.txt');
  getmem(objectinfo,512);
  gridpic:=nil;

  setpal(@pal16,0,16);
  init3d;

  lightvec.setlight(0,0,0,500,50,10,SC.ColourDepth shr 1);

  with SC.screenport do
  application:=new(clay,create(0,0,x2,y2));
  InitTWIN(application);
  if fexist(clay_dir+'warn.pcx') then
    warningsign:=readpcx(clay_dir+'warn.pcx',PAcolcheck)
  else
    warningsign:=nil;


  application^.draw;

  mouseon;
  root:=application;



  registerfile:=loadtext(clay_dir+'register.txt');

  desktop^.add_and_draw(new(infodialog,create(90,80,590,470,registerfile,true)),VPcentre,PIDundefined);

  while not fin do begin

    eventmpos;
    eventkey;
    status^.update;

  end;
  mouseoff;
  if vfontin then
    vfont.done;

  draw_object^.done;
  close3d;
  application^.done;
  freemem(textfile,strlen(textfile));
  {freemem(objectinfo,512);}
  if warningsign<>nil then
    destroybitmap(warningsign);
  closegraph;
  writecon('That was ClayWorks V'+VersionStr+', (C) T.lewis 1995.$'+chr(13));
end.

unit basic3d;

INTERFACE
uses colour,twindraw;
var
{size of the colour ranges and the 'specular' size value}
rangesize:word;
specularrangesize:byte;
Const
nodeselectedcolour=yellow;
nodecolour=white;
linecolour=lightblue;
selectedlinecolour=yellow;

{////GLOBAL EFFECTS AND LIGHTING CONSTANTS/////////////}
maxranges=8;
{red, green, blue, yellow, magenta, cyan, brown, grey}
rangebasecolours:array[0..maxranges-1]of rgbtype=
( (r:31;g:0;b:0),(r:0;g:31;b:0),(r:0;g:0;b:31),(r:31;g:31;b:0),(r:31;g:0;b:31),
  (r:0;g:31;b:31),(r:31;g:16;b:0),(r:31;g:25;b:25) );
{
  rangebasecolours:array[0..maxranges-1]of rgbtype=
( (r:20;g:20;b:20),(r:0;g:4;b:20),(r:10;g:10;b:10),(r:31;g:31;b:0),(r:31;g:0;b:31),
  (r:31;g:31;b:31),(r:31;g:16;b:0),(r:25;g:25;b:25) );
 }

highlight=10;
lightcol:rgbtype=(r:64;g:64;b:64);
ambient:rgbtype=(r:2;g:2;b:4);
fog=35;
spec=1;       {precentage representing highlight value}
specoffset=1;
lightshift=16;  {16 bits for fractional part of normal vector}

{////WORLD BOUNDS//////////////////////////////////////}
maxbound=32000;
minbound=-32000;
ClipNearZ=1;
ClipFarZ=32000;

{////MAXIMUM POINTS WHEN USING ARRAYS//////////////////}
ZaverageBufSize=3000;
Maximumpoints=2300;
Maximumlines=3000;
Maximumpolys=1400;
Maxtextures=100;
Maxstars=1000;
MaximumLights=2;
Maxlights:byte=0;

{////ORIENTATION CONSTANTS/////////////////////////////}
ZY_view=0; XZ_view=1; XY_view=2; view_3d=3;
Xaxis=0;Yaxis=1;Zaxis=2;Allaxis=3;

{////SELECT MODES//////////////////////////////////////}
SMall_nodes=0;
SMselected_nodes=1;
SMobjects=2;

{////WORLD ATTRIBUTES//////////////////////////////////}
WAstars=1;
WAground=2;

{////LIGHT TYPES///////////////////////////////////////}
LTdirectional=1;
LTpoint=2;
LTconical=3;

{////OBJECT TYPES//////////////////////////////////////}
OTmesh=1;                    {all types can become a mesh}
OTsquare=2;
OTcube=3;
OTsphere=4;
OTcylinder=5;
OTcone=6;
OTgrid=7;
OTsinegrid=8;
OTtext=9;

{////OBJECT ATTRIBUTES/////////////////////////////////}
OAvisible=1;
OAselected=2;
OAMatrixDeformed=4; {object has been deformed but the change can be represented by a matrix}
OAselectable=8;
OAcamerafix=16;  {used for fixed starfields,sky's etc}
OAmoving=32;    {object's matrix to be updated by movement vector}


{////NODE ATTRIBUTES///////////////////////////////////}
NAvisible=1;
NAselected=2;
NAreserved=128; {used internally, do not set directly}

{////DELETE MODES///////////////////////////////}
DMnodes=1;
DMjoins=2;
DMpolys=4;
DMall=7;

{////COPY MODES/////////////////////////////////}
CMjoins=1;
CMpolys=2;
CMall=3;

{////EXTRUDE MODE///////////////////////////////}
XMabsolute=1;                            {simply extrudes to destination}
XMtopoint=2;                             {destination is a node}
XMbyref=3;                               {destination is a reference list}
XMcopy=4;                                {destination is ignored, a new polygon is created using CTM}
XMbevel=5;                               {edges are beveled}
XMmodemask=7;                            {masks for modes}
XMflipnormals=8;                         {special bit, if set then normals are flipped on creation}

{////POLYGON CREATION MODES/////////////////////}
PClines=1;
PCpolys=2;
PCall=3;{mask for the above two}
PCchecklines=4;   {check lines to see if they exist already}
PCcheckpolys=8;   {check polys to see if they exist already}
PCclockWise=16;   {Create the polygon in a clockwise order}

{////POLYGON SETTING VARIABLES/////////////////////////}
PAmodeFALSE=0;
PAmodeTRUE=1;
PAmodeABS=2;

{////POLYGON ATTRIBUTE FLAGS///////////////////////////}
PAclockwise=64; {phase this out -should be on creation}
PAsetmask3d=not PAclockwise;
PAallselected=512;
PAsomeselected=1024;
PAselected=PAallselected + PAsomeselected;

PAvisible=128;
PAabsolute=32;
PAconnected=16;
PAoutLined=8;
PAsmooth=2;
PAdoubleSided=1;



{////FILLER MODES//////////////////////////////////////}
CMDdots           =130;
CMDlines          =131;
CMDhlines         =132;
CMDCpolygons      =133;
CMDLsource        =135;
CMDgouraud        =136;
{1 unit = 0.7 degrees}
PersStart=500;
Pers=PersStart;

{////ASSIGNED GLOBAL VARIABLES/////////////////////////}
WAttrib:byte=0;      {global attribute byte}
nodepatt:array[0..4] of byte=(124,68,68,68,124); {pattern for nodes}
Scale:real=0.3;        {scaling value}

type

Vectorstruct=record
  x,y,z:real;
end;

polygonstruct=record
  numsides:byte;
  p:array[0..3] of word;
  colour:byte;
  attrib:byte;
end;

JoinStruct=record
  f,t:word
end;

IMPLEMENTATION

end.
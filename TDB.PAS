unit tdb;

{Pascal 3d unit by Tim Lewis (c) 1993 -Real maths version 2.0}

INTERFACE
uses
    ttypes,tmaths,SinCos,
    gbasics,ggraph,colour,
    Basic3d;


const makebig=10;
{setpolyvertex return codes}
PVnotset=0;
PVdeleted=1;
PVsetok=2;


type

NodeType=object(VectorReal)
  Nattrib:byte;
end;

NormalType=object(VectorReal)
  NodeCount:word;
end;

lightvectype=object
  f,t,uvec:VectorReal;
  procedure setlight(fx,fy,fz,tx,ty,tz:real;range:integer);
end;

vectorintsmallarray=^vectorintsmallarray_;
vectorintsmallarray_=array[0..0] of vectorintsmall;
vectorrealarray=^vectorrealarray_;
vectorrealarray_=array[0..0] of vectorreal;
NormalArray=^NormalArray_;
NormalArray_=array[0..0] of NormalType;
Nodearray=^Nodearray_;
Nodearray_=array[0..0] of NodeType;
polygonptr=^polygontype;
joinptr=^jointype;


Polygontype=object
  textureref:byte;
  numsides:byte;
  Pattrib:word;
  p:array[0..3] of word;
  norm:vectorreal;

  {norm:VectorReal;}
  procedure reverse;
  Procedure Setattrib(attrib_: word; mode: Byte);
  function anyequal(testpoly:polygonptr):boolean;
  function equals(testpoly:polygonptr):boolean;
  function allselected(thred:nodearray):boolean;
  function countselected(thred:nodearray):byte;
  function anyselected(thred:nodearray):boolean;
  function getfirstselected(thred:nodearray):byte;
  procedure normalize(thred:nodearray);
  function setpolyvertex(pvertref:byte;vertref:word):byte;
  function anyduplicates:boolean;
end;

jointype=object
  f,t:integer;
  function equals(const join:jointype):boolean;
  function allselected(thred:nodearray):boolean;
  function anyselected(thred:nodearray):boolean;
  function clockwise(thred:nodearray):boolean;
  procedure reverse;
  function insidepoly(const poly:polygontype):boolean;
end;

Texturetype=record
  specular,diffuse,ambient,palref,transparency:byte;
  Colour:RGBtype;
  texturemap,bumpmap:bitmaptypeptr;
end;


polylisttype=^polylisttype_;
polylisttype_=array[0..0] of Polygontype;
joinarray=^joinarray_;
joinarray_=array[0..0] of jointype;

objtype=^objtype_;
objtype_=object
  Oattrib:byte;
  Otype:byte;
  OtypeData:pointer;

  obmat:matrix3x4type_;

  name:string[80];

  Maxpoints,Maxjoins,Maxpolys,
  OldMaxpoints,OldMaxjoins,OldMaxpolys,
  draw_points_offset,
  draw_lines_offset,
  draw_polys_offset,
  pointsize,joinsize,polysize,maxselect,minselect:word;
  {node selection, old method UPDATE SOON!}

  select:wordarray;
  thred:Nodearray;
  tmpz:realarray;
  {Normals:vectorrealarray;}
  twod:pointtypearray;

  jointo:joinarray;

  polys:Polylisttype;
  zav:realarray;

  max,min:VectorReal;
  selcentre:VectorReal;

  constructor Create(mpnts,mjoins,mpolys:word);
  destructor Done;virtual;

  {sets the 'selected' flags in all the nodes according to 'select_'}
  Procedure ResetNodeReservedAttrib;
  Procedure setselected(select_:wordarray;size:word);
  function  intensity(Poly:polygonptr):integer;
  Procedure multmatrix(mat:matrix3x4type);virtual;
  procedure Doorth(orientation:byte;xoff,yoff:integer;scale:real);
  procedure Do3d(xoffs,yoffs:integer);

  procedure dotter;
  procedure liner;
  procedure noder(drawall:boolean);
  procedure depthsort;
  Procedure coloursort;
  procedure filler(mode:byte);
  procedure getmaxmin;
  procedure reset3d;

  Function ObjectSize(mnodes,mjoins,mpolys:word):longint;
end;



const
obspos:vectorint=(x:0;y:0;z:-PersStart);
{obsrot:vectorintsmall=(x:0;y:180;z:0);}

var
texturebank:array[0..maxtextures-1] of texturetype;
lightvec:lightvectype;
{obs_matrix:matrix3x4type;}

{lights:array[1..4]of vectorintsmall;}

matrix:matrix3x4type_;

CurrNode:^NodeType;
currtmp:^Real;
currtwod:^pointtype;

currpoly:polygonptr;
currjoin:^jointype;

Procedure init3d;
procedure close3d;

IMPLEMENTATION

Procedure init3d;
var
lop:byte;
begin
  init_sin_cos_real;
  {initialize textures}
  for lop:=0 to 15 do with texturebank[lop] do begin
    getrgb(lop,colour.r,colour.g,colour.b);
    palref:=lop;
  end;
  for lop:=0 to maxtextures-1 do with texturebank[lop] do begin
    specular:=255;
    diffuse:=200;
    ambient:=100;
    transparency:=0;
    texturemap:=nil;bumpmap:=nil
  end;
end;

procedure close3d;
begin
end;


{////POLYGON TYPE///////////////////////////}

procedure Polygontype.normalize(thred:nodearray);
var
Mat:matrix3x4type_;
lop:byte;
begin
  CalcSurfNormal(thred^[p[0]],thred^[p[1]],thred^[p[2]],norm);
  LmRotate(@mat,round(norm.x * maxangle),round(norm.y * maxangle),round(norm.z * maxangle));
  for lop:=0 to numsides-1 do begin
    thred^[p[lop]].multmatrix(@mat);
  end;
end;

function Polygontype.anyduplicates:boolean;
var i,ib:integer;
begin
  for i:=0 to numsides-1 do
     for ib:=i+1 to numsides-1 do
     begin
       if (p[ib]=p[i]) then begin anyduplicates:=true;exit;end;
     end;
     anyduplicates:=false;
end;

function Polygontype.setpolyvertex(pvertref:byte;vertref:word):byte;
var i:integer;
begin

 if (numsides<3)or(p[pvertref]=vertref)or(pvertref>3) then begin
   setpolyvertex:=PVnotset;
   exit;
 end;
 for i:=0 to numsides-1 do begin
      if (p[i]=vertref)  then begin
        move(p[pvertref+1],p[pvertref],(3-pvertref) shl 1);
        dec(numsides);
        setpolyvertex:=PVdeleted;
        exit;
      end;
 end;
 p[pvertref]:=vertref;
 setpolyvertex:=PVsetok;

end;

Procedure Polygontype.setattrib(attrib_: word; mode: Byte);
var oldselect:word;
begin
  oldselect:=pattrib and PAselected;
  case mode of
    PAmodeFALSE:pattrib:=pattrib and not word(attrib_ or PAselected);
    PAmodeTRUE:pattrib:=pattrib or word(attrib_);
    PAmodeABS:pattrib:=attrib_;
  end;
  pattrib:=pattrib or oldselect;
end;

procedure polygontype.reverse;
var pcpy:array[0..3] of word;
    lop:byte;
begin
  move(p,pcpy,numsides shl 1);
  for lop:=0 to numsides-1 do
    p[lop]:=pcpy[numsides-lop-1];
end;
function polygontype.anyequal(testpoly:polygonptr):boolean;
var lop,lop2:byte;
begin
  anyequal:=false;
  for lop:=0 to numsides-1 do
    for lop2:=0 to testpoly^.numsides-1 do
      if p[lop]=testpoly^.p[lop2] then begin
        anyequal:=true;
        exit;
      end;
end;

function polygontype.equals(testpoly:polygonptr):boolean;
var t1,t2:longint;lop:byte;
begin
  if numsides=testpoly^.numsides then begin
    t1:=0;t2:=0;
    for lop:=0 to numsides-1 do begin
      inc(t1,p[lop]);
      inc(t2,testpoly^.p[lop]);
    end;
    equals:=t1=t2;
  end else
    equals:=false;
end;

function polygontype.anyselected(thred:nodearray):boolean;
{var lop:byte;}
begin
  anyselected:=Pattrib and PAsomeselected<>0;
  {for lop:=0 to numsides-1 do
    if (thred^[p[lop]].nattrib and NAselected)<>0 then begin
      anyselected:=true;
      exit;
    end;
  anyselected:=false;}
end;

function polygontype.countselected(thred:nodearray):byte;
var lop:byte;count:byte;
begin
  if Pattrib and PAsomeselected=0 then begin
     countselected:=0;exit;
  end;
  count:=0;

  for lop:=0 to numsides-1 do
    if (thred^[p[lop]].nattrib and NAselected)<>0 then
      inc(count);
  countselected:=count;
end;

function polygontype.getfirstselected(thred:nodearray):byte;
var lop:byte;
begin


  for lop:=0 to numsides-1 do
    if (thred^[p[lop]].nattrib and NAselected)<>0 then begin
      getfirstselected:=lop;
      exit;
    end;
  getfirstselected:=255;
end;



function polygontype.allselected(thred:nodearray):boolean;
{var lop:byte;}
begin
  allselected:=Pattrib and PAallselected<>0;
  {for lop:=0 to numsides-1 do
    if thred^[p[lop]].nattrib and NaSelected=0 then begin
      allselected:=false;
      exit;
    end;
  allselected:=true;}
end;

{////JOIN TYPE////////////////////////////}
procedure jointype.reverse;
begin
  fswap(f,t,sizeof(word));
end;

function jointype.insidepoly(const poly:polygontype):boolean;
begin
  with poly do
  insidepoly:=((f=p[0])and(t=p[1]))or((t=p[0])and(f=p[1]))or
              ((f=p[1])and(t=p[2]))or((t=p[1])and(f=p[2]))or
              ((f=p[2])and(t=p[3]))or((t=p[2])and(f=p[3]))or
              ((f=p[3])and(t=p[0]))or((t=p[3])and(f=p[0]));
end;

function jointype.equals(const join:jointype):boolean;
begin
  equals:=((join.f=f)and(join.t=t))or((join.f=t)and(join.t=f));
end;

function jointype.allselected(thred:nodearray):boolean;
begin
  allselected:=((thred^[f].nattrib and NaSelected)=NaSelected) and ((thred^[t].nattrib and Naselected)=NaSelected);
end;

function jointype.anyselected(thred:nodearray):boolean;
begin
  anyselected:=((thred^[f].nattrib and NaSelected)=NaSelected) or ((thred^[t].nattrib and NaSelected)=NaSelected);
end;

function jointype.clockwise(thred:nodearray):boolean;
begin

end;

{////LIGHT VECTOR/////////////////////////////}

Procedure lightvectype.setlight(fx,fy,fz,tx,ty,tz:real;range:integer);
begin
  f.moveto(fx,fy,fz);
  t.moveto(tx,ty,tz);

  uvec.moveto(f.x-t.x,f.y-t.y,f.z-t.z);
  uvec.unitvec(range);
end;

{////OBJTYPE////////////////////////////////////////}


function objtype_.intensity(Poly:polygonptr):integer;
Var u:VectorReal;
Begin
  with poly^ do
    CalcSurfNormal(thred^[p[1]],thred^[p[0]],thred^[p[2]],U);
  intensity:=((SC.colourdepth-1) shr 1)+round(dot(u,lightvec.uvec));
end;

procedure FSwap(Var s,d; L:Integer);
Begin
  Inline($1e /$c5/$b6/s /$c4/$be/d /$8b/$8e/l /$fc /$26/$8a/$05
         /$86/$04 /$46 /$aa /$e2/$f7 /$1f);
end;

{clear the reserved field in the nodes}
Procedure objtype_.ResetNodeReservedAttrib;
var
i:word;
begin
  for i:=0 to maxpoints-1 do with thred^[i] do
    nattrib:=nattrib and not (NAreserved);

end;

constructor objtype_.Create(mpnts,mjoins,mpolys:word);
Begin
  name:='';
  LmUnit(@ObMat);

  pointsize:=mpnts;joinsize:=mjoins;polysize:=mpolys;
  maxpoints:=0;maxjoins:=0;maxpolys:=0;
  oldmaxpoints:=0;oldmaxjoins:=0;oldmaxpolys:=0;
  maxselect:=0;
  minselect:=0;
  draw_points_offset:=0;
  draw_lines_offset:=0;
  draw_polys_offset:=0;


  getmem(tmpz,pointsize*sizeof(Real));
  {getmem(Normals,pointsize*sizeof(NormalType));}
  getmem(thred,pointsize*sizeof(NodeType));
  getmem(select,pointsize*sizeof(word));

  getmem(jointo,joinsize*sizeof(jointype));
  getmem(polys,polysize*sizeof(polygontype));
  getmem(twod,pointsize*sizeof(pointtype));
  getmem(zav,polysize*sizeof(real));
  max.moveto(0,0,0);
  min:=max;
end;

Destructor objtype_.Done;
Begin
  freemem(tmpz,pointsize*sizeof(Real));
  {freemem(Normals,pointsize*sizeof(NormalType));}
  freemem(select,pointsize*sizeof(word));
  freemem(thred,pointsize*sizeof(NodeType));
  freemem(jointo,joinsize*sizeof(jointype));
  freemem(polys,polysize*sizeof(polygontype));
  freemem(twod,pointsize*sizeof(pointtype));
  freemem(zav,polysize*sizeof(real));
end;

procedure objtype_.multmatrix(mat:matrix3x4type);
var lop:word;
begin
  if maxselect>0 then begin
    for lop:=0 to maxselect-1 do
      Thred^[select^[lop]].multmatrix(mat);
    getmaxmin;
  end;
end;

procedure objtype_.do3d;
var lop:word;
    {domat:matrix3x4type_;}
Begin
  with obmat do begin
    obmat.p.sub(obspos.x,obspos.y,obspos.z);
    Currtmp:=pointer(tmpz);
    inc(currtmp,draw_points_offset);
    CurrNode:=pointer(thred);
    inc(CurrNode,draw_points_offset);
    currtwod:=pointer(twod);
    inc(currtwod,draw_points_offset);

    For lop:=0 to maxpoints-1-draw_points_offset do begin
      with CurrNode^ do begin
        currtmp^:=(m02*x + m12*y + m22*z + p.z);
        if currtmp^<=0 then currtmp^:=1;
        {there is an error here}
        currtwod^.x:=trunc((m00*x + m10*y + m20*z + p.x) /currtmp^ *pers)+xoffs;
        currtwod^.y:=trunc((m01*x + m11*y + m21*z + p.y) /currtmp^ *pers)+yoffs;
      end;
      inc(CurrNode);
      inc(currtmp);
      inc(currtwod);
    end;
    obmat.p.add(obspos.x,obspos.y,obspos.z);
  end;
end;

Procedure objtype_.coloursort;
Procedure sort(l,r:integer);
var lop1,lop2:integer;lop3:integer;
Begin
  lop1:=l; lop2:=r; lop3:=polys^[(l+r) shr 1].textureref;
  repeat
    while polys^[lop1].textureref<lop3 do inc(lop1);
    while lop3<polys^[lop2].textureref do dec(lop2);
    if lop1<=lop2 then
    Begin
      fswap(polys^[lop1],polys^[lop2],sizeof(polygontype));
      inc(lop1);dec(lop2);
    end;
  until lop1>lop2;
  if l<lop2 then sort(l,lop2);
  if lop1<r then sort(lop1,r);
end;
begin
 sort(0,maxpolys-1);
end;


Procedure objtype_.depthsort;
Procedure sort(l,r:integer);
var lop1,lop2:integer;lop3:real;

Begin
  lop1:=l; lop2:=r; lop3:=zav^[(l+r) shr 1];
  repeat
    while zav^[lop1]<lop3 do inc(lop1);
    while lop3<zav^[lop2] do dec(lop2);
    if lop1<=lop2 then
    Begin
      fswap(zav^[lop1],zav^[lop2],sizeof(real));
      fswap(polys^[lop1],polys^[lop2],sizeof(polygontype));
      inc(lop1);dec(lop2);
    end;
  until lop1>lop2;
  if l<lop2 then sort(l,lop2);
  if lop1<r then sort(lop1,r);
end;
var lop:word;lopb:byte;
Begin
 For lop:=0 to maxpolys-1 do with polys^[lop] do begin
   zav^[lop]:=0;
   if numsides>0 then begin
     for lopb:=0 to numsides-1 do
       zav^[lop]:=zav^[lop]+tmpz^[p[lopb]];
     zav^[lop]:=-(zav^[lop] / numsides);
   end;
 end;
 sort(0,maxpolys-1);
end;

procedure objtype_.filler(mode:byte);
Var
lop2,oldcol,testattrib,shademode,amask:byte;facetowards:boolean;
dx1,dy1,dx2,dy2:integer;
lop:word;
i:array[0..3]of byte;
pn:array[0..3] of pointtype;
Begin
  if (maxpolys>0)then begin
    depthsort;
    oldcol:=t_fillcol;
    currpoly:=pointer(polys);
    case mode of
      CMDLsource:begin amask:=byte(not PAsmooth);shademode:=0;end;
      CMDgouraud:begin amask:=byte(not PAsmooth);shademode:=PAsmooth;end;
      CMDhlines:begin amask:=255;shademode:=PAoutlined+PAconnected;end;
      else begin amask:=255;shademode:=0;end;
    end;
    For lop:=0 to maxpolys-1 do with currpoly^,texturebank[textureref] do begin
      for lop2:=0 to 3 do begin
        pn[lop2].x:=twod^[p[lop2]].x;
        pn[lop2].y:=twod^[p[lop2]].y;
      end;
      dx1:=pn[1].x-pn[0].x;
      dy1:=pn[1].y-pn[0].y;
      dx2:=pn[2].x-pn[0].x;
      dy2:=pn[2].y-pn[0].y;
      facetowards:=(pattrib and PaDoubleSided<>0) or((dx1 * dy2) > (dx2 * dy1));
      if (facetowards) then begin
        testattrib:=(Pattrib and amask)or Shademode;
        if numsides=2 then begin
          t_col:=palref;
          line(pn[0].x,pn[0].y,pn[1].x,pn[1].y);
        end else if (testattrib and PaOutlined<>0) then begin
          t_col:=palref;
          {if not facetowards then setlinepattern(136,false);}
          for lop2:=0 to numsides-2 do
            line(pn[lop2].x,pn[lop2].y,pn[lop2+1].x,pn[lop2+1].y);
          if testattrib and PaConnected<>0 then
            line(pn[numsides-1].x,pn[numsides-1].y,pn[0].x,pn[0].y);
          {setlinepattern(255,false);}
        end else if testattrib and PaAbsolute<>0 then begin
          t_fillcol:=palref;
          triangle(pn[0].x,pn[0].y,pn[1].x,pn[1].y,pn[2].x,pn[2].y);
          if numsides>3 then triangle(pn[0].x,pn[0].y,pn[3].x,pn[3].y,pn[2].x,pn[2].y);
        end else if Testattrib and PaSmooth<>0 then begin
          for lop2:=0 to numsides-1 do begin
            i[lop2]:=palref+lop2{intensity(n,addval,colour,Pattrib)};
          end;
          Gtriangle(pn[0].x,pn[0].y,pn[1].x,pn[1].y,pn[2].x,pn[2].y,i[0],i[1],i[2]);
          if numsides>3 then Gtriangle(pn[0].x,pn[0].y,pn[3].x,pn[3].y,pn[2].x,pn[2].y,i[0],i[3],i[2]);
        end else begin
          t_fillcol:=palref;
          triangle(pn[0].x,pn[0].y,pn[1].x,pn[1].y,pn[2].x,pn[2].y);
          if numsides>3 then triangle(pn[0].x,pn[0].y,pn[3].x,pn[3].y,pn[2].x,pn[2].y);
        end;
      end;
      inc(currpoly)
    end;
    t_fillcol:=oldcol;
  end;
end;

procedure objtype_.doorth(orientation:byte;xoff,yoff:integer;scale:real);
var lop,maxlimit:word;
begin
  maxlimit:=maxpoints-1-draw_points_offset;
  currtwod:=pointer(twod);
  inc(currtwod,draw_points_offset);
  CurrNode:=pointer(thred);
  inc(CurrNode,draw_points_offset);
    case orientation of
      XY_view:For lop:=0 to maxlimit do with currtwod^ do begin
        x:=round(CurrNode^.x*scale)+xoff;
        y:=round(CurrNode^.y*scale)+yoff;
        inc(currtwod);
        inc(CurrNode);
      end;
      ZY_view:For lop:=0 to maxlimit do with currtwod^ do begin
        x:=round(CurrNode^.z*scale)+xoff;
        y:=round(CurrNode^.y*scale)+yoff;
        inc(currtwod);
        inc(CurrNode);
      end;
      XZ_view:For lop:=0 to maxlimit do with currtwod^ do begin
        x:=round(CurrNode^.x*scale)+xoff;
        y:=round(CurrNode^.z*scale)+yoff;
        inc(currtwod);
        inc(CurrNode);
      end;
    end;
end;

procedure objtype_.liner;
var lop:word;
Begin
  if draw_lines_offset<maxjoins then begin
  currjoin:=pointer(jointo);
  inc(currjoin,draw_lines_offset);
  {setselected(@select,maxselect);}
  For lop:=0 to maxjoins-1-draw_lines_offset do begin
    with currjoin^ do begin
      {if allselected(@thred) then
         t_col:=selectedlinecolour
      else
         t_col:=linecolour;}

      line(twod^[f].x,twod^[f].y,twod^[t].x,twod^[t].y);
    end;
    inc(currjoin);
  end;
  end;
end;

procedure objtype_.dotter;
var lop:word;
Begin
  currtwod:=pointer(twod);
  inc(currtwod,draw_points_offset);
  For lop:=0 to maxpoints-1-draw_points_offset do begin
    with currtwod^ do putpixel(x,y);
    inc(currtwod);
  end;
end;

procedure objtype_.noder(drawall:boolean);
var lop:word;
Begin
  {t_col:=nodeselectedcolour;}
  t_col:=nodecolour;
  if (drawall) then begin

    currtwod:=pointer(twod);
    currnode:=pointer(thred);
    inc(currtwod,draw_points_offset);
    For lop:=0 to maxpoints-1-draw_points_offset do begin
      {if currnode^.nattrib and NAselected=0 then}
            with currtwod^ do drawbytes(x-3,y-2,@nodepatt,5);
      inc(currtwod);
      inc(currnode);
    end;
  end else
  if maxselect>0 then
    For lop:=0 to maxselect-1 do begin
      with twod^[select^[lop]] do drawbytes(x-3,y-2,@nodepatt,5);
    end;
end;

Procedure objtype_.Getmaxmin;
var lop:word;
    tmpmat:matrix3x4type;
    oldmin,oldmax:VectorReal;
const
  big=6400000;

Begin
  if maxselect>0 then Begin
    oldmin:=min; oldmax:=max;
    min.moveto(big,big,big);
    max.moveto(-big,-big,-big);
    For lop:=0 to maxselect-1 do Begin
      if thred^[select^[lop]].x>max.x then max.x:=thred^[select^[lop]].x;
      if thred^[select^[lop]].y>max.y then max.y:=thred^[select^[lop]].y;
      if thred^[select^[lop]].z>max.z then max.z:=thred^[select^[lop]].z;
      if thred^[select^[lop]].x<min.x then min.x:=thred^[select^[lop]].x;
      if thred^[select^[lop]].y<min.y then min.y:=thred^[select^[lop]].y;
      if thred^[select^[lop]].z<min.z then min.z:=thred^[select^[lop]].z;
    End;
    selcentre:=max;
    selcentre.sub(min.x,min.y,min.z);
    selcentre.divide(2);
  end;
End;

Procedure objtype_.setselected(select_:wordarray;size:word);
var lop:word;
begin
  if size=0 then exit;
  maxselect:=size;
  move(select_^,select^,maxselect shl 1);
  for lop:=0 to maxpoints-1 do with thred^[lop] do
    Nattrib:=Nattrib and not NaSelected;
  for lop:=0 to maxselect-1 do with thred^[select^[lop]] do
    Nattrib:=Nattrib or NaSelected;
end;

Function ObjType_.ObjectSize(mnodes,mjoins,mpolys:word):longint;
var size:longint;
begin
  size:=0;
  inc(size,(sizeof(vectorstruct))*mnodes);
  inc(size,sizeof(joinstruct)*mjoins);
  inc(size,sizeof(polygonstruct)*mpolys);
  inc(size,6);
  ObjectSize:=Size;
end;

procedure objtype_.reset3d;
begin
  oldmaxpoints:=maxpoints;
  oldmaxjoins:=maxjoins;
  oldmaxpolys:=maxpolys;
  maxselect:=0;
  maxpoints:=0;
  maxjoins:=0;
  maxpolys:=0;
end;

end.

Unit Tdeditb;
{$X+}{$g+}{$a+}
{Pascal 3d edting unit by Tim Lewis (c) 1996 -Real maths version 2.0}
{Please note that all window referenceing operations are performed on
'edit_view', a pointer to the currently selected 'delta_3d' view}

INTERFACE
uses
  ttypes,Diskop,tmaths,msmouse,SinCos,
  gbasics,ggraph,vectfont,colour,
  Basic3d,tdb,crt2;

{////GLOBALS///////////////////////////////////}
const
edit_orientation:byte=0;

{////ERROR LEVELS//////////////////////////////}
ERRnone=0;
ERRnovectors=1;
ERRnojoins=2;
ERRnopolys=3;
ERRnotselected=4;
ERRfileerror=5;
ERRoneselected=6;
ERRparseerror=7;
ERRlineexists=100;
ERRpolygonexists=101;
ErrorLevel:word=ERRnone;
loadscale:real=1;

{////SELECTION LIST/////////////////////////////}
SMnewlist=0;
SMaddtolist=1;
SMcutfromlist=2;
SMintersect=3;


{////DRAWING MODE///////////////////////////////}
render_mode:word=CMDlines;
maxrotate:real=2*pi;

{///COLOUR INDEXS///////////////////////////////}
fgtexture:byte=15;
bktexture:byte=0;
crs:VectorReal=(x:0;y:0;z:0);

{////DATA TYPES : USED IN PARSING///////////////}
DTstring=1;
DTreal=2;
DTint=3;

CurrFile_Version=1;
CurrFile_Header:array[0..5] of char=('C','L','A','Y','T','L');

var
CTM:matrix3x4type;

Type

ClayFileheader=record
  header:array[0..5]of char;
  version:byte;
  maxtextures:byte;
  maxpoints,maxjoins,maxpolys:word;
  filler:array[0..64-15]of byte;
end;

MatrixElem=^MatrixElem_;
MatrixElem_=object(belem)
  Mat:matrix3x4type_;
end;
tokenstring=string[30];

longintlist=^longintlist_;
longintlist_=object(belem)
  data:longint;
end;

prototype=^prototype_;
prototype_=object(belem)
  name:tokenstring;
  bufpos:longint;
end;

tokentype=^tokentype_;
tokentype_=object(belem)
  token:tokenstring;
end;

realrgb=record
  r,g,b:real;
end;

edit_objtype=^edit_objtype_;
edit_objtype_=object(objtype_)
  Function  getnode(id:byte;xps,yps:integer;getselected:boolean):integer;
  Function  getselectlist(id:byte;R:trect;selmode:byte):boolean;
  procedure selectall;
  procedure selectconnected(noderef:word);
  Function getselectlistconnected(id:byte;R:trect):boolean;
  function getallconnectedpolygons(poly:polygonptr):linkedlistptr;
  procedure selectnode(noderef:word);
  procedure selectpoly(polyref:word);
  procedure clearselection;
  procedure calcselectedpolys;
  function counttriangles:integer;

  Procedure copyobj(copymode:byte;extrude,reselect:boolean);
  Procedure copypoint(dot:word);

  Procedure addvector(xa,ya,za:real);
  procedure addjoin(dot1,dot2:word);
  procedure addjoincheck(dot1,dot2:word);
  procedure addpolygon(startp,count:word;attrib_:byte;mode:word);
  procedure addpolygonByRef(startp:wordarray;count:word;attrib_:byte;mode:word);
  procedure addquad(p1,p2,p3,p4:word;attrib_:word);
  procedure addtriangle(p1,p2,p3:word;attrib_:word);
  procedure addline(p1,p2:word;attrib_:word);
  procedure connect(p1,p2,count:word;attrib_:byte;connectup:boolean);
  Procedure connectbyref(p1:word;list:wordarray;count:word;attrib:byte);
  Procedure ConnectPoint(p1,point,count:word;attrib_:byte);

  procedure delete_select(whattodel:byte);
  procedure deletejoin(lineno:word);
  procedure deletepoly(polyno:word);
  procedure merge;
  {procedure deleteduplicatereferences(var p:polygontype);}
  Procedure flip(direction:byte);

  Procedure FlipSelectedNormals;
  Procedure SetSelectedTexture(textureref_:byte);
  Procedure SetSelectedAttrib(attrib_: word; mode: byte);

  Procedure QuadDivideSelected;
  Procedure TriangulateSelected;
  procedure TriangulatePoly(polyref:word;from_p:byte);
  procedure splitpolygons;
  procedure mktext(x1,y1,z1:real;txt:string;var vfont:font_type);
  Procedure mkcircle(cx,cy,rx,ry,z1:real;stp:word;startangle:real;mode:byte;attrib_:byte);
  Procedure mksquare(x1,y1,x2,y2,z1:real;attrib_:byte);
  procedure mkcylinder(cx,cy,rx1,ry1,rx2,ry2,z1,z2:real;stp:word;startangle:real;attrib_:byte);
  Procedure mksphere(cx,cy,cz,rx,ry,rz:real;stp,stpz:word;startangle:real;attrib_:byte);
  procedure mkcone(cx,cy,rx,ry,z1,z2:real;stp:word;startangle:real;attrib_:byte);
  procedure mkcube(x1,y1,z1,x2,y2,z2:real;attrib_:byte);
  procedure mkgrid(x1,y1,x2,y2,z1:real;xstp,ystp:word;sineornot,checkornot:boolean;attrib_:byte);
  Procedure mkgridfrompic(x1,y1,x2,y2,z1:real;pic:bitmaptypeptr;checkornot:boolean;attrib_:byte);
  procedure rotateobj(axis:byte;stp,attrib:byte);
  procedure extrudepath(path:objtype;attrib:byte;extrude:boolean);
  procedure splitline(line:word);

  procedure readgor(filename:string;append:boolean);
  procedure readVTek(filename:string);
  procedure read3d(filename:string;append:boolean);
  procedure readEAfile(filename:string);
  procedure readOBJ(filename:string);
  Procedure readGEO(filename:string);
  procedure readRW(filename:string);
  procedure readVRML(filename:string);

  procedure writegor(filename:string);
  procedure writeVRML(filename:string);
  procedure writejava(filename:string);
  procedure write3d(filename:string);
  procedure writePLG(filename:string);
  procedure writeSG(filename:string);
  procedure writeRW(filename:string);
  procedure writePOV(filename:string);
  procedure writeOBJ(filename:string);
  Procedure writeGEO(filename:string);
  procedure write3ds(filename:string);
  procedure write3dsasc(filename:string);
  procedure writeCOBasc(filename:string);
end;

Procedure conv2d_3d(id:byte;xp,yp:real;filter,dot:VectorRealptr);
Procedure conv3d_2d(id:byte;dot:VectorRealptr;var x,y:integer);

IMPLEMENTATION
function createMATRIX(const mat:matrix3x4type):matrixelem;
var newmat:matrixelem;
begin
  getmem(newmat,sizeof(matrixelem_));
  newmat^.mat:=mat^;
  createMATRIX:=newmat;
end;

function createTOKEN(const token:tokenstring):tokentype;
var newtoken:tokentype;
begin
  getmem(newtoken,sizeof(tokentype_));
  newtoken^.token:=token;
  createTOKEN:=newtoken;
end;

function createPROTOTYPE(const protoname:tokenstring;filepos:longint):prototype;
var newproto:prototype;
begin
  getmem(newproto,sizeof(prototype_));
  newproto^.name:=protoname;
  newproto^.bufpos:=filepos;
  createPROTOTYPE:=newproto;
end;
function createLONGINT(data:longint):longintlist;
var newlongint:longintlist;
begin
  getmem(newlongint,sizeof(longintlist_));
  newLONGINT^.data:=data;
  createLONGINT:=newlongint;
end;

{This will take a 2d point and convert it to 3d space, the missing
axis (x,y or z) being in the apropriate position in 'filter'.
Scaling (via the global real 'scale') IS performed}

Procedure conv2d_3d(id:byte;xp,yp:real;filter,dot:VectorRealPtr);
Begin
  xp:=xp/scale;
  yp:=yp/scale;
  with dot^ do
  case id of
    XY_view:moveto(xp,yp,filter^.z);
    XZ_view:moveto(xp,filter^.y,yp);
    ZY_view:moveto(filter^.x,yp,xp);
  End;
End;

{This will parallel project from (real) 3d to (integer)2d along
x/y, z/y or x/z depending on 'id'. Scaling is performed using
the global 'scale'
}

Procedure conv3d_2d(id:byte;dot:VectorRealPtr;var x,y:integer);
Begin
  case id of
    XY_view:Begin x:=round(dot^.x*scale);y:=round(dot^.y*scale);End;
    XZ_view:Begin x:=round(dot^.x*scale);y:=round(dot^.z*scale);End;
    ZY_view:Begin x:=round(dot^.z*scale);y:=round(dot^.y*scale);End;
  end;
End;

{////EDIT_OBJTYPE///////////////////////////////}


Procedure edit_objtype_.copyobj(copymode:byte;extrude,reselect:boolean);
{var retcopy:edit_objtype;}
var lop,oldmax,oldmaxp:word;
    oldtexture:byte;

function getspos(node:word):word;
var sublop:word;
begin
  {if maxselect<oldmaxp-1 then begin}
    sublop:=0;
    while (select^[sublop]<>node) and (sublop<maxselect) do
      inc(sublop);
  {end else
    sublop:=node;}

  getspos:=sublop+oldmaxp;
end;

Begin
  if maxselect=0 then begin
    ErrorLevel:=ERRnotselected;
  end else begin
    oldmaxp:=maxpoints;
    if Extrude then
      connectbyref(maxpoints,select,maxselect,0);
    if errorlevel>ERRnone then exit;

    for lop:=0 to maxselect-1 do
      copypoint(select^[lop]);
    oldmax:=maxjoins;
    if (copymode and CMjoins<>0)and(maxjoins>0) then
    for lop:=0 to oldmax-1 do with jointo^[lop] do
      if (thred^[f].Nattrib and Naselected<>0) and (thred^[t].Nattrib and Naselected<>0) then begin
        {fgtexture:=colour;}
        addjoin(getspos(f),getspos(t));
      end;
    if errorlevel>ERRnone then exit;
    oldmax:=maxpolys;
    if (copymode and CMpolys<>0)and(maxpolys>0) then begin
      oldtexture:=fgtexture;
      for lop:=0 to oldmax-1 do with polys^[lop] do
        if allselected(thred) then begin
          fgtexture:=textureref;
          case numsides of
            2:addline(getspos(p[1]),getspos(p[0]),pattrib and PAsetmask3d);
            3:addtriangle(getspos(p[2]),getspos(p[1]),getspos(p[0]),pattrib and PAsetmask3d);
            4:addquad(getspos(p[3]),getspos(p[2]),getspos(p[1]),getspos(p[0]),pattrib and PAsetmask3d);
          end;
        end;
      fgtexture:=oldtexture;
    end;
    {select new points}
    if reselect then
    for lop:=0 to maxselect-1 do begin
      with thred^[select^[lop]] do Nattrib:=Nattrib and not NaSelected;
      select^[lop]:=oldmaxp+lop;
      with thred^[oldmaxp+lop] do Nattrib:=Nattrib or NaSelected;
    end;
    calcselectedpolys;
  end;
end;

{splits a lines and any related faces}
Procedure edit_objtype_.splitline(line:word);
var

newvec:vectorreal;
count:integer;
lop:byte;
join:joinptr;
begin
  join:=@jointo^[line];
  newvec:=thred^[join^.f];
  with thred^[join^.t] do
    newvec.add(x,y,z);
  newvec.divide(2);

  addvector(newvec.x,newvec.y,newvec.z);
  addjoin(join^.f,maxpoints-1);
  addjoin(maxpoints-1,join^.t);
  count:=maxpolys-1;
  while (count>=0) do begin
    if jointo^[line].insidepoly(polys^[count]) then with polys^[count] do begin
      lop:=0;
      while (p[lop]<>join^.f)or(p[lop]<>join^.t) do
        inc(lop);
      {split up faces here! do it tomorrow}
      count:=maxpolys;
    end;
    dec(count);
  end;


end;


Procedure edit_objtype_.quaddivideselected;
Var lop,lop2,sublop:word;
    pointlop:byte;
    new:vectorreal;
    oldtexture:byte;
begin
  if (maxpolys>0) then begin
    CTM:=@unitmatrix;
    for lop:=0 to maxpolys-1 do with polys^[lop] do
    if (allselected(thred))and(numsides>2) then begin
      oldtexture:=fgtexture;
      fgtexture:=textureref;
      if (numsides=4) then begin
        lop2:=0;
        while (lop2<maxjoins)and(maxjoins>=0) do begin {delete affected lines}
          if jointo^[lop2].insidepoly(polys^[lop]) then
            deletejoin(lop2)
          else
            inc(lop2);
        end;
        new.moveto(0,0,0);
        for pointlop:=0 to 3 do with thred^[p[pointlop]] do
          new.add(x,y,z);
        new.divide(4);
        with new do begin
          {sub(x,y,z);}
          addvector(x,y,z);
        end;

        for pointlop:=0 to 2 do begin
          new:=thred^[p[pointlop]];
          with thred^[p[pointlop+1]] do
            new.add(x,y,z);
          new.divide(2);
          with new do
            addvector(x,y,z);
        end;
        new:=thred^[p[3]];
        with thred^[p[0]] do
          new.add(x,y,z);
        new.divide(2);
        with new do
          addvector(x,y,z);
        addjoincheck(maxpoints-1,maxpoints-5);
        addjoincheck(maxpoints-5,maxpoints-3);
        addjoincheck(maxpoints-4,maxpoints-5);
        addjoincheck(maxpoints-5,maxpoints-2);


        addjoincheck(p[0],maxpoints-4);
        addjoincheck(maxpoints-4,p[1]);
        addjoincheck(p[1],maxpoints-3);
        addjoincheck(maxpoints-3,p[2]);
        addjoincheck(p[2],maxpoints-2);
        addjoincheck(maxpoints-2,p[3]);
        addjoincheck(p[3],maxpoints-1);
        addjoincheck(maxpoints-1,p[0]);

        addquad(maxpoints-4,p[1],maxpoints-3,maxpoints-5,pattrib or PaClockWise);
        addquad(maxpoints-5,maxpoints-3,p[2],maxpoints-2,pattrib or PaClockWise);
        addquad(maxpoints-1,maxpoints-5,maxpoints-2,p[3],pattrib or PaClockWise);
        p[1]:=maxpoints-4;
        p[2]:=maxpoints-5;
        p[3]:=maxpoints-1;
      end;
      fgtexture:=oldtexture;
    end;
  end
    else ErrorLevel:=ERRnotselected;
end;

procedure edit_objtype_.TriangulatePoly(polyref:word;from_p:byte);
var oldtexture:byte;
    to_p:byte;
begin
  with polys^[polyref] do begin
  oldtexture:=fgtexture;
  fgtexture:=textureref;
  if (numsides>3) then begin
    to_p:=(from_p +2) mod numsides;
    from_p:=from_p mod numsides;
    addjoincheck(p[from_p],p[to_p]);
    addtriangle(p[from_p],p[(from_p+1)mod numsides],p[to_p],pattrib or PaClockWise or Paallselected);

    numsides:=3;
    p[0]:=from_p;
    p[1]:=to_p;
    p[2]:=(to_p +1 ) and 3;


    fgtexture:=oldtexture;
  end;
  end;
end;

procedure edit_objtype_.splitpolygons;
var lop:word;
    selected:byte;
begin
  if (maxpolys>0)and(maxselect>0)and(maxselect<3) then begin
     for lop:=0 to maxpolys do with polys^[lop] do if numsides=4 then begin

         selected:=GetFirstSelected(thred);
         if selected<>255 then begin
           {if thred^[p[selected+2]].nattrib and NAselected<>0 then begin}
              triangulatepoly(lop,selected);
           {end;}
         end else begin
           {sound(100);delay(10);nosound;}
         end;

     end;

  end else
    ErrorLevel:=ERRnotselected;
end;

Procedure edit_objtype_.Triangulateselected;
Var lop:word;
    oldtexture:byte;
begin
  if maxpolys>0 then begin
    CTM:=@unitmatrix;
    for lop:=0 to maxpolys-1 do with polys^[lop] do
    if (allselected(thred))and(numsides=4) then begin
      oldtexture:=fgtexture;
      fgtexture:=textureref;
      addjoincheck(p[1],p[3]);
      addtriangle(p[1],p[2],p[3],pattrib or PaClockWise or Paallselected);

      numsides:=3;
      p[2]:=p[3];
      p[3]:=0;
      fgtexture:=oldtexture;
    end;
  end else
    ErrorLevel:=ERRnotselected;
end;

Procedure edit_objtype_.connectbyref(p1:word;list:wordarray;count:word;attrib:byte);
Var lop:word;
    pf,pt:word;

function getspos(node:word;var pos:word):boolean;
var
    found:boolean;
begin
  pos:=0;
  found:=false;
  while (not found) and (pos<maxselect) do begin
    found:=select^[pos]=node;
    inc(pos);
  end;
  dec(pos);
  inc(pos,maxpoints);
  getspos:=found;
end;

Begin
  For lop:=0 to count-1 do
    addjoin(p1+lop,list^[lop]);
  For lop:=0 to maxjoins-2 do with jointo^[lop] do begin
    if (allselected(thred))and(getspos(f,pf))and(getspos(t,pt)) then begin
      addquad(pf,pt,t,f,attrib);
    end;
  end;

End;

Procedure edit_objtype_.copypoint(dot:word);
Begin
  addvector(thred^[dot].x,thred^[dot].y,thred^[dot].z);
End;

Function edit_objtype_.getnode(id:byte;xps,yps:integer;getselected:boolean):integer;
const border=3;
var lop:word;ans:integer;chk:pointtype;
Begin
lop:=0;ans:=-1;
while (ans=-1) and (lop<maxpoints) do
Begin
   conv3d_2d(id,@thred^[lop],chk.x,chk.y);
   with chk do
   if (xps>x-border) and (xps<x+border)  and
      (yps<y+border) and (yps>y-border) and
      (((getselected) and (thred^[lop].Nattrib and NaSelected<>0))or not getselected) then ans:=lop;
   inc(lop);
End;
getnode:=ans;
End;{of function}

Procedure edit_objtype_.addvector(xa,ya,za:real);
begin
  if maxpoints<pointsize then
    with thred^[maxpoints] do begin
      moveto(xa,ya,za);
      multmatrix(CTM);
      Nattrib:=0;
      inc(maxpoints);
    end
  else
    ErrorLevel:=ERRnovectors;
end;

{this routine is the basis of 2d-to-3d operations.
Scale factors and cursor position are taken into account.
Always draws in X/Y. The CTM can rotate and translate into
any other orientation in the routines 'addvector'
}
procedure edit_objtype_.addjoin(dot1,dot2:word);
begin
  if (maxjoins<joinsize) then begin
    with jointo^[maxjoins] do begin
      f:=dot1;
      t:=dot2;
    end;
    inc(maxjoins);
  end else
    ErrorLevel:=ERRnoJoins;
end;

procedure edit_objtype_.addjoincheck(dot1,dot2:word);
var exists:boolean;
    lop:word;
    newjoin:jointype;
begin
  lop:=0;
  exists:=false;
  with newjoin do begin
    f:=dot1;
    t:=dot2;
  end;
  while (lop<maxjoins)and(not exists) do begin
    exists:=jointo^[lop].equals(newjoin);
    inc(lop);
  end;
  if not exists then begin
    if (maxjoins<joinsize) then begin
      jointo^[maxjoins]:=newjoin;
      inc(maxjoins);
    end else
      ErrorLevel:=ERRnoJoins;
  end;
end;

procedure edit_objtype_.addpolygon(startp,count:word;attrib_:byte;mode:word);
var lop:word;

{checks if a horizontal line ( x to inf.,y) intersects xa,ya to xb,yb)}
function intersect(x,y,xa,ya,xb,yb:integer):boolean;
begin
  if ya>yb then begin fswap(ya,yb,2);fswap(xa,xb,2);end;
  intersect:=(y>=ya)and(y<=yb)and((x>=xa)or(x>=xb));
end;




begin
  if mode and PClines<>0 then begin
    for lop:=0 to count-2 do
      if mode and PCchecklines<>0 then
        addjoincheck(startp+lop,startp+lop+1)
      else
        addjoin(startp+lop,startp+lop+1);
    if attrib_ and PaConnected<>0 then
      if mode and PCchecklines<>0 then
        addjoincheck(startp+count-1,startp)
      else
        addjoin(startp+count-1,startp);
  end;
  if mode and PCpolys<>0 then
    if count=2 then
      addline(startp,startp+1,attrib_)
    else begin
      if count>3 then begin
        for lop:=0 to (count shr 1)-2 do
          addquad(startp+lop,startp+lop+1,startp+count-lop-2,startp+count-lop-1,attrib_);
        inc(lop);
      end else
        lop:=0;
      inc(lop,startp);
      if (count mod 2)=1 then
        addtriangle(lop,lop+1,lop+2,attrib_);
    end;
end;

procedure edit_objtype_.AddPolygonByRef(startp:wordarray;count:word;attrib_:byte;mode:word);
var lop:word;
begin
  if mode and PClines<>0 then begin
    for lop:=0 to count-2 do
      if mode and PCchecklines<>0 then
        addjoincheck(startp^[lop],startp^[lop+1])
      else
        addjoin(startp^[lop],startp^[lop+1]);

    if attrib_ and PaConnected<>0 then
      if mode and PCchecklines<>0 then
        addjoincheck(startp^[count-1],startp^[0])
      else
        addjoin(startp^[count-1],startp^[0])
  end;
  if mode and PCpolys<>0 then begin
    if count=2 then
      addline(startp^[count-1],startp^[count-2],attrib_)
    else begin
      if count>3 then begin
        for lop:=0 to (count shr 1)-2 do begin
          addquad(startp^[lop],startp^[1+lop],startp^[count-lop-2],startp^[count-lop-1],attrib_);
          {with polys^[maxpolys-1] do
            if allselected(@thred) then pattrib:=pattrib or PAallselected; }
        end;
        inc(lop);
      end else
        lop:=0;
      if (count mod 2)=1 then begin
        addtriangle(startp^[lop],startp^[lop+1],startp^[lop+2],attrib_);
        {with polys^[maxpolys-1] do
            if allselected(@thred) then pattrib:=pattrib or PAallselected;}
      end;
    end;
    calcselectedpolys;

  end;
end;



Procedure edit_objtype_.addquad(p1,p2,p3,p4:word;attrib_:word);
Begin
  if maxpolys<polysize then
    with polys^[maxpolys] do begin
      textureref:=fgtexture;
      numsides:=4;
      pattrib:=attrib_ and PAsetmask3d;


      if (attrib_ and PAclockwise<>0) then begin
        p[0]:=p1;p[1]:=p2;
        p[2]:=p3;p[3]:=p4;
      end else begin
        p[3]:=p1;p[2]:=p2;
        p[1]:=p3;p[0]:=p4;
      end;
      if not anyduplicates then
      inc(maxpolys);
    End
  Else
    ErrorLevel:=ERRnopolys;
End;


Procedure edit_objtype_.addtriangle(p1,p2,p3:word;attrib_:word);
Begin
  if maxpolys<polysize then

    with polys^[maxpolys] do begin
      textureref:=fgtexture;
      numsides:=3;
      pattrib:=attrib_ and PAsetmask3d;
      if ((attrib_ and PAclockwise<>0)) then begin
        p[0]:=p1;p[1]:=p2;p[2]:=p3;
      end else begin
        p[0]:=p3;p[1]:=p2;p[2]:=p1;
      end;
      if not anyduplicates then
      inc(maxpolys);
    End
  Else
    ErrorLevel:=ERRnopolys;
End;

Procedure edit_objtype_.addline(p1,p2:word;attrib_:word);
Begin
  if maxpolys<polysize then
    with polys^[maxpolys] do begin
      textureref:=fgtexture;
      numsides:=2;
      pattrib:=attrib_ and PAsetmask3d;
      p[0]:=p1;p[1]:=p2;
      if not anyduplicates then
      inc(maxpolys);
    End
  Else
    ErrorLevel:=ERRnopolys;
End;

{Procedure edit_objtype_.linering(start,fin,off:word);
var lop:byte;
Begin
  For lop:=0 to fin-2 do
    addjoin(start+lop,start+lop+off);
  addjoin(start,start+fin-2+off);
End;}

Procedure edit_objtype_.connect(p1,p2,count:word;attrib_:byte;connectup:boolean);
Var lop:word;
    Cstart:word;
Begin
  Cstart:=0;
  For lop:=0 to count-1 do Begin
    addjoin(p1+lop,p2+lop);
    if lop<count-1 then
      addquad(p1+lop,p1+lop+1,p2+1+lop,p2+lop,attrib_);
  End;
  if connectup then
    addquad(p1+count-1,p1,p2,p2+count-1,attrib_);
End;



Procedure edit_objtype_.ConnectPoint(p1,point,count:word;attrib_:byte);
var lop:word;
begin
  for lop:=0 to count-1 do
    addjoin(p1+lop,point);
  For lop:=0 to count-2 do
    addtriangle(p1+lop+1,p1+lop,point,attrib_);
  addtriangle(p1,p1+count-1,point,attrib_);
End;

procedure edit_objtype_.calcselectedpolys;
var lop:word;
    nlop,nselected:byte;

begin
  if maxpolys>0 then begin
  for lop:=0 to maxpolys-1 do with polys^[lop] do begin
    nselected:=numsides;
    for nlop:=0 to numsides-1 do begin
      if thred^[p[nlop]].nattrib and NAselected<>0 then
        dec(nselected);
    end;
    pattrib:=pattrib and (not PAallselected+PAsomeselected);
    if nselected=0 then
      pattrib:=pattrib or PAallselected
    else if nselected<numsides then
      pattrib:=pattrib or PAsomeselected;


  end;
  end;
end;


function edit_objtype_.getallconnectedpolygons(poly:polygonptr):linkedlistptr;
var list:linkedlistptr;
lop:word;
begin
  new(list,create(sizeof(wordlistelem)));

  for lop:=0 to maxpolys-1 do begin
    if polys^[lop].anyequal(poly) then
      if not polys^[lop].allselected(thred) then
        list^.add(createwordelem(lop));
  end;
  getallconnectedpolygons:=list;

end;


procedure edit_objtype_.selectconnected(noderef:word);

procedure GetNextPoly(currpoly:polygonptr);
var list:linkedlistptr;
    elem:wordlistelemptr;
begin
  list:=getallconnectedpolygons(currpoly);
  elem:=list^.first;
  while elem<>nil do begin
    selectpoly(elem^.data);
    elem:=elem^.next;
  end;
  elem:=list^.first;
  while elem<>nil do begin
    GetNextPoly(@polys^[elem^.data]);
    elem:=elem^.next;
  end;
  dispose(list,done);
end;

var lop,nlop:word;
    polyref:integer;
begin
  polyref:=-1;
  lop:=0;
  while (polyref=-1)and (lop<maxpolys) do with polys^[lop] do begin
    for nlop:=0 to numsides-1 do
      if p[nlop]=noderef then
        polyref:=lop;
    inc(lop);
  end;

  if polyref<>-1 then begin
    GetNextPoly(@polys^[polyref]);
  end;
end;

Function edit_objtype_.getselectlistconnected(id:byte;R:trect):boolean;
var
lop:word;
noderef:integer;
chkpoint:pointtype;
Begin
  if maxpoints>0 then with R do begin
    lop:=0;
    clearselection;
    while (lop<maxpoints) do with chkpoint do begin
      if (thred^[lop].Nattrib and NAselected=0) then begin
        conv3d_2d(id,@thred^[lop],x,y);
        if (x>=x1) and (x<=x2) and (y>=y1) and (y<=y2) then
          selectconnected(lop);
      end;
      inc(lop);
    end;
    getmaxmin;
  end;
End;{of procedure}

function close_to(x,y,xm,ym,howclose:integer):boolean;
begin
  close_to:=(xm>=x-howclose)and(ym>=y-howclose)and
            (xm<=x+howclose)and(ym<=y+howclose);
end;




Function edit_objtype_.getselectlist(id:byte;R:trect;selmode:byte):boolean;
var lop,cnt:word;
chkpoint:pointtype;

Begin
  if maxpoints>0 then with R do begin
    {freemem(select,maxselect);}

    with chkpoint do
    case selmode of
      SMintersect:if (maxselect>0) then
        for lop:=0 to maxpoints-1 do begin
          conv3d_2d(id,@thred^[lop],x,y);
          if not(r.contains(x,y)) then
            with thred^[lop] do Nattrib:=Nattrib and not NaSelected;
        end;
      SMcutfromlist:if (maxselect>0) then
        for lop:=0 to maxpoints-1 do begin
          conv3d_2d(id,@thred^[lop],x,y);
          if (r.contains(x,y)) then
            with thred^[lop] do Nattrib:=Nattrib and not NaSelected;

        end;
      SMnewlist:
        for lop:=0 to maxpoints-1 do begin
          conv3d_2d(id,@thred^[lop],x,y);
          if (r.contains(x,y)) then
            with thred^[lop] do Nattrib:=Nattrib or NaSelected
          else
            with thred^[lop] do Nattrib:=Nattrib and not NaSelected;
        end;

      SMaddtolist:
        for lop:=0 to maxpoints-1 do begin
          conv3d_2d(id,@thred^[lop],x,y);
          if (r.contains(x,y)) then
            with thred^[lop] do Nattrib:=Nattrib or NaSelected;
        end;
    end;
    {find out how many are selected}
    maxselect:=0;
    for lop:=0 to maxpoints-1 do begin
      with thred^[lop] do
      if Nattrib and NAselected<>0 then inc(maxselect);
    end;
    {GetMem(select,maxselect);}
    cnt:=0;
    for lop:=0 to maxpoints-1 do begin
      with thred^[lop] do
      if Nattrib and NAselected<>0 then begin
        select^[cnt]:=lop;
        inc(cnt);
      end;
    end;
    getmaxmin;

    calcselectedpolys;
  end;

End;{of procedure}

procedure edit_objtype_.selectpoly(polyref:word);
var lop:byte;
begin

  with polys^[polyref] do begin
    for lop:=0 to numsides-1 do
      selectnode(p[lop]);
    Pattrib:=Pattrib or PAallselected;
  end;
end;

procedure edit_objtype_.selectnode(noderef:word);
begin
  if thred^[noderef].nattrib and NAselected=0 then begin
    thred^[noderef].Nattrib:=thred^[noderef].Nattrib or NAselected;
    select^[maxselect]:=noderef;
    inc(maxselect);
  end;
end;

procedure edit_objtype_.clearselection;
var lop:word;
begin
  if maxselect>0 then begin
    for lop:=0 to maxselect-1 do
      with thred^[Select^[lop]] do Nattrib:=Nattrib and not NaSelected;
    maxselect:=0;
    for lop:=0 to maxpolys do with polys^[lop] do begin
      Pattrib:=Pattrib and (not PAselected);
    end;
  end;
end;

Procedure edit_objtype_.FlipSelectedNormals;
var lop:word;
begin
  if maxselect>0 then begin
    if maxjoins>0 then
    for lop:=0 to maxjoins-1 do with jointo^[lop] do
      if allselected(thred) then reverse;
    if maxpolys>0 then
    for lop:=0 to maxpolys-1 do with polys^[lop] do
      if allselected(thred) then reverse;
  end else
    ErrorLevel:=ERRnotselected;
end;

Procedure edit_objtype_.SetSelectedTexture(textureref_:byte);
var lop:word;
begin
  if maxselect>0 then begin
    if maxpolys>0 then
    for lop:=0 to maxpolys-1 do with polys^[lop] do
      if allselected(thred) then
        textureref:=textureref_;
  end else
    ErrorLevel:=ERRnotselected;
  {if maxjoins>0 then
  for lop:=0 to maxjoins-1 do with jointo^[lop] do
    if (thred^[f].selected) and (thred^[t].selected) then colour:=col;}
end;

Procedure edit_objtype_.SetSelectedAttrib(attrib_: word; mode: byte);
var lop:word;
begin
  if maxselect>0 then begin
    if maxpolys>0 then
    for lop:=0 to maxpolys-1 do with polys^[lop] do
      if allselected(thred) then SetAttrib(attrib_,mode);
  end else
    ErrorLevel:=ERRnotselected;
end;

procedure edit_objtype_.selectall;
var lop:word;
begin
  if maxpoints>0 then begin
  maxselect:=maxpoints;
  for lop:=0 to maxselect-1 do begin
    select^[lop]:=lop;
    with thred^[lop] do Nattrib:=Nattrib or Naselected;
  end;
  getmaxmin;
  calcselectedpolys;
  end;
end;

Procedure edit_objtype_.flip(direction:byte);
var lop:word;
begin
  if maxselect>0 then begin
    for lop:=0 to maxselect-1 do with thred^[select^[lop]] do
    case direction of
      Xaxis:x:=(max.x+min.x)-x;
      Yaxis:y:=(max.y+min.y)-y;
      Zaxis:z:=(max.z+min.z)-z;
    end;
    FlipSelectedNormals;
  end else
    ErrorLevel:=ERRnotselected;
End;

{procedure edit_objtype_.deleteduplicatereferences(var i:word);
var i,ib,numdups:byte;
var p:^polygontype;
begin
  p=&polys[i];
  numdups:=0;
  if (p^.numsides<3) then begin deletepoly(i);exit;end;
  for i:=0 to p.numsides-1 do
    for ib:=i+1 to p.numsides-1 do
       if (p.p[ib]=p.p[i]) then inc(numdups);
  if (numdups>1) deletepoly(i);exit;end;

end;}

function edit_objtype_.counttriangles:integer;
var i,count:word;
begin
  count:=0;
  if (maxpolys>0) then
  for i:=0 to maxpolys-1 do with polys^[i] do begin
    if (numsides=4) then
      inc(count,2)
    else
      inc(count);
  end;
  counttriangles:=count;
end;

procedure edit_objtype_.merge;
function joinexists(j1,j2:word):boolean;
var lop:word;
begin
  joinexists:=false;
  if j1<>j2 then
  for lop:=0 to maxjoins-1 do with jointo^[lop] do
    if (j1+j2)=(f+t) then begin
      joinexists:=true;
      exit;
    end;
end;

var lop,mergeto:word;lopb:byte;

begin
  if maxselect>1 then begin
    with thred^[select^[0]] do Nattrib:=Nattrib and not NaSelected;
    mergeto:=select^[0];
    if maxjoins>0 then
    for lop:=0 to maxjoins-1 do with jointo^[lop] do begin
      {if not joinexists(f,mergeto) then}
        if thred^[f].Nattrib and NaSelected<>0 then f:=mergeto;
      {if not joinexists(t,mergeto) then}
        if thred^[t].Nattrib and NaSelected<>0 then t:=mergeto;
    end;
    if maxpolys>0 then

    for lop:=0 to maxpolys-1 do with polys^[lop] do begin

      for lopb:=0 to numsides-1 do begin
        if thred^[p[lopb]].Nattrib and NaSelected<>0 then begin
          if (setpolyvertex(lopb,mergeto)=PVdeleted) then break;
        end;
      end;
      if (numsides<3) then
          deletepoly(lop);
    end;


    dec(maxselect);
    for lop:=0 to maxselect-1 do
      select^[lop]:=select^[lop+1];
    calcselectedpolys;
    delete_select(DMall);
    maxselect:=0;
    getmaxmin;
    calcselectedpolys;
  end else
    ErrorLevel:=ERRoneselected;
end;

procedure edit_objtype_.delete_select(whattodel:byte);
var lop,selectlop,sublop,joinlop,index:integer;
    oldsel:integer;
    delpoly,DelNode:boolean;

begin
  if maxselect>0 then begin

    DelNode:=WhatToDel and DMnodes<>0;
    if whatToDel and DMjoins<>0 then begin
      index:=0;
      lop:=maxjoins;
      while (lop>0) do begin
        if ((delnode) and (jointo^[index].anyselected(thred)))
        or((Not DelNode) and (jointo^[index].allselected(thred))) then begin
          deletejoin(index);
        end else
          inc(index);
        dec(lop);
      end;
    end;

    if whatToDel and DMpolys<>0 then begin
      index:=0;
      lop:=maxpolys;
      while (lop>0) do begin
        if ((delnode) and (polys^[index].anyselected(thred)))
        or((Not DelNode) and (polys^[index].allselected(thred))) then begin
          deletepoly(index);
        end else
          inc(index);
        dec(lop);
      end;
    end;

    lop:=0;
    if DelNode then
    while (lop<maxpoints)and(maxpoints>0) do begin
      if thred^[lop].Nattrib and NaSelected<>0 then begin
        for joinlop:=0 to maxjoins do begin
          if jointo^[joinlop].t>lop then dec(jointo^[joinlop].t);
          if jointo^[joinlop].f>lop then dec(jointo^[joinlop].f);
        end;
        for joinlop:=0 to maxpolys do
          for sublop:=0 to 3 do
            if polys^[joinlop].p[sublop]>lop then dec(polys^[joinlop].p[sublop]);
        for sublop:=lop to maxpoints-2 do begin
          thred^[sublop]:=thred^[sublop+1];
         end;
        dec(maxpoints);
      end else
        inc(lop);
    end;
    if delnode then maxselect:=0;
  end else
    ErrorLevel:=ERRnotselected;
end;

procedure edit_objtype_.deletejoin(lineno:word);
begin
  if (lineno<maxjoins)and(lineno>=0) then begin
    move(jointo^[lineno+1],jointo^[lineno],(maxjoins-lineno-1)*sizeof(jointype));
    dec(maxjoins);
  end;
end;

procedure edit_objtype_.deletepoly(polyno:word);
begin
  if polyno<maxpolys then begin
    move(polys^[polyno+1],polys^[polyno],(maxpolys-polyno-1)*sizeof(polygontype));
    dec(maxpolys);
  end;
end;

{////CREATION PROCEDURES///////////////////////////////}

Procedure edit_objtype_.mkcircle(cx,cy,rx,ry,z1:real;stp:word;startangle:real;mode:byte;attrib_:byte);
var lop:word;
    addval,val:real;
Begin
  addpolygon(maxpoints,stp,attrib_,mode);


  val:=startangle;
  addval:=(2*pi)/stp;

For lop:=0 to stp-1 do begin
  {addvector(
            (sin_real[(startangle+((lop*maxangle)div stp))and maxangle_mask]*rx)+cx,
            (cos_real[(startangle+(lop*maxangle)div stp)and maxangle_mask]*ry)+cy,
            z1);                                                                  }
   addvector((sin(val)*rx)+cx,(cos(val)*ry)+cy,z1);
   val:=val+addval;
end;
End;

Procedure edit_objtype_.mksphere(cx,cy,cz,rx,ry,rz:real;stp,stpz:word;startangle:real;attrib_:byte);
var lop:word;oldcurs:VectorReal;xyval,xyaddval,zpos,xypos:real;
Begin
  dec(stpz);dec(stp);
  xyval:=0;
  xyaddval:=(2*pi)/stpz;

  For lop:=0 to stpz do begin
    {connect to 'cone' if end nodes, else connect as extruded circle}
    if lop<stpz then
    if lop=0 then
      ConnectPoint(maxpoints+1,maxpoints,stp+1,attrib_)
    else if lop=stpz-1 then
      ConnectPoint(maxpoints,maxpoints+1+stp,stp+1,attrib_ xor PAclockwise)
    else
      connect(maxpoints,maxpoints+stp+1,stp+1,attrib_,true);
    zpos:=cz+(cos( ((lop*pi)  / stpz) ))*rz;

    if (lop>0)and(lop<stpz) then begin
      xypos:=sin(xyval/2);
      mkcircle(cx,cy,xypos*rx,xypos*ry,zpos,stp+1,startangle,PClines,attrib_)
    end else
      addvector(cx,cy,zpos);
    xyval:=xyval+xyaddval;

  End;
End;

Procedure edit_objtype_.mkcone(cx,cy,rx,ry,z1,z2:real;stp:word;startangle:real;attrib_:byte);
var lop:word;
Begin
  mkcircle(cx,cy,rx,ry,z1,stp,startangle,PCall,attrib_);
  connectpoint(maxpoints-stp,maxpoints,stp,attrib_);
  addvector(cx,cy,z2);
End;

Procedure edit_objtype_.mksquare(x1,y1,x2,y2,z1:real;attrib_:byte);
Begin
  addpolygon(maxpoints,4,attrib_,PCall);
  addvector(x1,y2,z1);
  addvector(x2,y2,z1);
  addvector(x2,y1,z1);
  addvector(x1,y1,z1);
End;

procedure edit_objtype_.mkcube(x1,y1,z1,x2,y2,z2:real;attrib_:byte);
var polydir:byte;
begin
  {get the right orientation for the surfaces}
  if z2>z1 then
    polydir:=0
  else
    polydir:=PaClockWise;
  mksquare(x1,y1,x2,y2,z1,attrib_ xor polydir);
  polydir:=polydir xor PaClockWise;
  mksquare(x1,y1,x2,y2,z2,attrib_ xor polydir);
  connect(maxpoints-8,maxpoints-4,4,attrib_ xor PolyDir,true);

end;

procedure edit_objtype_.mkcylinder(cx,cy,rx1,ry1,rx2,ry2,z1,z2:real;stp:word;startangle:real;attrib_:byte);
var polydir:byte;
begin
  attrib_:=attrib_ and PAsetmask3d;
  {get the right orientation for the surfaces}
  if z2>z1 then
    polydir:=0
  else
    polydir:=PaClockwise;
  mkcircle(cx,cy,rx1,ry1,z1,stp,startangle,PCall,attrib_ xor polydir);
  polydir:=polydir xor PaClockWise;
  mkcircle(cx,cy,rx2,ry2,z2,stp,startangle,PCall,attrib_ xor polydir);
  connect(maxpoints-(stp shl 1),maxpoints-stp,stp,attrib_ xor polydir,true);
end;

Procedure edit_objtype_.rotateobj(axis:byte;stp,attrib:byte);
Var sellop,lop,oldmax:word;
    rotby:real;
    tmpmat:matrix3x4type_;
Begin
  if maxselect>0 then begin
    CTM:=@tmpmat;
    rotby:=0;
    oldmax:=maxpoints;
    for lop:=0 to stp-1 do begin
        rotby:=(lop*maxrotate)/stp;
        Case axis of
          Xaxis:LmRotate(@tmpmat,rotby,0,0);
          Yaxis:LmRotate(@tmpmat,0,rotby,0);
          Zaxis:LmRotate(@tmpmat,0,0,rotby);
        end;
        addpolygon(maxpoints,maxselect,attrib,PClines);
        if (lop<stp-1) then
           connect(maxpoints,maxpoints+maxselect,maxselect,attrib xor PaClockWise,true)
        else
           connect(maxpoints,oldmax,maxselect,attrib xor PaClockWise,true);


        For sellop:=0 to maxselect-1 do Begin

           copypoint(select^[sellop]);
        end;
    End;
    CTM:=@unitmatrix;
  End else
    ErrorLevel:=ERRnotselected;
End;{of procedure}

Procedure edit_objtype_.extrudepath(path:objtype;attrib:byte;extrude:boolean);
Var sellop,lop,oldmaxpnts:word;
    tmpmat,tmpmatb:matrix3x4type_;
    middle:vectorreal;
    tmpvec:vectorreal;
    connectup:boolean;
    rotby:real;
Begin
  if (maxselect>0)and(path^.maxjoins>0) then begin
    with path^ do
      connectup:=true{jointo^[maxjoins-1].t=0};
    middle:=max;
    middle.sub(min.x,min.y,min.z);
    middle.divide(2);
    middle.add(min.x,min.y,min.z);
    with middle do
      LMtrans(@tmpmat,-x,-y,-z);
    multmatrix(@tmpmat);
    oldmaxpnts:=maxpoints;
    CTM:=@tmpmat;
    for lop:=0 to path^.maxpoints-1 do begin
      with path^.thred^[lop] do
        LMtrans(@tmpmat,x,y,z);

      rotby:=(lop*maxrotate) / (path^.maxpoints);

      {to be replaced by an angle finding routine}
      Case edit_orientation of
          Xaxis:LmRotate(@tmpmatb,-rotby,0,0);
          Yaxis:LmRotate(@tmpmatb,0,-rotby,0);
          Zaxis:LmRotate(@tmpmatb,0,0,-rotby);
        end;
      tmpmat.multiply(@tmpmatb,mtpostconcat);

      if extrude then begin
        copyobj(CMjoins,false,false);
        if lop<path^.maxpoints-1 then
          connect(maxpoints,maxpoints-maxselect,maxselect,attrib,connectup)
        else
          connect(oldmaxpnts,maxpoints-maxselect,maxselect,attrib,connectup);
      end else
        copyobj(CMall,false,false);
    end;

    {translate back}
    with middle do
      LMtrans(@tmpmat,x,y,z);
    multmatrix(@tmpmat);
    CTM:=@unitmatrix;
  End else
    ErrorLevel:=ERRnotselected;
End;{of procedure}

procedure mkgridlines(obj:edit_objtype;xstp,ystp:word;checkornot:boolean;attrib_:byte);
var xlop,ylop:word;
    currjoin:word;

    xorby,oldfgtexture:byte;
begin
  dec(xstp);
  dec(ystp);
  with obj^ do begin
    xorby:=bktexture xor fgtexture;
    currjoin:=maxpoints;
    oldfgtexture:=fgtexture;
    For ylop:=0 to ystp-1 do begin
      For xlop:=0 to xstp do begin
        if checkornot then
          fgtexture:=fgtexture xor Xorby;
        if (xlop<xstp) then
          addquad(currjoin,currjoin+1,currjoin+xstp+2,currjoin+xstp+1,attrib_);
        inc(currjoin);
      end;
      if (checkornot) and (ystp mod 2<>0) then
        fgtexture:=fgtexture xor Xorby;
    end;
    currjoin:=maxpoints;
    For ylop:=0 to ystp do begin
      For xlop:=0 to xstp do begin
        if xlop<xstp then
          addjoin(currjoin,currjoin+1);
        if ylop<ystp then
          addjoin(currjoin,currjoin+xstp+1);
        inc(currjoin);
      end;
    end;
  end;
end;

Procedure edit_objtype_.mkgridfrompic(x1,y1,x2,y2,z1:real;pic:bitmaptypeptr;checkornot:boolean;attrib_:byte);

var ylop,xlop:word;

Begin


  with pic^ do begin
  mkgridlines(@self,size.x,size.y,checkornot,attrib_);
  For ylop:=0 to size.x-1 do
    For xlop:=0 to size.y-1 do
      addvector(x1+(xlop*(x2-x1))/ (size.x-1),y1+(ylop*(y2-y1))/ (size.y-1),
                z1+round(flatdata^[xlop+(ylop*size.x)])/2);
  end;

End;


Procedure edit_objtype_.mkgrid(x1,y1,x2,y2,z1:real;xstp,ystp:word;sineornot,checkornot:boolean;attrib_:byte);
var xlop,ylop:word;zpos:real;

Begin
  zpos:=z1;
  mkgridlines(@self,xstp,ystp,checkornot,attrib_);
  dec(xstp);
  dec(ystp);
  For ylop:=0 to ystp do
    For xlop:=0 to xstp do begin
      if sineornot then
        zpos:=z1+(cos(ylop /(ystp / 10))*sin(xlop /(xstp / 10)))*8;
      addvector(x1+(xlop*(x2-x1))/ xstp,y1+(ylop*(y2-y1))/ ystp,zpos);
    End;
End;

Procedure edit_objtype_.mktext(x1,y1,z1:real;txt:string;var vfont:font_type);
var lop,tmp:byte;
lop1,mx,my:integer;
stroke:^stroke_type;
begin
  with vfont do
  for lop:=1 to length(txt) do begin
    tmp:=ord(txt[lop]);
    stroke:=pointer(strokes[tmp].s);
    for lop1:=0 to strokes[tmp].num_ops-3 do
    with stroke^ do begin
      if opcode=drawit then begin
        addjoin(maxpoints-1,maxpoints);
        addline(maxpoints-1,maxpoints,PaOutlined+PaDoublesided);
      end;
      addvector(x+x1,y+y1,z1);
      inc(stroke);
    end;
    x1:=x1+widths[tmp];
  end;
end;

procedure edit_objtype_.readOBJ(filename:string);
var f:text;
    lop,val:word;
    lopb:byte;
    dummy:string;
    tmpvec:VectorReal;
    maxp:word;
    pref:array[0..30] of word;
    nsides:byte;

begin
  assign(f,filename);
  name:=filename;
  system.reset(f);
  system.readln(f,dummy);
  maxpoints:=0;
  maxjoins:=0;
  maxpolys:=0;

  readln(f,maxp);
  if maxp>0 then begin
    for lop:=0 to maxp-1 do with tmpvec do begin
      system.read(f,x);
      system.read(f,y);
      system.readln(f,z);
      addvector(x,y,-z);
    end;
    maxjoins:=0;
    readln(f,maxp);
    if maxp>0 then begin
      for lop:=0 to maxp-1 do begin
        system.read(f,fgtexture);
        system.read(f,nsides);
        for lopb:=0 to nsides-1 do begin
          system.read(f,pref[lopb]);
          dec(pref[lopb]);
        end;
        addpolygonByRef(@pref,nsides,0,PCall);
      end;
    end;
  end;
  close(f);
end;

procedure gettoken(var buf:bufferedblock;data:pointer;datatype:byte);
const
  records:word=1;
var
  token:tokenstring;
  tptr:char;
begin
  token:='';
  tptr:=char(buf.bufferpos^);
  while(not buf.eof)and((tptr=whitespace)or(tptr=#13)or(tptr=#10)or(tptr=#9)) do
    tptr:=char(buf.get);
  {strip comments}
  if tptr='#' then begin
    while (not buf.eof)and(tptr<>#13) do
      tptr:=char(buf.get);
    gettoken(buf,data,datatype);
  end else begin
    while (not buf.eof)and(tptr<>whitespace)and(tptr<>#13)and(tptr<>#10)and(tptr<>#9) do begin
      token:=token+upcase(tptr);
      tptr:=char(buf.get);
    end;
    case datatype of
      DTstring:stringptr(data)^:=token;
      DTint:integerptr(data)^:=atoi(token);
      DTreal:realptr(data)^:=atof(token);
    end;
  end;
end;

procedure edit_objtype_.writeOBJ(filename:string);
var f:text;
    lop:word;
    lopb:byte;
begin
  assign(f,filename);
  rewrite(f);
  writeln(f,filename);
  writeln(f,maxpoints);
  if maxpoints>0 then begin
    for lop:=0 to maxpoints-1 do with thred^[lop] do begin
      system.write(f,x:3:5,' ');
      system.write(f,y:3:5,' ');
      system.write(f,-z:3:5);
      writeln(f,'');
    end;
    writeln(f,maxpolys);
    if maxpolys>0 then begin
      for lop:=0 to maxpolys-1 do with polys^[lop] do begin
        system.write(f,'1 ');
        system.write(f,numsides);
        for lopb:=numsides-1 downto 0 do begin
          system.write(f,' ',p[lopb]+1);
        end;
        writeln(f,'');
      end;
    end;
  end;
  close(f);
end;

procedure edit_objtype_.readGEO(filename:string);
var f:text;
    lop,val:word;
    lopb:byte;
    dummy:string;
    tmpvec:VectorReal;
    maxn,maxp:word;
    pref:array[0..30] of word;
    nsides:byte;
begin
  Assign(F, filename);
  name:=filename;

  Reset(F);
  read(f,maxn);
  t_col:=15;
  if maxn>0 then begin
    readln(f,maxp);
    maxpoints:=0;
    maxjoins:=0;
    maxpolys:=0;
    for lop:=0 to maxn-1 do with tmpvec do begin
      system.read(f,x);
      system.read(f,y);
      system.readln(f,z);
      addvector(x{*50},y{*50},-z{*50});
    end;
    if maxp>0 then begin
      for lop:=0 to maxp-1 do begin
        system.read(f,nsides);
        for lopb:=0 to nsides-1 do begin
          system.read(f,pref[lopb]);
          dec(pref[lopb]);
        end;
        addpolygonByRef(@pref,nsides,0,PCall);
      end;
    end;
  end;
  close(f);
end;

procedure edit_objtype_.writeGEO(filename:string);
var f:text;
    lop:word;
    lopb:byte;
begin
  assign(f,filename);
  rewrite(f);
  writeln(f,maxpoints,' ',maxpolys);
  if maxpoints>0 then begin
    for lop:=0 to maxpoints-1 do with thred^[lop] do begin
      write(f,x:3:5,' ');
      write(f,y:3:5,' ');
      writeln(f,-z:3:5);
    end;
    if maxpolys>0 then begin
      for lop:=0 to maxpolys-1 do with polys^[lop] do begin
        system.write(f,numsides);
        for lopb:=numsides-1 downto 0 do
          system.write(f,' ',p[lopb]+1);
        writeln(f,'');
      end;
    end;
  end;
  close(f);
end;

procedure edit_objtype_.readVTek(filename:string);
var lop,recsize:word;
    f:file;
begin
  assign(f,filename);
  name:=filename;
  recsize:=1;
  maxpoints:=filesize(f) div sizeof(vectorint);
  maxjoins:=0;
  maxpolys:=0;
  for lop:=0 to maxpoints-1 do begin
    blockread(f,thred^[lop],sizeof(vectorint),recsize);
  end;
  close(f);
end;

procedure edit_objtype_.writegor(filename:string);
var
f:text;
i:word;
pi:byte;
p:polygonptr;
v:vectorrealptr;
begin
  assign(f,filename);
  rewrite(f);
  writeln(f,maxpolys);
  for i:=0 to maxpolys-1 do begin
    p:=@polys^[i];
    writeln(f,'');
    writeln(f,p^.textureref*16);
    for pi:=0 to p^.numsides-1 do begin
      v:=@thred^[p^.p[pi]];

      writeln(f,round(v^.x*scale),' ',round(-v^.y*scale),' ',round(v^.z*scale));
    end;
    if (p^.numsides=3) then
      writeln(f,round(v^.x*scale),' ',round(-v^.y*scale),' ',round(v^.z*scale));

  end;
  close(f);

end;

procedure edit_objtype_.readgor(filename:string;append:boolean);
var
f:text;
numquads:word;
i:word;
pi:byte;
xp,yp,zp:integer;
begin
  name:=filename;
  assign(f,filename);

  Reset(f);

  if (not append) then begin
    maxpoints:=0;
    maxjoins:=0;
    maxpolys:=0;
  end;
  readln(f,numquads);
  t_col:=15;
  for i:=1 to numquads do begin
    readln(f,fgtexture);
    fgtexture :=fgtexture div 16;{and 15;}
    AddQuad(maxpoints,maxpoints+1,maxpoints+2,maxpoints+3,PAclockwise+PAdoublesided);
    AddJoin(maxpoints,maxpoints+1);
    AddJoin(maxpoints+1,maxpoints+2);
    AddJoin(maxpoints+2,maxpoints+3);
    AddJoin(maxpoints+3,maxpoints);

    for pi:=0 to 3 do begin
      read(f,xp);read(f,yp);readln(f,zp);
      AddVector(xp/scale,-yp/scale,zp/scale);
    end;

 end;
 close(f);

end;

function mottointel_int16(val:integer):integer;
begin
end;

function mottointel_int32(val:longint):longint;
begin
end;
{
procedure edit_objtype_.readlw(filename:string;append:boolean);
var f:file;
recsize:integer;
begin
  recsize:=1;
  name:=filename;
  assign(f,filename);
  Reset(f,recsize);


end;
 }
procedure edit_objtype_.read3d(filename:string;append:boolean);
Var maxs:array[0..2] of word;
  tmppoly:PolygonStruct;
  tmpjoin:joinstruct;
  tmpvector:VectorStruct;
  recsize,addpnts:word;
  lop:word;
  ypos:integer;
  f:file;
Begin
  recsize:=1;
  name:=filename;
  assign(f,filename);
  Reset(f,recsize);

  blockread(f,maxs,sizeof(maxs),recsize);
  if append then begin
    addpnts:=maxpoints;
  end else begin
    addpnts:=0;
    reset3d;
  end;

  if objectsize(maxs[0],maxs[1],maxs[2])<>filesize(f) then begin
    maxpoints:=0;maxjoins:=0;maxpolys:=0;
    ErrorLevel:=ERRfileerror;
    close(f);
    exit;
  end;

  t_col:=15;
  if maxs[0]>0 then
  for lop:=0 to maxs[0]-1 do with tmpvector do begin
    blockread(f,tmpvector,sizeof(VectorStruct));
    addvector(x,y,z);
    thred^[maxpoints-1].divide(loadscale);
  end;


  fgtexture:=11;
  if maxs[1]>0 then
  for lop:=0 to maxs[1]-1 do begin
    blockread(f,tmpjoin,sizeof(joinstruct),recsize);
    addjoin(tmpjoin.f+addpnts,tmpjoin.t+addpnts);
  end;

  if maxs[2]>0 then
  for lop:=0 to Maxs[2]-1 do begin
    blockread(f,TmpPoly,sizeof(polygonstruct),recsize);
    with TmpPoly do begin
      fgtexture:=colour;
      case numsides of
        2:Addline(p[0]+addpnts,p[1]+addpnts,attrib or PaClockwise);
        3:AddTriangle(p[0]+addpnts,p[1]+addpnts,p[2]+addpnts,attrib or PaClockwise);
        4:AddQuad(p[0]+addpnts,p[1]+addpnts,p[2]+addpnts,p[3]+addpnts,attrib or PAclockwise);
      end;
    end;
  end;
  close(f);
end;

procedure edit_objtype_.write3d(filename:string);
Var maxs:array[0..2] of word;recsize:word;
    tmppoly:polygonstruct;
    lop:word;
    tmpvec:VectorStruct;
    f:file;
Begin
  recsize:=1;
  assign(f,filename);
  Rewrite(f,1);
  maxs[0]:=maxpoints;maxs[1]:=maxjoins;maxs[2]:=maxpolys;
  blockwrite(f,maxs,sizeof(maxs));
  if maxpoints>0 then begin
    CurrNode:=pointer(thred);
    for lop:=0 to maxpoints-1 do with tmpvec do begin
      x:=CurrNode^.x;y:=CurrNode^.y;z:=CurrNode^.z;
      {thred^[maxpoints-1].multiply(loadscale);}
      blockwrite(f,tmpvec,sizeof(VectorStruct),recsize);
      inc(CurrNode);
    end;
    if maxjoins>0 then
      for lop:=0 to maxjoins-1 do
        blockwrite(f,jointo^[lop],4);
    if maxpolys>0 then begin
      Currpoly:=pointer(polys);
      for lop:=0 to maxpolys-1 do with tmppoly do begin
        numsides:=currpoly^.numsides;
        attrib:=currpoly^.pattrib;
        colour:=currpoly^.textureref;
        move(currpoly^.p,p,8);
        blockwrite(f,TmpPoly,sizeof(polygonstruct),recsize);
        inc(currpoly);
      end;
    end;
  end;
  close(f);
end;

procedure edit_objtype_.writeSG(filename:string);
Var dummy:string;tmp_lop,lop2:word;f:text;
Begin
  Assign(f,filename);
  Rewrite(f);
  writeln(f,maxpoints-1);
  writeln(f,maxpolys-1);
  writeln(f,filename);
  For tmp_lop:= 0 to maxpoints-1 do Begin
    writeln(f,thred^[tmp_lop].x :1:4);
    writeln(f,thred^[tmp_lop].y :1:4);
    writeln(f,thred^[tmp_lop].z :1:4);
  end;
  if maxpolys>0 then begin
  For tmp_lop:= 0 to maxpolys-1 do Begin
    Writeln(f,4);
    writeln(f,polys^[tmp_lop].textureref);
    For lop2:=0 to 3 do
      Writeln(f,polys^[tmp_lop].p[lop2]);
    end;
  close(f);
 end;
end;
{writes some java code for use in my java3d engine}

procedure edit_objtype_.writejava(filename:string);
const
loadscale=20;


Var i:integer;
pal:array[0..255]of realrgb;
 oldcol:byte;
 c:rgbtype;
 f:text;
Begin
  coloursort;
  Assign(f,filename);
  Rewrite(f);
  oldcol:=0;

  for i:=0 to 255 do begin
    getrgb(i,c.r,c.g,c.b);
    pal[i].r:=c.r /64.0;
    pal[i].g:=c.g /64.0;
    pal[i].b:=c.b /64.0;
  end;


  writeln(f,'super(',maxpoints,',',counttriangles,');');
  if (maxpoints<0) then exit;
  for i:=0 to maxpoints-1 do with thred^[i] do
      writeln(f,'addvertex(',x:2:4,'f,',y:2:4,'f,',z:2:4,'f);');
  for i:=0 to maxpolys-1 do with polys^[i] do begin
    if (textureref<>oldcol) then
      writeln(f,'cred=',pal[textureref].r:2:4,'f;cgreen=',
                        pal[textureref].g:2:4,'f;cblue=',
                        pal[textureref].b:2:4,'f;');

    if (numsides=4) then
    writeln(f,'addquad(',Pattrib and PAdoublesided,',points[',p[0],'],points[',p[1],'],points[',p[2],'],points[',p[3],']);')
    else
    writeln(f,'addtriangle(',Pattrib and PAdoublesided,',points[',p[0],'],points[',p[1],'],points[',p[2],']);');
    oldcol:=textureref;
  end;
  close(f);
end;


procedure edit_objtype_.writeVRML(filename:string);
const
loadscale=20;
Var lop,lop2:word;f:text;
    r1,g1,b1,oldtexture:byte;
    pal:array[0..255]of realrgb;
            c:rgbtype;

Begin
  Assign(f,filename);
  Rewrite(f);
  writeln(f,'#VRML V1.0 ascii');

  writeln(f,'Separator{');
  writeln(f,'MaterialBinding{');
  writeln(f,'  value PER_FACE_INDEXED');
  writeln(f,'}');

  writeln(f,'Material {');
  writeln(f,'ambientColor 0.0 0.0 0.3');
  writeln(f,'specularColor 1.0 1.0 1.0');


  writeln(f,'diffuseColor[');
  for lop:=0 to 255 do begin
    getrgb(lop,c.r,c.g,c.b);
    writeln(f,'  ',c.r /64:2:4,' ',c.g /64:2:4,' ',c.b /64:2:4,',');

  end;
  writeln(f,']');
  writeln(f,'} #material');

  writeln(f,'  Coordinate3 {');
  writeln(f,'    point[');
  if maxpoints>0 then
  For lop:= 0 to maxpoints-1 do Begin
    with thred^[lop] do
      writeln(f,'      ',x/loadscale :1:4,' ',y/loadscale :1:4,' ',z/loadscale :1:4,',');
  end;
  writeln(f,'    ]');
  writeln(f,'  }');
  if maxpolys>0 then begin
    writeln(f,  '  ','IndexedFaceSet{');
    writeln(f,'    ','coordIndex[');

    For lop:= 0 to maxpolys-1 do with polys^[lop] do Begin
      {if lop=maxpolys-1 then comma:=' ';}
      Write(f,'      ');
      For lop2:=numsides-1 downto 0 do
        write(f,p[lop2],',');
      Writeln(f,'-1,');
    end;
    writeln(f, '     ',']');
    writeln(f,  '  ','materialIndex[');
    For lop:= 0 to maxpolys-1 do with polys^[lop] do Begin
      Write(f,'      ');
      writeln(f,textureref,',');
    end;

    writeln(f,'  ]');
    writeln(f, '}');
  end;
  writeln(f, '}');
  close(f);
end;

procedure edit_objtype_.readVRML(filename:string);
const
loadscale=20;
var
buf:bufferedblock;
token:string;
vstring:string[10];
parsed:boolean;

Begin
  parsed:=false;
  buf.open(filename);
  gettoken(buf,@token,DTstring);
  if token='#VRML' then begin
    gettoken(buf,@vstring,DTstring);
    gettoken(buf,@token,DTstring);
    while not buf.eof do begin
      gettoken(buf,@token,DTstring);
    end;
  end;
  buf.close;
end;

procedure edit_objtype_.writePLG(filename:string);
Var dummy:string;tmp_lop,lop2:word;f:text;
Begin
  Assign(f,filename);
  Rewrite(f);

  writeln(f,'##MULTI');
  writeln(f,'SAVED ',maxpoints,' ',maxpolys);
  For tmp_lop:= 0 to maxpoints-1 do Begin
    write(f,round(thred^[tmp_lop].x*makebig),' ');
    write(f,round(-thred^[tmp_lop].y*makebig),' ');
    writeln(f,round(thred^[tmp_lop].z*makebig));
  end;
  if maxpolys>0 then begin
  For tmp_lop:= 0 to maxpolys-1 do with polys^[tmp_lop] do Begin
    Write(f,'0x1955 ',numsides,' ');
    For lop2:=numsides-1 downto 0 do
      Write(f,p[lop2],' ');
    writeln(f);
  end;
  close(f);
 end;
end;

procedure edit_objtype_.writePOV(filename:string);
Var lop,lop2:word;f:text;
    r1,g1,b1:byte;

  procedure WriteVector(vec:word);
  begin
    write(f,'    <',thred^[vec].x:3:5,',');
    write(f,-thred^[vec].y:3:5,',');
    write(f,thred^[vec].z:3:5,'>');
  end;

  procedure WriteTriangle(p1,p2,p3:byte);
  begin
    with currpoly^ do begin
      writeln(f,'  triangle {');
      WriteVector(p[p1]);
      writeln(f,',');
      WriteVector(p[p2]);
      writeln(f,',');
      WriteVector(p[p3]);
      writeln(f,' ');

      writeln(f,'    texture { Col',textureref,' }');;
      writeln(f,'  }');
    end;
  end;

Begin
  assign(f,filename);
  Rewrite(f);

  writeln(f,'camera {');
  writeln(f,'  location  <0, 0, -200>');
  writeln(f,'  look_at <0, 0, 0>');
  writeln(f,'}');

  for lop:=0 to SC.ColourDepth-1 do begin
    getrgb(lop,r1,g1,b1);
    writeln(f,'#declare Col',lop,' = texture {');
    writeln(f,'  pigment { color red ',r1/64:3:5,' green ',g1/64:3:5,' blue ', b1/64:3:5,' }' );
    writeln(f,'  finish {phong 2}');
    writeln(f,'}');
  end;

  writeln(f,'light_source {<15, 5,  -140> color red 0.5 green 0.7 blue 0.9}');
  writeln(f,'light_source {<124, 125, -140> color red 1.0 green 1.0 blue 0.9}');
  writeln(f,'light_source {<5, 45, -120> color red 0.9 green 0.7 blue 0.3}');

  currpoly:=pointer(polys);
  if maxpolys>0 then begin
    For lop:= 0 to maxpolys-1 do with currpoly^ do Begin
      case numsides of
        3:WriteTriangle(0,1,2);
        4:begin
            WriteTriangle(0,1,3);
            WriteTriangle(1,2,3);
          end;
      end;
      inc(currpoly);
    end;
  end;
  close(f);
end;


function fileend(var f:file):boolean;
begin
  fileend:=filesize(f)-filepos(f)>0;
end;

procedure edit_objtype_.readRW(filename:string);
var
  buf:bufferedblock;
  tokenstack,matrixstack,protolist:linkedlist;
  parsed:boolean;
  token:tokenstring;
  rotmat,usemat,tmpmat,origmat:matrix3x4type_;
  poffset:integer;
  currattrib:byte;
  {uses to create and destroy the protolist}
  protoref:prototype;
  oldfileposlist:linkedlist;
  lop:byte;
  nsides:byte;
  i:array[0..11] of word;
  id:wordarray;
  readvec:vectorreal;
  angle:real;
  currtokenref:tokentype;
  geom:boolean;
  const
  records:word=1;
begin
  reset3d;
  parsed:=false;
  poffset:=0;
  name:=filename;

  {RenderWare draws along a different axis to me, this matrix will compensate}
  lmrotate(@rotmat,-maxrotate / 4,0,0);
  {default matrix scales by 100,100,100 and rotates around X 180 degrees}
  Lmscale(@origmat,100,100,100);
  lmrotate(@tmpmat,maxrotate / 2,0,0);
  origmat.multiply(@tmpmat,mtpostconcat);
  usemat:=origmat;
  CTM:=@usemat;

  buf.open(filename);

  tokenstack.create(sizeof(tokentype_));
  matrixstack.create(sizeof(matrixelem_));
  protolist.create(sizeof(prototype_));
  oldfileposlist.create(sizeof(longintlist_));
  currattrib:=PAconnected;
  while ((not parsed)and(Errorlevel<=ERRparseerror)) do begin
    gettoken(buf,@token,DTstring);
    parsed:=buf.eof;
    begin
      if token='MODELBEGIN' then
        tokenstack.add(createtoken(token))
      else if token='CLUMPBEGIN' then begin
        tokenstack.add(createtoken(token));
        poffset:=maxpoints;
      end else if token='CLUMPEND' then begin
        poffset:=maxpoints;
        if tokentype(tokenstack.last)^.token='CLUMPBEGIN' then
          tokenstack.delete(tokenstack.last)
        else
          Errorlevel:=ERRparseerror;
      end else if token='MODELEND' then begin
        if tokentype(tokenstack.last)^.token='MODELBEGIN' then
          tokenstack.delete(tokenstack.last)
        else
          Errorlevel:=ERRparseerror;
      end else if token='TRANSFORMBEGIN' then with readvec do begin
        tokenstack.add(createtoken(token));
        matrixstack.add(creatematrix(@usemat));
      end else if token='MATERIALBEGIN' then with readvec do begin
      end else if token='MATERIALEND' then with readvec do begin
      end else if token='TRANSFORMEND' then begin
        if tokentype(tokenstack.last)^.token='TRANSFORMBEGIN' then begin
          tokenstack.delete(tokenstack.last);
          usemat:=matrixelem(matrixstack.last)^.mat;
          matrixstack.delete(matrixstack.last);
        end else
          Errorlevel:=ERRparseerror;
      end else if token='TRANSFORM' then with readvec,tmpmat do begin
        gettoken(buf,@m00,DTreal);gettoken(buf,@m01,DTreal);gettoken(buf,@m02,DTreal);gettoken(buf,@x,DTreal);
        gettoken(buf,@m10,DTreal);gettoken(buf,@m11,DTreal);gettoken(buf,@m12,DTreal);gettoken(buf,@x,DTreal);
        gettoken(buf,@m20,DTreal);gettoken(buf,@m21,DTreal);gettoken(buf,@m22,DTreal);gettoken(buf,@x,DTreal);
        gettoken(buf,@p.x,DTreal);gettoken(buf,@p.y,DTreal);gettoken(buf,@p.z,DTreal);gettoken(buf,@x,DTreal);
        CTM^:=origmat;
        CTM^.multiply(@tmpmat,mtpostconcat);
      end else if token='PROTOBEGIN' then begin
        gettoken(buf,@token,DTstring);
        protolist.add(createprototype(token,buf.fpos));
        while token<>'PROTOEND' do
          gettoken(buf,@token,DTstring);
      end else if token='PROTOEND' then begin
        if oldfileposlist.count<>0 then begin
          poffset:=maxpoints;
          buf.fseek(longintlist(oldfileposlist.last)^.data);
          oldfileposlist.delete(oldfileposlist.last)
        end;
      end else if (token='PROTOINSTANCE')or(token='PROTOINSTANCEGEOMETRY') then begin

        geom:=token='PROTOINSTANCEGEOMETRY';
        gettoken(buf,@token,DTstring);
        {search protolist to see if the name is there}
        protoref:=protolist.first;
        while (protoref<>nil)and(protoref^.name<>token) do
          protoref:=protoref^.next;
        if protoref<>nil then begin
          if geom then
             poffset:=maxpoints;
          oldfileposlist.add(createlongint(buf.fpos));
          buf.fseek(protoref^.bufpos);
        end else
          Errorlevel:=ERRparseerror;
      end else if token='SCALE' then with readvec do begin
        tmpmat:=CTM^;
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        LmScale(CTM,x,y,z);
        tmpmat.multiply(CTM,mtpostconcat);
        CTM^:=tmpmat;
      end else if token='TRANSLATE' then with readvec do begin
        tmpmat:=CTM^;
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        LmTrans(CTM,x,y,z);
        tmpmat.multiply(CTM,mtpostconcat);
        CTM^:=tmpmat;
      end else if token='ROTATE' then with readvec do begin
        tmpmat:=CTM^;
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        gettoken(buf,@angle,DTreal);
        angle:=(angle * maxrotate) /360;
        LmRotate(CTM,round(x*angle),round(y*angle),round(z*angle));
        tmpmat.multiply(CTM,mtpostconcat);
        CTM^:=tmpmat;
      end else if token='IDENTITY' then with readvec do begin
        lmunit(CTM);
      end else if (token='VERTEX')or(token='VERTEXEXT') then with readvec do begin
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        addvector(x,y,z);
      end else if (token='QUAD')or(token='QUADEXT') then begin
        for lop:=0 to 3 do begin
          gettoken(buf,@i[lop],DTint);
          inc(i[lop],poffset-1);
        end;
        addpolygonByRef(@i,4,currattrib,PCall+PCchecklines);
      end else if (token='TRIANGLE')or(token='TRIANGLEEXT') then begin
        for lop:=0 to 2 do begin
          gettoken(buf,@i[lop],DTint);
          inc(i[lop],poffset-1);
        end;
        addpolygonByRef(@i,3,currattrib,PCall+PCchecklines);
      end else if (token='POLYGON')or(token='POLYGONEXT') then begin
        gettoken(buf,@nsides,DTint);
        getmem(id,nsides*sizeof(word));
        for lop:=0 to nsides-1 do begin
          gettoken(buf,@id^[lop],DTint);
          inc(id^[lop],poffset-1);
        end;
        addpolygonByRef(id,nsides,currattrib or PAconnected,PCall+PCchecklines);
        freemem(id,nsides*sizeof(word));
      end else if token='DISC' then with readvec do begin
        tmpmat:=CTM^;
        CTM^.multiply(@rotmat,mtpostconcat);
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@nsides,DTint);
        mkcircle(0,0,y,y,-x,nsides,PCall,0,currattrib or PAconnected);
        CTM^:=tmpmat;
      end else if token='BLOCK' then with readvec do begin
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@Z,DTreal);
        divide(2);
        mkcube(-x,-y,-z,x,y,z,currattrib or PAconnected);
      end else if token='CONE' then with readvec do begin
        tmpmat:=CTM^;
        CTM^.multiply(@rotmat,mtpostconcat);
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@nsides,DTint);
        mkcone(0,0,-y,-y,0,-x,nsides,0,currattrib or PAconnected);
        CTM^:=tmpmat;
      end else if token='CYLINDER' then with readvec do begin
        tmpmat:=CTM^;
        CTM^.multiply(@rotmat,mtpostconcat);
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        gettoken(buf,@nsides,DTint);
        mkcylinder(0,0,-y,-y,-z,-z,0,-x,nsides,0,currattrib or PAconnected);
        CTM^:=tmpmat;
      end else if token='SPHERE' then with readvec do begin
        tmpmat:=CTM^;
        CTM^.multiply(@rotmat,mtpostconcat);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@nsides,DTint);
        mksphere(0,0,0,-y,-y,-y,nsides * 2,nsides,0,currattrib or PAconnected);
        CTM^:=tmpmat;
      end else if token='LIGHTSAMPLING' then begin
        gettoken(buf,@token,DTstring);
        if token='VERTEX' then
          Currattrib:=Currattrib or PAsmooth
        else if token='FACET' then
          Currattrib:=Currattrib and not PAsmooth
      end else if token='GEOMETRYSAMPLING' then with readvec do begin
        gettoken(buf,@token,DTstring);
        if token='SOLID' then
          Currattrib:=Currattrib and not PAoutlined
        else if token='WIREFRAME' then
          Currattrib:=Currattrib or PAoutlined
      end else if token='COLOR' then with readvec do begin
        gettoken(buf,@x,DTreal);
        gettoken(buf,@y,DTreal);
        gettoken(buf,@z,DTreal);
        fgtexture:=allocateRGB(round(x*64),round(y*64),round(z*64));
      end;
    end;
  end;
  CTM:=@unitmatrix;
  tokenstack.done;
  matrixstack.done;
  protolist.done;
  oldfileposlist.done;
  buf.close;
end;



procedure edit_objtype_.writeRW(filename:string);
Var lop,lop2:word;f:text;
    r1,g1,b1:byte;
    pal:array[0..255]of realrgb;
    oldtexture:byte;
    oldattrib:byte;
Begin
  for lop:=0 to SC.ColourDepth-1 do begin
    getrgb(lop,r1,g1,b1);
    pal[lop].r:=r1/64;pal[lop].g:=g1/64;pal[lop].b:=b1/64;
  end;
  assign(f,filename);
  Rewrite(f);
  writeln(f,'ModelBegin ');
  writeln(f,'  ClumpBegin ');
  writeln(f,'    Surface 0.200000 0.900000 0.400000 ');
  writeln(f,'    GeometrySampling Solid ');
  writeln(f,'    Texture NULL ');
  if maxpoints>0 then
    for lop:=0 to maxpoints-1 do with thred^[lop] do
      writeln(f,'    Vertex ',x/100:3:5,' ',-y/100:3:5,' ',-z/100:3:5,' ');
  oldtexture:=polys^[lop].textureref+1;
  oldattrib:=polys^[lop].pattrib+1;
  if maxpolys>0 then begin
    For lop:= 0 to maxpolys-1 do with polys^[lop] do begin
      if textureref<>oldtexture then
      with texturebank[textureref] do begin
        with colour do writeln(f,'    color ',r/64:3:5,' ',g/64:3:5,' ',b/64:3:5,' ');
        writeln(f,'    Surface ',ambient/256:3:5,' ',diffuse/256:3:5,' ',specular/256:3:5);
      end;
      if (oldattrib and PaSmooth)<>(pattrib and PaSmooth)then begin
        if pattrib and PAsmooth<>0 then
          writeln(f,'    LightSampling Vertex ')
        else
          writeln(f,'    LightSampling Facet ');
      end;
      if (oldattrib and PaOutlined)<>(pattrib and PaOutlined)then begin
        if pattrib and Paoutlined<>0 then
          writeln(f,'    GeometrySampling Wireframe ')
        else
          writeln(f,'    GeometrySampling Solid ');
      end;
      case numsides of
        {2:writeln(f,    '    triangle ',p[1]+1,' ',p[1]+1,' ',p[0]+1);}
        3:writeln(f,    '    triangle ',p[2]+1,' ',p[1]+1,' ',p[0]+1,' ');
        4:writeln(f,    '    Quad ',p[3]+1,' ',p[2]+1,' ',p[1]+1,' ',p[0]+1,' ');
      end;
      {if Attrib and PaDoubleSided <> 0 then
        writeln(f,'    Quad ',p[3]+1,' ',p[2]+1,' ',p[1]+1,' ',p[0]+1);}
      oldtexture:=textureref;
      oldattrib:=pattrib;
    end;
  end;
  writeln(f,'  ClumpEnd ');
  writeln(f,'ModelEnd ');
  close(f);
end;

procedure edit_objtype_.write3dsasc(filename:string);
var f:text;
lop:word;
maxtriangles:word;
r1,g1,b1:byte;
begin
  assign(f,filename);
  rewrite(f);

  maxtriangles:=0;
  for lop:=0 to maxpolys-1 do with polys^[lop] do
    if numsides=3 then
      inc(maxtriangles)
    else
      inc(maxtriangles,2);

  writeln(f,'Ambient light color: Red=0.1 Green=0.1 Blue=0.3');
  writeln(f,'Named object: "',filename,'"');
  writeln(f,'Tri-mesh, Vertices: ',maxpoints,' Faces: ',maxtriangles);
  writeln(f,'Vertex list:');
  for lop:=0 to maxpoints-1 do with thred^[lop] do
    writeln(f,'Vertex ',lop,': X:',x/100:3:5,' Y:',-y/100:3:5,' Z:',z/100:3:5,' ');
  writeln(f,'Face list:');
  maxtriangles:=0;
  for lop:=0 to maxpolys-1 do with polys^[lop] do begin
    writeln(f,'Face ',maxtriangles,': A:',p[0],' B:',p[1],' C:',p[2],' AB:',1,' BC:',1,' CA:',1);
    {with texturebank[textureref].colour do
    writeln(f,'Material:"r',r shl 2,'g',g shl 2,'b',b shl 2,'a0"');}
    write(f,'Material:"color');
    if textureref<10 then write(f,'0');
    writeln(f,textureref,'"');
    writeln(f,'Smoothing:',1{byte(pattrib and PaSmooth <>0)});
    inc(maxtriangles);
    if numsides>3 then begin
      writeln(f,'Face ',maxtriangles,': A:',p[0],' B:',p[2],' C:',p[3],' AB:',1,' BC:',1,' CA:',1);
      {with texturebank[textureref].colour do
      writeln(f,'Material:"r',r shl 2,'g',g shl 2,'b',b shl 2,'a0"');}
      write(f,'Material:"color');
      if textureref<10 then write(f,'0');
      writeln(f,textureref,'"');

      writeln(f,'Smoothing:',1{byte(pattrib and PaSmooth <>0)});
      inc(maxtriangles);
    end;
  end;
  close(f);
end;


procedure edit_objtype_.writeCOBasc(filename:string);
var f:text;
lop,objid:word;
lopb:byte;
r1,g1,b1:byte;
begin
  assign(f,filename);
  rewrite(f);
  objid:=10000;

  writeln(f,'Caligari V00.01ALH');
  writeln(f,'PolH V1.00 Id ',objid,'Parent 0 Size ',0);
  writeln(f,'Name',filename,'"');
  {PolH V0.02 Id 2440108 Parent 0 Size 00067914}
  writeln(f,'center 0.0 0.0 0.0');
  writeln(f,'Transform');
  Writeln(f,obmat.m00:3:4,' ',obmat.m01:3:4,' ',obmat.m02:3:4,' 0.0');
  Writeln(f,obmat.m10:3:4,' ',obmat.m11:3:4,' ',obmat.m12:3:4,' 0.0');
  Writeln(f,obmat.m20:3:4,' ',obmat.m21:3:4,' ',obmat.m22:3:4,' 0.0');
  Writeln(f,obmat.p.x:3:4,' ',obmat.p.y:3:4,' ',obmat.p.z:3:4,' 1.0');
  writeln(f,'World Vertices ',maxpoints);
  for lop:=0 to maxpoints-1 do with thred^[lop] do
    writeln(f,'Vertex ',x/100:3:5,' ',-y/100:3:5,' ',z/100:3:5);

  writeln(f,'Texture Vertices 1');
  writeln(f,'0.000000 0.000000');
  writeln(f,'Faces ',maxpolys);
  for lop:=0 to maxpolys-1 do with polys^[lop] do begin

    writeln(f,'Face verts ',numsides,' flags 0 mat ',textureref);
    for lopb:=0 to numsides-1 do
      write(f,'<',p[lopb],',0> ');
    writeln(f);
  end;
  {alpha 1  ka 0.29  ks 0.94  exp 0.1  ior 1}
  for lop:=0 to 15 do with texturebank[lop] do begin
    writeln(f,'mat# ',lop);
    writeln(f,'shader: phong facet: smooth');
    {if attrib and PaSmooth<>0 then
      writeln(f,'smooth')
    else
      writeln(f,'faceted')}

    with colour do
    writeln(f,'rgb ',r / 64:3:4,',',g / 64:3:4,',',b / 64:3:4);
  end;
  writeln(f,'END  V1.00 Id 0 Parent 0 Size        0');

  close(f);

end;

procedure edit_objtype_.write3ds(filename:string);
const
{chunks are *mostly* in any order but some chunks expect others
after them}
HeaderChunk=$4D4D;
ObjectChunk=$3D3D;         {Start of object mesh data.}
  BackgroundColourBlock=$1200;
  AmbientColourBlock=$2100;
  ObjectDescriptionChunk=$4000;
    {insert name here -assciz}
    ShadowChunk=$4012;             {shadow?}
    TriangleObjectChunk=$4100;     {Triangular Polygon Object}
      VertexListChunk=$4110;         {Vertex List}
      TrianglelistChunk=$4120;      {Points List}
      MatrixChunk=$4160;             {Translation Matrix}
    LightChunk=$4600;              {Light}
    CameraChunk=$4700;             {Camera}
KeyFrameChunk=$B000;           {Start of keyframer data.}


Var lop,lop2,tricount:word;
    f:file;
    recsize:word;
    NumTriPos,EndTriListPos:longint;
    r1,g1,b1:byte;
    pal:array[0..255]of realrgb;
    objectname:array[0..255] of byte;
    oldcolour:byte;
    oldsmooth:byte;
    wword,trilistsize,vertlistsize,meshsize,
    objdiscriptionsize,objectdatasize,totalobjectsize:word;

Begin
  recsize:=1;
  for lop:=0 to SC.ColourDepth-1 do begin
    getrgb(lop,r1,g1,b1);
    pal[lop].r:=r1/64;pal[lop].g:=g1/64;pal[lop].b:=b1/64;
  end;
  tricount:=0;
  for lop:=0 to maxpolys-1 do with polys^[lop] do begin
     inc(tricount);
     if numsides=4 then
       inc(tricount);
   end;

  trilistsize:=4+(6*tricount);
  vertlistsize:=4+(16*maxpoints);
  meshsize:=4+trilistsize+vertlistsize;
  objdiscriptionsize:=4+meshsize+sizeof(name)+1;
  objectdatasize:=4+objdiscriptionsize;
  totalobjectsize:=4+objectdatasize;



  {make a null-terminated string and write it}
  if length(name)>0 then
  for lop2:=1 to length(name) do
    objectname[lop-1]:=byte(name[lop]);
  objectname[length(name)]:=0;

  assign(f,filename);
  rewrite(f,recsize);
  {////////////HEADER////////////}
  wword:=HeaderChunk;
  blockwrite(f,wword,2,recsize);
  wword:=totalobjectsize;
  blockwrite(f,wword,2,recsize);
  {POST OPTIONS: OBJECT(S), KEYFRAMING}
    {////////////OBJECT DATA////////////}
    {OPTIONS:
    BACKGROUND COLOUR,AMBIENT COLOUR}
    wword:=ObjectChunk;
    blockwrite(f,wword,2,recsize);
    wword:=objectdatasize;
    blockwrite(f,wword,2,recsize);
      {////////////OBJECT TYPE/DESCRIPTION HEADER////////////}
      {OPTIONS:
      SHADOW,LIGHT,CAMERA}
      wword:=ObjectDescriptionChunk;
      blockwrite(f,wword,2,recsize);
      wword:=objdiscriptionsize;
      blockwrite(f,wword,2,recsize);
      blockwrite(f,objectname,sizeof(name)+1);
        {////////////TRIANGLE MESH////////////}
        wword:=TriangleObjectChunk;
        blockwrite(f,wword,2,recsize);
        wword:=meshsize;
        blockwrite(f,wword,2,recsize);
        {POST OPTIONS:
        VERTEX LIST, TRIANGLE LIST, MATRIX}
          {////////////VERTEX LIST////////////}
          wword:=VertexListChunk;
          blockwrite(f,wword,2,recsize);
          wword:=vertlistsize;
          blockwrite(f,wword,2,recsize);
          {num points}
          blockwrite(f,maxpoints,2,recsize);
          {actual vertex data in IEEE format}
          for lop:=0 to maxpoints-1 do
            blockwrite(f,thred^[lop],4,recsize);
          {end of vertex list chunk}

          {////////////TRIANGLE LIST////////////}
          wword:=TrianglelistChunk;
          blockwrite(f,wword,2,recsize);
          wword:=trilistsize;
          blockwrite(f,wword,2,recsize);
          blockwrite(f,tricount,2,recsize);
          {actual triangle data}
          for lop:=0 to maxpolys-1 do with polys^[lop] do begin
            for lop2:=0 to 2 do begin
              wword:=p[lop2]+1;
              blockwrite(f,wword,2,recsize);
            end;
            if numsides=4 then begin
              wword:=p[1]+1;
              blockwrite(f,wword,2,recsize);
              wword:=p[3]+1;
              blockwrite(f,wword,2,recsize);
              wword:=p[2]+1;
              blockwrite(f,wword,2,recsize);
            end;
          end;

  close(f);
end;

procedure edit_objtype_.ReadEAfile(filename:string);
Var dummy:string;
    tmp_lop,lop2,maxlines,curline,oldline:word;code:integer;
    f:text;
Begin
  assign(f,filename);
  name:=filename;
  Rewrite(f);
  {Readln(f,dummy);}
  readln(f,maxpoints);
  For tmp_lop:=0 to maxpoints-1 do Begin
    system.read(f,thred^[tmp_lop].x);system.read(f,thred^[tmp_lop].y);system.read(f,thred^[tmp_lop].z);
    readln(f);
  end;
  readln(f,maxlines);
  maxjoins:=0;
  For tmp_lop:=1 to maxlines do begin
    oldline:=curline;
    system.read(f,curline);
    system.read(f,code);
    if code<>0 then begin
      jointo^[maxjoins].f:=oldline-1;
      jointo^[maxjoins].t:=curline-1;
      inc(maxjoins);
    end;
    readln(f);
  end;

  close(f);
end;

begin
  CTM:=@unitmatrix;
end.
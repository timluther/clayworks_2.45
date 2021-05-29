Unit Tmaths;

INTERFACE
uses sincos,strings;
const
MTpreconcat=1;
MTpostconcat=2;
MTreplace=3;

type
BasicUnit=real{single};
matrix3x4type=^matrix3x4type_;
vectorintptr=^vectorint;

pointreal=object
  x,y:real;
  function length:real;
  procedure normalize;
  procedure moveto(x_,y_:real);
  procedure sub(var p:pointreal);
  procedure add(var p:pointreal);
  procedure mul(var p:real);
  procedure divi(var p:real);
end;

vectorint=object
  x,y,z:longint;

  function equals(Vector:Vectorint):boolean;
  procedure moveto(x_,y_,z_:longint);
  procedure add(xa,ya,za:longint);
  procedure sub(xs,ys,zs:longint);
  procedure divide(divby:longint);
  procedure multiply(multby:longint);
  procedure multmatrix(mat:matrix3x4type);
  Procedure unitvec(range:longint);
end;

vectorintsmallptr=^vectorintsmall;

vectorintsmall=object
  x,y,z:integer;
  function equals(Vector:VectorIntSmall):boolean;
  procedure moveto(x_,y_,z_:Integer);
  procedure add(xa,ya,za:Integer);
  procedure sub(xs,ys,zs:Integer);
  procedure divide(divby:Integer);
  procedure multiply(multby:Integer);
  procedure multmatrix(mat:matrix3x4type);
  Procedure unitvec(range:integer);
end;

VectorReal=object
  x,y,z:basicunit;
  function equals(const VectorReal:VectorReal):boolean;
  procedure add(tx,ty,tz:BasicUnit);
  procedure sub(tx,ty,tz:BasicUnit);
  Procedure Divide(d:BasicUnit);
  Procedure multiply(m:BasicUnit);
  Procedure multmatrixinto(mat:matrix3x4type;multby:VectorReal);
  procedure multmatrixinto_notrans(mat:matrix3x4type;multby:VectorReal);
  Procedure multmatrix(mat:matrix3x4type);
  Procedure unitvec(range:basicunit);
  procedure moveto(tx,ty,tz:basicunit);
End;

vectorrealptr=^vectorreal;

usemattype=^usemattype_;
usemattype_=array[0..3,0..3] of basicunit;

matrix3x4type_=object
  m00,m01,m02,
  m10,m11,m12,
  m20,m21,m22:basicunit;        {rotation fields}
  p:VectorReal;


  procedure sub(mat:matrix3x4type);
  procedure add(mat:matrix3x4type);
  procedure divide(divby:basicunit);
  procedure multiply(mat:matrix3x4type;mode:byte);
  procedure multiplyinto(B,A:matrix3x4type);
  procedure invert;
  procedure invertnotrans;
  procedure transpose;
end;

procedure gettricentre(xa,ya,xb,yb,xc,yc:integer; var retx,rety:integer);
procedure getlinecentre(xa,ya,xb,yb:integer;var retx,rety:integer);
function lineintersect(x1a,y1a,x2a,y2a,x1b,y1b,x2b,y2b:integer):boolean;
function linelength(x1,y1,x2,y2:integer):integer;
function linelengthrl(x1,y1,x2,y2:real):real;
function linelength3d(x1,y1,z1,x2,y2,z2:longint):longint;
function linelength3drl(x1,y1,z1,x2,y2,z2:real):real;
function LongDiv(X: Longint; Y: Integer): Integer;
function longmul(X, Y: integer): Longint;
Function itoa(num:longint):string;
Function pitoa(num:longint;instr:pchar):pchar;
function tstrcat(dst,src:pchar):pchar;
function tstrcat_pascal(dst:pchar;src:string):pchar;
function tstrend(src:pchar):pchar;
function charcat(dst:pchar;ch:char):pchar;


Function atoi(numstr:string):longint;
Function ftoa(num:real;i,j:byte):string;
function atof(numstr:string):real;
Function isqrt(a:longint):longint;
function bound(val,r1,r2:longint):longint;
Function smaller(n1,n2:longint):longint;
Function bigger(n1,n2:longint):longint;
Function Power(num:longint;raise:integer):longint;
Function numlength(num:longint):byte;
Function Random32(range:longint):longint;

Procedure CalcSurfNormal(p1,p2,p3:VectorReal;var pn:VectorReal);
Function Dot(var p1,p2:VectorReal):basicunit;
Procedure LMAxisRotate(mat:matrix3x4type;x,y,z,theta:real);
Procedure LmTrans(mat:matrix3x4type;xt,yt,zt:BasicUnit);
Procedure LmRotTrans(mat:matrix3x4type;rx,ry,rz:real;xt,yt,zt:basicunit);
Procedure LmUnit(mat:matrix3x4type);
Procedure LmRotUnit(mat:matrix3x4type);
Procedure LmFlip(mat:matrix3x4type);
Procedure LmRotateAround(mat:matrix3x4type;rx,ry,rz:real;vec:VectorReal);
Procedure LmStretch(mat:matrix3x4type;oldmin,oldmax,newmin,newmax:VectorReal);
Procedure LmScale(mat:matrix3x4type;x,y,z:basicunit);
Procedure LmRotate(mat:matrix3x4type;rx,ry,rz:real);
Procedure LmXrotate(mat:matrix3x4type;r:real);
Procedure LmYrotate(mat:matrix3x4type;r:real);
Procedure LmZrotate(mat:matrix3x4type;r:real);
Procedure FSwap(Var s,d; L:byte);

var
UnitMatrix:matrix3x4type_;
const
maxangle=sincos.maxangle;
maxangle_mask=maxangle-1;
{UnitMatrix:matrix3x4type_=(m00:1;m01:0;m02:0;
                           m10:0;m11:1;m12:0;
                           m20:0;m21:0;m22:1;
                           p:(x:0;y:0;z:0));}


IMPLEMENTATION
{assemblerize this routine}
var
swaptemp:longint;
{swaps two variables of arbitary length, inline into the code}
Procedure FSwap(Var s,d; L:byte);
begin
  move(s,swaptemp,l);
  move(d,s,l);
  move(swaptemp,d,l);
end;


{////VectorReal PROCEDURES///////////////////////////////////}

Function VectorReal.equals(const VectorReal:VectorReal):boolean;
begin
  equals:=(VectorReal.x=x)and(VectorReal.y=y)and(VectorReal.z=z);
end;

procedure VectorReal.multmatrixinto(mat:matrix3x4type;multby:VectorReal);
begin
  with multby,mat^ do begin
    self.x:=(m00*x +m01*y +m02*z)+p.x;
    self.y:=(m10*x +m11*y +m12*z)+p.y;
    self.z:=(m20*x +m21*y +m22*z)+p.z;
  end;
end;

procedure VectorReal.multmatrixinto_notrans(mat:matrix3x4type;multby:VectorReal);
begin
  with multby,mat^ do begin
    self.x:=(m00*x +m01*y +m02*z);
    self.y:=(m10*x +m11*y +m12*z);
    self.z:=(m20*x +m21*y +m22*z);

  end;
end;

procedure VectorReal.multmatrix(mat:matrix3x4type);
var multby:VectorReal;
begin
  multby:=self;
  with multby,mat^ do begin
    self.x:=(m00*x +m01*y +m02*z)+p.x;
    self.y:=(m10*x +m11*y +m12*z)+p.y;
    self.z:=(m20*x +m21*y +m22*z)+p.z;
  end;
end;

procedure VectorReal.add(tx,ty,tz:BasicUnit);
Begin
  x:=x+tx;y:=y+ty;z:=z+tz;
end;

procedure VectorReal.sub(tx,ty,tz:BasicUnit);
Begin
  x:=x-tx;y:=y-ty;z:=z-tz;
end;

{normalize to a range}
Procedure VectorReal.unitvec(range:basicunit);
var uli:BasicUnit;
begin
  Uli:=sqrt(abs( (x*x)+ (y*y)+ (z*z)));
  if uli=0 then uli:=1;
  x:=(x *range)/ uli;
  y:=(y *range)/ uli;
  z:=(z *range)/ uli;
end;

Procedure VectorReal.Divide(D:BasicUnit);
begin
  if D<>0 then begin
    X:=X / D;
    Y:=Y / D;
    Z:=Z / D;
  end;
end;

Procedure VectorReal.multiply(m:BasicUnit);
begin
  X:=X * M;
  Y:=Y * M;
  Z:=Z * M;
end;

Procedure VectorReal.moveto(tx,ty,tz:basicunit);
begin
  x:=tx;y:=ty;z:=tz;
end;

procedure pointreal.moveto(x_,y_:real);
begin
  x:=x_;
  y:=y_;
end;

function pointreal.length:real;
begin
  length:=sqrt((x*x)+(y*y));
end;

procedure pointreal.normalize;
var uli:real;
begin
  uli:=length;
  x:=x/uli;
  y:=y/uli;
end;

procedure pointreal.sub(var p:pointreal);
begin
  x:=x-p.x;
  y:=y-p.y;
end;

procedure pointreal.add(var p:pointreal);
begin
  x:=x+p.x;
  y:=y+p.y;
end;

procedure pointreal.divi(var p:real);
begin
  x:=x / p;
  y:=y / p;
end;

procedure pointreal.mul(var p:real);
begin
  x:=x * p;
  y:=y * p;
end;


{////VECTOR INT///////////////////////////////////////////}

procedure VectorInt.multmatrix(mat:matrix3x4type);
var new:VectorInt;
begin
  {if selected then begin}
  new:=self;
  with new,mat^ do begin
    self.x:=round(m00*x + m10*y + m20*z +p.x);
    self.y:=round(m01*x + m11*y + m21*z +p.y);
    self.z:=round(m02*x + m12*y + m22*z +p.z);
  end;
  {end;}
end;

Procedure VectorInt.unitvec(range:longint);
var uli:longint;
begin
  Uli:=(isqrt(abs( (x*x)+ (y*y)+ (z*z) )));
  if range<>1 then
    multiply(range);
  if uli<>0 then
    divide(uli);
end;

Procedure VectorInt.moveto(x_,y_,z_:longint);
begin
  x:=x_;y:=y_;z:=z_;
end;

Procedure VectorInt.divide(divby:longint);
begin
  x:=x div divby;y:=y div divby;z:=z div divby;
end;

Procedure VectorInt.multiply(multby:longint);
begin
  x:=x*multby;y:=y*multby;z:=z*multby;
end;

procedure VectorInt.add(xa,ya,za:longint);
begin
  inc(x,xa);inc(y,ya);inc(z,za);
end;

procedure VectorInt.sub(xs,ys,zs:longint);
begin
  dec(x,xs);dec(y,ys);dec(z,zs);
end;

Function vectorint.equals(vector:vectorint):boolean;
begin
  equals:=(vector.x=x)and(vector.y=y)and(vector.z=z);
end;
{////VECTOR INT Small///////////////////////////////////////////}

procedure VectorIntSmall.multmatrix(mat:matrix3x4type);
var new:VectorIntSmall;
begin
  {if selected then begin}
  new:=self;
  with new,mat^ do begin
    self.x:=round(m00*x + m10*y + m20*z +p.x);
    self.y:=round(m01*x + m11*y + m21*z +p.y);
    self.z:=round(m02*x + m12*y + m22*z +p.z);
  end;
  {end;}
end;

Procedure VectorIntSmall.unitvec(range:integer);
var uli:integer;
begin
  Uli:=(isqrt(abs( (x*x)+ (y*y)+ (z*z) )));
  if range<>1 then
    multiply(range);
  if uli<>0 then
    divide(uli);
end;

Procedure VectorIntSmall.moveto(x_,y_,z_:integer);
begin
  x:=x_;y:=y_;z:=z_;
end;

Procedure VectorIntSmall.divide(divby:integer);
begin
  x:=x div divby;y:=y div divby;z:=z div divby;
end;

Procedure VectorIntSmall.multiply(multby:integer);
begin
  x:=x*multby;y:=y*multby;z:=z*multby;
end;

procedure VectorIntSmall.add(xa,ya,za:integer);
begin
  inc(x,xa);inc(y,ya);inc(z,za);
end;

procedure VectorIntSmall.sub(xs,ys,zs:integer);
begin
  dec(x,xs);dec(y,ys);dec(z,zs);
end;

Function VectorIntSmall.equals(vector:VectorIntSmall):boolean;
begin
  equals:=(vector.x=x)and(vector.y=y)and(vector.z=z);
end;


{////MATRIX PROCEDURES///////////////////////////////////}

Procedure LMAxisRotate(mat:matrix3x4type;x,y,z,theta:real);
var
c,s,t,txy,txz,tyz,sx,sy,sz:real;
begin
    c:=cos(theta);s:=sin(theta);t:=1-c;
    txy:=t*x*y;txz:=t*x*z;tyz:=t*y*z;
    sx:=s*x;sy:=s*y;sz:=s*z;
    with mat^ do begin
      m00:=t*x*x+c; m01:=txy*sz;  m02:=txz-sy;
      m10:=txy-sz;  m11:=t*y*y+c; m12:=tyz+sx;
      m20:=txz+sy;  m21:=tyz-sx;  m22:=t*z*z+c;
      p.moveto(0,0,0);
    end;
end;

Procedure LmRotTrans(mat:matrix3x4type;rx,ry,rz:real;xt,yt,zt:basicunit);
var precalc:basicunit;
    tmpmat:matrix3x4type_;
begin
  with mat^ do begin
  LmXrotate(mat,rx);
  LmYrotate(@tmpmat,ry);
  multiply(@tmpmat,MTpostconcat);
  LmZrotate(@tmpmat,rz);
  multiply(@tmpmat,MTpostconcat);

  {m00:=cos(rz]*cos(ry];
  precalc:=cos(rz]* -sin(ry];
  m01:=precalc *-sin(rx] +sin(rz]*cos(rx];
  m02:=precalc * cos(rx] + sin(rz]*sin(rx];

  m10:=-sin(rz] * cos(ry];
  precalc:=-sin(rz] * -sin(ry];
  m11:=precalc * -sin(rx] + cos(rz] * cos(rx];
  m12:=precalc * -sin(ry] * cos(rx] + cos(rz] * sin(rx];

  m20:=sin(ry] ;
  m21:=cos(ry]* -sin(rx] ;
  m22:=cos(ry]* cos(rx];}


  p.moveto(xt,yt,zt);
  end;
end;

Procedure LmXrotate(mat:matrix3x4type;r:real);
begin

  with mat^ do begin
    m00:=1;            m01:=0;            m02:=0;
    m10:=0;            m11:=cos(r);  m12:=sin(r);
    m20:=0;            m21:=-sin(r); m22:=cos(r);
    p.moveto(0,0,0);
  end;
end;
Procedure LmYrotate(mat:matrix3x4type;r:real);
begin

  with mat^ do begin
    m00:=cos(r);  m01:=0;            m02:=-sin(r);
    m10:=0;            m11:=1;            m12:=0;
    m20:=sin(r);  m21:=0;            m22:=cos(r);
    p.moveto(0,0,0);
  end;
end;

Procedure LmZrotate(mat:matrix3x4type;r:real);
begin


  with mat^ do begin
    m00:=cos(r);  m01:=sin(r); m02:=0;
    m10:=-sin(r); m11:=cos(r); m12:=0;
    m20:=0;            m21:=0          ; m22:=1;
    p.moveto(0,0,0);
  end;
end;

Procedure LmRotate(mat:matrix3x4type;rx,ry,rz:real);
begin
  LmRotTrans(mat,rx,ry,rz,0,0,0);
end;

Procedure LmRotateAround(mat:matrix3x4type;rx,ry,rz:real;vec:VectorReal);
var tmpmat:matrix3x4type_;
begin
  LmTrans(mat,-vec.x,-vec.y,-vec.z);
  LmRottrans(@tmpmat,rx,ry,rz,0,0,0);
  mat^.multiply(@tmpmat,MTpostconcat);
  LmTrans(@tmpmat,vec.x,vec.y,vec.z);
  mat^.multiply(@tmpmat,MTpostconcat)
end;

Procedure LmStretch(mat:matrix3x4type;oldmin,oldmax,newmin,newmax:VectorReal);
var multby:VectorReal;
    tmpmat:matrix3x4type_;
begin
  multby:=oldmax;
  multby.sub(oldmin.x,oldmin.y,oldmin.z);
  with multby do begin
    if x=0 then x:=1;x:=(newmax.x-newmin.x)/x;
    if y=0 then y:=1;y:=(newmax.y-newmin.y)/y;
    if z=0 then z:=1;z:=(newmax.z-newmin.z)/z;
  end;
  with mat^ do begin
    m00:=multby.x; m01:=0;        m02:=0;
    m10:=0;        m11:=multby.y; m12:=0;
    m20:=0;        m21:=0;        m22:=multby.z;
    p.x:=(-oldmin.x)*multby.x+newmin.x;
    p.y:=(-oldmin.y)*multby.y+newmin.y;
    p.z:=(-oldmin.z)*multby.z+newmin.z;
  end;
end;

Procedure LmTrans(mat:matrix3x4type;xt,yt,zt:basicunit);
begin
  with mat^ do begin
    m00:=1;m01:=0;m02:=0;
    m10:=0;m11:=1;m12:=0;
    m20:=0;m21:=0;m22:=1;
    p.x:=xt;p.y:=yt;p.z:=zt;
  end;
end;

Procedure LmRotUnit(mat:matrix3x4type);
begin
  with mat^ do begin
    m00:=1; m01:=0; m02:=0;
    m10:=0; m11:=1; m12:=0;
    m20:=0; m21:=0; m22:=1;
  end;
end;


Procedure LmUnit(mat:matrix3x4type);
begin
  with mat^ do begin
    m00:=1; m01:=0; m02:=0;
    m10:=0; m11:=1; m12:=0;
    m20:=0; m21:=0; m22:=1;
    p.x:=0; p.y:=0; p.z:=0;
  end;
end;
Procedure LmFlip(mat:matrix3x4type);
begin
  with mat^ do begin
    m00:=0; m01:=0; m02:=1;
    m10:=0; m11:=1; m12:=0;
    m20:=1; m21:=0; m22:=0;
    p.x:=0; p.y:=0; p.z:=0;
  end;
end;

Procedure LmScale(mat:matrix3x4type;x,y,z:basicunit);
begin
  with mat^ do begin
    m00:=x; m01:=0; m02:=0;
    m10:=0; m11:=y; m12:=0;
    m20:=0; m21:=0; m22:=z;
    p.x:=0; p.y:=0; p.z:=0;
  end;
end;

procedure matrix3x4type_.add(mat:matrix3x4type);
begin
  m00:=m00+mat^.m00; m01:=m01+mat^.m01; m02:=m02+mat^.m02;
  m10:=m10+mat^.m10; m11:=m11+mat^.m11; m12:=m12+mat^.m12;
  m20:=m20+mat^.m20; m21:=m21+mat^.m21; m22:=m22+mat^.m22;
  p.add(mat^.p.x,mat^.p.y,mat^.p.z);
end;

procedure matrix3x4type_.sub(mat:matrix3x4type);
begin
  m00:=m00-mat^.m00; m01:=m01-mat^.m01; m02:=m02-mat^.m02;
  m10:=m10-mat^.m10; m11:=m11-mat^.m11; m12:=m12-mat^.m12;
  m20:=m20-mat^.m20; m21:=m21-mat^.m21; m22:=m22-mat^.m22;
  p.sub(mat^.p.x,mat^.p.y,mat^.p.z);
end;

procedure matrix3x4type_.divide(divby:basicunit);
begin
  if divby<>0 then begin
    m00:=m00/divby; m01:=m01/divby; m02:=m02/divby;
    m10:=m10/divby; m11:=m11/divby; m12:=m12/divby;
    m20:=m20/divby; m21:=m21/divby; m22:=m22/divby;
    p.divide(divby);
  end;
end;

procedure matrix3x4type_.invert;
var tmppx,tmppy:basicunit;
    
begin
 transpose;
 tmppx:=p.x;tmppy:=p.y;
 p.x:=(-m00*tmppx)+(-m01*tmppy)+(-m02*p.z);
 p.y:=(-m10*tmppx)+(-m11*tmppy)+(-m12*p.z);
 p.z:=(-m20*tmppx)+(-m21*tmppy)+(-m22*p.z);
end;

procedure matrix3x4type_.invertnotrans;
begin
  transpose;
  p.moveto(0,0,0);
end;

procedure matrix3x4type_.transpose;
var tmpmat:matrix3x4type_;
begin
  tmpmat:=self;
  self.m01:=tmpmat.m10;
  self.m02:=tmpmat.m20;
  self.m10:=tmpmat.m01;
  self.m12:=tmpmat.m21;
  self.m20:=tmpmat.m02;
  self.m21:=tmpmat.m12;
end;

procedure matrix3x4type_.multiply(mat:matrix3x4type;mode:byte);
var A:matrix3x4type_;
Begin

  A:=self;
  {multiplyinto(@a,@unitmatrix);}

  case mode of
    MTpostconcat:begin
      multiplyinto(@a,mat);
    end;
    MTpreconcat:begin
      multiplyinto(mat,@a);
    end;
    MTreplace:Self:=mat^;
  end;
end;

procedure matrix3x4type_.multiplyinto(B,A:matrix3x4type);
var
i,j,k:byte;
Begin
  with B^ do begin
    self.m00:=(A^.m00*m00 + A^.m01*m10 + A^.m02*m20);
    self.m10:=(A^.m10*m00 + A^.m11*m10 + A^.m12*m20);
    self.m20:=(A^.m20*m00 + A^.m21*m10 + A^.m22*m20);

    self.m01:=(A^.m00*m01 + A^.m01*m11 + A^.m02*m21);
    self.m11:=(A^.m10*m01 + A^.m11*m11 + A^.m12*m21);
    self.m21:=(A^.m20*m01 + A^.m21*m11 + A^.m22*m21);

    self.m02:=(A^.m00*m02 + A^.m01*m12 + A^.m02*m22);
    self.m12:=(A^.m10*m02 + A^.m11*m12 + A^.m12*m22);
    self.m22:=(A^.m20*m02 + A^.m21*m12 + A^.m22*m22);


    self.p.x:=(A^.m00*p.x + A^.m01*p.y + A^.m02*p.z)+A^.p.x;
    self.p.y:=(A^.m10*p.x + A^.m11*p.y + A^.m12*p.z)+A^.p.y;
    self.p.z:=(A^.m20*p.x + A^.m21*p.y + A^.m22*p.z)+A^.p.z;
  end;
end;

{returns the dot product between two vectors}
Function Dot(var p1,p2:VectorReal):basicunit;
Begin
  dot:=((P1.X*P2.X + P1.Y*P2.Y + P1.Z*P2.Z));
end;

Procedure CalcSurfNormal(p1,p2,p3:VectorReal;var pn:VectorReal);
Begin
  {make magnitude Nodes, P2 being the base}
  {make magnitude Nodes, P2 being the base}
  P3.sub(P2.X,P2.Y,P2.Z);
  P1.sub(P2.X,P2.Y,P2.Z);
  pn.x:=(p1.y*p3.z) - (p1.z*p3.y);
  pn.y:=(p1.z*p3.x) - (p1.x*p3.z);
  pn.z:=(p1.x*p3.y) - (p1.y*p3.x);
  pn.unitvec(1);
end;

{returns number of digits in a number}

Function numlength(num:longint):byte;
var count:byte;
begin
  if num=0 then numlength:=1 else begin
    count:=0;
    while num<>0 do begin
      num:=num div 10;
      inc(count);
    end;
    numlength:=count;
  end;
end;

Function Power(num:longint;raise:integer):longint;
var tmp:longint;
begin
  tmp:=num;
  if raise>0 then begin
    for raise:=1 to raise-1 do
      num:=num*tmp;
  Power:=num;
  end else power:=1;
end;

function bound(val,r1,r2:longint):longint;
begin
  if val>r2 then val:=r2;
  if val<r1 then val:=r1;
  bound:=val;
end;
Function smaller(n1,n2:longint):longint;
Begin
  if n1<n2 then smaller:=n1
  else
  smaller:=n2;
end;

Function Bigger(n1,n2:longint):longint;
Begin
  if n1>n2 then Bigger:=n1
  else
  Bigger:=n2;
end;

function LongDiv(X: Longint; Y: Integer): Integer;
begin
inline($59/$58/$5A/$F7/$F9);
end;

Function atoi(numstr:string):longint;
var lop:byte;
    multby,numcount:longint;
begin
  multby:=1;
  numcount:=0;
  for lop:=length(numstr) downto 1 do begin
    inc(numcount,(ord(numstr[lop])-ord('0'))*multby);
    multby:=multby*10;
  end;
  atoi:=numcount;
end;

Function itoa(num:longint):string;
var lop,numlen,numcount,dot,powerlop:byte;
    precalc,powered:longint;
    tmp:string;
begin
  {str(num,tmp);}
  tmp:='';
  dot:=0;
  numlen:=numlength(num)-1;
  numcount:=numlen;
  if num<0 then begin tmp:=tmp+'-'; num:=-num; end;
  for lop:=0 to numlen do begin
    powered:=power(10,numcount);
    precalc:=num div powered;
    tmp:=tmp+char(precalc+byte('0'));
    dec(num,precalc * powered);
    dec(numcount);
  end;
  itoa:=tmp;
end;

function tstrend(src:pchar):pchar;
begin
  while (src^<>#0) do
    inc(src);

  tstrend:=src;
end;

function tstrcat_pascal(dst:pchar;src:string):pchar;
var i:integer;
begin
  tstrcat_pascal:=dst;
  while (dst^<>#0) do
    inc(dst);
  for i:=1 to byte(src[0]) do begin
    dst^:=src[i];
    inc(dst);
  end;
  dst^:=#0;
end;


function tstrcat(dst,src:pchar):pchar;
begin
  tstrcat:=dst;
  while (dst^<>#0) do
    inc(dst);
  while (src^<>#0) do begin

    dst^:=src^;
    inc(dst);
    inc(src);
  end;
  dst^:=#0;
end;

function charcat(dst:pchar;ch:char):pchar;
var last:array [0..1] of char;
begin
   charcat:=dst;
   while (dst^<>#0) do
     inc(dst);
   dst^:=ch;
   inc(dst);
   dst^:=#0;
end;

Function pitoa(num:longint;instr:pchar):pchar;
var lop,numlen,numcount,dot,powerlop:byte;
    precalc,powered:longint;
    tmp:pchar;
begin
  tmp:=instr;
  dot:=0;
  numlen:=numlength(num)-1;
  numcount:=numlen;
  {if num<0 then begin tmp^:='-'; num:=-num; inc(tmp);end;}
  if num<0 then begin charcat(tmp,'-'); num:=-num; end;
  for lop:=0 to numlen do begin
    powered:=power(10,numcount);
    precalc:=num div powered;
    {tmp^:=char(precalc+byte('0'));
    inc(tmp);}
    charcat(tmp,char(precalc+byte('0')));
    dec(num,precalc * powered);
    dec(numcount);
  end;
  {tmp^:=#0;}
  pitoa:=instr;
end;

Function ftoa(num:real;i,j:byte):string;
var temp:string;
Begin
  str(num:i:j,temp);ftoa:=temp;
end;

function atof(numstr:string):real;
var lop:byte;
    numcount,multby:real;
begin
  multby:=1;
  numcount:=0;

  for lop:=length(numstr) downto 1 do begin
    case(numstr[lop]) of
      '0'..'9':begin
        numcount:=numcount+(ord(numstr[lop])-ord('0'))*multby;
        multby:=multby*10;
      end;
      '.':begin
        numcount:=numcount/multby;
        multby:=1;
      end;
    end;
  end;
  if numstr[1]='-' then
    atof:=-numcount
  else
    atof:=numcount;
end;

function longmul(X, Y: integer): Longint;
begin
  inline($5A/$58/$f7/$EA);
end;

Function isqrt(a:longint):longint;
var x,y,z:longint;
begin
  x:=0;y:=1;z:=1;
  while y<=a do begin
    inc(x);
    inc(z,2);
    inc(y,z);
  end;
  isqrt:=x;
end;

procedure gettricentre(xa,ya,xb,yb,xc,yc:integer; var retx,rety:integer);
begin
  retx:=(xa+xb+xc) div 3;
  rety:=(ya+yb+yc) div 3;
end;

procedure getlinecentre(xa,ya,xb,yb:integer;var retx,rety:integer);
begin
  retx:=(xa+xb) shr 1;
  rety:=(ya+yb) shr 1;
end;

function lineintersect(x1a,y1a,x2a,y2a,x1b,y1b,x2b,y2b:integer):boolean;
begin
  if (x2a>=x1b)and (x1a<=x2b)and(y2a>=y1b)and (y1a<=y2b) then begin

  end else
    lineintersect:=false;
end;

function linelength(x1,y1,x2,y2:integer):integer;
Begin
  x1:=abs(x2-x1);y1:=abs(y2-y1);
  linelength:=isqrt((x1*x1)+(y1*y1));
end;

function linelengthRl(x1,y1,x2,y2:real):real;
Begin
  x1:=abs(x2-x1);y1:=abs(y2-y1);
  linelengthrl:=sqrt((x1*x1)+(y1*y1));
end;

function linelength3d(x1,y1,z1,x2,y2,z2:longint):longint;
Begin
  x1:=abs(x2-x1);y1:=abs(y2-y1);z1:=abs(z2-z1);
  linelength3d:=isqrt((x1*x1)+(y1*y1)+(z1*z1));
end;

function linelength3drl(x1,y1,z1,x2,y2,z2:real):real;
Begin
  x1:=abs(x2-x1);y1:=abs(y2-y1);z1:=abs(z2-z1);
  linelength3drl:=sqrt((x1*x1)+(y1*y1)+(z1*z1));
end;

function random32(range:longint):longint;
var nums:array[0..1] of word;
begin
  nums[0]:=random (range and 65535);
  nums[1]:=random (range shr 16);
  random32:=longint(nums);
end;

begin
  LmUnit(@unitmatrix);
end.

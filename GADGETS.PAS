Unit gadgets;
{$X+}{$g+}{$a+}

INTERFACE

uses Gbasics,views,ggraph,twindraw,twinb,msmouse,tmaths,SinCos;
type

angle_box=object(tview_)
  currangle,xoffs,yoffs,halfheight,halfwidth:integer;
  constructor create(x1_,y1_,x2_,y2_:integer);

  procedure Tchangebounds(var bounds:trect);virtual;
  procedure draw;virtual;
  private
    procedure calcoffs;
    procedure drawline;
end;


IMPLEMENTATION

constructor angle_box.create(x1_,y1_,x2_,y2_:integer);
begin
  currangle:=0;
  inherited create(x1_,y1_,x2_,y2_);
  calcoffs;
end;

procedure angle_box.calcoffs;
begin
  xoffs:=x1+halfx;
  yoffs:=y1+halfy;
end;

procedure angle_box.Tchangebounds(var bounds:trect);
begin
  setbounds(bounds);
  calcoffs;
end;

procedure angle_box.drawline;
const
inner_range=6;
begin
  line(xoffs,yoffs,
  xoffs+trunc((cos(currangle)*(halfwidth-inner_range))),
  yoffs+trunc((sin(currangle)*(halfheight-inner_range))));
end;

procedure angle_box.draw;
const
stp=16;
marker_length=2;
extra_marker=maxangle div 8;
var lop:integer;
Ccos,Csin:real;
begin
  outbox(x2,y2,x1,y1);
  for lop:=0 to stp do begin
    Ccos:=cos((lop*2*pi)/ stp);
    Csin:=sin((lop*2*pi)/ stp);
    line(xoffs+trunc(Ccos*(halfwidth-1)),
         yoffs+trunc(Csin*(halfheight-1)),
         xoffs+trunc(Ccos*(halfwidth-marker_length-1)),
         yoffs+trunc(Csin*(halfheight-marker_length-1)));
  end;
  drawline;
end;

{procedure angle_box.handle;
const
quater=maxangle div 4;
begin
  while chkicon>0 do begin
    mpos;
    if ms_moved then begin
      mouseoff;
      t_col:=midcol;drawline;
      dec(currangle,oldxm-xm);
      currangle:=currangle and maxangle_mask;
      t_col:=darkcol;drawline;
      ;mouseon;
    end;
  end;
end;}


end.
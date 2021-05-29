Unit Sincos;

INTERFACE
const
{set these up so you don'y have to use tmaths directly}
maxangle=256;
maxangle_mask=maxangle-1;

shiftsize=10;
shiftmult=1 shl shiftsize;


var
Sin_real,Cos_real:array[0..maxangle+1] of real;
Sin_int,Cos_int:array[0..maxangle+1] of longint;
procedure init_sin_cos_int;
procedure init_sin_cos_real;
IMPLEMENTATION



procedure init_sin_cos_real;
var lop:word;
begin
  For lop:=0 to maxangle+1 do Begin
    Sin_real[lop]:=sin(lop*pi/(maxangle shr 1));
    Cos_real[lop]:=cos(lop*pi/(maxangle shr 1));
  end;
end;


procedure init_sin_cos_int;
var lop:word;
begin
  For lop:=0 to maxangle+1 do Begin
    Sin_int[lop]:=ROUND(sin(PI/(maxangle shr 1)*lop)*shiftmult);
    Cos_int[lop]:=ROUND(cos(PI/(maxangle shr 1)*lop)*shiftmult);
  end;
end;
end.
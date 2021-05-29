UNIT vesainfo;
INTERFACE
uses ttypes;


const
SVGAok=     $004F;{ Function is supported}
SVGAErr2 =    $4F00;{ Function is not supported}
SVGAErr3 =    $0000;{ Function call successful}
SVGAErr4 =    $0100;{ Function call failed}
SVGAErr5 =    $0200;{ Software supports this function, but the hardware does not}
SVGAErr6 =    $0300;{ Function call invalid in current video mode}

{Errstrings:array[0..5] of string=('Function is supported'}
TEST_SVGA640x400x256=5;
TEST_SVGA640x480x256=1;
TEST_SVGA800x600x256=3;
TEST_SVGA1024x768x256=5;

type

headerblockptr= ^headerblock;
headerblock=record
  VESAsig:array[0..3] of char;
  VESAversion:word;
  OEMStringPtr:byteptr;
  Capabilities:byte;
  Modelist:wordptr;
  totalmemory:word;
  emSoftwareRev:word;
  OemVendorNamePtr:Pchar;
  OemProductNamePtr:Pchar;
  OemProductRevPtr:Pchar;
  reserved:array[0..237] of byte;
end;




infoblockptr=^infoblocktype;
infoblocktype=record
   ModeAttributes      :word      ;{ mode attributes}
   WinAAttributes      :byte      ;{ window A attributes}
   WinBAttributes      :byte      ;{ window B attributes }
   WinGranularity      :word      ;{ window granularity}
   WinSize             :word      ;{ window size}
   WinASegment         :word      ;{ window A start segment}
   WinBSegment         :word      ;{ window B start segment}
   WinFuncPtr          :procedure;{ pointer to window function}
   BytesPerScanLine    :word      ;{ bytes per scan line}

   { Mandatory information for VBE 1.2 and above}
   XResolution         :word      ;{ horizontal resolution in pixels or chars}
   YResolution         :word      ;{ vertical resolution in pixels or chars}
   XCharSize           :byte      ;{ character cell width in pixels}
   YCharSize           :byte      ;{ character cell height in pixels}
   NumberOfPlanes      :byte      ;{ number of memory planes}
   BitsPerPixel        :byte      ;{ bits per pixel}
   NumberOfBanks       :byte      ;{ number of banks}
   MemoryModel         :byte      ;{ memory model type}
   BankSize            :byte      ;{ bank size in KB}
   NumberOfImagePages  :byte      ;{ number of images}
   Reserved            :byte      ;{ reserved for page function}

   { Direct Color fields (required for direct/6 and YUV/7 memory models)}
   RedMaskSize         :byte      ;{ size of direct color red mask in bits}
   RedFieldPosition    :byte      ;{ bit position of lsb of red mask}
   GreenMaskSize       :byte      ;{ size of direct color green mask in bits}
   GreenFieldPosition  :byte      ;{ bit position of lsb of green mask}
   BlueMaskSize        :byte      ;{ size of direct color blue mask in bits}
   BlueFieldPosition   :byte      ;{ bit position of lsb of blue mask}
   RsvdMaskSize        :byte      ;{ size of direct color reserved mask in bits}
   RsvdFieldPosition   :byte      ;{ bit position of lsb of reserved mask}
   DirectColorModeInfo :byte      ;{ direct color mode attributes}

   { Mandatory information for VBE 2.0 and above}
   PhysBasePtr         :longint      ;{ physical address for flat frame buffer}
   OffScreenMemOffset  :pointer      ;{ pointer to start of off screen memory}
   OffScreenMemSize    :word      ;{ amount of off screen memory in 1k units}
   Filler              :array[0..206] of byte  ;{ remainder of ModeInfoBlock}


end;


var
SVGAheader:headerblock;
SVGAinfo:infoblocktype;


function getvesaheaderinfo(infobloc:headerblockptr):word;
function getvesainfo(infobloc:infoblockptr;mode:word):word;


{Input: A Real-Mode pointer;
Output: The equivilant Protected-Mode pointer
Usage: PM_Pointer:=ConvertPtr(RM_Pointer);
Alternate: MyPointer:=ConvertPtr(MyPointer);
Restrictions: Must be in Protected Mode; Must have a DPMI host.
}


IMPLEMENTATION
function ConvertPtr(RMPointer:Pointer):pointer; assembler;
asm
   mov     ax,0002h
   mov     bx,word ptr RMPointer+2 {Convert the RM segment to PM selector}
   int     31h                     {Call DPMI}
   mov     dx,ax                   {Return pointer in DX:AX}
   mov     ax,word ptr RMPointer   {Offset is the same}
end;


function getvesaheaderinfo(infobloc:headerblockptr):word;
var retword:word;
begin
  asm

    mov ah,4fh
    mov al,00

    {mov cx,mode}
    les DI,infobloc
    int $10
    mov retword,ax;
  end;
  infobloc^.modelist:=ConvertPtr(infobloc^.modelist);
  getvesaheaderinfo:=retword;
end;


function getvesainfo(infobloc:infoblockptr;mode:word):word;
var retword:word;
begin
  asm

    mov ah,4fh
    mov al,01

    mov cx,mode
    les DI,infobloc
    int $10
    mov retword,ax;
  end;

  getvesainfo:=retword;
end;
end.
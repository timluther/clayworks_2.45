Unit emsunit;
INTERFACE
uses dos;


Type
  ST3  = string[3];
  ST80 = string[80];
  ST5  = string[5];

Const
  EMS_INT                    = $67;
  DOS_Int                    = $21;
  GET_PAGE_FRAME             = $41;
  GET_UNALLOCATED_PAGE_COUNT = $42;
  ALLOCATE_PAGES             = $43;
  MAP_PAGES                  = $44;
  MAP_MULTIPLE_PAGES         = $50;
  DEALLOCATE_PAGES           = $45;
  GET_VERSION                = $46;
  STATUS_OK                  = 0;
  EMS_current_handle:word=64000;

  {important global varibales!}
  var

    EMS_Base_Address:word; {base segment of ems page frame}
    EMS_Total_Pages:word;
    EMS_Pages_Available:word;
    EMS_version:st3; {3 character string containing version number}

  {misc functions}
  Function Hex_String (Number: Integer): ST5;
  {init & status functions}
  Function EMS_Installed: Boolean;
  Procedure Error (Error_Message: ST80; Error_Number: Integer);

  {allocation, mapping and deallocation functions}
  Function EMS_Allocate(Var Handle: word;Pages_Needed: word): byte;
  Function EMS_Map(Handle, Logical_Page:word;physical_page:byte): byte;
  Function EMS_Deallocate(Handle: word): byte;
  Function EMS_MapMultiple(Handle,count:word; mappingdata:pointer;func:byte): byte;

  IMPLEMENTATION
  

  {------------------------------------------------------------}
  { The function Hex_String converts an integer into a four    }
  { character hexadecimal number (string) with leading zeros.  }
  {------------------------------------------------------------}
  Function Hex_String (Number: Integer): ST5;
    Function Hex_Char (Number: Integer): Char;
      Begin
        If Number < 10 then
          Hex_Char := Char (Number + 48)
        else
          Hex_Char := Char (Number + 55);
      end; { Function Hex_char }

  Var
    S: ST5;

  Begin
    S := '';
    S := Hex_Char ((Number shr 1) shr 11);
    Number := (((Number shr 1) mod 2048) shl 1) + (Number and 1);
    S := S + Hex_Char (Number shr 8);
    Number := Number mod 256;
    S := S + Hex_Char (Number shr 4);
    Number := Number mod 16;
    S := S + Hex_Char (Number);
    Hex_String := S + 'h';


  end; { Function Hex_String }


  {------------------------------------------------------------}
  { The function EMS_Installed checks to see if the            }
  { EMS is loaded in memory.  It does this by looking          }
  { for the string 'EMSXXXX0', which should be located         }
  { at 10 bytes from the beginning of the code segment the     }
  { EMS interrupt, 67h, points to.                             }
  { Also gets system information                               }
  {------------------------------------------------------------}
  Function EMS_Installed: Boolean;
    Var
      EMS_Device_Name   : string[8];
      Int_67_Device_Name: string[8];
      Position          : integer;
      Regs              : registers;

    Begin
      Int_67_Device_Name := '';
      EMS_Device_Name    := 'EMMXXXX0';
      with Regs do
        Begin
          {----------------------------------------------------}
          { Get the code segment interrupt 67h points to       }
          { the EMS interrupt by using DOS function 35h.       }
          { (get interrupt vector)                             }
          {----------------------------------------------------}
          AH := $35;
          AL := EMS_INT;
          Intr (DOS_Int, Regs);
          {----------------------------------------------------}
          { The ES pseudo-register contains the segment        }
          { address pointed to by interrupt 67h.  Create an    }
          { eight character string from the eight successive   }
          { bytes at address ES:$000A (10 bytes from ES)       }
          {----------------------------------------------------}
          For Position := 0 to 7 do
            Int_67_Device_Name :=
              Int_67_Device_Name + Chr (mem[ES:Position + $0A]);
          EMS_Installed := True;
          {----------------------------------------------------}
          { If the string is the EMS manager signature,        }
          { 'EMSXXXX0', then EMS is installed and ready for    }
          { use.  If not, then EMS is not present.             }
          {----------------------------------------------------}
          If Int_67_Device_Name <> EMS_Device_Name
            then EMS_Installed := False;
        end; { with Regs do }

      asm
        mov ah,GET_UNALLOCATED_PAGE_COUNT
        int EMS_INT
        {----------------------------------------------------}
        { Unload the pseudo-registers after invoking EMS.    }
        {    BX = currently unallocated pages                }
        {    DX = total pages in the system                  }
        {    AH = status                                     }
        {----------------------------------------------------}
        mov EMS_Pages_Available,bx
        mov EMS_Total_pages,dx

        {----------------------------------------------------}
        {    AH = get page frame segment function            }
        {----------------------------------------------------}
        mov ah,GET_PAGE_FRAME
        int EMS_INT
        {----------------------------------------------------}
        { Unload the pseudo-registers after invoking EMS.    }
        {    BX = page frame segment address                 }
        {    AH = status                                     }
        {----------------------------------------------------}
        mov EMS_BASE_Address,BX

        {----------------------------------------------------}
        {
        {    AH = get EMS version function                   }

        mov ah,GET_VERSION
        int EMS_INT
        {----------------------------------------------------}
        { If the version number returned was OK, then        }
        { convert it to a three-character string.            }
        {----------------------------------------------------}
        cmp ah,status_ok
        jnz @error
            {------------------------------------------------}
            { The upper four bits of AH are the integer      }
            { portion of the version number, the lower four  }
            { bits are the fractional portion.  Convert the  }
            { integer value to ASCII by adding 48.           }
            {------------------------------------------------}
            lea di,EMS_Version
            mov dh,3
            mov ds:[di],dh

            {Integer_Part    := Char (AL shr 4  + 48);}
            mov dh,al
            shr dh,4
            add dh,48
            {mov Integer_Part,dh}
            mov ds:[di+1],dh
            mov dh,'.'
            mov ds:[di+2],dh
            {Fractional_Part := Char (AL and $F + 48);}
            mov dh,al
            and dh,$f
            add dh,48
            {mov fractional_Part,dh}
            mov ds:[di+3],dh
        @error:
      end;
    end; { Function EMS_Installed }

  {------------------------------------------------------------}
  { This function requests the specified number of pages       }
  { from the EMS.                                              }
  {------------------------------------------------------------}
  Function EMS_Allocate(Var Handle: word;Pages_Needed: word): byte;assembler;
  asm
    {----------------------------------------------------}
    { Allocate the specified number of pages from EMS.   }
      { Load pseudo-registers prior to invoking EMS.       }
      {    AH = allocate pages function.                   }
      {    BX = number of pages to allocate.               }
      {----------------------------------------------------}
      mov AH, ALLOCATE_PAGES;
      mov BX, Pages_Needed;
      int EMS_int
      {----------------------------------------------------}
      { Unload the pseudo-registers after invoking EMS.    }
      {    DX = EMS handle                                 }
      {    AH = status                                     }
      {----------------------------------------------------}
      les di,Handle
      mov es:[di],dx
      {move into result variable}
      mov al,ah
    end;

  {------------------------------------------------------------}
  { This function maps a logical page allocated by the         }
  { Allocate_Expanded_Memory_Pages function into one of the    }
  { four physical pages.                                       }
  {------------------------------------------------------------}
  Function EMS_MapMultiple(Handle,count:word; mappingdata:pointer;func:byte): byte;assembler;
    asm
       {----------------------------------------------------}
       { Map a logical page at a physical page.             }
       { Load pseudo-registers prior to invoking EMS.       }
       {    AH = map page function                          }
       {    DX = handle                                     }
       {    CX = Count                                      }
       {    AL = SUB FUNCTION                               }
       {    DS:SI = POINTER TO DATA                         }
       {----------------------------------------------------}
       mov bx,ds

       mov ah,MAP_MULTIPLE_PAGES
       mov al,func
       mov DX,Handle
       mov cx,count

       lds si,mappingdata

       int EMS_INT
       {move into result register}
       mov al,ah;
       mov ds,bx
    end; { Function Map_Expanded_Memory_Pages }

  Function EMS_Map(Handle, Logical_Page:word; Physical_Page: byte): byte;assembler;
    asm
       {----------------------------------------------------}
       { Map a logical page at a physical page.             }
       { Load pseudo-registers prior to invoking EMS.       }
       {    AH = map page function                          }
       {    DX = handle                                     }
       {    BX = logical page number                        }
       {    AL = physical page number                       }
       {----------------------------------------------------}
       mov ah,MAP_PAGES
       mov DX,Handle
       mov EMS_current_handle,DX;
       {0-3}
       mov BX,Logical_Page
       mov AL,Physical_Page
       int EMS_INT
       {move into result register}
       mov al,ah;
    end; { Function Map_Expanded_Memory_Pages }

  {------------------------------------------------------------}
  { This function releases the EMS memory pages allocated to   }
  { us, back to the EMS memory pool.                           }
  {------------------------------------------------------------}
  Function EMS_Deallocate(Handle: word): byte;assembler;
    asm
      {----------------------------------------------------}
      { Deallocate the pages allocated to an EMS handle.   }
      { Load pseudo-registers prior to invoking EMS.       }
      {    AH = deallocate pages function                  }
      {    DX = EMS handle                                 }
      {----------------------------------------------------}
      mov ah,DEALLOCATE_PAGES
      mov dx,Handle
      int EMS_INT
      {----------------------------------------------------}
      {    AH = status                                     }
      {----------------------------------------------------}
      mov al,ah
   end; { Function Deallocate_Expanded_Memory_Pages }

  {------------------------------------------------------------}
  { This procedure prints an error message passed by the       }
  { caller, prints the error code passed by the caller in hex, }
  { and then terminates the program with an error level of 1.  }
  {------------------------------------------------------------}
  Procedure Error (Error_Message: ST80; Error_Number: Integer);
    Begin
      Writeln (Error_Message);
      Writeln ('  Error_Number = ', Hex_String (Error_Number));
      Writeln ('EMS test program aborting.');
      Halt (1);
    end; { Procedure Error }

end.


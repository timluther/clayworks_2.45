Unit DMA;

INTERFACE
const
DMA_Channel=0;
DMAbaseAdd=0;
DmaPageReg=0;


Type
DMAinfo=record
  Page:byte;
  Offset:word;
  Length:word;
end;

IMPLEMENTATION

{    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; IN: DX:AX = segment/offset address of memory area
    ;
    ;OUT: DH = Page (0-F)  (DL is destroyed)
    ;     AX = Offset
    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure MakePage;assembler;
asm
  mov     bl,dh   {save lower byte of segment}
  shr     bl,4    {isolate upper 4 bits of segment}
  shl     dx,4    {make segment into ABS address}
  add     ax,dx   {add the offset and put it in AX}
  adc     bl,0    {complete the addition}
  mov     dh,bl   {put the PAGE where it goes}
                  {DH:AX is now the PAGE:OFFSET address}
end;

Procedure MakePageVars(inp:pointer;var outpage:byte;var outoffs:word);assembler;
asm
  mov     bl,byte ptr inp+3   {save lower byte of segment}
  mov     ax,word ptr inp

  shr     bl,4    {isolate upper 4 bits of segment}
  shl     dx,4    {make segment into ABS address}
  add     ax,dx   {add the offset and put it in AX}
  adc     bl,0    {complete the addition}

  les di,outoffs
  mov es:[di],ax
  les di,outpage
  mov es:[di],bl
end;

{    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; This routine programs the DMAC for channels 0-7
    ;
    ; IN: [DMA_Channel], [DMAbaseAdd], [DMApageReg] must be setup
    ;       [DAMBaseAdd] =  Memory Address port
    ;
    ;     dh = mode
    ;     ax = address
    ;     cx = length
    ;     dl = page
    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure Prog_DMA47;assembler;
asm
  push    bx
  mov     bx,ax

  mov     al,[DMA_Channel]
  out     0D4h,al         { mask reg bit}

  sub     al,al
  out     0D8h,al         { clr byte ptr}

  mov     al,[DMA_Channel]
  sub     al,4
  add     al,dh
  out     0D6h,al         { set mode reg}

  push    dx

  mov     dx,[DMAbaseAdd]
  mov     al,bl
  out     dx,al           ;{set base address low}
  mov     al,bh
  out     dx,al           { set base address high}

  add     dl,2            {point to length}
  mov     al,cl
  out     dx,al           { set length low}
  mov     al,ch
  out     dx,al           { set length high}

  pop     dx

  mov     al,dl
  mov     dx,[DmaPageReg]
  out     dx,al           { set DMA page reg}

  mov     al,[DMA_Channel]
  and     al,00000011b
  out     0D4h,al         { unmask (activate) dma channel}
  pop     bx
  ret
END;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; This routine programs the DMAC for channels 0-7
;
; IN: [DMA_Channel], [DMAbaseAdd], [DMApageReg] must be setup
;       [DAMBaseAdd] =  Memory Address port
;
;     dh = mode
;     ax = address
;     cx = length
;     dl = page
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

procedure Prog_DMA;assembler;
asm
  push    bx
  mov     bx,ax

  cmp     byte ptr [DMA_Channel],4
  jb      @@DoDMA03

  mov     al,[DMA_Channel]
  out     0D4h,al         { mask reg bit}

  sub     al,al
  out     0D8h,al         { clr byte ptr }

  mov     al,[DMA_Channel]
  sub     al,4
  add     al,dh
  out     0D6h,al         { set mode reg}

  push    dx

  mov     dx,[DMAbaseAdd]
  mov     al,bl
  out     dx,al           { set base address low}
  mov     al,bh
  out     dx,al           { set base address high}

  add     dl,2            {point to length}
  mov     al,cl
  out     dx,al           { set length low}
  mov     al,ch
  out     dx,al           { set length high}

  pop     dx

  mov     al,dl
  mov     dx,[DmaPageReg]
  out     dx,al           { set DMA page reg}

  mov     al,[DMA_Channel]
  and     al,00000011b
  out     0D4h,al         { unmask (activate) dma channel}
  pop     bx
  ret

@@DoDMA03:
  mov     al,4
  add     al,[DMA_Channel]
  out     0Ah,al          { mask reg bit}

  sub     al,al
  out     0Ch,al          { clr byte ptr}

  mov     al,dh
  add     al,[DMA_Channel]
  out     0Bh,al          { set mode reg}

  push    dx

  mov     dx,[DMAbaseAdd]
  mov     al,bl
  out     dx,al           { set base address low}
  mov     al,bh
  out     dx,al           { set base address high}

  inc     dx              {point to length}
  mov     al,cl
  out     dx,al           { set length low}
  mov     al,ch
  out     dx,al           { set length high}

  pop     dx

  mov     al,dl
  mov     dx,[DmaPageReg]
  out     dx,al           { set DMA page reg}

  mov     al,[DMA_Channel]
  out     0Ah,al          { unmask (activate) dma channel}
  pop     bx
  ret

end;

end.
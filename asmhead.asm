; reset vector
; 8086:  0xFFFF0, CS=0xFFFF, IP=0
; 80826: 0xFFFF0, CS=0xF000, IP=0xFFF0
; 80386: 0xFFFFFFF0, CS.selector=0xF000, CS.base




;======================================================================
;
; Boot time memory layout
; 0x00000000 - 0x000003FF  1KB real mode interrupt vector table IVT
; 0x00000400 - 0x000004FF  256 bytes BDA bios data area
; 0x00000500 - 0x00007BFF  ~30KB, free to use
; 0x00007C00 - 0x00007DFF  512 bytes boot sector
; 0x00007E00 - 0x0007FFFF  free to use
; 0x00080000 - 0x0009FBFF  free to use
; 0x0009FC00 - 0x0009FFFF  EBDA, extended bios data area
; 0x000A0000 - 0x000FFFFF  video memory and ROM area, 384K UMA (upper memory area), the first 128KB is video ram
;
; 0x000A0000 - 0x000BFFFF  video ram
; monochrom: 0xB0000 - 0xB7FFF
; text:      0xB8000 - 0xBFFFF
;
;=====================================================================




;==============================================================
;
;  0x00000000 - 0x000FFFFF: used at boot time
;  0x00100000 - 0x00267FFF: we save the floopy image here
;  0x00268000 - 0x0026F7FF: empty 30KB
;  0x0026F800 - 0x0026FFFF: IDT 2kB
;  0x00270000 - 0x0027FFFF: GDT 64KB
;  0x00280000 - 0x002FFFFF: bootpack.hrb 512KB
;  0x00300000 - 0x003FFFFF: stack and other data 1MB
;  0x00400000 -           : empty
;
;================================================================



[BITS 16]

; the following are 32bit address using in protected mode
botpak  equ     0x00280000   ; we put bootpack code here 
dskcac  equ     0x00100000   ; bootsect code is saved here, dskcac is short for disk cache
dskcac0 equ     0x00008000   ; the rest of the data we read from floopy disk in bootsect are moved to here


; the following are places we store 
; configuration information
cyls    equ     0x0ff0      
leds    equ     0x0ff1
vmode   equ     0x0ff2      
scrnx   equ     0x0ff4      
scrny   equ     0x0ff6      
vram    equ     0x0ff8      

vbemode equ     0x105   





org 0xC400

;section .text

    ; test whether VBE is supported
    mov   ax,0x9000
    mov   es,ax
    mov   di,0
    mov   ax,0x4f00
    int   0x10
    cmp   ax,0x004f
    jne   scrn320

    ; if supported, VBE information
    ; is stored at [ES:DI]
    mov   ax,[es:di+4]
    cmp   ax,0x0200
    jb    scrn320   
    mov   cx,vbemode
    mov   ax,0x4f01
    int   0x10
    cmp   ax,0x004f
    jne   scrn320

    cmp   byte [es:di+0x19],8
    jne   scrn320

    cmp   byte [es:di+0x1b],4
    jne   scrn320

    mov   ax,[es:di+0x00]
    and   ax,0x0080
    jz    scrn320   


    mov   bx,vbemode+0x4000
    mov   ax,0x4f02
    int   0x10

    mov   byte [vmode],8
    mov   ax,[es:di+0x12]
    mov   [scrnx],ax
    mov   ax,[es:di+0x14]
    mov   [scrny],ax
    mov   eax,[es:di+0x28]
    mov   [vram],eax

    jmp   keystatus


    ; set VGA card to  320x200x8 mode

scrn320:

    mov  al,0x13     
    mov  ah,0x00
    int  0x10


    mov  byte  [vmode],8
    mov  word  [scrnx],320
    mov  word  [scrny],200
    mov  dword [vram],0x000a0000


    ;=========================================================================
    ;
    ; INT 0x16, AH=0x02, keyboard service
    ;
    ; Expects: AH 02H
    ;
    ; Returns: AL KbdShiftFlagsRec (status of Ctl, Alt, etc.)
    ; 
    ; Info: Returns the current status of the shift keys.  This is the same
    ;       as the byte at 0040:0017 in the BIOS Data Area.
    ;
    ; Notes: Additional shift-key information is available via INT 16H 12H
    ;        for systems equipped with 101-key BIOSes.
    ;
    ; There is no corresponding fn to set the keyboard shift status.
    ;
    ;  bit mask
    ;  0:  01H alpha-shift (right side) DOWN
    ;  1:  02H alpha-shift (left side) DOWN
    ;  2:  04H Ctrl-shift (either side) DOWN
    ;  3:  08H Alt-shift  (either side) DOWN
    ;  4:  10H ScrollLock state
    ;  5:  20H NumLock state
    ;  6:  40H CapsLock state
    ;  7:  80H Insert state
    ;
    ; Note: AH=0x12 returns extended keyboard shift status (16bit status in ax)
    ;
    ;=========================================================================


keystatus:

    mov    ah,0x02
    int    0x16        
    mov    [leds],al ; store keyboard shift flag to leds


    ;==========================================================================
    ;
    ; Programming with the 8259 PIC
    ;
    ; Each chip (master and slave) has a command port and a data 
    ; port (given in the table below). When no command is issued, 
    ; the data port allows us to access the interrupt mask of the 8259 PIC.
    ;
    ; Chip - Purpose  I/O port
    ; Master PIC - Command    0x0020
    ; Master PIC - Data       0x0021
    ;
    ; Slave PIC - Command     0x00A0
    ; Slave PIC - Data        0x00A1 
    ;
    ;
    ; If you are going to use the processor local APIC and the IOAPIC, 
    ; you must first disable the PIC. This is done via:
    ;
    ; mov al, 0xff
    ; out 0xa1, al
    ; out 0x21, al
    ;

    mov    al,0xff
    out    0x21,al
    nop                 
    out    0xa1,al


    ;=======================================================================================
    ;
    cli ; before entering into protected mode, we have to disable interrupt                 
    ;??? do we have to use sti later ????

    ;=========================================================================================
    ;
    ; see AEB's A20 page:
    ;
    ; The output port of the keyboard controller has a number of functions.
    ; Bit 0 is used to reset the CPU (go to real mode) - a reset happens when bit 0 is 0.
    ; Bit 1 is used to control A20 - it is enabled when bit 1 is 1, disabled when bit 1 is 0.
    ; One sets the output port of the keyboard controller by first writing 0xd1 to port 0x64, 
    ; and the the desired value of the output port to port 0x60. 
    ; One usually sees the values 0xdd and 0xdf used to disable/enable A20. 
    ;
    ; PS/2 Controller IO Ports
    ;
    ; 0x60 R/W Data Port
    ; 0x64 R   Status Register
    ; 0x64 W   Command Register
    ;
    ; why 0x64 is not R/W ??
    ;
    ;==========================================================================================

    call    waitkbdout    ; wait until keyboard is ready 
    mov     al,0xd1       ; oxd1, write next byte to controller output port
    out     0x64,al       ; send command
    call    waitkbdout
    mov     al,0xdf       ; 0xdf is the command to enable A20 
    out     0x60,al       ; write 0xdf to 8042 controller to enable A20
    call    waitkbdout    ; after return, A20 should be enabled









    ;=================================================
    ;
    ; Enter into protected mode
    ;
    ; CR0: PE(0), protected mode enable
    ;      MP(1), monitor co-processor
    ;      EM(2), x87 emulation
    ;      TS(3), task switched
    ;      ET(4), extension type
    ;      NE(5), numeric error
    ;      WP(16), write protect
    ;      AM(18), alignment mask
    ;      NW(29), not-write through
    ;      CD(30), cache disable
    ;      PG(31), paging
    ;
    ;=================================================

;[BITS 32]

    mov ax,0
    mov ds,ax

    lgdt    [gdtr0]     
    mov     eax,cr0
    and     eax,0x7fffffff  ; 0111,111..., clear PG bit, why ??
    or      eax,0x00000001  ; set PE bit
    mov     cr0,eax         ; lmsw (load machine status word) also work, but seldom used I guess

    jmp     pipelineflush ; use jmp intruction immediately after setting up CR0 
                          ; according to the author of this book. This has
                          ; something to do with pipeline mechanism in protected mode
                          ; thus the name of the jump point



pipelineflush:

;===============================================================================
;
; segment register changed it meaning after cpu entering into protected mode
; they become selectors. 
;
; bit 0-1 (RPL, request privilege level) determines the privilege level 
;         of of the request (00: ring0, 01: ring1, 10: ring2, 11: ring3)
;
; bit 2 (TI, I think it's short for Table Index) 
;       specifies if the operation is used with GDT(0) or LDT(1)
;
; bit 3-15 of a selector is the index of an entry in the descriptor table 
;
; | 15 | 14 | 13 | 12 | 11 | 10 | 09 | 08 | 07 | 06 | 05 | 04 | 03 | 02 | 01 | 00 |
; |  DT entry index                                                | TI | RPL     |
;
; DS = 0x0008 = 0000 0000 0000 1000
; DT entry index = 0000 0000 0000 1
; TI = 0, GDT
; PRL = 0, highest privilege
;
;
; 1. bootsector is loaded by BIOS into memory at the location 0x7C00
; 2. boot code copies 10 cylinders (512 x 18 x 2 x 10 = 0x2D000 bytes) into memory at the location 0x8000-0x35000
;    (note that the actually copy start from 0x8200, the first 512 byte is left out)
; 3. bootsect + FAT + root entry = 512+18*512+14*512 = 33*512 = 0x4200 bytes, 
;    so the kernel code start at 0x8000+0x4200 = 0xC200,
;    in linux, mount flopyy image and copy kernel, the kernel starts from the 4th cluster 
;    (0,1, cluster does not exist, so 4th cluster is acutully the second cluster)
;    so in this case, kernel code's memory position is at 0xC400
;
; 4. We jump to 0xC200/0xC400, start executing instructions in asmhead.asm 
; 5. after setting up protected mode, we copy bootpack code to 0x00280000
;
;================================================================================


    ; set segment registers so that they point to the first entry (data segment) 
    ; in the GDT
    mov     ax,1*8      
    mov     ds,ax 
    mov     es,ax 
    mov     fs,ax
    mov     gs,ax
    mov     ss,ax   ; ds = es = fs = gs = ss = 8


    ;================================================
    ;
    ; copy code/data start from bootpack to botpak, 
    ; the number of bytes = 512KB = 64K DWORD
    ;
    ;=================================================
    mov     esi,bootpack
    mov     edi,botpak  
    mov     ecx,512*1024/4
    call    memcpy  


    ; copy 512 bytes (the boot sector) from 0x7C00 to dskcac (disk cache)
    mov     esi,0x7C00  
    mov     edi,dskcac  
    mov     ecx,512/4
    call    memcpy


    ; copy cached floppy data in dskcac0 to dskcac
    mov     esi,dskcac0+512
    mov     edi,dskcac+512

    mov     ecx,0
    mov     cl, [cyls] ; ecx = cyls

    imul    ecx,512*18*2/4
    sub     ecx,512/4   
    call    memcpy


    xchg bx,bx


; the following are special heads defined by the author,
; I guess it copies data segment to 0x00310000
; [base+00] = ??
; [base+04] = 'Hari'
; [base+08] = ??
; [base+12] = 0x00310000
; [base+16] = the size of data segment in bytes
; [base+20] = the offset of data segment in exe image 
; [base+24].... code segment
;


    mov     ebx,botpak
    mov     ecx,[ebx+16] ; ecx the size of data segment in bytes
    add     ecx,3        ; 
    shr     ecx,2        ; (ecx+3)/4 convert the size of data segment in bytes to size in double-word (4bytes)
    jz      skip         ; only when ecx = 0 will this be skipped
    mov     esi,[ebx+20]
    add     esi,ebx
    mov     edi,[ebx+12]
    call    memcpy



    xchg bx,bx

skip:
    mov   esp,[ebx+12]  ; esp = 0x0031_0000
    ;mov esp, 0x00310000
    jmp dword 2*8:ENTRY
    ;jmp   dword 2*8:0x0000001b  ; mixed jump, jump to 32 bit address
                                ; 2*8 the second entry in GDT
                                ; 0x0000,001b the entry point of kernel


    ;
    ; after jump:
    ;  push ebp
    ;  mov ebp,esp
    ;  pop ebp
    ;  jmp
    ;  


;==================================================
;
; waitkbdout:
;    wait for keyboard to finish handling input
;    see AEB's A20 page
;
;==================================================

waitkbdout:
        in   al,0x64     ; read 1 byte form port 0x64 (kerboard controller)
        and  al,0x02     ; 0x02 = 0000 0100
        ; test al,0x02   ; can be used to replace al al,0x02
        jnz  waitkbdout  ; wait until the system flag bit is cleared
        ret


;=============================================
;
; memcpy:
;
;  input esi source pointer 
;        edi destination pointer
;        ecx number of DWORD to copy
;
;=============================================

memcpy:
        mov  eax,[esi]
        add  esi,4
        mov  [edi],eax
        add  edi,4
        sub  ecx,1
        jnz  memcpy      
        ret


;section .data

        align 16, db 0 ; alignb 8 or no align is ok, just somewhat slower





;======================================================================
; 
; gdt contains at least a null descriptor, a code descriptor
; and a data descriptor
;
;                     limit         base        ar
; set_segmdesc(gdt+1, 0xFFFFFFFF,   0x00000000, AR_DATA32_RW)
; set_segmdesc(gdt+2, LIMIT_BOTPAK, ADR_BOTPAK, AR_CODE32_ER)
;
; AR_DATA32_RW  = 0x4092
; LIMIT_BOTPAK  = 0x0007 FFFF
; ADR_BOTPAK    = 0x0028 0000
; AR_CODE32_ER  = 0x409A
;
;======================================================================

gdt0:
        times 8 db 0                      ; some people said it can be set to a gdt pointer, not sure

        ;==========================================
        ;
        ; data segment base 0x00000000
        ;
        ;==========================================

        ;dw 0xffff,0x0000,0x9200,0x00cf   ; each entry occupies 8 bytes
        db 0xff,0xff,0x00,0x00,0x00,0x92,0xcf,0x00 ; data segment all 4G space
        ;dw 0xffff,0x0000,0x9a28,0x0047   ; 1st entry data segment, 2nd entry code segment
        db 0xff,0xff,0x00,0x00,0x28,0x9a,0x47,0x00  ; code segment start from 0x00280000, 1M space

        dw 0                              ; ???????


;
; lgdt load a linear base address and limit value from a six-byte data operand 
; in memory into the gdtr. 
;
; If a 16-bit operand is used with LGDT or LIDT, 
; the register is loaded with a 16-bit limit and a 24-bit base, 
; and the high-order eight bits of the six-byte data operand are not used. 
;
; If a 32-bit operand is used, a 16-bit limit and a 32-bit base is loaded; 
; the high-order eight bits of the six-byte operand 
; are used as high-order base address bits.
;
; lgdt and lidt are the only instructions that directly load a linear address 
; (i.e., not a segment relative address) in 80386 Protected Mode. 
;

gdtr0:
     dw  8*3-1    ; why minus one
     dd  gdt0     ; address, 16bit or 32bit???

     align 16, db 0



bootpack:




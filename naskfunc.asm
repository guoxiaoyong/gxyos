global  bochs_magic
global  io_hlt, io_cli, io_sti, io_stihlt
global  io_in8,  io_in16,  io_in32
global  io_out8, io_out16, io_out32
global  io_load_eflags, io_store_eflags
global  load_cr0, store_cr0
global  load_gdtr, load_idtr
global  asm_inthandler21, asm_inthandler27, asm_inthandler2c
global  memtest_sub

extern  inthandler21, inthandler27, inthandler2c


section .text


;; void bochs_magic(void);
bochs_magic:
   xchg bx,bx
   ret


; hlt the system
;; void io_hlt(void);
io_hlt:
    hlt
    ret


;; void io_cli(void);
io_cli:
    cli
    ret


;; void io_sti(void);
io_sti:
    sti
    ret



;; void io_stihlt(void);
io_stihlt:
    sti
    hlt
    ret


;; int  io_in8(int port);
io_in8:
    mov   edx,[esp+4] 
    mov   eax,0
    in    al,dx
    ret


;; int  io_in16(int port);
io_in16:
    mov   edx,[esp+4] 
    mov   eax,0
    in    ax,dx
    ret


;; int  io_in32(int port);
io_in32:
    mov   edx,[esp+4] 
    in    eax,dx
    ret




;; void io_out8(int port, int data);
io_out8:
    mov   edx,[esp+4] 
    mov   al,[esp+8]  
    out   dx,al
    ret


;; void io_out16(int port, int data);
io_out16:
    mov   edx,[esp+4] 
    mov   eax,[esp+8] 
    out   dx,ax
    ret


;; void io_out32(int port, int data);
io_out32:
    mov   edx,[esp+4] 
    mov   eax,[esp+8] 
    out   dx,eax
    ret


;; int  io_load_eflags(void);
io_load_eflags:
    pushfd  
    pop   eax
    ret


;; void io_store_eflags(int eflags);
io_store_eflags:
    mov   eax,[esp+4]
    push  eax
    popfd 
    ret



;; void load_gdtr(int limit, int addr);
load_gdtr:  
    mov   ax,[esp+4]  
    mov   [esp+6],ax
    lgdt  [esp+6]
    ret


;; void load_idtr(int limit, int addr);
load_idtr:  
    mov   ax,[esp+4]  
    mov   [esp+6],ax
    lidt  [esp+6]
    ret



;; void asm_inthandler21(void);
asm_inthandler21:
    push  es
    push  ds
    pushad
    mov   eax,esp
    push  eax
    mov   ax,ss
    mov   ds,ax
    mov   es,ax

    call  inthandler21

    pop   eax
    popad
    pop   ds
    pop   es
    iretd


; =======================================
;
; pushad
; eax,ecx,edx,ebx,esp,ebp,esi,edi, 
; esp on the stack the value before eax has been put on the stack
;
; ==========================================


;; void asm_inthandler27(void);
asm_inthandler27:
    push es
    push ds
    pushad                 
    mov   eax,esp
    push  eax
    mov   ax,ss
    mov   ds,ax
    mov   es,ax

    call  inthandler27

    pop   eax
    popad
    pop   ds
    pop   es
    iretd


;; void asm_inthandler2c(void);
asm_inthandler2c:
    push  es
    push  ds
    pushad
    mov   eax,esp
    push  eax
    mov   ax,ss
    mov   ds,ax
    mov   es,ax

    call  inthandler2c

    pop   eax
    popad
    pop   ds
    pop   es
    iretd





;; unsigned int load_cr0(void);
load_cr0:	
		mov		eax,cr0
		ret

;; void store_cr0(unsigned int cr0);
store_cr0:
		mov		eax,[esp+4]
		mov		cr0,eax
		ret



;; unsigned int memtest_sub(unsigned int start, unsigned int end);
memtest_sub:  
    push  edi
    push  esi
    push  ebx

    mov   esi,0xAA55AA55                     ; pat0 = 0xaa55aa55;
    mov   edi,0x55AA55AA                     ; pat1 = 0x55aa55aa;
    mov   eax,[esp+12+4]                     ; i = start;

.mts_loop:
    mov   ebx,eax
    add   ebx,0xFFC                          ; p = i + 0xffc;
    mov   edx,[ebx]                          ; old = *p;

    mov   [ebx],esi                          ; *p = pat0;
    xor   dword [ebx],0xFFFFFFFF             ; *p ^= 0xffffffff;
    cmp   edi,[ebx]                          ; if (*p != pat1) goto fin;
    jne   .mts_fin

    xor   dword [ebx],0xFFFFFFFF             ; *p ^= 0xffffffff;
    cmp   esi,[ebx]                          ; if (*p != pat0) goto fin;
    jne   .mts_fin

    mov   [ebx],edx                          ; *p = old;
    add   eax,0x1000                         ; i += 0x1000;
    cmp   eax,[esp+12+8]                     ; if (i <= end) goto mts_loop;
    jbe   .mts_loop

    pop   ebx
    pop   esi
    pop   edi
    ret

.mts_fin:
    mov   [ebx],edx       ; *p = old;


    pop   ebx
    pop   esi
    pop   edi
    ret






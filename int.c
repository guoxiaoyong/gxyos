#include "bootpack.h"
//#include <stdio.h>


/*=============================
 *
 * Whenever a command is issued with A0=0 and D4 = 1,
 * this is interpreted as an ICW1
 *
 * IRR ISR and IMR can be read (how)
 *
 *=============================* */
void init_pic(void)
{
    io_out8(PIC0_IMR,  0xff); // disable all interrupt when program the PIC
    io_out8(PIC1_IMR,  0xff);

    // 0x20 -> A0=0, 0001_0001 -> D4 = 1, an ICW1
    // only the low 3 bit of ICW1 are meaningful in 8086 system
    // interval = 8, cascade mode, ICW4 is used
    io_out8(PIC0_ICW1, 0x11); // low-to-up edge trigger mode, fixed value
 
    // ICW2 is used to set IRQ number
    // | 7 |  6 |  5 |  4 |  3 |  2 |  1  | 0   | 
    // |  user defined         |  IR pin number |
    // we can only define the higher 5 bits
    io_out8(PIC0_ICW2, 0x20  ); // IRQ 0-7 map to INT 0x20-0x27

    // in X86 PC, the second PIC is always connect to IR2, for master PIC, always set it to 4
    io_out8(PIC0_ICW3, 1 << 2); // PIC1 connected to IR2, fixed value for IBM-compatible PC

    // un-buffered, not specially nested, normal EOI (end of interrupt)
    // 80x86 mode if last bit is 1
    // if last bit is 0, then it is in 8080/8085 mode
    // full-recursive, unbuffered, AEOI=0, x86 mode
    io_out8(PIC0_ICW4, 0x01  ); // un-buffered mode, fixed value for IBM-compatible PC

    io_out8(PIC1_ICW1, 0x11  );
    io_out8(PIC1_ICW2, 0x28  ); // IRQ 0-7 map to INT 0x28-0x2F

    // in X86 PC, the second PIC is always connect to IR2, for slave PIC, always set it to 2
    // only lower 3 bit are meaningful for slave PIC
    io_out8(PIC1_ICW3, 2     ); // =====
    io_out8(PIC1_ICW4, 0x01  );

    io_out8(PIC0_IMR,  0xfb  );  // 0x11111011
    io_out8(PIC1_IMR,  0xff  );

    return;
}


#if 0
#define PORT_KEYDAT  0x0060

struct FIFO8 keyfifo;
struct FIFO8 mousefifo;


// esp is not used!!!
void inthandler21(int *esp) {

    unsigned char data;

    // 0x61 = 0110_0001, D4=0, not a ICW1, so must be OCW2
    // for OCW2, D4 and D3 are always 0, for ICW1, D4 is always 1
    // so ICW1 and OCw2 share the same port without cause any confusion
    //
    // send EOI (end of interrupt service) signal
    //0x61 = 0110_0001 
    //the last 3 bit is the interrupt we want to clear
    //can we put this line at the end of interrupt service routine???
    io_out8(PIC0_OCW2, 0x61); // set priority, low 3 bit are priority number 1->keyboard
    

    // read from port 0x0060
    data = io_in8(PORT_KEYDAT);


    // put data into FIFO
    fifo8_put(&keyfifo, data);

    return;
}


/*
  Typical steps

  Assembly to save additional CPU context
  Invoke C handler to process interrupt
  E.g., communicate with I/O devices
  Invoke kernel scheduler
  Assembly to restore CPU context and return

*/


void inthandler2c(int *esp) {

    unsigned char data;

    // set priority, IRQ 4 in PIC1 is mouse
    io_out8(PIC1_OCW2, 0x64); 
    io_out8(PIC0_OCW2, 0x62); 

    // keyboard and mouse share the same port 0x60
    data = io_in8(PORT_KEYDAT);
    fifo8_put(&mousefifo, data);

    return;

}
#endif


void inthandler27(int *esp) {

    // IRQ7 is Parallel device conneced to PIC0
    io_out8(PIC0_OCW2, 0x67); // just clear this interrupt
    return;
}









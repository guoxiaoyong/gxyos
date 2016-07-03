

SECTIONS {



     .text 0x00: {


     LONG(0x00)       
     LONG(0x69726148) 
     LONG(0x00)       
     LONG(0x00310000) 
     LONG(SIZEOF(.data))
     LONG(SIZEOF(.text))

     *.o (.text)

     }


    .data 0x00310000 : AT(ADDR(.text) + SIZEOF(.text)) {

       *.o (.data)
       *.o (.rodata*)
     }


     .eh_frame : {}
}



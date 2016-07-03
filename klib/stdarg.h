/* copyright(C) 2003 H.Kawai (under KL-01). */

#if (!defined(STDARG_H))

#define STDARG_H	1

#if (defined(__cplusplus))
extern "C" {
#endif

/*
#define va_start(v,l)	__builtin_stdarg_start((v),l)
#define va_end			__builtin_va_end
#define va_arg			__builtin_va_arg
#define va_copy(d,s)	__builtin_va_copy((d),(s))
#define	va_list			__builtin_va_list
*/

typedef char* va_list;

// n is a define variable, this macro return the space the variable n occupied in stack space
// ceil( sizeof(n)/sizeof(int) ) * sizeof(int)
#define ALIGNSIZE(n) ( (sizeof(n)+sizeof(int)-1) &~(sizeof(int) - 1) )

// va_start get the address of the second parameter
#define va_start(ap,v) ( ap = (va_list)&v + ALIGNSIZE(v) ) 

//move ap to next parameter, 
#define va_arg(ap,t) ( *(t *)((ap += ALIGNSIZE(t)) - ALIGNSIZE(t)) ) 

#define va_end(ap) ( ap = (va_list)0 ) 

#define va_copy(a,b) 



#if (defined(__cplusplus))
}
#endif

#endif

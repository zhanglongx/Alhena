#ifndef _MESSAGE_H
#define _MESSAGE_H

#include <stdio.h>
#include <stdarg.h>

#define _ALHENA_DBG    0
#define _ALHENA_INF    ( _ALHENA_DBG + 1 )
#define _ALHENA_ERR    ( _ALHENA_INF + 1 )
#define _ALHENA_OFF    ( _ALHENA_ERR + 1 )

enum _alhena_msg_type_enum
{
    ALHENA_MSG_TYPE_STDOUT = 0,
    ALHENA_MSG_TYPE_SYSLOG
};

#ifdef __cplusplus
extern "C" {
#endif

void msg_init( int , int );
void msg( int, const char *, ... );
void msg_deinit( void );

#define msg_Dbg( ... )      msg( _ALHENA_DBG, __VA_ARGS__ );
#define msg_Info( ... )     msg( _ALHENA_INF, __VA_ARGS__ );
#define msg_Err( ... )      msg( _ALHENA_ERR, __VA_ARGS__ );

#ifdef __cplusplus
};
#endif

#endif //_MESSAGE_H


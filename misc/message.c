#ifdef HAVE_CONFIG_H
#   include <config.h>
#endif

#ifdef HAVE_SYSLOG_H
#   include <syslog.h>
#endif

#include "message.h"

static int g_print_level = _ALHENA_INF;
static void (*g_print_callback)( int, const char *, va_list ) = NULL;

static void syslog_cb( int i_level, const char *psz_fmt, va_list arg );

void msg_init( int i_log_level, int i_log_type )
{
    /* change print at runtime */
    if( i_log_level < _ALHENA_DBG )
        i_log_level = _ALHENA_DBG;
    else if( i_log_level > _ALHENA_OFF )
        i_log_level = _ALHENA_OFF;

    g_print_level    = i_log_level;
    g_print_callback = NULL;
    
    if( i_log_type == ALHENA_MSG_TYPE_SYSLOG )
    {
#ifdef HAVE_SYSLOG_H
        openlog( "alhena", LOG_PID|LOG_NDELAY, LOG_USER );
        g_print_callback = syslog_cb;
#else
        fprintf( stderr, "alhena [error]: system doesn't support syslog\n" );
#endif
    }
}    

void msg_deinit()
{
#ifdef HAVE_SYSLOG_H
    if( g_print_callback == syslog_cb )
        closelog();
#endif
}

// XXX: 1. this is *not* reentrantable now!!
//      2. always print on stderr
void msg( int i_level, const char *psz_fmt, ... )
{
    if( i_level >= g_print_level )
    {
        char *psz_prefix;

        va_list arg;        
        va_start( arg, psz_fmt );

        switch( i_level )
        {
            case _ALHENA_ERR:
                psz_prefix = "error";
                break;
            case _ALHENA_INF:
                psz_prefix = "out";
                break;
            case _ALHENA_DBG:
                psz_prefix = "debug";
                break;
            default:
                psz_prefix = "unknown";
                break;
        }
        
        fprintf( stderr, "alhena [%s]: ", psz_prefix );
        vfprintf( stderr, psz_fmt, arg );
        fprintf( stderr, "\n" );

        if( g_print_callback )
            g_print_callback( i_level, psz_fmt, arg );

        va_end( arg );
    }
}

#ifdef HAVE_SYSLOG_H
static void syslog_cb( int i_level, const char *psz_fmt, va_list arg )
{
    if( i_level >= g_print_level )
    {
        int  i_facility = LOG_USER;

        switch( i_level )
        {
            case _ALHENA_ERR:
                i_facility |= LOG_INFO;
                break;
            case _ALHENA_INF:
                i_facility |= LOG_INFO;
                break;
            case _ALHENA_DBG:
                i_facility |= LOG_DEBUG;
                break;
            default:
                i_facility |= LOG_DEBUG;
                break;
        }
        
        vsyslog( i_facility, psz_fmt, arg );
    }
}
#else
static void syslog_cb( int i_level, const char *psz_fmt, va_list arg )
{
    
}
#endif


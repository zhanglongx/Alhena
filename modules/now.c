#include <time.h>

#include "analyser/common.h"
#include "analyser/modules.h"

typedef struct _now_t
{
    int     i_look_back;

    int     i_loc_year;
    int     i_loc_month;
    int     i_loc_day;

    /* record nearest date */
    struct {
        int     i_day;
        int     i_month;
        int     i_year;
    }record;

}now_t;

#define delta_day( y1, m1, d1, y2, m2, d2 ) \
    (julian( (y2), (m2), (d2) ) - julian( (y1), (m1), (d1) ))

static int julian( int , int , int  );

void *alhena_module_now_init( variable_t *p_configs, alhena_data_t *p_data, 
                              int i_total, float *p_output )
{
    now_t *p;
    time_t timer;
    struct tm *loc;

    p = (now_t *)calloc( 1, sizeof( now_t ) );
    if( !p )
        return NULL;

    p->i_look_back = var_get_integer( p_configs, "now-lookback" );

    time( &timer );

    loc = localtime( &timer );

    p->i_loc_year  = loc->tm_year + 1900;
    p->i_loc_month = loc->tm_mon + 1;
    p->i_loc_day   = loc->tm_mday;

    return (void *)p;
}

void alhena_module_now_deinit( void *h )
{
    now_t *p = (now_t *)h;

    if( p->record.i_year )
    {
        fprintf( stdout, "now," );
        fprintf( stdout, "%d-%02d-%02d\n",
                         p->record.i_year,
                         p->record.i_month,
                         p->record.i_day );
    }

    free( p );
}

bool alhena_module_now_record_pre( void *h, alhena_data_t *p_data, 
                                   int i_day, int i_end )
{
    now_t *p = (now_t *)h;
    int i_year, i_month, i_mday;

    i_year  = p_data->day[i_day].i_year;
    i_month = p_data->day[i_day].i_month;
    i_mday  = p_data->day[i_day].i_day;

    if( delta_day( i_year, i_month, i_mday, p->i_loc_year, p->i_loc_month, p->i_loc_day )
            > p->i_look_back )
        return false;

    p->record.i_year  = i_year;
    p->record.i_month = i_month;
    p->record.i_day   = i_mday;
    
    return true;
}

static int julian( int year, int month, int day ) 
{ 
    int a = (14 - month) / 12; 
    int y = year + 4800 - a; 
    int m = month + 12 * a - 3; 
    if (year > 1582 || (year == 1582 && month > 10) || (year == 1582 && month == 10 && day >= 15)) 
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045; 
    else 
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083; 
} 


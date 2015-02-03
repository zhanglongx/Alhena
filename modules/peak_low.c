#include "analyser/common.h"
#include "analyser/modules.h"

#include "peak_low.h"

typedef struct _peak_low_t
{
    int     i_max_stat_days;
    int     i_records;
    
    /* each record have a slot */
    struct {
        int     i_day;
        int     i_month;
        int     i_year;
    }day[MAX_DAYS];
    
    float   lowest1[MAX_DAYS];
    int     lowest_day1[MAX_DAYS];

    float   highest[MAX_DAYS];
    int     highest_day[MAX_DAYS];

    float   lowest2[MAX_DAYS];
    int     lowest_day2[MAX_DAYS];
}peak_low_t;

void *alhena_module_peaklow_init( variable_t *p_config, alhena_data_t *p_data,
                                  int i_total, float *p_output_data )
{
    peak_low_t *p_stat = NULL;

    p_stat = (peak_low_t *)calloc( 1, sizeof( peak_low_t ) );
    if( !p_stat )
    {
        msg_Err( "alloc peak_low_t failed" );
        return NULL;
    }

    p_stat->i_max_stat_days = var_get_integer( p_config, "peak-low-max-days" );

    return (void *)p_stat;
}

bool alhena_module_peaklow_record_pre( void *h, alhena_data_t *p_data, 
                                       int i_day, int i_end )
{
    peak_low_t *p_stat = (peak_low_t *)h;
    float f_highest, f_lowest;
    float f_flag_close = p_data->f_close[i_day];
    int i;

    i_end = MIN( i_end, i_day + p_stat->i_max_stat_days );
    if( i_day >= i_end - 2 )
        return false;

    /* init */

    f_highest = 0.0;
    f_lowest  = 8000.0; // this should be high enough

    for( i=i_day+1; i<i_end; i++ )
    {
        if( p_data->f_low[i] < f_lowest )
        {
            f_lowest = p_data->f_low[i];
            p_stat->lowest_day2[p_stat->i_records] = i - i_day;
        }

        if( p_data->f_high[i] > f_highest )
        {
            f_highest = p_data->f_high[i];
            p_stat->highest_day[p_stat->i_records] = i - i_day;
        }
    }

    /* in percentage */
    p_stat->lowest2[p_stat->i_records] = (f_lowest - f_flag_close) / f_flag_close;
    p_stat->highest[p_stat->i_records] = (f_highest - f_flag_close) / f_flag_close;

    f_lowest = 8000.0;
    i_end = i_day + p_stat->highest_day[p_stat->i_records];

    for( i=i_day+1; i<=i_end; i++ )
    {
        if( p_data->f_low[i] < f_lowest )
        {
            f_lowest = p_data->f_low[i];
            p_stat->lowest_day1[p_stat->i_records] = i - i_day;
        }
    }

    p_stat->lowest1[p_stat->i_records] = (f_lowest - f_flag_close) / f_flag_close;

    p_stat->day[p_stat->i_records].i_day   = p_data->day[i_day].i_day;
    p_stat->day[p_stat->i_records].i_month = p_data->day[i_day].i_month;
    p_stat->day[p_stat->i_records].i_year  = p_data->day[i_day].i_year;

    p_stat->i_records++;

    return true;
}

void alhena_module_peaklow_deinit( void *h )
{
    peak_low_t *p_stat = (peak_low_t *)h;
    int i;

    for( i=0; i<p_stat->i_records; i++ )
    {
        fprintf( stdout, "stat," );
        fprintf( stdout, "%d/%d/%d,",
                         p_stat->day[i].i_month,
                         p_stat->day[i].i_day,
                         p_stat->day[i].i_year );
        fprintf( stdout, "%f,%d,%f,%d,%f,%d\n", 
                         p_stat->lowest1[i],
                         p_stat->lowest_day1[i],
                         p_stat->highest[i], 
                         p_stat->highest_day[i],
                         p_stat->lowest2[i],
                         p_stat->lowest_day2[i] );
    }

    free( p_stat );
}


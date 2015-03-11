#include "analyser/common.h"
#include "analyser/modules.h"

#include "peak_low.h"
#include "fi.h"

typedef struct _peak_low_t
{
    int     i_max_stat_days;
    int     i_records;

    float   fi[MAX_DAYS];

    int     up_days[MAX_DAYS];          /* up days before fi up */
    float   go_down[MAX_DAYS];          /* avg value go down between fi up and fi down */
    int     go_days[MAX_DAYS];          /* days between fi up and fi down */
    
    /* each record have a slot */
    struct {
        int     i_day;
        int     i_month;
        int     i_year;
    }day[MAX_DAYS];
    
    float   lowest1[MAX_DAYS];          /* first lowest value after happens */
    int     lowest_day1[MAX_DAYS];      /* first lowest value's day */

    float   highest[MAX_DAYS];          /* highest value after happens */
    int     highest_day[MAX_DAYS];      /* highest value's day */

    float   lowest2[MAX_DAYS];          /* reserved */
    int     lowest_day2[MAX_DAYS];      /* reserved */
}peak_low_t;

void *alhena_module_peaklow_init( variable_t *p_config, alhena_data_t *p_data,
                                  int i_total, float *p_output_data )
{
    peak_low_t *p_stat = NULL;
    int i;

    p_stat = (peak_low_t *)calloc( 1, sizeof( peak_low_t ) );
    if( !p_stat )
    {
        msg_Err( "alloc peak_low_t failed" );
        return NULL;
    }

    for( i=0; i<i_total; i++ )    
        p_stat->fi[i] = fi_v( p_data, i );

    p_stat->i_max_stat_days = var_get_integer( p_config, "peak-low-max-days" );

    return (void *)p_stat;
}

bool alhena_module_peaklow_record_pre( void *h, alhena_data_t *p_data, 
                                       int i_day, int i_end )
{
    peak_low_t *p_stat = (peak_low_t *)h;
    float f_highest, f_lowest;
    float f_flag_close = p_data->f_close[i_day];
    int i_record = p_stat->i_records;
    int i, i_start = 0;

    i_end = MIN( i_end, i_day + p_stat->i_max_stat_days );
    if( i_day >= i_end - 2 )
        return false;

#define RATIO1   (4.0f)

    for( i=1; i < i_day; i++ )
    {
        // FIXME: 80
        if( p_stat->fi[i_day-i] > avg_v( p_stat->fi, i_day - i, 80 )
                                  + RATIO1 * dev_v( p_stat->fi, i_day - i, 80 ) )
        {
            i_start = i_day - i;
            break;
        }
    }

    assert( i_start );

    p_stat->go_days[i_record] = i_day - i_start;

    for( i=1; i < i_start; i++ )
    {
        if( p_data->f_close[i_start - i] > p_data->f_close[i_start - i + 1] )
            break;

        p_stat->up_days[i_record]++;
    }

    if( i_start + 1 == i_day )
        p_stat->go_down[i_record] = (p_data->f_high[i_day] + p_data->f_low[i_day]) / 2;
    else
        p_stat->go_down[i_record] = avg_v( p_data->f_close, i_day, i_day - i_start - 1 );

    p_stat->go_down[i_record] = (p_stat->go_down[i_record] - p_data->f_close[i_start]) 
                              / p_data->f_close[i_start];

    /* find lowest */
    f_highest = .0f;
    f_lowest  = 8000.0f;

    for( i=i_day+1; i<i_end; i++ )    
    {
        if( p_data->f_high[i] > f_highest )
        {
            f_highest = p_data->f_high[i];
            p_stat->highest_day[i_record] = i - i_day;
        }
    }

    p_stat->highest[i_record] = (f_highest - f_flag_close) / f_flag_close;
    i_end = i_day + p_stat->highest_day[i_record];

    for( i=i_day+1; i<=i_end; i++ )
    {
        if( p_data->f_low[i] < f_lowest )
        {
            f_lowest = p_data->f_low[i];
            p_stat->lowest_day1[i_record] = i - i_day;
        }
    }

    p_stat->lowest1[i_record] = (f_lowest - f_flag_close) / f_flag_close;

    p_stat->day[i_record].i_day   = p_data->day[i_day].i_day;
    p_stat->day[i_record].i_month = p_data->day[i_day].i_month;
    p_stat->day[i_record].i_year  = p_data->day[i_day].i_year;    

    p_stat->i_records++;

    return true;
#undef RATIO1
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
        fprintf( stdout, "%d,%f,%d,%f,%d,%f\n",
                         p_stat->up_days[i],
                         p_stat->go_down[i],
                         p_stat->go_days[i],
                         p_stat->lowest1[i],
                         p_stat->lowest_day1[i],
                         p_stat->highest[i] );
    }

    free( p_stat );
}


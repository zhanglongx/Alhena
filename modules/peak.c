/*****************************************************************************
 * Copyright (C) 2015 Alhena project
 *
 * Authors: longxiao zhang <zhanglongx@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
  *****************************************************************************/

#include "analyser/common.h"
#include "analyser/modules.h"

#include "fi.h"
#include "peak.h"

typedef struct _peak_t
{
    int     i_max_stat_days;
    int     i_records;
    
    /* each record have a slot */
    struct {
        int     i_day;
        int     i_month;
        int     i_year;
    }day[MAX_DAYS];

    float   fi[MAX_DAYS];

    float   fi_dev[MAX_DAYS];
    
    bool    is_open_high[MAX_DAYS];     /* is high after happens */

    float   highest1[MAX_DAYS];         /* first highest value after happens */
    int     highest_day1[MAX_DAYS];     /* first highest value's day */

    float   lowest[MAX_DAYS];           /* lowest value after happens */
    int     lowest_day[MAX_DAYS];       /* lowest value's day */

    float   highest2[MAX_DAYS];         /* second highest value after happens */
    int     highest_day2[MAX_DAYS];     /* second highest value's day */
}peak_t;

void *alhena_module_peak_init( variable_t *p_config, alhena_data_t *p_data,
                               int i_total, float *p_output_data )
{
    peak_t *p_stat = NULL;
    int i;

    p_stat = (peak_t *)calloc( 1, sizeof( peak_t ) );
    if( !p_stat )
    {
        msg_Err( "alloc peak_t failed" );
        return NULL;
    }

    for( i=0; i<i_total; i++ )
        p_stat->fi[i] = fi_v( p_data, i );

    p_stat->i_max_stat_days = var_get_integer( p_config, "peak-max-days" );

    return (void *)p_stat;
}

bool alhena_module_peak_record_pre( void *h, alhena_data_t *p_data, 
                                    int i_day, int i_end )
{
    peak_t *p_stat = (peak_t *)h;
    float f_highest, f_lowest;
    float f_flag_close = p_data->f_close[i_day];
    bool is_open_high;
    int i;

    i_end = MIN( i_end, i_day + p_stat->i_max_stat_days );
    if( i_day >= i_end - 2 )
        return false;

#define FI_LENGTH   (80)

    /* init */
    p_stat->fi_dev[p_stat->i_records] = (p_stat->fi[i_day] - avg_v( p_stat->fi, i_day, FI_LENGTH ) )
                                      / dev_v( p_stat->fi, i_day, FI_LENGTH );
    
    is_open_high = p_data->f_open[i_day + 1] > f_flag_close;

    p_stat->is_open_high[p_stat->i_records] = is_open_high;
    f_highest = 0.0;
    f_lowest  = 8000.0; // this should be high enough

    for( i=i_day+1; i<i_end; i++ )
    {
        if( p_data->f_low[i] < f_lowest )
        {
            f_lowest = p_data->f_low[i];
            p_stat->lowest_day[p_stat->i_records] = i - i_day;
        }

        if( p_data->f_high[i] > f_highest )
        {
            f_highest = p_data->f_high[i];
            p_stat->highest_day2[p_stat->i_records] = i - i_day;
        }
    }

    /* in percentage */
    p_stat->lowest[p_stat->i_records]   = (f_lowest - f_flag_close) / f_flag_close;
    p_stat->highest2[p_stat->i_records] = (f_highest - f_flag_close) / f_flag_close;    

    f_highest = 0.0;
    i_end = i_day + p_stat->lowest_day[p_stat->i_records];

    for( i=i_day+1; i<=i_end; i++ )
    {
        if( p_data->f_high[i] > f_highest )
        {
            f_highest = p_data->f_high[i];
            p_stat->highest_day1[p_stat->i_records] = i - i_day;
        }
    }

    p_stat->highest1[p_stat->i_records] = (f_highest - f_flag_close) / f_flag_close;

    p_stat->day[p_stat->i_records].i_day   = p_data->day[i_day].i_day;
    p_stat->day[p_stat->i_records].i_month = p_data->day[i_day].i_month;
    p_stat->day[p_stat->i_records].i_year  = p_data->day[i_day].i_year;

    p_stat->i_records++;

    return true;
#undef FI_LENGTH
}

void alhena_module_peak_deinit( void *h )
{
    peak_t *p_stat = (peak_t *)h;
    int i;

    for( i=0; i<p_stat->i_records; i++ )
    {
        fprintf( stdout, "stat," );
        fprintf( stdout, "%d-%02d-%02d,",
                         p_stat->day[i].i_year,
                         p_stat->day[i].i_month,
                         p_stat->day[i].i_day );
        fprintf( stdout, "%d,%f,%f,%d,%f,%d,%f,%d\n", 
                         p_stat->is_open_high[i],
                         p_stat->fi_dev[i],
                         p_stat->highest1[i],
                         p_stat->highest_day1[i],
                         p_stat->lowest[i], 
                         p_stat->lowest_day[i],
                         p_stat->highest2[i],
                         p_stat->highest_day2[i] );
    }

    free( p_stat );
}


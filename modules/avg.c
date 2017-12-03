/*****************************************************************************
 * Copyright (C) 2015-2017 Alhena project
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

#include <float.h>

#include "analyser/common.h"
#include "analyser/modules.h"

#include "avg.h"

typedef struct _avg_t
{
    bool   b_output_data;
        
    float  avg[MAX_DAYS];

    bool   b_upper;
    int    i_compare_days;
    float  f_range;
    
}avg_t;

void *alhena_module_avg_init( variable_t *p_config, 
                              alhena_data_t *p_data, int i_total,
                              float *p_output_data )
{
    avg_t *p_avg;
    int i;

    p_avg = (avg_t *)calloc( 1, sizeof( avg_t ) );
    if( !p_avg )
    {
        msg_Err( "cannot alloc avg_t" );
        return NULL;
    }

    p_avg->b_upper        = var_get_bool( p_config, "avg-upper" );
    p_avg->i_compare_days = var_get_integer( p_config, "avg-compare-days" );
    p_avg->f_range        = var_get_float( p_config, "avg-range-in-percentage" );

    if( !i_total )
        return p_avg;

    for( i=0; i < i_total; i++ )
    {
        float avg = 0.0;
        int i_count = 0, k;

        for( k=i - MIN( i, p_avg->i_compare_days ); k <=i; k++ )
        {
            avg += p_data->f_close[k];
            i_count++;
        }

        p_avg->avg[i] = avg / i_count;

        if (p_output_data)
            p_output_data[i] = p_avg->avg[i];
    }

    return p_avg;
}

void alhena_module_avg_close( void *h )
{
    avg_t *p_avg = (avg_t *)h;

    free( p_avg );
}

bool alhena_module_avg_pos( void *h, alhena_data_t *p_data, 
                           int i_day, int i_end )
{
    avg_t *p_avg = (avg_t *)h;
    float f_close = p_data->f_close[i_day];

    if( p_avg->b_upper )
    {
        if( f_close > p_avg->avg[i_day] * ( 1.0 + p_avg->f_range / 100.0 ) )
            return true;
    }
    else
    {
        if( f_close < p_avg->avg[i_day] * ( 1.0 - p_avg->f_range / 100.0 ) )
            return true;
    }

    return false;
}

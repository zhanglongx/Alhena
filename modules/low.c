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

#include "low.h"

typedef struct _low_t
{
    bool   b_output_data;
        
    float  lowest[MAX_DAYS];

    int    i_compare_days;
    float  f_range;
    
}low_t;

void *alhena_module_low_init( variable_t *p_config, 
                              alhena_data_t *p_data, int i_total,
                              float *p_output_data )
{
    low_t *p_low;
    int i;

    p_low = (low_t *)calloc( 1, sizeof( low_t ) );
    if( !p_low )
    {
        msg_Err( "cannot alloc low_t" );
        return NULL;
    }

    p_low->i_compare_days = var_get_integer( p_config, "low-compare-days" );
    p_low->f_range        = var_get_float( p_config, "low-range-in-percentage" );

    if( !i_total )
        return p_low;

    for( i=0; i < i_total; i++ )
    {
        float low = FLT_MAX;
        int k;

        for( k=i - MIN( i, p_low->i_compare_days ); k <=i; k++ )
        {
            low = MIN( low, p_data->f_low[k] );
        }

        p_low->lowest[i] = low;

        if (p_output_data)
            p_output_data[i] = p_low->lowest[i];
    }

    return p_low;
}

void alhena_module_low_close( void *h )
{
    low_t *p_low = (low_t *)h;

    free( p_low );
}

bool alhena_module_low_pos( void *h, alhena_data_t *p_data, 
                           int i_day, int i_end )
{
    low_t *p_low = (low_t *)h;
    float f_close = p_data->f_close[i_day];

    if( f_close < p_low->lowest[i_day] * ( 1.0 + p_low->f_range / 100.0 ) )
        return true;

    return false;
}

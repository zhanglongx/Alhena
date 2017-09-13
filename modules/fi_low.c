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

#include <math.h>

#include "analyser/common.h"
#include "analyser/modules.h"

#include "fi.h"     /* fi_v() */
#include "fi_low.h"

typedef struct _fi_low_t
{
    bool   b_output_data;
        
    float  fi[MAX_DAYS];

    int    i_compare_days;
    int    i_look_back;
    
}fi_low_t;

void *alhena_module_filow_init( variable_t *p_config, 
                                alhena_data_t *p_data, int i_total,
                                float *p_output_data )
{
    fi_low_t *p_fi;
    int i;

    p_fi = (fi_low_t *)calloc( 1, sizeof( fi_low_t ) );
    if( !p_fi )
    {
        msg_Err( "cannot alloc fi_low_t" );
        return NULL;
    }

    for( i=0; i<i_total; i++ )
    {
        p_fi->fi[i] = fi_v( p_data, i );

        if( p_output_data )
            p_output_data[i] = p_fi->fi[i];
    }

    p_fi->i_compare_days = var_get_integer( p_config, "fi-low-compare-days" );
    p_fi->i_look_back    = var_get_integer( p_config, "fi-low-lookback" );

    return p_fi;
}

void alhena_module_filow_close( void *h )
{
    fi_low_t *p_fi = (fi_low_t *)h;

    free( p_fi );
}

bool alhena_module_filow_pos( void *h, alhena_data_t *p_data, 
                              int i_day, int i_end )
{
    fi_low_t *p_fi = (fi_low_t *)h;
    int i_length = p_fi->i_compare_days;
    int i, i_start = i_day - i_length - p_fi->i_look_back;

    if( i_start < 0 )
        return false;

#define RATIO1   (4.0f)
#define RATIO2   (4.0f)

    if( p_fi->fi[i_day] > avg_v( p_fi->fi, i_day, i_length )
                          - RATIO2 * dev_v( p_fi->fi, i_day, i_length ) )
        return false;

    for( i=i_day - p_fi->i_look_back; i<i_day; i++ )
    {
        if( p_fi->fi[i] > avg_v( p_fi->fi, i, i_length ) 
                          + RATIO1 * dev_v( p_fi->fi, i, i_length ) )
            return true;
    }

    return false;
#undef RATIO2
#undef RATIO1
}


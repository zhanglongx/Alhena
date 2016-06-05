/*****************************************************************************
 * Copyright (C) 2015,2016 Alhena project
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

#include "vol.h"

typedef struct _vol_t
{
    bool   b_output_data;
        
    uint64_t  vol[MAX_DAYS];

    int    i_compare_days;

    float  f_ratio;
    
}vol_t;

void *alhena_module_vol_init( variable_t *p_config, 
                             alhena_data_t *p_data, int i_total,
                             float *p_output_data )
{
    vol_t *p_vol;
    int i;

    p_vol = (vol_t *)calloc( 1, sizeof( vol_t ) );
    if( !p_vol )
    {
        msg_Err( "cannot alloc vol_t" );
        return NULL;
    }

    for( i=0; i<i_total; i++ )
    {
        p_vol->vol[i] = p_data->l_vol[i];

        if( p_output_data )
            p_output_data[i] = (float)p_vol->vol[i];
    }

    p_vol->i_compare_days = var_get_integer( p_config, "vol-compare-days" );
    p_vol->f_ratio        = var_get_float( p_config, "vol-ratio" );

    return p_vol;
}

void alhena_module_vol_close( void *h )
{
    vol_t *p_vol = (vol_t *)h;

    free( p_vol );
}

bool alhena_module_vol_pos( void *h, alhena_data_t *p_data, 
                            int i_day, int i_end )
{
    vol_t *p_vol = (vol_t *)h;
    int i_length = p_vol->i_compare_days;
    int i_start = i_day - i_length;

    if( i_start < 0 )
        return false;

//#define RATIO   (4.0f)
#define RATIO     (p_vol->f_ratio)

    if( p_vol->vol[i_day] < l_avg_v( p_vol->vol, i_day, i_length ) 
                          + RATIO * l_dev_v( p_vol->vol, i_day, i_length ) )
        return false;

    return true;
#undef RATIO
}


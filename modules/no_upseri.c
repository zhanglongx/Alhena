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

#include "analyser/common.h"
#include "analyser/modules.h"

#include "no_upseri.h"

typedef struct _no_upseri_t
{
    int i_back_days;    
}no_upseri_t;

void *alhena_module_no_upseri_init( variable_t *p_config, 
                                    alhena_data_t *p_data, int i_total,
                                    float *p_output_data )
{
    no_upseri_t *p;

    p = calloc( 1, sizeof( no_upseri_t ) );
    if( !p )
        return NULL;

    p->i_back_days = var_get_integer( p_config, "no-upseri-days" );
    
    return (void *)p;
}

void alhena_module_no_upseri_close( void *h )
{
    no_upseri_t *p = (no_upseri_t *)h;

    free( p );
}

bool alhena_module_no_upseri_neg( void *h, alhena_data_t *p_data, 
                                  int i_day, int i_end )
{
    no_upseri_t *p = (no_upseri_t *)h;
    int i_back_day = MAX( 0, i_day - p->i_back_days );
    int i;

    if( i_day == 0 )
        return false;

    for( i=i_back_day; i<=i_day; i++ )
    {
        if( p_data->f_close[i] < p_data->f_open[i] )
            return false;
    }

    return true;
}


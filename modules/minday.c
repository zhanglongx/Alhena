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

typedef struct _minday_t
{
    int i_start_day;
    int i_compare_days;
}minday_t;

void *alhena_module_minday_init( variable_t *p_configs, alhena_data_t *p_data, 
                                 int i_total, float *p_output )
{
    minday_t *p;

    p = (minday_t *)calloc( 1, sizeof( minday_t ) );
    if( !p )
        return NULL;

    p->i_compare_days = var_get_integer( p_configs, "minday-days" );

    return (void *)p;
}

void alhena_module_minday_deinit( void *h )
{
    minday_t *p = (minday_t *)h;

    free( p );
}

bool alhena_module_minday_pre( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    minday_t *p = (minday_t *)p_sys;
    
    p->i_start_day = i_day;

    return true;
}

bool alhena_module_minday_pos( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    minday_t *p = (minday_t *)p_sys;
    
    return (i_day - p->i_start_day > p->i_compare_days) ? true: false;
}


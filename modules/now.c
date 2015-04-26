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


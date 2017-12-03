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

#ifndef _AVG_H_
#define _AVG_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_avg_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_avg_close( void * );

bool alhena_module_avg_pos( void *h, alhena_data_t *, 
                            int, int );

alhena_module_begin( avg, "avg" )
    set_init_deinit( alhena_module_avg_init, alhena_module_avg_close )
    set_ops( NULL,
             alhena_module_avg_pos,
             NULL )
    create_config_bool_set_value( "avg-upper", false )
    create_config_integer_with_range( "avg-compare-days", 80, 1, 500 )
    create_config_float_with_range( "avg-range-in-percentage", 10.0, 1.0, 80.0 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _AVG_H_


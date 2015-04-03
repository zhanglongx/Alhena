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

#ifndef _MINDAY_H_
#define _MINDAY_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_minday_init( variable_t *, alhena_data_t *, 
                                 int , float * );
void alhena_module_minday_deinit( void * );

bool alhena_module_minday_pre( void *, alhena_data_t *, 
                               int , int );
bool alhena_module_minday_pos( void *, alhena_data_t *, 
                               int, int );

alhena_module_begin( minday, "minday" )
    set_init_deinit( alhena_module_minday_init, 
                     alhena_module_minday_deinit )
    set_ops( alhena_module_minday_pre,
             alhena_module_minday_pos,
             NULL )
    create_config_integer_with_range( "minday-days", 4, 1, 100 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _MINDAY_H_


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

#ifndef _NOW_H_
#define _NOW_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_now_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_now_deinit( void * );
bool alhena_module_now_record_pre( void *, alhena_data_t *, int , int );

alhena_module_begin( now, "now" )
    set_init_deinit( alhena_module_now_init, 
                     alhena_module_now_deinit )
    set_stats( alhena_module_now_record_pre,
               NULL )
    create_config_integer_with_range( "now-lookback", 5, 1, 12 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif /* _NOW_H_ */


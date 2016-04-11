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

#ifndef _VOL_H_
#define _VOL_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_vol_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_vol_close( void * );

bool alhena_module_vol_pos( void *h, alhena_data_t *, 
                            int, int );

alhena_module_begin( vol, "vol" )
    set_init_deinit( alhena_module_vol_init, alhena_module_vol_close )
    set_ops( NULL,
             alhena_module_vol_pos,
             NULL )
    create_config_integer_with_range( "vol-compare-days", 80, 1, 150 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _VOL_H_


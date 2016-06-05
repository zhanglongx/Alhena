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

#ifndef _MODULE_DUMMY_H_
#define _MODULE_DUMMY_H_

#ifdef __cplusplus
extern "C" {
#endif

bool alhena_module_dummy_pos( void *, alhena_data_t *, 
                              int, int );

alhena_module_begin( dummy, "dummy" )
    set_init_deinit( NULL, NULL )
    set_ops( NULL,
             alhena_module_dummy_pos,
             NULL )
    create_config_integer_with_range( "dummy-test-int", 1, 0, 10 )
    create_config_bool_set_value( "dummy-test-bool", false )
    create_config_string( "dummy-test-string", "" )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _MODULE_DUMMY_H_


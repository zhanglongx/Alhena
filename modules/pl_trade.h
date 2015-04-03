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

#ifndef _PL_TRADE_H_
#define _PL_TRADE_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_pl_trade_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_pl_trade_close( void * );

bool alhena_module_pl_trade_pre( void *, alhena_data_t *, 
                                 int , int );
bool alhena_module_pl_trade_pos( void *h, alhena_data_t *, 
                                 int, int );

alhena_module_begin( pl_trade, "pl-trade" )
    set_init_deinit( alhena_module_pl_trade_init, alhena_module_pl_trade_close )
    set_ops( alhena_module_pl_trade_pre,
             alhena_module_pl_trade_pos,
             NULL )
    create_config_float_with_range( "pl-trade-loss", 7.0, 1.0, 80.0 )
    create_config_float_with_range( "pl-trade-profit", 7.0, 1.0, 80.0 )
    create_config_float_with_range( "pl-trade-start", 3.0, 0.0, 80.0 )
    create_config_integer_with_range( "pl-trade-days", 22, 1, 40 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _PL_TRADE_H_


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

#ifndef _RULE_H_
#define _RULE_H_

#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

int  alhena_rule_init( alhena_t * );
void alhena_rule_deinit( alhena_t * );
int  alhena_rule_run( alhena_t * );
void alhena_rule_output_day( alhena_t *, int );

#ifdef __cplusplus
};
#endif

#endif // _MODULES_H_


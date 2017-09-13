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

#ifndef _ALHENA_H_
#define _ALHENA_H_

#if defined(__linux__) || defined (__APPLE__)
#   include <inttypes.h>
#   include <stdbool.h>
#   include <limits.h>
#elif defined(_MSC_VER)
/* FIXME: vs 2015 check? */
#   include <stdint.h>
#   include <stdbool.h>
#else
#   error  "not supported platform"
#endif

#include "misc/message.h"

#define  ALHENA_VERSION             "1.5.1"
#define  ALHENA_MAX_FILENAME        1024

#define  ALHENA_EOK                 (-0)
#define  ALHENA_EFATAL              (-1)
#define  ALHENA_ENEG                (-10)

#define  ALHENA_INLINE              static __inline

#define  MIN(a, b)    ((a) < (b) ? (a) : (b))
#define  MAX(a, b)    ((a) > (b) ? (a) : (b))

#if defined(__linux__) || defined (__APPLE__)
#   define ALHENA_SNPRINTF       snprintf
#   define ALHENA_STRDUP         strdup
#elif defined(_MSC_VER)
#   define ALHENA_SNPRINTF       _snprintf
#   define ALHENA_STRDUP         _strdup
#else
#   error  "not supported platform"
#endif

#define  FLOAT_TOLERABLE            (0.001)

#define  is_float_eq(f, x) \
         ((f) > (x) - FLOAT_TOLERABLE && (f) < (x) + FLOAT_TOLERABLE)

typedef struct _alhena_t alhena_t;

#ifdef __cplusplus
extern "C" {
#endif

int bank_collect(void);
void bank_decollect(void);
int parse_command_line( int , char *[] );

alhena_t *alhena_create( void );
int alhena_process_data( alhena_t * );
void alhena_output( alhena_t *h );
void alhena_delete( alhena_t * );

#ifdef __cplusplus
};
#endif

#endif // _ALHENA_H_


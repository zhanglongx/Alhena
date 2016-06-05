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

#ifndef _VARIABLES_H_
#define _VARIABLES_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "alhena.h"
#include "misc/list.h"

#define ALHENA_VAR_INTEGER          0x01
#define ALHENA_VAR_BOOL             0x02
#define ALHENA_VAR_FLOAT            0x04
#define ALHENA_VAR_STRING           0x08

#define ALHENA_MAX_VAR_NAME         (512)

typedef union
{
    int        i_int;
    bool       b_bool;
    char       *p_string;
    float      f_float;
    
}alhena_value_t;

typedef struct _variable_t
{
    struct _variable_t  *prev;
    struct _variable_t  *next;
    
    int                 i_type;
    char                psz_name[ALHENA_MAX_VAR_NAME];

    alhena_value_t      value;
    alhena_value_t      min;
    alhena_value_t      max;
    
}variable_t;

ALHENA_INLINE void __list_add_var( variable_t *l,
                                   variable_t *prev,
                                   variable_t *next )
{
    next->prev = l;
    l->next = next;
    l->prev = prev;
    prev->next = l;
}

ALHENA_INLINE void __list_del_var( variable_t * prev, variable_t * next)
{
    next->prev = prev;
    prev->next = next;
}

#define list_add_tail_var( a, v ) \
    do{ \
        __list_add_var( a, v, v->next ); \
    }while(0)

#define list_del_var( a ) \
    do{ \
        __list_del_var( a->prev, a->next ); \
    }while(0)

#ifdef __cplusplus
extern "C" {
#endif

int var_create( variable_t *, const char *, int  );
int var_integer_min_max( variable_t *, const char *, 
                         alhena_value_t , alhena_value_t  );
int var_set_integer_check( variable_t *, const char *,
                           alhena_value_t  );
int var_get_integer( variable_t *, const char * );
int var_float_min_max( variable_t *, const char *, 
                       alhena_value_t , alhena_value_t );
int var_set_float_check( variable_t *, const char *,
                         alhena_value_t );
float var_get_float( variable_t *, const char * );
int var_set_bool( variable_t *, const char *,
                  alhena_value_t  );
bool var_get_bool( variable_t *, const char * );
int var_set_string( variable_t *, const char *, const char * );
char *var_get_string( variable_t *, const char * );
void var_destory_all( variable_t * );

#ifdef __cplusplus
};
#endif

#define var_create_integer( head, name ) \
    var_create( (head), (name), ALHENA_VAR_INTEGER )

#define var_create_float( head, name ) \
    var_create( (head), (name), ALHENA_VAR_FLOAT )
    
#define var_create_bool( head, name ) \
    var_create( (head), (name), ALHENA_VAR_BOOL )

#define var_create_string( head, name ) \
    var_create( (head), (name), ALHENA_VAR_STRING )

#define var_create_integer_with_range( head, name, v, i_min, i_max ) \
    do { \
        alhena_value_t _value, _min, _max; \
        _value.i_int = (v); \
        _min.i_int = (i_min); \
        _max.i_int = (i_max); \
        if ( !var_create_integer( (head), (name) ) && \
             !var_integer_min_max( (head), (name), _min, _max ) ) \
        { \
            var_set_integer_check( (head), (name), _value ); \
        } \
    }while(0)

#define var_create_float_with_range( head, name, v, f_min, f_max ) \
    do { \
        alhena_value_t _value, _min, _max; \
        _value.f_float = (v); \
        _min.f_float = (f_min); \
        _max.f_float = (f_max); \
        if( !var_create_float( (head), (name) ) && \
            !var_float_min_max( (head), (name), _min, _max ) ) \
        { \
            var_set_float_check( (head), (name), _value ); \
        } \
    }while(0)

#define var_create_bool_value( head, name, v ) \
    do { \
        alhena_value_t _value; \
        _value.b_bool = (v); \
        if( !var_create_bool( (head), (name) ) ) \
            var_set_bool( (head), (name), _value ); \
    }while(0)

#define var_create_string_value( head, name, s ) \
    do { \
        if( !var_create_string( (head), (name) ) ) \
            var_set_string( (head), (name), (s) ); \
    }while(0)

#endif // _VARIABLES_H_


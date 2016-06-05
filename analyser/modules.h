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

#ifndef _MODULES_H_
#define _MODULES_H_

#include "analyser/variables.h"
#include "analyser/data.h"

#define ALHENA_MAX_SYS_NAME      (256)

// FIXME: use list
#define ALHENA_MAX_SYS_NUMS      (128)

#define ROOT_MODULE_NAME            "__root"

typedef void *(*pf_sys_init_t)( variable_t *, alhena_data_t *, 
                                int, float * );
typedef void (*pf_sys_deinit_t)( void * );

typedef bool (*pf_sys_rule_t)( void *, alhena_data_t *, 
                               int, int );

typedef pf_sys_rule_t  pf_sys_record_t;

#define _MODULE_SYMBOL          ALHENA_INLINE

#define ALHENA_SYS_EOK          (-0)
#define ALHENA_SYS_ERROR        (-1)

// FIXME: 1. improve register macros
//        2. add help context
#define alhena_module_begin( foo, name ) \
    _MODULE_SYMBOL void alhena_modules_##foo##_register( alhena_sys_t *sys ) \
    { \
        memset( sys, 0, sizeof( alhena_sys_t ) ); \
        strncpy( sys->psz_name, (name), ALHENA_MAX_SYS_NAME ); \
        INIT_LIST( &sys->configs );

#define set_init_deinit( init, deinit ) \
    sys->pf_sys_init   = (init); \
    sys->pf_sys_deinit = (deinit); 

#define set_ops( pre, pos, neg ) \
    sys->pf_sys_rule_pre = (pre); \
    sys->pf_sys_is_pos   = (pos); \
    sys->pf_sys_is_neg   = (neg);

#define set_stats( pre, post ) \
    sys->pf_sys_stat_pre  = (pre); \
    sys->pf_sys_stat_post = (post);

#define create_config_integer_with_range( name, v, min, max ) \
    var_create_integer_with_range( &sys->configs, (name), (v), (min), (max) );

#define create_config_float_with_range( name, v, min, max ) \
    var_create_float_with_range( &sys->configs, (name), (v), (min), (max) );

#define create_config_bool_set_value( name, v ) \
    var_create_bool_value( &sys->configs, (name), (v) );

#define create_config_string( name, s ) \
    var_create_string_value( &sys->configs, (name), (s) );

#define alhena_module_end( ... ) \
    }

#define sys_get_bool( m, name ) \
    var_get_bool( &(m)->configs, (name) )

#define sys_get_integer( m, name ) \
    var_get_integer( &(m)->configs, (name) )

#define sys_get_float( m, name ) \
    var_get_float( &(m)->configs, (name) )

#define sys_get_string( m, name ) \
    var_get_string( &(m)->configs, (name) )

typedef struct _alhena_sys_t
{
    char psz_name[ALHENA_MAX_SYS_NAME];

    // XXX: these callback ops *CAN* be NULL !
    pf_sys_init_t        pf_sys_init;
    pf_sys_deinit_t      pf_sys_deinit;

    pf_sys_record_t      pf_sys_rule_pre;

    pf_sys_rule_t        pf_sys_is_pos;
    pf_sys_rule_t        pf_sys_is_neg;

    pf_sys_record_t      pf_sys_stat_pre;
    pf_sys_record_t      pf_sys_stat_post;

    variable_t           configs;          /* config parameters */

}alhena_sys_t;

typedef struct _alhena_sys_bank_t
{
    alhena_sys_t   sys[ALHENA_MAX_SYS_NUMS];
    int            i_sys;
    
}alhena_sys_bank_t;

typedef struct _alhena_module_t
{
    const alhena_sys_t  *p_sys;

    void                *p_private_sys;     /* private handle for each sys */
    float               *p_sys_data;        /* private data for modules */

    struct _alhena_module_t     *prev;
    struct _alhena_module_t     *next;
}alhena_module_t;

ALHENA_INLINE void __list_add_mod( alhena_module_t *l,
                                   alhena_module_t *prev,
                                   alhena_module_t *next )
{
    next->prev = l;
    l->next = next;
    l->prev = prev;
    prev->next = l;
}

ALHENA_INLINE void __list_del_mod( alhena_module_t * prev, alhena_module_t * next)
{
    next->prev = prev;
    prev->next = next;
}

#define list_add_tail_mod( a, v ) \
    do{ \
        __list_add_mod( a, v, v->next ); \
    }while(0)

#define list_del_mod( a ) \
    do{ \
        __list_del_mod( a->prev, a->next ); \
    }while(0)

#ifdef __cplusplus
extern "C" {
#endif

alhena_sys_t *bank_find_sys( const char * );
alhena_module_t *module_new( const char *, alhena_data_t *, int,
                             bool, float *, int );
void module_delete( alhena_module_t * );
bool module_set_pre( alhena_module_t *, alhena_data_t *, int, int );
bool module_is_positive( alhena_module_t *, alhena_data_t *, int , int );
bool module_is_negative( alhena_module_t *, alhena_data_t *, int , int );
bool module_stat_pre( alhena_module_t *, alhena_data_t *, int , int );
bool module_stat_post( alhena_module_t *, alhena_data_t *, int , int );

int parse_command_line( int argc, char *argv[] );

#ifdef __cplusplus
};
#endif

#endif // _MODULES_H_


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

#include "variables.h"

// FIXME: use a more generic wrapper function 
#define GET_VARIABLE( l, head, name, i_type ) \
    (l) = find_variable_check( (head), (name), (i_type) ); \
    if( !(l) ) \
    { \
        msg_Err( "%s doesn't exist", (name) ); \
        return -1; \
    }

ALHENA_INLINE variable_t *find_variable( variable_t *var, const char *psz_name,
                                         bool b_create )
{
    variable_t *l = NULL;
    
    list_for_each( l, var )
    {
        if( !strncmp( l->psz_name, psz_name, ALHENA_MAX_VAR_NAME ) )
            return l;
    }

    if( !b_create )
    {
        msg_Err( "find `%s' failed", psz_name );
        assert(0); // FIXME: make get_xxx more stronger to remove it
    }
    return NULL;
}

ALHENA_INLINE variable_t *find_variable_check( variable_t *var, const char *psz_name,
                                               int i_type )
{
    variable_t *l = find_variable( var, psz_name, false );
    
    if( !l )
        return NULL;

    if( l->i_type != i_type )
    {
        msg_Err( "find `%s' with wrong type", psz_name );
        assert(0); // FIXME: make get_xxx more stronger to remove it
        return NULL;
    }

    return l;
}

int var_create( variable_t *var, const char *psz_name, int i_type )
{
    variable_t *new_var;

    if( find_variable( var, psz_name, true ) )
    {
        msg_Err( "%s already exists", psz_name );
        return -1;
    }

    new_var = (variable_t *)calloc( 1, sizeof( variable_t ) );
    if( !new_var )
    {
        msg_Err( "alloc new variable failed" );
        return -1;
    }

    switch( i_type )
    {
        case ALHENA_VAR_INTEGER: 
        {
            new_var->min.i_int = INT_MIN;
            new_var->max.i_int = INT_MAX;
            break;
        }
        case ALHENA_VAR_FLOAT:
        {
            new_var->min.f_float = .0f;
            new_var->max.f_float = 10000.0f;
        }
        default:
            break;
    }

    strncpy( new_var->psz_name, psz_name, ALHENA_MAX_VAR_NAME );
    new_var->i_type = i_type;

    list_add_tail_var( new_var, var );

    msg_Dbg( "Adding %s with type %d", psz_name, i_type );    

    return 0;
}

int var_integer_min_max( variable_t *var, const char *psz_name, 
                         alhena_value_t min, alhena_value_t max )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_INTEGER );

    if( min.i_int > max.i_int )
    {
        msg_Err( "set %s min exceeds max", 
                 psz_name, min.i_int, max.i_int );
        return -2;
    }

    l->min.i_int = min.i_int;
    l->max.i_int = max.i_int;

    return 0;
}

int var_set_integer_check( variable_t *var, const char *psz_name,
                           alhena_value_t value )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_INTEGER );

    if( value.i_int < l->min.i_int )
    {
        msg_Err( "set `%s' %d below min %d, using min", 
                 psz_name, value.i_int, l->min.i_int );
        value.i_int = l->min.i_int;
    }

    if( value.i_int > l->max.i_int )
    {
        msg_Err( "set `%s' %d above max %d, using max", 
                 psz_name, value.i_int, l->max.i_int );
        value.i_int = l->max.i_int;
    }

    l->value.i_int = value.i_int;
    msg_Dbg( "setting `%s' to value %d", psz_name, value.i_int );

    return 0;
}

int var_get_integer( variable_t *var, const char *psz_name )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_INTEGER );   

    return l->value.i_int;
}

int var_float_min_max( variable_t *var, const char *psz_name, 
                       alhena_value_t min, alhena_value_t max )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_FLOAT );

    if( min.f_float > max.f_float )
    {
        msg_Err( "set %s min exceeds max",
                 psz_name, min.f_float, max.f_float );
        return -2;
    }

    l->min.f_float = min.f_float;
    l->max.f_float = max.f_float;

    return 0;
}

int var_set_float_check( variable_t *var, const char *psz_name,
                         alhena_value_t value )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_FLOAT );

    if( value.f_float < l->min.f_float )
    {
        msg_Err( "set `%s' %f below min %f, using min",
                 psz_name, value.f_float, l->min.f_float );
        value.f_float = l->min.f_float;
    }

    if( value.f_float > l->max.f_float )
    {
        msg_Err( "set `%s' %f above max %f, using max",
                 psz_name, value.f_float, l->max.f_float );
        value.f_float = l->max.f_float;
    }

    l->value.f_float = value.f_float;
    msg_Dbg( "setting `%s' to value %f", psz_name, value.f_float );

    return 0;
}

float var_get_float( variable_t *var, const char *psz_name )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_FLOAT );   

    return l->value.f_float;
}

int var_set_bool( variable_t *var, const char *psz_name,
                  alhena_value_t value )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_BOOL );

    l->value.b_bool = value.b_bool;
    msg_Dbg( "setting `%s' to %s", psz_name, value.b_bool ? "true" : "false" );

    return 0;
}

bool var_get_bool( variable_t *var, const char *psz_name )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_BOOL );

    return l->value.b_bool;
}

int var_set_string( variable_t *var, const char *psz_name, const char *string )
{
    variable_t *l;

    GET_VARIABLE( l, var, psz_name, ALHENA_VAR_STRING );

    if( l->value.p_string )     free( l->value.p_string );

    l->value.p_string = ALHENA_STRDUP( string );
    msg_Dbg( "setting `%s' to %s", psz_name, string );

    return 0;
}

char *var_get_string( variable_t *var, const char *psz_name )
{
    variable_t *l = find_variable_check( var, psz_name, ALHENA_VAR_STRING );
    if( !l )
    {
        msg_Err( "%s doesn't exist", psz_name );
        return NULL;
    }

    return l->value.p_string;
}

void var_destory_all( variable_t *var )
{
    variable_t *l, *n;
    
    list_for_each_safe( l, n, var )
    {
        list_del_var( l );
        
        if( l->i_type == ALHENA_VAR_STRING )
        {
            if( l->value.p_string )
                free( l->value.p_string );
        }
        
        free( l );
    }
}


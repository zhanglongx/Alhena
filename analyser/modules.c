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

#include "common.h"
#include "modules.h"

#include "misc/getopt.h"

/* TODO: include modules here */
#include "modules/dummy.h"
#include "modules/fi.h"
#include "modules/fi_low.h"
#include "modules/maxday.h"
#include "modules/minday.h"
#include "modules/no_upseri.h"
#include "modules/now.h"
#include "modules/pl_trade.h"

#include "modules/peak.h"
#include "modules/peak_low.h"

#include "modules/vol.h"

#define MODULE_REGISTER_HELPER( foo, sys ) \
    alhena_modules_##foo##_register( (sys) );

// FIXME: parallelly run
alhena_sys_bank_t __g_sys_bank;

/* alhena 'root' module, need for global settings */
alhena_module_begin( root, ROOT_MODULE_NAME )
    create_config_string( "stats", "" )
    create_config_string( "close-chain", "" )
    create_config_string( "open-chain", "" )
    create_config_bool_set_value( "gen-output", false )
    /* general parameters */
    create_config_string( "input-filename", "" )
    create_config_integer_with_range( "debug", \
                _ALHENA_INF, _ALHENA_DBG, _ALHENA_OFF )
    create_config_bool_set_value( "week", false )
    create_config_bool_set_value( "help", false )
alhena_module_end()

static void usage();
static int generate_short_options( char *, int );
static int generate_long_options( struct option *, int );
static alhena_sys_t *find_sys_by_config( const char * );
static variable_t *find_config_by_short( alhena_sys_t *, char );
static variable_t *find_config_by_name( alhena_sys_t *, const char * );

int bank_collect()
{
    int i_sys = 0;
    
    // TODO/FIXME: register modules here, fix to use dynamic link
    MODULE_REGISTER_HELPER( root,      &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( dummy,     &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( fi,        &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( filow,     &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( maxday,    &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( minday,    &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( no_upseri, &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( now,       &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( pl_trade,  &__g_sys_bank.sys[i_sys++] );

    MODULE_REGISTER_HELPER( peak,    &__g_sys_bank.sys[i_sys++] );
    MODULE_REGISTER_HELPER( peaklow, &__g_sys_bank.sys[i_sys++] );

    MODULE_REGISTER_HELPER( vol,     &__g_sys_bank.sys[i_sys++] );    

    assert( i_sys < ALHENA_MAX_SYS_NUMS );
    __g_sys_bank.i_sys = i_sys;

    return ALHENA_EOK;
}

void bank_decollect()
{
    int i, i_modules = __g_sys_bank.i_sys;

    /* call module deinit */
    for( i=0; i<i_modules; i++ )
    {
        alhena_sys_t *p_sys = &__g_sys_bank.sys[i];
        
        var_destory_all( &p_sys->configs );
    }
}

alhena_sys_t *bank_find_sys( const char *psz_name )
{
    int i, i_modules = __g_sys_bank.i_sys;

    for( i=0; i<i_modules; i++ )
    {
        alhena_sys_t *p_sys = &__g_sys_bank.sys[i];
        
        if( !strncmp( p_sys->psz_name, psz_name, ALHENA_MAX_SYS_NAME ) )
            return p_sys;
    }

    return NULL;
}

alhena_module_t *module_new( const char *psz_name, 
                             alhena_data_t *p_data, int i_total,
                             bool b_output,
                             float *arg, int i_args )
{
    alhena_module_t *p_module;
    alhena_sys_t    *p_sys;

    p_sys = bank_find_sys( psz_name );
    if( !p_sys )
    {
        msg_Err( "cannot find sys: %s", psz_name );
        return NULL;
    }

    p_module = (alhena_module_t *)calloc( 1, sizeof( alhena_module_t ) );
    if( !p_module )
        return NULL;

    p_module->p_sys = p_sys;

    if( b_output )
    {
        /* msg_Err is enough */
        p_module->p_sys_data = calloc( 1, sizeof( float ) * MAX_DAYS );
        if( !p_module->p_sys_data )
            msg_Err( "can't alloc sys data for %s, turn off output", 
                     psz_name );
    }
    
    if( p_sys->pf_sys_init )
    {
        p_module->p_private_sys = p_sys->pf_sys_init( &p_sys->configs, 
                                                      p_data, i_total,
                                                      p_module->p_sys_data );
        if( !p_module->p_private_sys )
        {
            msg_Err( "init sys: %s failed", psz_name );
            goto lable_free_sys_data;
        }

        assert( p_sys->pf_sys_deinit );
    }

    msg_Dbg( "module inited as: %s", psz_name );

    return p_module;

lable_free_sys_data:
    if( p_module->p_sys_data )    free( p_module->p_sys_data );

    free( p_module );
    return NULL;
}

void module_delete( alhena_module_t *p )
{
    msg_Dbg( "deleting %s", p->p_sys->psz_name );

    if( p->p_private_sys )
        p->p_sys->pf_sys_deinit( p->p_private_sys );
    
    if( p->p_sys_data )    free( p->p_sys_data );
    
    free( p );
}

bool module_set_pre( alhena_module_t *p,
                     alhena_data_t *p_data, int i_day, int i_end )
{
    const alhena_sys_t *p_sys = p->p_sys;

    if( p_sys->pf_sys_rule_pre )
        return p_sys->pf_sys_rule_pre( p->p_private_sys, 
                                       p_data, i_day, i_end );
    else
        return false;
}

bool module_is_positive( alhena_module_t *p, 
                         alhena_data_t *p_data, int i_day, int i_end )
{
    const alhena_sys_t *p_sys = p->p_sys;

    if( p_sys->pf_sys_is_pos )
        return p_sys->pf_sys_is_pos( p->p_private_sys, 
                                     p_data, i_day, i_end );
    else
        return true;
}

bool module_is_negative( alhena_module_t *p, 
                         alhena_data_t *p_data, int i_day, int i_end )
{
    const alhena_sys_t *p_sys = p->p_sys;

    if( p_sys->pf_sys_is_neg )
        return p_sys->pf_sys_is_neg( p->p_private_sys, 
                                     p_data, i_day, i_end );
    else
        return false;
}

bool module_stat_pre( alhena_module_t *p, 
                      alhena_data_t *p_data, int i_day, int i_end )
{
    const alhena_sys_t *p_sys = p->p_sys;

    if( p_sys->pf_sys_stat_pre )
        return p_sys->pf_sys_stat_pre( p->p_private_sys,
                                       p_data, i_day, i_end );
    else
        return false;
}

bool module_stat_post( alhena_module_t *p, 
                       alhena_data_t *p_data, int i_day, int i_end )
{
    const alhena_sys_t *p_sys = p->p_sys;

    if( p_sys->pf_sys_stat_post )    
        return p_sys->pf_sys_stat_post( p->p_private_sys,
                                        p_data, i_day, i_end );
    else
        return false;
}

int parse_command_line( int argc, char *argv[] )
{
#define SHORT_OPTION_LEN    (256)
#define LONG_OPTION_LEN     (1024)

    char    psz_short_option[SHORT_OPTION_LEN] = "\0";
    struct  option longOptions[LONG_OPTION_LEN] = { {0, 0, 0, 0} };
    int     index;
    int     c;

    alhena_sys_t *p_root = bank_find_sys( ROOT_MODULE_NAME );
        
    if( generate_short_options( psz_short_option, SHORT_OPTION_LEN ) < 0 )
        return ALHENA_EFATAL;

    if( generate_long_options( longOptions, LONG_OPTION_LEN ) < 0 )
        return ALHENA_EFATAL;

    for (;;) {
        alhena_sys_t *p_sys = NULL;
        variable_t *p_config = NULL;
        alhena_value_t value;
        
        c = getopt_long(argc, argv, psz_short_option, longOptions, &index);

        if (c == -1) {
            break;
        }

        switch (c) {
            case 0:
            {
                p_sys = find_sys_by_config( longOptions[index].name );
                p_config = find_config_by_name( p_sys, longOptions[index].name );
                
                break;
            }
            case 'h':
            {
                goto lable_display_usage;
            }
            default:
            {
                p_sys = p_root;
                p_config = find_config_by_short( p_sys, (char)c );
                
                break;
            }
        }

        if( !p_sys || !p_config )
            goto lable_display_usage;

        if( p_config->i_type == ALHENA_VAR_BOOL )
        {
            value.b_bool = true;
            var_set_bool( &p_sys->configs, p_config->psz_name, value );
        }
        else if( p_config->i_type == ALHENA_VAR_INTEGER )
        {
            sscanf( optarg, "%d", &value.i_int );

            var_set_integer_check( &p_sys->configs, p_config->psz_name, value );
        }
        else if( p_config->i_type == ALHENA_VAR_FLOAT )
        {
            sscanf( optarg, "%f", &value.f_float );

            var_set_float_check( &p_sys->configs, p_config->psz_name, value );
        }
        else if( p_config->i_type == ALHENA_VAR_STRING )
        {
            var_set_string( &p_sys->configs, p_config->psz_name, optarg );
        }
        else
            assert(0);
    }

    if( sys_get_bool( p_root, "help" ) )
    {
        alhena_value_t value;

        value.b_bool = false;
        var_set_bool( &p_root->configs, "help", value );
        goto lable_display_usage;
    }

    if( optind > argc - 1 )
    {
        fprintf( stderr, "No input file. Run `alhena --help' for a list of options.\n" );
        return -1;
    }

    var_set_string( &p_root->configs, "input-filename", argv[optind++] );

#undef LONG_OPTION_LEN
#undef SHORT_OPTION_LEN

    return 0;

lable_display_usage:
    usage();
    return -2;
}

static void usage()
{
    int i, i_sys = __g_sys_bank.i_sys;
    variable_t *l;

    fprintf( stderr, "alhena %s\n", ALHENA_VERSION );
    fprintf( stderr, "usage:\n" );
    fprintf( stderr, "alhena [OPTION] [FILE]\n" );

    for( i=0; i<i_sys; i++ )
    {
        alhena_sys_t *p_sys = &__g_sys_bank.sys[i];
        bool b_root = false;
        
        if( strncmp( p_sys->psz_name, ROOT_MODULE_NAME, ALHENA_MAX_SYS_NAME ) )
            fprintf( stderr, "%s:\n", p_sys->psz_name );
        else
            b_root = true;

        if( LIST_IS_EMPTY( &p_sys->configs ) )
            fprintf( stderr, "     (none parameters)\n" );
        else
            list_for_each( l, &p_sys->configs )
            {
                char short_opt[16] = "\0";

                if( !strcmp( l->psz_name, "input-filename" ) )
                    continue;

                if( b_root )
                    sprintf( short_opt, "-%c |", l->psz_name[0] );

                fprintf( stderr, "%s --%s  ", b_root ? short_opt : "    ", l->psz_name );

                /* print default value */
                if( l->i_type == ALHENA_VAR_INTEGER )
                    fprintf( stderr, "(%d)", sys_get_integer( p_sys, l->psz_name ) );
                else if( l->i_type == ALHENA_VAR_BOOL )
                    fprintf( stderr, "(%s)", sys_get_bool( p_sys, l->psz_name ) ? 
                                             "true" : "false" );
                else if( l->i_type == ALHENA_VAR_FLOAT )
                    fprintf( stderr, "(%.2f)", sys_get_float( p_sys, l->psz_name ) );
                else if( l->i_type == ALHENA_VAR_STRING &&
                         strlen( sys_get_string( p_sys, l->psz_name ) ) )
                    fprintf( stderr, "(%s)", sys_get_string( p_sys, l->psz_name ) );

                fprintf( stderr, "\n" );
            }

        fprintf( stderr, "\n" );
    }
}

static int generate_short_options( char *psz_short, int i_length )
{
    int i_opt_length = 0;
    char *p = psz_short;
    variable_t *l;
    alhena_sys_t *p_root = bank_find_sys( ROOT_MODULE_NAME );
    if( !p_root )
        return -1;

    // FIXME: bug! fix dump
    list_for_each( l, &p_root->configs )
    {
        if( !strcmp( l->psz_name, "input-filename" ) )
            continue;

        if( l->i_type == ALHENA_VAR_INTEGER || l->i_type == ALHENA_VAR_STRING ||
            l->i_type == ALHENA_VAR_FLOAT )
        {
            ALHENA_SNPRINTF( p, i_length - i_opt_length, "%c:", l->psz_name[0] );
            i_opt_length += 2;
            p += 2;            
        }
        else if( l->i_type == ALHENA_VAR_BOOL )
        {
            ALHENA_SNPRINTF( p, i_length - i_opt_length, "%c", l->psz_name[0] );
            i_opt_length++;
            p++;
        }
    }

    *p = '\0';

    return i_opt_length ? i_opt_length : -2;
}

static int generate_long_options( struct option *long_options, int i_size )
{
    int i_options = 0, i;
    int i_modules = __g_sys_bank.i_sys;
    variable_t *l;
    struct option *option = long_options;
    alhena_sys_t *p_root = bank_find_sys( ROOT_MODULE_NAME );
    if( !p_root )
        return -1;

    for( i=0; i<i_modules; i++ )
    {
        list_for_each( l, &__g_sys_bank.sys[i].configs )
        {
            if( !strcmp( l->psz_name, "input-filename" ) )
                continue;

            if( i_options > i_size )
                return -2;

            option->name    = ALHENA_STRDUP( l->psz_name );   // FIXME: free
            option->has_arg = (l->i_type == ALHENA_VAR_BOOL) ? 
                              no_argument : required_argument;
            option->flag    = NULL;
            option->val     = 0;

            option++;
            i_options++;
        }
    }

    return i_options ? i_options : -2;
}

static alhena_sys_t *find_sys_by_config( const char *psz_name )
{
    int i_modules = __g_sys_bank.i_sys, i;
    variable_t *l;    

    for( i=0; i<i_modules; i++ )
    {
        list_for_each( l, &__g_sys_bank.sys[i].configs )
        {
            if( !strncmp( l->psz_name, psz_name, ALHENA_MAX_VAR_NAME ) )
                return &__g_sys_bank.sys[i];
        }
    }

    return NULL;
}

static variable_t *find_config_by_short( alhena_sys_t *p_sys, char c )
{
    variable_t *l;

    list_for_each( l, &p_sys->configs )
    {
        if( l->psz_name[0] == c )
            return l;
    }

    return NULL;
}

static variable_t *find_config_by_name( alhena_sys_t *p_sys, const char *name )
{
    variable_t *l;

    list_for_each( l, &p_sys->configs )
    {
        if( !strncmp( l->psz_name, name, ALHENA_MAX_VAR_NAME ) )
            return l;
    }

    return NULL;
}


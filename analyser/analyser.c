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

#include "common.h"
#include "rule.h"

// FIXME: fix this extern thing
extern alhena_sys_bank_t __g_sys_bank;

static int load_data( alhena_t * );
static int week( alhena_data_t *, const alhena_data_t *, int  );

alhena_t *alhena_create()
{
    alhena_t *h = NULL;
    alhena_sys_t *p_root = bank_find_sys( ROOT_MODULE_NAME );

    if( !p_root )
        return NULL;

    msg_init( sys_get_integer( p_root, "debug" ), ALHENA_MSG_TYPE_STDOUT );

    h = (alhena_t *)calloc( 1, sizeof( alhena_t ) );
    if( !h )
    {
        msg_Err( "alloc alhena_t failed" );
        goto label_msg_deint;
    }

    h->p_sys_root = p_root;

    h->p_data = (alhena_data_t *)calloc( 1, sizeof( alhena_data_t ) );
    if( !h->p_data )
    {
        msg_Err( "alloc alhena_data_t failed" );
        goto label_free_h; 
    }

    if( load_data( h ) < 0 )
    {
        msg_Err( "load data failed" );
        goto lable_free_data;
    }

    if( alhena_rule_init( h ) != ALHENA_EOK )
    {
        msg_Err( "load rule failed" );
        goto lable_free_data;
    }
    
    return h;

lable_free_data:
    free( h->p_data );
label_free_h:
    free( h );
label_msg_deint:
    msg_deinit();
    
    return NULL;
}

int alhena_process_data( alhena_t *h )
{
    return alhena_rule_run( h );
}

void alhena_output( alhena_t *h )
{
    alhena_data_t *p_data = h->p_data;
    uint32_t i_day;
    
    for( i_day=0; i_day<h->i_days; i_day++ )
    {
        fprintf( stdout, "%d-%02d-%02d,%.2f,%.2f,%.2f,%.2f,%lld,",
                         p_data->day[i_day].i_year,             
                         p_data->day[i_day].i_month, 
                         p_data->day[i_day].i_day,
                         p_data->f_open[i_day],
                         p_data->f_high[i_day],
                         p_data->f_low[i_day],
                         p_data->f_close[i_day], 
                         p_data->l_vol[i_day] );

        alhena_rule_output_day( h, i_day );

        fprintf( stdout, "%d,%d\n", p_data->open_flag[i_day],
                                    p_data->close_flag[i_day] );
    }
    
}

void alhena_delete( alhena_t *h )
{
    alhena_rule_deinit( h );
    
    free( h->p_data );
    free( h );
    
    msg_deinit();
}

static int load_data( alhena_t *h )
{
    alhena_data_t *p_scratch;
    alhena_sys_t *p_root = h->p_sys_root;
    char *psz_filename = sys_get_string( p_root, "input-filename" );
    bool b_week = sys_get_bool( p_root, "week" );
    FILE *fp;
    uint32_t i_days = 0;

    fp = fopen( psz_filename, "r" );
    if( !fp )
    {
        msg_Err( "cannot open %s for data", psz_filename );
        return -1;
    }

    p_scratch = calloc( 1, sizeof( alhena_data_t ) );
    if( !p_scratch )
    {
        fclose( fp );

        msg_Err( "alloc scratch failed" );
        return -1;
    }

    while( !feof( fp ) )
    {
#define GET_LINE_MAX    (512)
        char line[GET_LINE_MAX] = {'\0'};

        fgets( line, GET_LINE_MAX, fp );
        if ( 9 == sscanf( line, "%d-%d-%d,%f,%f,%f,%f,%lld,%lld", 
                                &p_scratch->day[i_days].i_year,
                                &p_scratch->day[i_days].i_month, 
                                &p_scratch->day[i_days].i_day,
                                &p_scratch->f_open[i_days],
                                &p_scratch->f_high[i_days],
                                &p_scratch->f_low[i_days],
                                &p_scratch->f_close[i_days],
                                &p_scratch->l_vol[i_days],
                                &p_scratch->l_equity[i_days] ) )
        {
            i_days++;
        }

        if( i_days >= MAX_DAYS )
        {
            msg_Err( "data volume exceeds max" );
            break;
        }
        
#undef GET_LINE_MAX
    }

    if( !i_days )
    {
        msg_Err( "%s doesn't contain any data", psz_filename );
        return -1;
    }

    msg_Dbg( "finish reading %d days data", i_days );
    h->i_days = i_days;

    if( b_week )
        h->i_days = week( h->p_data, p_scratch, i_days );
    else
        memcpy( h->p_data, p_scratch, sizeof( alhena_data_t ) );

    free( p_scratch );

    fclose( fp );
    return 0;
}

static int week( alhena_data_t *p_week, const alhena_data_t *p_data, int i_days )
{
    float f_week_open = .0f, f_week_high = .0f;
    float f_week_low  = 8000.0f, f_week_close = .0f;
    uint64_t l_week_vol = 0, l_week_equity = 0;
    int i_last_day = 1, i_last_mon = 1, i_last_year = 2001;
    int i_w_day = 0, i_w_mon, i_w_year;
    int i_week_dur = 0;
    int i, k;
    
    for( i=0, k=0; i < i_days; i++ )
    {
        int i_day  = p_data->day[i].i_day;
        int i_mon  = p_data->day[i].i_month;
        int i_year = p_data->day[i].i_year;

        int i_delta_day = delta_day( i_last_year, i_last_mon, i_last_day, i_year, i_mon, i_day );
        
        if( i_delta_day > 1 )
        {
            if( i )  /* not first one */
            {
                p_week->day[k].i_day   = i_w_day;
                p_week->day[k].i_month = i_w_mon;
                p_week->day[k].i_year  = i_w_year;

                p_week->f_open[k]  = f_week_open;
                p_week->f_high[k]  = f_week_high;
                p_week->f_low[k]   = f_week_low;
                p_week->f_close[k] = f_week_close;

                p_week->l_vol[k]    = l_week_vol;
                p_week->l_equity[k] = l_week_equity / i_week_dur;

                k++;
            }

            f_week_open  = 
            f_week_high  = 
            f_week_close = .0f;

            f_week_low   = 8000.0f;

            l_week_vol    = 
            l_week_equity = 0;

            i_week_dur = 0;
        }

        if( !(f_week_open > .0f) )
        {
            f_week_open = p_data->f_open[i];

            i_w_day  = i_day;
            i_w_mon  = i_mon;
            i_w_year = i_year;
        }

        if( p_data->f_low[i] < f_week_low )
            f_week_low = p_data->f_low[i];

        if( p_data->f_high[i] > f_week_high )
            f_week_high = p_data->f_high[i];

        f_week_close = p_data->f_close[i];

        l_week_vol    += p_data->l_vol[i];
        l_week_equity += p_data->l_equity[i];

        i_week_dur++;

        i_last_day  = i_day;
        i_last_mon  = i_mon;
        i_last_year = i_year;
    }

    if( f_week_open > .0f )
    {
        p_week->day[k].i_day   = i_w_day;
        p_week->day[k].i_month = i_w_mon;
        p_week->day[k].i_year  = i_w_year;

        p_week->f_open[k]  = f_week_open;
        p_week->f_high[k]  = f_week_high;
        p_week->f_low[k]   = f_week_low;
        p_week->f_close[k] = f_week_close;

        p_week->l_vol[k]    = l_week_vol;
        p_week->l_equity[k] = l_week_equity / i_week_dur;

        k++;
    }

    return k;
}


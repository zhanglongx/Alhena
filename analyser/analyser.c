#include "common.h"
#include "rule.h"

// FIXME: fix this extern thing
extern alhena_sys_bank_t __g_sys_bank;

static int load_data( alhena_t * );

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
        fprintf( stdout, "%2d/%2d/%d,%.2f,%.2f,%.2f,%.2f,%lld,",
                         p_data->day[i_day].i_month, 
                         p_data->day[i_day].i_day,
                         p_data->day[i_day].i_year,
                         p_data->f_open[i_day],
                         p_data->f_high[i_day],
                         p_data->f_low[i_day],
                         p_data->f_close[i_day], 
                         p_data->l_vol[i_day] );

        alhena_rule_output_day( h, i_day );

        fprintf( stdout, "%d,%d\n", p_data->open_flag[i_day],
                                    p_data->close_flag[i_day] ? 123456 : 0 );
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
    alhena_data_t *p_data = h->p_data;
    alhena_sys_t *p_root = h->p_sys_root;
    char *psz_filename = sys_get_string( p_root, "input-filename" );
    FILE *fp;
    uint32_t i_days = 0;

    fp = fopen( psz_filename, "r" );
    if( !fp )
    {
        msg_Err( "cannot open %s for data", psz_filename );
        return -1;
    }

    while( !feof( fp ) )
    {
#define GET_LINE_MAX    (512)
        float foo;
        char line[GET_LINE_MAX];

        fgets( line, GET_LINE_MAX, fp );
        if ( 9 == sscanf( line, "%d/%d/%d,%f,%f,%f,%f,%lld,%f", 
                                &p_data->day[i_days].i_month, 
                                &p_data->day[i_days].i_day,
                                &p_data->day[i_days].i_year,
                                &p_data->f_open[i_days],
                                &p_data->f_high[i_days],
                                &p_data->f_low[i_days],
                                &p_data->f_close[i_days],
                                &p_data->l_vol[i_days], &foo ) )
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
        msg_Err( "% doesn't contain any data", psz_filename );
        return -1;
    }

    msg_Dbg( "finish reading %d days data", i_days );
    h->i_days = i_days;

    fclose( fp );
    return 0;
}


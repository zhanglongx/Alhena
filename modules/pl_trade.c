#include "analyser/common.h"
#include "analyser/modules.h"

#include "pl_trade.h"

typedef struct _pl_trade_t
{
    int     i_open_day;
    float   f_flag_close;
    float   f_flag_start;

    bool    b_open;
    
    int     i_max_days;

    float   f_start;
    float   f_profile;
    float   f_loss;
    
}pl_trade_t;

void *alhena_module_pl_trade_init( variable_t *p_config, 
                                   alhena_data_t *p_data, int i_total,
                                   float *p_output_data )
{
    pl_trade_t *p_pl;

    p_pl = (pl_trade_t *)calloc( 1, sizeof( pl_trade_t ) );
    if( !p_pl )
    {
        msg_Err( "cannot alloc pl_trade_t" );
        return NULL;
    }

    p_pl->i_max_days = var_get_integer( p_config, "pl-trade-days" );

    p_pl->f_start   = var_get_float( p_config, "pl-trade-start" ) / 100.0f;
    p_pl->f_profile = var_get_float( p_config, "pl-trade-profile" ) / 100.0f;
    p_pl->f_loss    = var_get_float( p_config, "pl-trade-loss"  ) / 100.0f;

    return p_pl;
}

void alhena_module_pl_trade_close( void *h )
{
    pl_trade_t *p_pl = (pl_trade_t *)h;

    free( p_pl );
}

bool alhena_module_pl_trade_pre( void *h, alhena_data_t *p_data, 
                                 int i_day, int i_end )
{
    pl_trade_t *p_pl = (pl_trade_t *)h;

    p_pl->i_open_day   = i_day;
    p_pl->f_flag_close = p_data->f_close[i_day];
    p_pl->f_flag_start = 0.0f;

    p_pl->b_open = false;

    return true;
}

bool alhena_module_pl_trade_pos( void *h, alhena_data_t *p_data, 
                                 int i_day, int i_end )
{
    pl_trade_t *p_pl = (pl_trade_t *)h;
    float f_flag_close = p_pl->f_flag_close;
    float f_flag_start = p_pl->f_flag_start;

    if( i_day - p_pl->i_open_day > p_pl->i_max_days )
        return true;

    if( (i_day - p_pl->i_open_day == 1) && p_data->f_open[i_day] > f_flag_close )
        return true;

    if( p_pl->b_open == false )
    {
        if( p_data->f_high[i_day] > f_flag_close * (1.0f + p_pl->f_start) )
        {
            p_pl->b_open = true;
            p_pl->f_flag_start = f_flag_start = f_flag_close * (1.0f + p_pl->f_start);
        }
        else
            return false;
    }

    if( p_data->f_high[i_day] > f_flag_start * (1.0f + p_pl->f_loss) )
    {
        fprintf( stdout, "pl-trade,%d/%d/%d,%.2f\n", 
                         p_data->day[i_day].i_month,
                         p_data->day[i_day].i_day,
                         p_data->day[i_day].i_year,
                         p_pl->f_loss ); // tempz!!
        return true;
    }

    if( p_data->f_low[i_day] < f_flag_start * (1.0f - p_pl->f_profile ) )
    {
        fprintf( stdout, "pl-trade,%d/%d/%d,%.2f\n", 
                         p_data->day[i_day].i_month,
                         p_data->day[i_day].i_day,
                         p_data->day[i_day].i_year,
                         p_pl->f_profile * -1.0f ); // tempz!!
        return true;
    }

    return false;
}


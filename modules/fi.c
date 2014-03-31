#include "analyser/common.h"
#include "analyser/modules.h"

#include "fi.h"

typedef struct _fi_t
{
    bool   b_output_data;
        
    float  fi[MAX_DAYS];
    float  fi_accl[MAX_DAYS];

    int    i_compare_days;
    
}fi_t;

void *alhena_module_fi_init( variable_t *p_config, 
                             alhena_data_t *p_data, int i_total,
                             float *p_output_data )
{
    fi_t *p_fi;
    int i;

    p_fi = (fi_t *)calloc( 1, sizeof( fi_t ) );
    if( !p_fi )
    {
        msg_Err( "cannot alloc fi_t" );
        return NULL;
    }

    for( i=0; i<i_total; i++ )
    {
        p_fi->fi[i]      = fi_v( p_data, i );
        p_fi->fi_accl[i] = accel_v( p_fi->fi, i );

        if( p_output_data )
            p_output_data[i] = p_fi->fi[i];
    }

    p_fi->i_compare_days = var_get_integer( p_config, "fi-compare-days" );

    return p_fi;
}

void alhena_module_fi_close( void *h )
{
    fi_t *p_fi = (fi_t *)h;

    free( p_fi );
}

bool alhena_module_fi_pos( void *h, alhena_data_t *p_data, 
                           int i_day, int i_end )
{
    fi_t *p_fi = (fi_t *)h;
    float max;

    if( i_day < p_fi->i_compare_days )
        return false;

    PAST_MAX_N_FLOAT( max, p_fi->fi_accl, i_day, p_fi->i_compare_days );

    if( !is_float_eq( p_fi->fi_accl[i_day], max ) )
        return false;

    PAST_MAX_N_FLOAT( max, p_fi->fi, i_day, p_fi->i_compare_days );

    if( !is_float_eq( p_fi->fi[i_day], max ) )
        return false;
    
    return true;
}


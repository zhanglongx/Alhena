#include <math.h>

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
    float f_sum = .0, f_square_sum = .0;
    float f_sigma;
    int i, i_start = i_day - p_fi->i_compare_days;

    if( i_start < 0 || i_day <= 0 )
        return false;

    for( i=i_start; i<i_day; i++ )
    {
        f_sum        += p_fi->fi[i];
        f_square_sum += p_fi->fi[i] * p_fi->fi[i];
    }

    f_sum        /= p_fi->i_compare_days;
    f_square_sum /= p_fi->i_compare_days;

    f_sigma = f_square_sum - f_sum * f_sum;

    if( f_sigma < 0.0 )
        f_sigma = -1.0f * f_sigma;

#define SIGMA   (4.0f)

    if( p_fi->fi[i_day] < f_sum + SIGMA * sqrtf( f_sigma ) )
        return false;

    return true;
#undef SIGMA
}


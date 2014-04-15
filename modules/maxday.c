#include "analyser/common.h"
#include "analyser/modules.h"

typedef struct _maxday_t
{
    int i_start_day;

    int i_compare_days;
}maxday_t;

void *alhena_module_maxday_init( variable_t *p_configs, alhena_data_t *p_data, 
                                 int i_total, float *p_output )
{
    maxday_t *p;

    p = (maxday_t *)calloc( 1, sizeof( maxday_t ) );
    if( !p )
        return NULL;

    p->i_compare_days = var_get_integer( p_configs, "maxday-days" );

    return (void *)p;
}

void alhena_module_maxday_deinit( void *h )
{
    maxday_t *p = (maxday_t *)h;

    free( p );
}

bool alhena_module_maxday_pre( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    maxday_t *p = (maxday_t *)p_sys;
    
    p->i_start_day = i_day;

    return true;
}

bool alhena_module_maxday_neg( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    maxday_t *p = (maxday_t *)p_sys;
    
    return (i_day - p->i_start_day > p->i_compare_days ) ? true: false;
}


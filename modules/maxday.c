#include "analyser/common.h"
#include "analyser/modules.h"

#define DAYS     (4) // tempz!!

typedef struct _maxday_t
{
    int i_start_day;
}maxday_t;

void *alhena_module_maxday_init( variable_t *p_configs, alhena_data_t *p_data, 
                                 int i_total, float *p_output )
{
    maxday_t *p;

    p = (maxday_t *)calloc( 1, sizeof( maxday_t ) );
    if( !p )
        return NULL;

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
    
    return (i_day - p->i_start_day > DAYS) ? true: false;
}


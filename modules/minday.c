#include "analyser/common.h"
#include "analyser/modules.h"

#define MINDAYS     (4) // tempz!!

typedef struct _minday_t
{
    int i_start_day;
}minday_t;

void *alhena_module_minday_init( variable_t *p_configs, alhena_data_t *p_data, 
                                 int i_total, float *p_output )
{
    minday_t *p;

    p = (minday_t *)calloc( 1, sizeof( minday_t ) );
    if( !p )
        return NULL;

    return (void *)p;
}

void alhena_module_minday_deinit( void *h )
{
    minday_t *p = (minday_t *)h;

    free( p );
}

bool alhena_module_minday_pre( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    minday_t *p = (minday_t *)p_sys;
    
    p->i_start_day = i_day;

    return true;
}

bool alhena_module_minday_pos( void *p_sys, alhena_data_t *p_data, 
                               int i_day, int i_end )
{
    minday_t *p = (minday_t *)p_sys;
    
    return (i_day - p->i_start_day > MINDAYS) ? true: false;
}


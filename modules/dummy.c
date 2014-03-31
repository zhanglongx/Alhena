#include "analyser/common.h"
#include "analyser/modules.h"

int alhena_module_dummy_process( void *p_sys, alhena_data_t *p_data, 
                                 int i_day, int i_total, float *p_output )
{
    ALHENA_UNUSED( p_sys );
    ALHENA_UNUSED( p_output );
    
    return ALHENA_EOK;
}

bool alhena_module_dummy_pos( void *p_sys, alhena_data_t *p_data, 
                             int i_day, int i_end )
{
    ALHENA_UNUSED( p_sys );
    
    return (p_data->day[i_day].i_day == 1) ? true: false;
}


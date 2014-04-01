#include "analyser/common.h"
#include "analyser/modules.h"

bool alhena_module_dummy_pos( void *p_sys, alhena_data_t *p_data, 
                             int i_day, int i_end )
{
    ALHENA_UNUSED( p_sys );
    
    return (p_data->day[i_day].i_day == 1) ? true: false;
}


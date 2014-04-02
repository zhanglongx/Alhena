#include "analyser/common.h"
#include "analyser/modules.h"

#include "no_upseri.h"

#define BACK_DAY    (2)     // tempz!!

bool alhena_module_no_upseri_record_neg( void *h, alhena_data_t *p_data, 
                                         int i_day, int i_end )
{
    int i_back_day = MAX( 0, i_day - BACK_DAY );
    int i;

    for( i=i_back_day; i<=i_day; i++ )
    {
        if( p_data->f_close[i] > p_data->f_open[i] )
            return false;
    }

    return (i_day==0) ? false: true;
}


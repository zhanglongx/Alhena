#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <string.h>

#include "alhena.h"

int main(int argc, char **argv)
{
    alhena_t        *h;
    int i_ret;

    bank_collect();

    if( parse_command_line( argc, argv ) < 0 )
    {
        goto label_decollect;
    }

    h = alhena_create();
    if( !h )
    {
        fprintf( stderr, "create alhena failed\n" );
        goto label_decollect;
    }

    i_ret = alhena_process_data( h );
    if( i_ret != ALHENA_EOK )
    {
        fprintf( stderr, "alhena process failed, error code: %d\n",
                         i_ret );
        goto lable_delete;
    }

    alhena_output( h );

lable_delete:
    alhena_delete( h );

label_decollect:
    bank_decollect();

    return 0;
}


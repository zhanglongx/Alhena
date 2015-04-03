/*****************************************************************************
 * Copyright (C) 2015 Alhena project
 *
 * Authors: longxiao zhang <zhanglongx@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
  *****************************************************************************/

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


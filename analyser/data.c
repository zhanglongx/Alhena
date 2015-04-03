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

#include "alhena.h"
#include "data.h"

int compare_float( const void *p1, const void *p2 )
{
    float a1 = *(float *)p1;
    float a2 = *(float *)p2;

    return a1 > a2;
}

int compare_uint64( const void *p1, const void *p2 )
{
    uint64_t a1 = *(uint64_t *)p1;
    uint64_t a2 = *(uint64_t *)p2;

    return a1 > a2;
}


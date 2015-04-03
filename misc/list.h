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

#ifndef _LIST_H_
#define _LIST_H_

#define INIT_LIST(v) \
    do{ \
        (v)->next = (v); \
        (v)->prev = (v); \
    }while(0)
    
#define LIST_IS_EMPTY(v)             ((v) == (v)->next )

#define list_for_each( p, v ) \
    for( (p)=(v)->next; (p) != (v); (p)=(p)->next )

#define list_for_each_safe( p, n, v) \
    for ( (p) = (v)->next, (n) = (p)->next; (p) != (v); \
        (p) = (n), (n) = (p)->next)

#endif //_LIST_H_


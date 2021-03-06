/*****************************************************************************
 * Copyright (C) 2015-2017 Alhena project
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

#ifndef _DATA_H_
#define _DATA_H_

#include <math.h>

#define MAX_DAYS        (8192)      // almost 40 years

typedef struct _alhena_data_t
{
    struct {
        int     i_day;
        int     i_month;
        int     i_year;
    }day[MAX_DAYS];
    
    float   f_open[MAX_DAYS];
    float   f_close[MAX_DAYS];
    float   f_low[MAX_DAYS];
    float   f_high[MAX_DAYS];

    uint64_t l_vol[MAX_DAYS];
    uint64_t l_equity[MAX_DAYS];

    bool    open_flag[MAX_DAYS];
    bool    close_flag[MAX_DAYS];

}alhena_data_t;

typedef int (*pf_compare_t)( const void *, const void * );

ALHENA_INLINE float _sum_v( float *f, int i_day, int i_length )
{
    float sum = 0.0;
    int i = i_day - i_length;

    if( i < 0 )
        return 0.0;

    for( ; i<i_day; i++ )
        sum += f[i];

    return sum;
}

ALHENA_INLINE float avg_v( float *f, int i_day, int i_length )
{
    return _sum_v( f, i_day, i_length ) / i_length;
}

ALHENA_INLINE float dev_v( float *f, int i_day, int i_length )
{
    float avg = avg_v( f, i_day, i_length );
    float square = 0.0;
    int i = i_day - i_length;

    if( i < 0 )
        return 0.0;

    for( ; i<i_day; i++ )
        square += f[i] * f[i];

    square = square / i_length - avg * avg;
    if( square < 0.0 )
        square *= -1.0f;

    return sqrtf( square );
}

ALHENA_INLINE uint64_t _l_sum_v( uint64_t *f, int i_day, int i_length )
{
    uint64_t sum = 0L;
    int i = i_day - i_length;

    if( i < 0 )
        return 0L;

    for( ; i<i_day; i++ )
        sum += f[i];

    return sum;
}

ALHENA_INLINE uint64_t l_avg_v( uint64_t *f, int i_day, int i_length )
{
    return _l_sum_v( f, i_day, i_length ) / i_length;
}

ALHENA_INLINE uint64_t l_dev_v( uint64_t *f, int i_day, int i_length )
{
    uint64_t avg = l_avg_v( f, i_day, i_length );
    uint64_t square = 0L;
    int i = i_day - i_length;

    if( i < 0 )
        return 0L;

    for( ; i<i_day; i++ )
        square += f[i] * f[i];

    square = square / i_length - avg * avg;
    if( square < 0.0 )
        square *= -1L;

    return (uint64_t)sqrt( (double)square );
}

#define PAST_MAX_N_FLOAT( max, data, day, n ) \
    MAX_N_FLOAT( (max), (data), (day) - (n), (day), (day) )

#define MAX_N_FLOAT( max, data, start, end, total ) \
    do{ \
        (max) = *(float *)_n_day_peak( (data), sizeof( float ), \
                                       (start), (end), (total), \
                                       compare_float ); \
    }while(0)

#define MAX_N_UINT64( max, data, start, end, total ) \
    do{ \
        (max) = *(uint64_t *)_n_day_peak( (data), sizeof( float ), \
                                          (start), (end), (total), \
                                          compare_uint64 ); \
    }while(0)

ALHENA_INLINE const void *_n_day_peak( const void *p, int i_size,
                                       int i_start, int i_end,
                                       int i_total, pf_compare_t pf )
{
    const uint8_t *peak;
    int t;
    int i;

    t = i_start = MAX( i_start, 0 );
    i_end   = MIN( i_end, i_total );

    i_start = MIN( i_start, i_end );
    i_end   = MAX( i_end, t );

    peak = (uint8_t *)p + i_start * i_size;

    for( i=i_start; i<=i_end; i++ )
    {
        if( pf( (uint8_t *)p + i * i_size, peak ) > 0 )
            peak = (uint8_t *)p + i * i_size;
    }

    return (void *)peak;
}

#ifdef __cplusplus
extern "C" {
#endif

int compare_float( const void *, const void * );
int compare_uint64( const void *, const void * );

#ifdef __cplusplus
};
#endif

#endif // _DATA_H_


#ifndef _DATA_H_
#define _DATA_H_

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

    bool    open_flag[MAX_DAYS];
    bool    close_flag[MAX_DAYS];

}alhena_data_t;

typedef int (*pf_compare_t)( const void *, const void * );

ALHENA_INLINE float accel_v( float *f, int i_day )
{
    if( i_day < 2 )
        return 0.0;

    return f[i_day] - f[i_day-1];
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


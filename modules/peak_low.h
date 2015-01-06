#ifndef _PEAK_LOW_H_
#define _PEAK_LOW_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_peaklow_init( variable_t *, alhena_data_t *,
                                  int , float * );
bool alhena_module_peaklow_record_pre( void *, alhena_data_t *, 
                                       int , int );
void alhena_module_peaklow_deinit( void * );

alhena_module_begin( peaklow, "peak-low" )
    set_init_deinit( alhena_module_peaklow_init, alhena_module_peaklow_deinit )
    set_stats( alhena_module_peaklow_record_pre, 
               NULL )
    create_config_integer_with_range( "peak-low-max-days", 20, 1, 100 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _PEAK_LOW_H_


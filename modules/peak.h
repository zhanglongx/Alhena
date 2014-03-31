#ifndef _PEAK_H_
#define _PEAK_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_peak_init( variable_t *, alhena_data_t *,
                               int , float * );
bool alhena_module_peak_record_pre( void *, alhena_data_t *, 
                                    int , int );
void alhena_module_peak_deinit( void * );

alhena_module_begin( peak, "peak" )
    set_init_deinit( alhena_module_peak_init, alhena_module_peak_deinit )
    set_stats( alhena_module_peak_record_pre, 
               NULL )
    create_config_integer_with_range( "peak-max-days", 20, 1, 100 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _PEAK_H_


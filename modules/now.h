#ifndef _NOW_H_
#define _NOW_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_now_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_now_deinit( void * );
bool alhena_module_now_record_pre( void *, alhena_data_t *, int , int );

alhena_module_begin( now, "now" )
    set_init_deinit( alhena_module_now_init, 
                     alhena_module_now_deinit )
    set_stats( alhena_module_now_record_pre,
               NULL )
    create_config_integer_with_range( "now-lookback", 5, 1, 12 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif /* _NOW_H_ */


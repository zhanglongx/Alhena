#ifndef _FI_LOW_H_
#define _FI_LOW_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_filow_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_filow_close( void * );

bool alhena_module_filow_pos( void *h, alhena_data_t *, 
                              int, int );

alhena_module_begin( filow, "fi-low" )
    set_init_deinit( alhena_module_filow_init, alhena_module_filow_close )
    set_ops( NULL,
             alhena_module_filow_pos,
             NULL )
    create_config_integer_with_range( "fi-low-compare-days", 80, 1, 150 )
    create_config_integer_with_range( "fi-low-lookback", 10, 1, 20 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _FI_LOW_H_


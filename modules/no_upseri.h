#ifndef _NO_UP_SERI_H_
#define _NO_UP_SERI_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_no_upseri_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_no_upseri_close( void * );
bool alhena_module_no_upseri_neg( void *, alhena_data_t *, int , int );

alhena_module_begin( no_upseri, "no-upseri" )
    set_init_deinit( alhena_module_no_upseri_init, 
                     alhena_module_no_upseri_close )
    set_ops( NULL, 
             NULL,
             alhena_module_no_upseri_neg )
    create_config_integer_with_range( "no-upseri-days", 2, 1, 7 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _NO_UP_SERI_H_


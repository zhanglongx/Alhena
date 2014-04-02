#ifndef _NO_UP_SERI_H_
#define _NO_UP_SERI_H_

#ifdef __cplusplus
extern "C" {
#endif

bool alhena_module_no_upseri_record_neg( void *, alhena_data_t *, 
                                         int , int );

alhena_module_begin( no_upseri, "no-upseri" )
    set_init_deinit( NULL, NULL )
    set_ops( NULL, 
             NULL,
             alhena_module_no_upseri_record_neg )
    create_config_integer_with_range( "no-upseri-days", 3, 1, 7 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _NO_UP_SERI_H_


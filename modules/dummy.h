#ifndef _MODULE_DUMMY_H_
#define _MODULE_DUMMY_H_

#ifdef __cplusplus
extern "C" {
#endif

bool alhena_module_dummy_pos( void *, alhena_data_t *, 
                              int, int );

alhena_module_begin( dummy, "dummy" )
    set_init_deinit( NULL, NULL )
    set_ops( NULL,
             alhena_module_dummy_pos,
             NULL )
    create_config_integer_with_range( "dummy-test-int", 1, 0, 10 )
    create_config_bool_set_value( "dummy-test-bool", false )
    create_config_string( "dummy-test-string", "" )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _MODULE_DUMMY_H_


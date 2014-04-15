#ifndef _MAXDAY_H_
#define _MAXDAY_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_maxday_init( variable_t *, alhena_data_t *, 
                                 int , float * );
void alhena_module_maxday_deinit( void * );

bool alhena_module_maxday_pre( void *, alhena_data_t *, 
                               int , int );
bool alhena_module_maxday_neg( void *, alhena_data_t *, 
                               int, int );

alhena_module_begin( maxday, "maxday" )
    set_init_deinit( alhena_module_maxday_init, 
                     alhena_module_maxday_deinit )
    set_ops( alhena_module_maxday_pre,
             NULL,
             alhena_module_maxday_neg )
    create_config_integer_with_range( "maxday-days", 4, 1, 50 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _MAXDAY_H_


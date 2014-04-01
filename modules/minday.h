#ifndef _MINDAY_H_
#define _MINDAY_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_minday_init( variable_t *, alhena_data_t *, 
                                 int , float * );
void alhena_module_minday_deinit( void * );

bool alhena_module_minday_pre( void *, alhena_data_t *, 
                               int , int );
bool alhena_module_minday_pos( void *, alhena_data_t *, 
                               int, int );

alhena_module_begin( minday, "minday" )
    set_init_deinit( alhena_module_minday_init, 
                     alhena_module_minday_deinit )
    set_ops( alhena_module_minday_pre,
             alhena_module_minday_pos,
             NULL )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _MINDAY_H_


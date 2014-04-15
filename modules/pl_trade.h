#ifndef _PL_TRADE_H_
#define _PL_TRADE_H_

#ifdef __cplusplus
extern "C" {
#endif

void *alhena_module_pl_trade_init( variable_t *, alhena_data_t *, int, float * );
void alhena_module_pl_trade_close( void * );

bool alhena_module_pl_trade_pre( void *, alhena_data_t *, 
                                 int , int );
bool alhena_module_pl_trade_pos( void *h, alhena_data_t *, 
                                 int, int );

alhena_module_begin( pl_trade, "pl-trade" )
    set_init_deinit( alhena_module_pl_trade_init, alhena_module_pl_trade_close )
    set_ops( alhena_module_pl_trade_pre,
             alhena_module_pl_trade_pos,
             NULL )
    create_config_float_with_range( "pl-trade-loss", 7.0, 1.0, 80.0 )
    create_config_float_with_range( "pl-trade-profile", 7.0, 1.0, 80.0 )
    create_config_float_with_range( "pl-trade-start", 3.0, 0.0, 80.0 )
    create_config_integer_with_range( "pl-trade-days", 22, 1, 40 )
alhena_module_end()

#ifdef __cplusplus
};
#endif

#endif // _PL_TRADE_H_


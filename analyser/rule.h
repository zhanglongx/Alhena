#ifndef _RULE_H_
#define _RULE_H_

#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

int  alhena_rule_init( alhena_t * );
void alhena_rule_deinit( alhena_t * );
int  alhena_rule_run( alhena_t * );
void alhena_rule_output_day( alhena_t *, int );

#ifdef __cplusplus
};
#endif

#endif // _MODULES_H_


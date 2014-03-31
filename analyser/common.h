#ifndef _COMMON_H_
#define _COMMON_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "alhena.h"
#include "data.h"
#include "analyser/modules.h"

#define RULE_SELL_ONLY          1
#define RULE_BUY_ONLY           2
#define RULE_SELL_2_BUY         4
#define RULE_BUY_2_SELL         8

#define MAX_STAGES              3

struct _alhena_t
{
    alhena_data_t       *p_data;
    uint32_t            i_days;

    alhena_sys_t        *p_sys_root;

    alhena_module_t     open_chain[MAX_STAGES];
    int                 i_open_stages;
    
    alhena_module_t     close_chain[MAX_STAGES];
    int                 i_close_stages;

    alhena_module_t     stats;
    
    int                 i_rule_type;
};

#define ALHENA_UNUSED(x)        (void)(x)
#define ARRAY_SIZE(x)           (sizeof(x) / sizeof((x)[0]))

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
};
#endif

#endif // _COMMON_H_


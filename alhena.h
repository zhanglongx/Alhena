#ifndef _ALHENA_H_
#define _ALHENA_H_

#ifdef __linux__
#   include <inttypes.h>
#   include <stdbool.h>
#   include <limits.h>
#elif defined(_MSC_VER)
typedef unsigned char       uint8_t;
typedef unsigned short      uint16_t;
typedef unsigned int        uint32_t;
typedef unsigned __int64    uint64_t;

typedef char           int8_t;
typedef short          int16_t;
typedef int            int32_t;
typedef __int64        int64_t;

typedef uint8_t        bool;
#define true           1
#define false          0
#else
#error  "not supported platform"
#endif

#include "misc/message.h"

#define  ALHENA_VERSION             "1.3.5"
#define  ALHENA_MAX_FILENAME        1024

#define  ALHENA_EOK                 (-0)
#define  ALHENA_EFATAL              (-1)
#define  ALHENA_ENEG                (-10)

#define  ALHENA_INLINE              static __inline

#define  MIN(a, b)    ((a) < (b) ? (a) : (b))
#define  MAX(a, b)    ((a) > (b) ? (a) : (b))

#ifdef __linux__
#   define ALHENA_SNPRINTF       snprintf
#   define ALHENA_STRDUP         strdup
#elif defined(_MSC_VER)
#   define ALHENA_SNPRINTF       _snprintf
#   define ALHENA_STRDUP         _strdup
#else
#error  "not supported platform"
#endif

#define  FLOAT_TOLERABLE            (0.001)

#define  is_float_eq(f, x) \
         ((f) > (x) - FLOAT_TOLERABLE && (f) < (x) + FLOAT_TOLERABLE)

typedef struct _alhena_t alhena_t;

#ifdef __cplusplus
extern "C" {
#endif

int bank_collect(void);
void bank_decollect(void);
int parse_command_line( int , char *[] );

alhena_t *alhena_create( void );
int alhena_process_data( alhena_t * );
void alhena_output( alhena_t *h );
void alhena_delete( alhena_t * );

#ifdef __cplusplus
};
#endif

#endif // _ALHENA_H_


#include "alhena.h"
#include "data.h"

int compare_float( const void *p1, const void *p2 )
{
    float a1 = *(float *)p1;
    float a2 = *(float *)p2;

    return a1 > a2;
}

int compare_uint64( const void *p1, const void *p2 )
{
    uint64_t a1 = *(uint64_t *)p1;
    uint64_t a2 = *(uint64_t *)p2;

    return a1 > a2;
}


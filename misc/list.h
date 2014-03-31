#ifndef _LIST_H_
#define _LIST_H_

#define INIT_LIST(v) \
    do{ \
        (v)->next = (v); \
        (v)->prev = (v); \
    }while(0)
    
#define LIST_IS_EMPTY(v)             ((v) == (v)->next )

#define list_for_each( p, v ) \
    for( (p)=(v)->next; (p) != (v); (p)=(p)->next )

#define list_for_each_safe( p, n, v) \
    for ( (p) = (v)->next, (n) = (p)->next; (p) != (v); \
        (p) = (n), (n) = (p)->next)

#endif //_LIST_H_


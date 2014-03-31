#include "rule.h"

static int build_chain( alhena_t *, alhena_module_t *, const char *, int );
static int build_stage( alhena_t *, alhena_module_t *, const char * );
static int run_chain( alhena_t *, bool );
static int search_stage( alhena_module_t *, int , alhena_data_t *,
                         int , int );

int alhena_rule_init( alhena_t *h )
{
    alhena_sys_t *p_root = h->p_sys_root;
    char *psz_chain;
    int i, i_stages;
    
    for( i=0; i<MAX_STAGES; i++ )
        INIT_LIST( &h->open_chain[i] );

    for( i=0; i<MAX_STAGES; i++ )
        INIT_LIST( &h->close_chain[i] );

    INIT_LIST( &h->stats );

    psz_chain = sys_get_string( p_root, "open-chain" );

    i_stages = build_chain( h, h->open_chain, psz_chain, ARRAY_SIZE( h->open_chain ) );
    if( i_stages < 0 )
        return ALHENA_EFATAL;
    
    h->i_open_stages = i_stages;
    if( i_stages == 0 )
    {
        msg_Err( "don't have open-chain as rule, check input" );
        return ALHENA_EFATAL;
    }

    psz_chain = sys_get_string( p_root, "close-chain" );

    i_stages = build_chain( h, h->close_chain, psz_chain, ARRAY_SIZE( h->close_chain ) );
    if( i_stages < 0 )
        return ALHENA_EFATAL;

    h->i_close_stages = i_stages;

    psz_chain = sys_get_string( p_root, "stats" );

    // NOTE: ignore stats fail
    build_chain( h, &h->stats, psz_chain, 1 );

    return ALHENA_EOK;
}

void alhena_rule_deinit( alhena_t *h )
{
    alhena_module_t *l, *n;
    int i;

    list_for_each_safe( l, n, &h->stats )
        module_delete( l );

    for( i=0; i<h->i_open_stages; i++ )
    {
        list_for_each_safe( l, n, &h->open_chain[i] )
            module_delete( l );
    }

    for( i=0; i<h->i_close_stages; i++ )
    {
        list_for_each_safe( l, n, &h->close_chain[i] )
            module_delete( l );
    }
}

int alhena_rule_run( alhena_t *h )
{
    return run_chain( h, true );
}

void alhena_rule_output_day( alhena_t *h, int i_day )
{
    int i_cnt, k;

    for( k=0; k<2; k++ )
    {
        alhena_module_t *p_chain = !k ? h->open_chain : h->close_chain;
        int i_stages = !k ? h->i_open_stages : h->i_close_stages;
        
        for( i_cnt=0; i_cnt<i_stages; i_cnt++ )
        {
            alhena_module_t *l;
            
            list_for_each( l, p_chain )
            {
                if( l->p_sys_data )
                    fprintf( stdout, "%.2f,", l->p_sys_data[i_day] );
            }

            p_chain++;
        }
    }
}

static int build_chain( alhena_t *h, alhena_module_t *p_chain, 
                        const char *psz_chain, int i_max_stages )
{
    alhena_module_t *p_start_chain = p_chain;
    const char *p = psz_chain;
    int i, i_stage = 0;

    for( ;strlen(p) && i_stage < i_max_stages; )
    {
#define MAX_STAGE_NAME_LEN      (5 * ALHENA_MAX_SYS_NAME)
        char psz_name[MAX_STAGE_NAME_LEN] = "\0";
        const char *p_dot = p;
        int k = 0;

        while( *p_dot != '\0' && *p_dot != ',' && k < MAX_STAGE_NAME_LEN )
            psz_name[k++] = *p_dot++;

        if( k == MAX_STAGE_NAME_LEN )
        {
            msg_Err( "input stage too long" );
            goto label_free_chain;
        }

        if( build_stage( h, p_chain, psz_name ) < 0 )
            goto label_free_chain;

        msg_Dbg( "loaded %s in stage: %d", psz_name, i_stage );

        p_chain++;
        i_stage++;

        if( *p_dot == '\0' )
        {
            p = p_dot;
            break;
        }

        p = p_dot+1;

#undef MAX_STAGE_NAME_LEN
    }

    if( strlen(p) && i_stage == i_max_stages )
    {
        msg_Err( "stages too much" );
        goto label_free_chain;
    }

    return i_stage;

label_free_chain:
    for( i=0; i<i_stage; i++ )
    {
        alhena_module_t *l, *n;
        
        list_for_each_safe( l, n, p_start_chain )
            module_delete( l );

        p_start_chain++;
    }
    
    return -1;
}

static int build_stage( alhena_t *h, alhena_module_t *p_stage, const char *psz_stage )
{
    alhena_sys_t *p_root = h->p_sys_root;
    alhena_module_t *p_mod, *l, *n;
    const char *p = psz_stage;
    bool b_output = sys_get_bool( p_root, "gen-output" );
    
    for( ;strlen(p); )
    {
        char psz_name[ALHENA_MAX_SYS_NAME] = "\0";
        const char *p_dot = p;
        bool b_have_mod = false;
        int k = 0;

        while( *p_dot != '\0' && *p_dot != '+' && k < ALHENA_MAX_SYS_NAME )
            psz_name[k++] = *p_dot++;

        if( k == ALHENA_MAX_SYS_NAME )
        {
            msg_Err( "input sys name too long" );
            goto label_free_stage;
        }

        list_for_each( l, p_stage )
            if( !strncmp( psz_name, l->p_sys->psz_name, ALHENA_MAX_SYS_NAME ) )
            {
                msg_Info( "already have %s in this stage" );
                b_have_mod = true;
            }

        if( !b_have_mod )
        {
            p_mod = module_new( psz_name, h->p_data, h->i_days, b_output, NULL, 0 );
            if( !p_mod )
            {
                msg_Err( "load %s failed", psz_name );
                goto label_free_stage;
            }

            list_add_tail_mod( p_mod, p_stage );
        }

        if( *p_dot == '\0' )
            break;

        p = p_dot+1;
    }

    return LIST_IS_EMPTY( p_stage ) ? -1 : 0;

label_free_stage:
    list_for_each_safe( l, n, p_stage )
        module_delete( l );

    return -1;
}

static int run_chain( alhena_t *h, bool b_open_flag )
{
    alhena_module_t *p_stage = b_open_flag ? h->open_chain : h->close_chain;
    alhena_module_t *l;
    alhena_data_t *p_data = h->p_data;
    int i_stages = b_open_flag ? h->i_open_stages : h->i_close_stages;
    uint32_t i_day;

    if( i_stages <= 0 )
        return ALHENA_EFATAL;
    
    for( i_day=0; i_day<h->i_days; i_day++ )
    {
        bool b_first_positive = true;
        int i_flag_day = -1;
                
        list_for_each( l, p_stage )
        {
            // FIXME: logic 'or' between modules?
            if( module_is_positive( l, p_data, i_day, h->i_days - 1 ) == false )
                b_first_positive = false;
        }

        if( b_first_positive )
        {
            if( i_stages > 1 )
                i_flag_day = search_stage( p_stage + 1, i_stages - 1,
                                           p_data, i_day, h->i_days - 1 );
            else
                i_flag_day = i_day;
        }

        if( i_flag_day > 0 )
        {
            if( b_open_flag )
            {
                p_data->open_flag[i_flag_day] = 1;
                
                list_for_each( l, &h->stats )
                    module_stat_pre( l, p_data, i_flag_day, h->i_days - 1 );
            }
            else
                p_data->close_flag[i_flag_day] = 1;
        }
    }

    return ALHENA_EOK;    
}

static int search_stage( alhena_module_t *p_stage, int i_stage, 
                         alhena_data_t *p_data,
                         int i_start, int i_end )
{
    alhena_module_t *l;
    int i;
    
    if( i_stage <= 0 )
        return i_start;

    if( i_start >= i_end - MAX_STAGES )
    {
        // not enough data to process
        return ALHENA_ENEG;
    }

    list_for_each( l, p_stage )
        module_set_pre( l, p_data, i_start, i_end );

    /* using recursive to search */
    for( i=i_start; i<i_end; i++ )
    {
        list_for_each( l, p_stage )
        {
            bool b_positive = true;
            
            if( module_is_negative( l, p_data, i, i_end ) == true )
                return ALHENA_ENEG;

            if( module_is_positive( l, p_data, i, i_end ) == false )
                b_positive = false;

            if( b_positive )
                return search_stage( p_stage + 1, i_stage - 1, 
                                     p_data, i, i_end );
        }
    }

    return ALHENA_ENEG;
}


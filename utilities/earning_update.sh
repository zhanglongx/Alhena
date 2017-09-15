#! /bin/sh

ALHENA_DIR=~/Programming/Alhena
ALHENA_EXTRA_DIR=$ALHENA_DIR/extra

UPDATE_FILE=earning_update.lst

failed_exit()
{
    echo "$0: $1"
    exit 1
}

test -e $UPDATE_FILE || failed_exit "$UPDATE_FILE not exist"

sed ':a;N;$!ba;s/\n/ /g' $UPDATE_FILE \
    | xargs perl -I $ALHENA_EXTRA_DIR $ALHENA_EXTRA_DIR/earning_querier.pl \
            -d --no-human -r -s 4 -f PE -p $ALHENA_DIR/database > /dev/null

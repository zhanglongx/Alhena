#! /bin/sh

ALHENA_DIR=~/Alhena
ALHENA_DATABASE_DIR=$ALHENA_DIR/database
ALHENA_EXTRA_DIR=$ALHENA_DIR/extra

UPDATE_FILE=earning_update.lst

#
# Command line handling
#
usage()
{
	echo "Usage: $0 START"

    exit 0
}

failed_exit()
{
    echo "$0: $1"
    exit 1
}

START=$1

test x$START != x || usage

test -e $ALHENA_DATABASE_DIR/$START.csv || failed_exit "$START is not in database"

STOCKS=`find $ALHENA_DIR/database -name '*.csv' -exec basename {} '.csv' \; | sort -n`

for s in $STOCKS; do
    if test $s -ge $START; then
        LIST="$LIST $s"
    fi
done

echo $LIST | xargs perl -I $ALHENA_EXTRA_DIR $ALHENA_EXTRA_DIR/earning_querier.pl \
                -d --no-human -r -s 4 -f PE -p $ALHENA_DIR/database > /dev/null

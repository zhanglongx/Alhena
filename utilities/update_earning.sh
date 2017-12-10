#! /bin/sh

ALHENA_DIR=~/Alhena
ALHENA_DATABASE_DIR=$ALHENA_DIR/database
ALHENA_EXTRA_DIR=$ALHENA_DIR/extra

MIN_TIME_INTERVAL=2592000 # 30 * 24 * 60 * 60
MIN_FILE_SIZE=3072 # 3 * 1024 bytes

#
# Command line handling
#
usage()
{
	echo "Usage: $0"

    exit 0
}

failed_exit()
{
    echo "$0: $1"
    exit 1
}

is_update_here()
{
    stock=$1
    file=${ALHENA_DIR}/database/earning/${stock}_balance.txt

    if [ ! -e $file ]; then
        return 1
    fi

    # modified in 12 hrs
    if [ `expr $(date +%s) - $(stat -c %Y $file)` -gt $MIN_TIME_INTERVAL ]; then
        return 1
    fi

    if [ `expr $(stat -c %s $file)` -le $MIN_FILE_SIZE ]; then
        return 1
    fi

    return 0
}

STOCKS=`find $ALHENA_DIR/database -name '*.csv' -exec basename {} '.csv' \; | sort -n`

for s in $STOCKS; do

    is_update_here $s
    if test $? != 0; then
        LIST="$LIST $s"
    fi
done

echo $LIST | xargs perl -I $ALHENA_EXTRA_DIR $ALHENA_EXTRA_DIR/earning_querier.pl \
                -d --no-human -r -s 4 -f PE -p $ALHENA_DIR/database > /dev/null

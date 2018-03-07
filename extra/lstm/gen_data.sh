#! /bin/bash

set -x

ALHENA=/home/zhlx/Alhena
ALL_CSV="all.csv"
TMP_SAMPLES="_samples.txt"
N_CHS=1 # N_CHS must match -f below!

#
# Command line handling
#
usage()
{
	echo "Usage: $0 [options]"
	echo "  -y YEARS    years"

    exit 0
}

while getopts 'y:h' OPT; do
    case $OPT in
        u)
            YEARS="$OPTARG";;
        h)
            usage;;
        ?)
            usage;;
    esac
done

failed_exit()
{
    echo "$0: $1"
    exit 1
}

test -d $ALHENA || failed_exit "alhena path error"

# clean up
if test -d './data'; then
	rm -rf ./data
fi

mkdir -p ./data
mkdir -p ./data/X
mkdir -p ./data/Y

# TODO: appoint -f, edit N below
perl -I $ALHENA/extra $ALHENA/extra/earning_querier.pl -p $ALHENA/database -s 4 -f ROE --no-human > $ALL_CSV

N_FILES=`ls -l $ALHENA/database/earning | wc -l`
N_FILES=`expr $N_FILES / 3`

# test n_samples contains exactly n_channels * n_samples entries
test `cat $ALL_CSV | wc -l` -eq `expr $N_CHS \* $N_FILES` || failed_exit "entries error"

# get x have exactly years
cat $ALL_CSV | awk -F , -v var="$YEARS" '{if(NF>=var+2) {print $1, $2; for(i=NF-var+1; i<=NF; i++) print , $i}}' > ./data/X/samples.csv

rm -f $ALL_CSV
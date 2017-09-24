#! /bin/sh

ALHENA_DIR=~/Programming/Alhena
ALHENA_EXTRA_DIR=$ALHENA_DIR/extra

DEFAULT_CSV_NAME=pe_roe_raw.csv

_PE_RAW_CSV=pe_raw.csv
_ROE_RAW_CSV=roe_raw.csv

_FORMULA_FILE=_formula.txt

_PE_CSV=pe.csv
_ROE_CSV=roe.csv

MAX_PE=25
MIN_ROE=0.18

#
# Command line handling
#
usage()
{
	echo "Usage: $0 [.csv]"
	echo "  if .csv was not given, it will try get a new one"

    exit 0
}

CSV_FILE=$1

failed_exit()
{
    echo "$0: $1"
    exit 1
}

update_raw()
{
    echo "PE\nROE" > $_FORMULA_FILE
    perl -I $ALHENA_EXTRA_DIR $ALHENA_EXTRA_DIR/earning_querier.pl \
        --no-human -s 4 -f $_FORMULA_FILE -p $ALHENA_DIR/database > $DEFAULT_CSV_NAME

    CSV_FILE=$DEFAULT_CSV_NAME

    return 1
}

test x$CSV_FILE != x || update_raw

test -e $CSV_FILE || failed_exit "$CSV_FILE not exist" 

sed -n 's@股价\*总股本/净利润@pe@p' $CSV_FILE > $_PE_RAW_CSV
sed -n 's@净利润/(资产总计-负债合计)@roe@p' $CSV_FILE > $_ROE_RAW_CSV

awk -F , -v MAXPE="$MAX_PE" '{b=1; for(i=3; i<=(NF>5?5:NF); i++) if($i > MAXPE || $i < 0) b=0; if(b && NF >= 5) print $0 }' $_PE_RAW_CSV > $_PE_CSV
awk -F , -v MINROE="$MIN_ROE" '{b=1; for(i=3; i<=(NF>5?5:NF); i++) if($i < MINROE) b=0; if(b && NF >= 5) print $0 }' $_ROE_RAW_CSV > $_ROE_CSV

sort -t , -no $_PE_CSV $_PE_CSV
sort -t , -no $_ROE_CSV $_ROE_CSV

join -t , -o 1.1 $_PE_CSV $_ROE_CSV

# for excel print
sed -i -e "s/^/'/" $_PE_CSV
sed -i -e "s/^/'/" $_ROE_CSV

# clean-up
test $CSV_FILE != $DEFAULT_CSV_NAME || rm -f $CSV_FILE

rm -f $_PE_RAW_CSV $_ROE_RAW_CSV $_FORMULA_FILE

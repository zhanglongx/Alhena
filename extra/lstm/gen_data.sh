#! /bin/bash

ALHENA=/home/zhlx/Alhena
ALL_CSV="all.csv"
SAMPLE_FILE="./data/X/sample.csv"
YEARS=5
N_CHS=2 # N_CHS must match -f below!

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
        y)
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
test $YEARS -gt 0 || failed_exit "input YEARS error"

test -d ./data || failed_exit "please mkdir ./data"

# clean up
rm -rf ./data/X
mkdir -p ./data/X

# TODO: appoint -f, edit N above
perl -I $ALHENA/extra $ALHENA/extra/earning_querier.pl -p $ALHENA/database -s 4 -f _formula.txt --no-human > $ALL_CSV

N_FILES=`ls -l $ALHENA/database/earning | wc -l`
N_FILES=`expr $N_FILES / 3`

# test n_samples contains exactly n_channels * n_samples entries
test `cat $ALL_CSV | wc -l` -eq `expr $N_CHS \* $N_FILES` || failed_exit "entries error"

# get x have exactly years
# XXX: about NF, workaround for the trailing ','
cat $ALL_CSV | \
	awk -F , -v var="$YEARS" '{if(NF>var+2) {printf "%06d, %s, ", $1, $2; for(i=NF-var; i<NF; i++) printf "%f, ", $i; printf "\n"}}' \
		> $SAMPLE_FILE

entries=`cat $SAMPLE_FILE | wc -l`

# missing entries
(( $entries % $N_CHS == 0 )) || failed_exit "samples.csv entries error"
entries=`expr $entries / $N_CHS`

for i in `seq $entries`; do
	let s=$i*$N_CHS-1 e=$i*$N_CHS-1+$N_CHS-1

	# get name
	lines=`sed -n "$s, ${e}p" $SAMPLE_FILE`
	name=`echo $lines | head -n 1 | cut -d , -f 1`

	# content
	sed -n "$s, ${e}p" $SAMPLE_FILE > ./data/X/${name}.csv
done

# tempz
# rm -f $SAMPLE_FILE
# rm -f $ALL_CSV
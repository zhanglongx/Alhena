#! /bin/bash

DEFAULT_TXT=_basic_formula.txt

#
# Command line handling
#
usage()
{
	echo "Usage: $0 [options] NAME"
	echo "  -f formula    formula"

    exit 0
}

while getopts 'f:h' OPT; do
    case $OPT in
        f)
            formula="$OPTARG";;
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

cat > $DEFAULT_TXT << EOF
PE
ROE
净利润 
净利润%
股价
EOF

alhena_dir=~/Alhena

test -e $alhena_dir/extra/earning_querier.pl || failed_exit "can't find earning_querier.pl"

querier_one()
{
    f=$1
    name=$2

    test -e $alhena_dir/database/$name.csv || failed_exit "$name not exist"

    perl -I $alhena_dir/extra $alhena_dir/extra/earning_querier.pl -s 4 -p $alhena_dir/database -f $f $name
}

shift $((OPTIND-1))
for name in $@; do
    if test x$formula = x; then
        querier_one $DEFAULT_TXT $name
    else
        querier_one $formula $name
    fi
done

rm -f $DEFAULT_TXT

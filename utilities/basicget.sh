#! /bin/bash

alhena_dir=~/Alhena

if ! [ -e $alhena_dir/database/$1.csv ] ; then
    echo "check argument"
    exit 1
fi

if ! [ -e $alhena_dir/extra/earning_querier.pl ]; then
    echo "check directory"
    exit 1
fi

perl -I $alhena_dir/extra $alhena_dir/extra/earning_querier.pl -s 4 -p $alhena_dir/database -f $alhena_dir/extra/formula.txt $1

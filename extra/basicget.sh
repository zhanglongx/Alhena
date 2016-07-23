#! /bin/bash

if ! [ -e ./database/$1.csv ] ; then
    echo "check argument"
    exit 1
fi

if ! [ -e ./extra/earning_querier.pl ]; then
    echo "check directory"
    exit 1
fi

perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '营业收入' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '营业收入%' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '净利润' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '净利润/营业收入' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '市盈率' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '负债合计/资产总计' $1
perl -I ./extra ./extra/earning_querier.pl -s 4 -t -p ./database --human -f '股价*总股本' $1

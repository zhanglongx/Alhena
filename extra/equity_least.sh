#! /bin/bash
data_dir=../database

#FILES="$data_dir/000001.csv $data_dir/000002.csv $data_dir/000004.csv"
FILES=`find $data_dir -name "*.csv"`

rm -f merge.csv

for csv_file in $FILES
do
    name=`basename $csv_file`
    name=${name/.csv/}
    cat $csv_file | sed "s/^/$name,/" | tail -n 1 >> merge.csv
done 

sort -nrk 8 < merge.csv

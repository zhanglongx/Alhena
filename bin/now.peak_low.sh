#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./now.peak_low.sh

Help:
  -h, --help               print this message

EOF
exit 1
fi

data_dir=../database
out_dir=./result

# clean last result
rm -rf result.csv
find $out_dir -name "*.csv" -exec rm -f {} \;

FILES=`find $data_dir -name "*.csv"`
#FILES="$data_dir/300079.csv $data_dir/600000.csv $data_dir/600004.csv"

for csv_file in $FILES
do
    ./alhena -o fi-low -s now --fi-low-lookback 3 $csv_file > ${csv_file/$data_dir/$out_dir}
done 

for out_file in `find $out_dir -name "*.csv"` 
do
    name=`basename $out_file`
    name=${name/.csv/}
    cat $out_file | sed -n "s/^now,/$name,/gp" >> result.csv
done

cat result.csv | sort -nrt '-' -k 3

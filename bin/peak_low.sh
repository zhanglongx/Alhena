#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./peak_low.sh [options]

Help:
  -h, --help               print this message

Standard options:
  --enable-hst             output .hst
  
EOF
exit 1
fi

data_dir=../database
out_dir=./result

# clean last result
rm -f result.csv
find $out_dir -name "*.csv" -exec rm -f {} \;

is_hst="no"

for opt do
    optarg="${opt#*=}"
    case "$opt" in
        --enable-hst)
            is_hst="yes"
            ;;
        *)
            echo "Unknown option $opt, ignored"
            ;;            
    esac
done

FILES=`find $data_dir -name "*.csv"`
#FILES="$data_dir/300079.csv $data_dir/600000.csv $data_dir/600004.csv"

for csv_file in $FILES
do
    ./alhena -o fi-low -s peak-low $csv_file > ${csv_file/$data_dir/$out_dir}
done 

for out_file in `find $out_dir -name "*.csv"` 
do
    name=`basename $out_file`
    name=${name/.csv/}
    cat $out_file | sed -n "s/^stat,/$name,/gp" >> result.csv
done

if [ $is_hst = yes ]; then
    cat result.csv \
        | awk -F ',' '{printf "../extra/data_printer.pl -n %s -s %s -b 20 -m ./hst/ \n", \
                                    $1, $2}' \
            | sh -x
fi

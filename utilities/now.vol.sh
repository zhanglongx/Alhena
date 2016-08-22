#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./now.vol.sh

Help:
  -h, --help               print this message

  --dir=DIR                path to Alhena
                           [~/Alhena]
  --list=FILE              stock list
EOF
exit 1
fi

alhena_dir=~/Alhena
out_dir=./result

for opt do
    optarg="${opt#*=}"
    case "$opt" in
        --dir=*)
            alhena_dir="$optarg"
            ;;
        --list=*)
            list_file="$optarg"
            ;;
        *)
            echo "Unknown option $opt, ignored"
            ;;
    esac
done

if [ ! -d $alhena_dir ]; then
    echo "alhena_dir: $alhena_dir not exsit"
    exit 1
fi   

# clean last result
rm -f result.csv
rm -f result.tmp.csv

if [ -d $out_dir ]; then
    find $out_dir -name "*.csv" -exec rm -f {} \;
else
    mkdir -p $out_dir
fi

all_stock="300079"

if [ x$list_file != x ] && [ -f $list_file ]; then
    all_stock=`cat $list_file`
fi

for stock in $all_stock
do
    file=$alhena_dir/database/$stock.csv
    
    if [ ! -f $file ]; then
        echo "stock: $stock dosen't exist"
        continue
    fi
    
    $alhena_dir/bin/alhena -o vol --vol-compare-days 30 -s now --now-lookback 1 $file > $out_dir/$stock.csv
done 

for out_file in `find $out_dir -name "*.csv"` 
do
    name=`basename $out_file`
    name=${name/.csv/}
    cat $out_file | sed -n "s/^now,/$name,/gp" >> result.tmp.csv
done

cat result.tmp.csv | sort -nrt '-' -k 3 >> result.csv

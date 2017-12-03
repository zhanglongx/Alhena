#! /bin/bash

RESULT_FILE=result.csv
RESULT_TMP_FILE=result.tmp.csv

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: $0 [options]

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
rm -f $RESULT_FILE
rm -f $RESULT_TMP_FILE

if [ -d $out_dir ]; then
    find $out_dir -name "*.csv" -exec rm -f {} \;
else
    mkdir -p $out_dir
fi

if [ x$list_file != x ] && [ -f $list_file ]; then
    all_stock=`cat $list_file | egrep -v '^.*#'`
    ops=`cat $list_file | sed -n 's/^.*#//p'`
fi

if [[ x$all_stock == x ]] || [[ x$ops == x ]]; then
    echo "list file error"
    exit 1
fi

for stock in $all_stock
do
    file=$alhena_dir/database/$stock.csv
    
    if [ ! -f $file ]; then
        echo "stock: $stock dosen't exist"
        continue
    fi
    
    $alhena_dir/bin/alhena $ops $file > $out_dir/$stock.csv
done 

for out_file in `find $out_dir -name "*.csv"` 
do
    name=`basename $out_file`
    name=${name/.csv/}
    cat $out_file | sed -n "s/^now,/$name,/gp" >> $RESULT_TMP_FILE
done

if [ -e $RESULT_TMP_FILE ]; then
    cat $RESULT_TMP_FILE | sort -nrt '-' -k 3 >> $RESULT_FILE
fi

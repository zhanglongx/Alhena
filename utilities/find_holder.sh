#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./find_holder.sh [options]

Help:
  -h, --help               print this message
Standard options:  
  --holders                holders
  --start-date             start date
EOF
exit 1
fi

if uname -a | egrep -i darwin > /dev/null 2>&1; then
    export LC_ALL=C
fi

alhena_dir=~/Alhena

holders=""
start_date="2008-01-01"

for opt do
    optarg="${opt#*=}"
    case "$opt" in
        --holders=*)
            holders="$optarg"
            ;;
        --start-date=*)
            start_date="$optarg"
            ;;
        *)
            echo "Unknown option $opt, ignored"
            ;;            
    esac
done

if [ x"$holders" = x ]; then
    echo "input holders name"
    exit 1
fi

if ! echo $start_date | egrep '[0-9]*-[0-9]*-[0-9]*' > /dev/null 2>&1; then
    echo "input start-date error"
    exit 1
fi

# add -p to name(s)
holders=`echo $holders | sed -e 's/ / -p /g' -e 's/^/-p /g'`

FILES=`find $alhena_dir/database/holder -name '*.txt'`

rm -f result.txt

for file in $FILES; do
    name=`basename $file`
    name=${name/.txt/}
    $alhena_dir/extra/holder_finder.pl -n $name $holders -s $start_date >> result.txt
done

cat result.txt

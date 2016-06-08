#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./now.vol.sh

Help:
  -h, --help               print this message

  -dir=DIR                 path to Alhena
                           [~/Alhena]
                           
  -t=time                  date or moth time (yy-mm-dd)
EOF
exit 1
fi

alhena_dir=~/Alhena
date=$(date -dlast-monday +%Y-%m-%d)

OPTIND=1
    while getopts ":d:t:" option; do
        case "$option" in
        d) alhena_dir=$OPTARG ;;
        t) date=$OPTARG ;;
        esac
    done
    shift $((OPTIND - 1))

name=$1

#echo $alhena_dir, $date, $name

if ! [ -d $alhena_dir/database ]; then
    echo "$alhena_dir/database doen't exist"
    exit 1
fi

if ! echo $date | egrep '[0-9]+-[0-9]+' 2>&1 > /dev/null; then
    echo "date format error"
    exit 1
fi

if ! [ -e $alhena_dir/database/$name.csv ]; then
    echo "$name error"
    exit 1
fi

egrep $date $alhena_dir/database/$name.csv | \
    awk -F ',' '{printf "%s, %.2f, %d\n", $1, $2, $2 * $7 / 100000000}'
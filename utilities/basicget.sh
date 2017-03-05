#! /bin/bash

if test x"$1" = x"-h" -o x"$1" = x"--help" ; then
cat <<EOF
Usage: ./$0 [options]

Help:
  -h, --help               print this message
Standard options:  
  --no-human               not human readable
EOF
exit 1
fi

alhena_dir=~/Alhena

human=true
stock=300079

for opt do
    optarg="${opt#*=}"
    case "$opt" in
        --no-human)
            human=false
            ;;
        *)
            # FIXME:
            stock=$opt
            ;;            
    esac
done

if ! [ -e $alhena_dir/database/$stock.csv ] ; then
    echo "check argument"
    exit 1
fi

if ! [ -e $alhena_dir/extra/earning_querier.pl ]; then
    echo "check directory"
    exit 1
fi

if test $human = true; then
    perl -I $alhena_dir/extra $alhena_dir/extra/earning_querier.pl -s 4 -p $alhena_dir/database -f $alhena_dir/extra/formulas.txt $stock
else
    perl -I $alhena_dir/extra $alhena_dir/extra/earning_querier.pl --no-human -s 4 -p $alhena_dir/database -f $alhena_dir/extra/formulas.txt $stock
fi

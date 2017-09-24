#
# Command line handling
#
usage()
{
	echo "Usage: $0 START"

    exit 0
}

failed_exit()
{
    echo "$0"
    exit 1
}

test -e ./database || failed_exit "no database found in"

find ./database -name '*.csv' | xargs tar -cJf database.tar.xz

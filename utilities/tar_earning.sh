#
# Command line handling
#

TAR_NAME=database_earning.tar.xz
TEMP_NAME=${TAR_NAME%.xz}

usage()
{
	echo "Usage: $0"

    exit 0
}

failed_exit()
{
    echo "$0"
    exit 1
}

test -e ./database/earning || failed_exit "no database earning dir found"

rm -f $TAR_NAME
rm -f $TEMP_NAME

find ./database/earning -name '*.txt' -exec tar -rf $TEMP_NAME {} \;
xz -z $TEMP_NAME

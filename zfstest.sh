#!/bin/sh

deleteimage () {
	if [ ! -b "$ZFSDEVICE" ]
	then
		rm $ZFSDEVICE
		sleep 1
	fi
}

destroypool () {
	zpool destroy zfstest
	rmdir /zfstest
	deleteimage
}

print_corruption () {
	sleep 1
	zpool status zfstest | grep $(basename -- "$ZFSDEVICE")
	zpool status zfstest | grep -i corruption > /dev/null
	if [ $? -eq 0 ]
	then
		echo "zfs detected corruption"
		RET=1
	else
		echo "zfs detected no corruption"
		RET=0
	fi
	return $RET
}

empty () {
	sleep 0
}

if [ "$#" -ne 1 ]
then
	echo "Usage: $0 device"
	exit 1
fi
ZFSDEVICE="$1"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

#CMD_SHASUM="shasum /zfstest/testfile"
CMD_SHASUM="dd status=none if=/zfstest/testfile bs=8192 | shasum"

set -e
modprobe -v zfs
if [ ! -b "$ZFSDEVICE" ]
then
	truncate -s 1G $ZFSDEVICE
fi
trap deleteimage EXIT
zpool create -f -m /zfstest zfstest `readlink -f $ZFSDEVICE`
trap destroypool EXIT
dd if=/dev/zero of=/zfstest/testfile bs=1M count=800 2> /dev/null
SUM_A=`eval $CMD_SHASUM`
echo "$SUM_A"
set +e
print_corruption
set -e
echo "corrupting filesystem"
echo -n -e '\x34' | dd of=$ZFSDEVICE seek=290000003 bs=1 conv=notrunc 2> /dev/null
#./disktest $ZFSDEVICE 34 290000003
sync
echo 3 > /proc/sys/vm/drop_caches

echo "trying to read a file from corrupted filesysten with shasum"
set +e
SUM_B=`eval $CMD_SHASUM`
echo "$SUM_B"
print_corruption
CORRUPTED=$?
set -e
if [ "$SUM_A" != "$SUM_B" ]
then
	if [ $CORRUPTED -eq 0 ]
	then
		echo "\n${RED}the pool is silently corrupted${NC}"
		trap empty EXIT
		exit 0
	else
		echo "\n${GREEN}zfs detected the corruption${NC}"
	fi
else
	echo "\nno corruption in file"
fi


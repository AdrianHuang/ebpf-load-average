#!/bin/bash

PGM=tar

TAR_SRC=/home/adrian/git-repo/linux
TAR_DEST=/home/adrian/archive/linux-archive.tar

SGV_TGT_FOLDER=/var/www/html/misc/ebpf/tar/v3/

if [ ! -d $SGV_TGT_FOLDER ]; then
	mkdir $SGV_TGT_FOLDER	
fi

uptime > uptime.log
${PGM} -cf $TAR_DEST $TAR_SRC &
tar_pid=$!

(pidstat -C ${PGM} 60 2>&1 | tee pidstat-${PGM}.log) &

(iostat -x 60 /dev/sda2 2>&1 | tee iostat-${PGM}.log) &

~/git-repo/bcc-master/tools/offcputime.py -K --state 2 -f 60 > ${PGM}.stacks

# Get more uptime data for 5-second interval
for i in {1..4}
do
	uptime >> uptime.log && sleep 5
done

# Generate flame graph
awk '{ print $1, $2 / 1000 }' ${PGM}.stacks | /home/adrian/git-repo/FlameGraph/flamegraph.pl --title="Kernel Uninterruptible Off-CPU Flame Graph (60 secs)" --color=io --countname=ms > ${PGM}.svg
mv ${PGM}.svg $SGV_TGT_FOLDER

# kill the running process
kill -9 $tar_pid
killall pidstat iostat

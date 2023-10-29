#!/bin/bash
########################################################
# apply.sh : script de déployement
# Version template : 1.0
# Instance : tpvagrant v1.0
# Alan Simon
########################################################

###### Var
filelist="process.yml testapp.js"
userapp="nodeapp"
destdir="/home/$userapp"
sourcedir="/vagrant/src"
archdir="/home/$userapp/archive"
suffix="`date +%Y-%m-%d-%H:%M:%S`"

function err {
	echo "`date +%Y/%m/%d-%H:%M:%S` : error : $1" >&2
	exit 4
}
function warn {
	echo "`date +%Y/%m/%d-%H:%M:%S` : warning : $1" >&2
}

test $(id -u) -eq 0 || err "you have to be root"

echo applying configuration
# if processes is running stop it
ps -ef | grep -v grep | grep -q $destdir/process.yml && su - nodeapp -c ". ./.nodeprofile ; pm2 stop $destdir/process.yml" || warn "stop failed"

for file in $filelist
do
# if desstinationn exists then save it
test -f $destdir/$file && mv $destdir/$file $archdir/$file.$suffix ||  warn "save failed"
done

for file in $filelist
do
cp $sourcedir/$file $destdir/$file || warn "deploy failed"
chgrp $userapp $destdir/$file
done

su - $userapp -c ". ./.nodeprofile ; pm2 start $destdir/process.yml" || err "start failed"

echo Done

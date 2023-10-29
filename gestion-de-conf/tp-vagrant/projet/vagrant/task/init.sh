#!/bin/bash
########################################################
# init.sh : Installation node, npm et pm2
# Version template : 1.0
# Instance : 
# Alan Simon
########################################################

###### var
ver="v17.4.0"
basenodename="node-${ver}-linux-x64"
tarball="$basenodename.tar.gz"
baseurl="http://nodejs.org/dist/$ver/$tarball"
dldir="/opt"
target="/usr/local/lib/nodejs"
user="nodeapp"
userhome="/home/$user"

function err {
	echo " error : $1" >&2
	exit 4
}

test $(id -u) -eq 0 || err "you have to be root"

echo downloading $basenodename
test -f $dldir/$tarball || curl -sLo $dldir/$tarball ${baseurl} || err "package download error"

echo extracting in $target
test -d $target || mkdir $target || err "making dir $target error"
tar zxf $dldir/$tarball -C $target || err "extract source error"

echo creating user $user
id -u $user 1>/dev/null 2>&1 || useradd -m $user || err "create user $user error" 
test -d $userhome/archive || mkdir $userhome/archive || err "create archive folder $userhome/archive failed"

echo setting up $user envrionment
grep -q ". .nodeprofile" $userhome/.bashrc || echo ". .nodeprofile" >> $userhome/.bashrc
echo "export NODEJS_HOME=$target/${basenodename}" > $userhome/.nodeprofile
echo 'export PATH=$NODEJS_HOME/bin:$PATH' >> $userhome/.nodeprofile

(. $userhome/.nodeprofile ; npm install npm@latest -g) || err "update npm error"
(. $userhome/.nodeprofile ; npm install pm2 -g)  || err "install pm2 error"

exit 0


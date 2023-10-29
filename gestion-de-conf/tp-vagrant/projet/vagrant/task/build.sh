#!/bin/bash
########################################################
# build.sh : script de build
# Version template : 1.0
# Instance : 
# Alan Simon
########################################################

function err {
	echo "`date +%Y/%m/%d-%H:%M:%S` : error : $1" >&2
	exit 4
}

test $(id -u) -eq 0 || err "you have to be root"
echo "building app"
# nothing to do here 
# hum, yes nothing
echo "done"

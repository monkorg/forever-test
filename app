#!/bin/bash

##########################################################################################
# forever startup application script
##########################################################################################
NAME=forever-app

SOURCE_FILE="app.js"
# SHUTDOWN_SCRIPT=prepareForStop.js
set -e

##########################################################################################
# Logging and debugging
##########################################################################################
# DEBUG="yes"
# LOG='yes'

forever_dir=/var/run
node=node
forever=forever
sed=sed

ABSOLUTE_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/`basename "${BASH_SOURCE[0]}"`
SOURCE_DIR="$( dirname "${ABSOLUTE_PATH}" )"


## TODO: check YES || Yes || yes || Y || y
## for both LOG and DEBUG

## TURN ON | OFF logging to file
log_to_file_on(){
	LOGDIR=$SOURCE_DIR/log
	LOGFILE=$LOGDIR/$NAME.log
	ERRORLOG=$LOGDIR/$NAME.error.log
	[ -d $LOGDIR ] || mkdir $LOGDIR
	# remove logfile if it exist's to allow forever run without -a (append log) option
	[ -f $LOGFILE ] && rm $LOGFILE
	log_options=""
}
log_to_file_off(){
	LOGFILE="/dev/null"
	ERRORLOG="/dev/null"
	log_options="-s -a"
}
if [[ -n $LOG ]]  && [[ $LOG = 'yes' ]] ; then
	log_to_file_on
else
	log_to_file_off
fi

if [[ -n $DEBUG ]]  && [[ $DEBUG = 'yes' ]] ; then
	log_to_file_on
	debug_options="-v"
	log_to_file_on
else
	debug_options=""
fi

# echo $LOGFILE
# echo $ERRORLOG

TMPDIR=$SOURCE_DIR/tmp
NPM_MODULES=$SOURCE_DIR/node_modules
PIDFILE=$TMPDIR/$NAME.pid


[ -d $TMPDIR ] || mkdir $TMPDIR
[ -d $NPM_MODULES ] || npm install

# echo $SOURCE_DIR
# echo $ABSOLUTE_PATH
# echo $LOGDIR
# echo $TMPDIR

##########################################################################################
# Initializing variables
##########################################################################################

# Read pid from pidfile
if [ -f $PIDFILE ]; then
	pid=`cat $PIDFILE`
else
	pid=""
fi

# get forever application ID
if [ "$pid" != "" ]; then
  foreverid=`$forever list | $sed -n /$pid/p | sed 's/\[//g;s/\]//g' | awk ' {print $2} '`
else
  foreverid=""
fi

# echo "pidfile   : ${PIDFILE}"
# echo "pid       : ${pid}"
# echo "foreverid : ${foreverid}"
# echo $SOURCE_DIR/$SOURCE_FILE

##########################################################################################
# functions
##########################################################################################
start(){
  echo "Starting $NAME node instance: "

  if [ "$foreverid" == "" ]; then
		# echo "log_options   : ${log_options}"
		# echo "debug_options : ${debug_optios}"
    $forever start $debug_option $log_options \
			--pidFile $PIDFILE \
      --minUptime 1000ms \
      --spinSleepTime 1000ms \
			-l $LOGFILE \
			-o $LOGFILE \
			-e $ERRORLOG \
			$SOURCE_DIR/$SOURCE_FILE
    RETVAL=$?
  else
    echo "Instance already running"
    RETVAL=0
  fi
}
stop(){
	echo -n "Shutting down $NAME node instance : "
	if [ "$foreverid" != "" ]; then
		$forever stop $foreverid
	else
		echo "Instance is not running";
	fi
	RETVAL=$?
}

##########################################################################################
RETVAL=0

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status -p ${pidfile}
		;;
	restart)
	  stop
	  foreverid=""
	  start
	  ;;
	*)
		echo "Usage:  {start|stop|restart}"
		exit 1
		;;
esac

exit $RETVAL

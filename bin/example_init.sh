#!/bin/bash
#
# EXAMPLE INIT SCRIPT FOR DANCER APP
#
# chkconfig: - 80 30
# description: Perl Dancer web app
#
# Perl Dancer web app
#


PERL="/home/libremailer/perl5/perlbrew/perls/perl-5.18.2_WITH_THREADS/bin/perl -X"
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
APP_HOME="/home/libremailer/app"
DAEMON="$APP_HOME/bin/app.pl"
PLACKUP="/usr/bin/plackup"
NAME="libremailer"
SOCK="/var/tmp/._dancer_$NAME.sock"
DESC="$NAME web app"
USER="www-data"
WORKERS="2"
OPTS="$PERL $PLACKUP -E production -s Starman --user=$USER --workers=$WORKERS -l $SOCK -a $DAEMON"

# Start the service
start() {
        echo -n "Starting $DESC: "
        cd $APP_HOME
        $OPTS &> /dev/null &
        echo -n "done."
        echo
}

# Restart the service
stop() {
        echo -n "Stopping $DESC: "
        /sbin/fuser -k $SOCK > /dev/null 2>&1
        rm -f $SOCK > /dev/null 2>&1
        echo -n "done."
        echo
}

### main logic ###
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        /sbin/fuser -v -u $SOCK
        ;;
  restart|reload|condrestart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|reload|status}"
        exit 1
esac

exit 0

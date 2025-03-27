#!/bin/sh

USAGE="<GIT REPO NAME> {start|stop} <PORT> [<JAVA OPTS>]"

if [ $# -lt 3 ]; then
        echo "$USAGE
                                THIS SCRIPT SHOULD ONLY BE USED BY -MONIT-!

                                If you want to restart an instance, use ./restart.sh

                                First 3 parameters are mandatory.
                                Don't forget that the process is monitored by 'monit'.
                                It will restart automatically if you stop the API.
                                If you want to stop it permanently, do 'sudo /etc/ini.d/monit stop' first.
                                "
        exit 65
fi

REPO=$1
ACTION=$2
PORT=$3
JAVA_OPTS="$4"

HOME="/home/sol"

# it is important to set the proper locale
. $HOME/.locale
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
JAVA_OPTS=$(echo "$JAVA_OPTS" |sed 's#,#\ #g')

cd $HOME/git/$REPO
case $ACTION in
        start)
                if [ -f target/universal/stage/RUNNING_PID ]; then
                        kill $(cat target/universal/stage/RUNNING_PID)
			rm target/universal/stage/RUNNING_PID
                fi
                export JAVA_OPTS="$JAVA_OPTS -XX:+ExitOnOutOfMemoryError -DpreferIPv4Stack"
                sbt --java-home $JAVA_HOME stage >> ./target/universal/stage/logs/application.log 2>&1
                ./target/universal/stage/bin/rpb -Dhttp.port=$PORT -no-version-check >> ./target/universal/stage/logs/application.log 2>&1
                ;;
        stop)
                kill $(cat target/universal/stage/RUNNING_PID)
                sleep 14
                kill -9 $(cat target/universal/stage/RUNNING_PID)
                rm target/universal/stage/RUNNING_PID
                ;;
        *)
                echo "usage: $USAGE"
                ;;
esac
exit 0

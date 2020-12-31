#!/bin/bash

cd `dirname $0`

ROOT_PATH=$(cd `dirname $0`;pwd)
MAIN_JAR="${ROOT_PATH}/web-test.war"
CONSOLE_LOG_PATH="/dev/null"
#CONSOLE_LOG_PATH="${ROOT_PATH}/logs/console.log"

JAVA_OPTS=" -Xms2g -Xmx2g -Xmn1g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 "

#SHUTDOWN_SIGNAL_12_WAIT is wait time in seconds for java process signal 12. -1 represents NOT sending signal 12.
SHUTDOWN_SIGNAL_12_WAIT=10

#SHUTDOWN_SIGNAL_15_WAIT is wait time in seconds for java process signal 15.
SHUTDOWN_SIGNAL_15_WAIT=10

# define color
RED="\033[00;31m"
GREEN="\033[00;32m"
YELLOW="\033[00;33m"
REG="\033[0m"

echoColor() {
  color=$1
  echo -e "${color}[`date '+%Y-%m-%d %H:%M:%S'`]$2${REG}"
}

echoRed() {
  echoColor ${RED} "$1"
}

echoGreen() {
  echoColor ${GREEN} "$1"
}

echoYellow() {
  echoColor ${YELLOW} "$1"
}

jvm_pid() {
  echo `ps -fe | grep ${MAIN_JAR} | grep -v grep | tr -s " "|cut -d" " -f2`
}

start() {
  pid=$(jvm_pid)

  #judge process is running.
  if [ -n "$pid" ]; then
    echoRed "${MAIN_JAR} is already running (pid: $pid)"
    return 1;
  fi

  # Start jvm
  echoGreen "Starting ${MAIN_JAR}"
  echoGreen "JAVA_OPTS:${JAVA_OPTS}"
  nohup java -jar ${JAVA_OPTS} ${MAIN_JAR} > ${CONSOLE_LOG_PATH} 2>&1 &
  status

  return 0
}

status(){
  pid=$(jvm_pid)
  if [ -n "$pid" ]; then
    echoGreen "${MAIN_JAR} is running with pid: $pid"
  else
    echoRed "${MAIN_JAR} is not running"
  fi
}

terminate() {
  echoRed "Terminating ${MAIN_JAR}"
  kill -9 $(jvm_pid)
}

stop() {
  pid=$(jvm_pid)
  if [ -n "$pid" ]; then
    echoRed "Stoping ${MAIN_JAR},pid=${pid}"

    if [ ${SHUTDOWN_SIGNAL_12_WAIT} -ge 0 ]; then
      echoRed "Send sigal 12 ..."
      kill -12 $pid

      signal12Count=0;
      until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $signal12Count -gt ${SHUTDOWN_SIGNAL_12_WAIT} ]
      do
        echoRed "Waiting for signal 12 process(${signal12Count})";
        sleep 1
        let signal12Count=$signal12Count+1;
      done
    fi

    echoRed "Send sigal 15 ..."
    kill -15 $pid

    signal15Count=0;
    until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $signal15Count -gt ${SHUTDOWN_SIGNAL_15_WAIT} ]
    do
      echoRed "Waiting for signal 15 process(${signal15Count})";
      sleep 1
      let signal15Count=$signal15Count+1;
    done


    if [ $signal15Count -gt ${SHUTDOWN_SIGNAL_15_WAIT} ]; then
      echoRed "Killing processes didn't stop after ${SHUTDOWN_SIGNAL_15_WAIT} seconds"
      terminate
    fi
  else
    echoRed "${MAIN_JAR} is not running"
  fi

  return 0
}

case $1 in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    stop
    start
  ;;
  status)
    status
  ;;
  kill)
    terminate
  ;;
  *)
    echoRed "Usage: $0 start|stop|restart|kill|status"
  ;;
esac

exit 0
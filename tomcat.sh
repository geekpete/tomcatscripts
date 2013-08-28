#!/bin/bash
#
# Tomcat 7 start/stop/status script
# Forked from: https://gist.github.com/valotas/1000094
# @author: Miglen Evlogiev <bash@miglen.com>
#
# Release updates:
# Updated method for gathering pid of the current proccess
# Added usage of CATALINA_BASE
# Added coloring and additional status
# Added check for existence of the tomcat user
#
 
# 
# -Location of JAVA_HOME (bin files) 
# either use default java - resolution is done dynamically
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:jre/bin/java::")

# or set manually for a custom java version/location
# Location of JAVA_HOME (bin files)
#export JAVA_HOME=/usr/java/jdk1.7.0_21
 
#Add Java binary files to PATH
export PATH=$JAVA_HOME/bin:$PATH
 
#CATALINA_HOME is the location of the bin files of Tomcat  
export CATALINA_HOME=/opt/apache-tomcat-7.0.42
 
#CATALINA_BASE is the location of the configuration files of this instance of Tomcat
# to create a new app config dir, copy your CATALINA_HOME to a new dir, eg. myapp1
export CATALINA_BASE=/usr/share/myapp1
 
#TOMCAT_USER is the default user of tomcat
# if TOMCAT_USER is not present, falls back to running as root.
# TODO: make tomcat fail if the required user is not available
export TOMCAT_USER=peter
 
#TOMCAT_USAGE is the message if this script is called without any options
TOMCAT_USAGE="Usage: $0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m}"
 
#SHUTDOWN_WAIT is wait time in seconds for java proccess to stop
SHUTDOWN_WAIT=20
 
# Configure tomcat ports using a prefix
PORT_PREFIX=80
# Or use a custom port prefix:
#PORT_PREFIX=100

# automatically set the jvm route as the short host name, needs to be configured the same way on the front reverse proxy.
JVM_ROUTE="`hostname -s`"

# Force redeploy on startup - not yet implemented
# Ensures the exploded war dirs in webapps are always wiped on startup, not an issue if using tomcat manager to deploy
#FORCE_REDEPLOY=true

# JAVA debug options (Java Platform Debug Architecture) used by Tomcat
JPDA_TRANSPORT=
JPDA_ADDRESS=${PORT_PREFIX}91
JPDA_SUSPEND=
JPDA_OPTS=
export JPDA_TRANSPORT JPDA_ADDRESS JPDA_SUSPEND JPDA_OPTS

# configure max threads for the container
MAX_THREADS="200"

# Configure ports using the port prefix specified above:
SNMP_PORT=${PORT_PREFIX}16
JMX_PORT=${PORT_PREFIX}45
JMXRMI_PORT=${PORT_PREFIX}46
HTTP_PORT=${PORT_PREFIX}80
HTTPS_PORT=${PORT_PREFIX}43
AJP_PORT=${PORT_PREFIX}09
SHUTDOWN_PORT=${PORT_PREFIX}05

LOGS_DIR="${CATALINA_BASE}/logs"

# Set runtime parameters for custom ports, logs dir, catalina_base, max_threads.
CUSTOM_PARAMETERS="-Dcustom.jvm.route=${JVM_ROUTE} -Dcustom.http.port=${HTTP_PORT} -Dcustom.https.port=${HTTPS_PORT} -Dcustom.ajp.port=${AJP_PORT} -Dcustom.shutdown.port=${SHUTDOWN_PORT} -Dcustom.logs.dir=${LOGS_DIR} -Dcustom.catalina.base=${CATALINA_BASE} -Dcustom.max.threads=${MAX_THREADS}"

# Other options you can enable/configure here:
#GC_LOG_OPTS="-XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -Xloggc:${LOGS_DIR}/gc.log"
#GC_OPTS="-XX:PermSize=64m -XX:MaxPermSize=256m -XX:+UseParallelGC -XX:-UseGCOverheadLimit"
#MEM_OPTS="-Xms256m -Xmx2500m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$CUSTOM_LOGS_DIR"
#JMX_OPTS="-Djmx.rmi.registry.port=${JMXRMI_PORT} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
#OTHER_OPTS="-server -Dfile.encoding=utf8 -XX:+AggressiveOpts"
#SSL_OPTS="-Djavax.net.ssl.trustStore=ssl/mytruststore.jks -Djavax.net.ssl.trustStorePassword=somepassword"
#PROXY_OPTS="-Dhttp.nonProxyHosts=10.0.0.1|localhost -Dhttps.nonProxyHosts=10.0.0.1|whateversite.mydomain -Dhttp.proxyHost=myproxy.mydomain -Dhttp.proxyPort=3128"
#APP_OPTS="-javaagent:$CATALINA_BASE/lib/org.springframework.instrument-3.0.2.RELEASE.jar -Dexternal.config.dir=${CATALINA_BASE}/config"

# Glue together all the options that were set and export them as JAVA_OPTS
export JAVA_OPTS="${CUSTOM_PARAMETERS} ${GC_OPTS} ${GC_LOG_OPTS} ${MEM_OPTS} ${JMX_OPTS} ${SSL_OPTS} ${APP_OPTS} ${PROXY_OPTS} ${OTHER_OPTS} ${SNMP_OPTS} "

### End of configuration section ###

#################################
tomcat_pid() {
        echo `ps -fe | grep $CATALINA_BASE | grep -v grep | tr -s " "|cut -d" " -f2`
}
 
start() {
  pid=$(tomcat_pid)
  if [ -n "$pid" ]
  then
    echo -e "\e[00;31mTomcat is already running (pid: $pid)\e[00m"
  else
    # Start tomcat
    echo -e "\e[00;32mStarting tomcat\e[00m"
    #ulimit -n 100000
    #umask 007
    #/bin/su -p -s /bin/sh tomcat
        if [ `user_exists $TOMCAT_USER` = "1" ]
        then
                su $TOMCAT_USER -c $CATALINA_HOME/bin/startup.sh
        else
                sh $CATALINA_HOME/bin/startup.sh
        fi
        status
  fi
  return 0
}
 
status(){
          pid=$(tomcat_pid)
          if [ -n "$pid" ]; then echo -e "\e[00;32mTomcat is running with pid: $pid\e[00m"
          else echo -e "\e[00;31mTomcat is not running\e[00m"
          fi
}
 
stop() {
  pid=$(tomcat_pid)
  if [ -n "$pid" ]
  then
    echo -e "\e[00;31mStoping Tomcat\e[00m"
    #/bin/su -p -s /bin/sh tomcat
        sh $CATALINA_HOME/bin/shutdown.sh
 
    let kwait=$SHUTDOWN_WAIT
    count=0;
    until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
    do
      echo -n -e "\n\e[00;31mwaiting for processes to exit\e[00m\n";
      sleep 1
      let count=$count+1;
    done
 
    if [ $count -gt $kwait ]; then
      echo -n -e "\n\e[00;31mkilling processes which didn't stop after $SHUTDOWN_WAIT seconds\e[00m\n"
      kill -9 $pid
    fi
  else
    echo -e "\e[00;31mTomcat is not running\e[00m"
  fi
 
  return 0
}
 
user_exists(){
        if id -u $1 >/dev/null 2>&1; then
        echo "1"
        else
                echo "0"
        fi
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
        *)
			echo -e $TOMCAT_USAGE
        ;;
esac    
exit 0

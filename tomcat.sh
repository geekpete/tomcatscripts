#!/bin/bash
#
# chkconfig: - 85 15
# description: tomcat service
#
# Tomcat start/stop/status script
# https://github.com/geekpete/tomcatscripts
#
# Forked from: https://gist.github.com/valotas/1000094
# @author: Miglen Evlogiev <bash@miglen.com>
# Release updates:
# - Updated method for gathering pid of the current proccess
# - Added usage of CATALINA_BASE
# - Added coloring and additional status
# - Added check for existence of the tomcat user
# Updates by Peter Dyson <pete@geekpete.com>
# - Added custom port prefix to configure multiple tomcat containers in a single host (if server.xml is configured/templated correctly)
# - Added RHEL chkconfig init compatibility
# - Added optional email notification functionality
# - Minor fixes to make shutdown look prettier
#
# Location of JAVA_HOME (bin files) 
# either use default java - resolution is done dynamically
#export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:jre/bin/java::")

# or set manually for a custom java version/location
# Location of JAVA_HOME (bin files)
#export JAVA_HOME=/usr/java/jdk1.7.0_21
export JAVA_HOME=/opt/jre1.7.0_25

#Add Java binary files to PATH
export PATH=$JAVA_HOME/bin:$PATH
 
#CATALINA_HOME is the location of the bin files of Tomcat  
export CATALINA_HOME=/opt/apache-tomcat-7.0.41
 
#CATALINA_BASE is the location of the configuration files of this instance of Tomcat
# to create a new app config dir, copy your CATALINA_HOME to a new dir, eg. myapp1
export CATALINA_BASE=/data/tomcat/myapp1
 
#TOMCAT_USER is the default user of tomcat
# if TOMCAT_USER is not present, falls back to running as root.
# TODO: make tomcat fail if the required user is not available, dropping back to root user is probably a bad idea.
TOMCAT_USER=tomcat

# Who to email whenenver the app starts or restarts.
# Adjust and uncomment this line to enable email notification.
#EMAIL_RECIPIENTS="email1@wherever, email2@wherever"

#TOMCAT_USAGE is the message if this script is called without any options
TOMCAT_USAGE="Usage: $0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m}"
 
#SHUTDOWN_WAIT is wait time in seconds for java proccess to stop
SHUTDOWN_WAIT=20
 
#### Configure tomcat ports using a prefix
PORT_PREFIX=80
# Or use a custom port prefix:
#PORT_PREFIX=123


# Force redeploy on startup - not yet implemented
# Ensures the exploded war dirs in webapps are always wiped on startup, not an issue if using tomcat manager to deploy
#FORCE_REDEPLOY=true

# JAVA debug options (Java Platform Debug Architecture) used by Tomcat
JPDA_TRANSPORT=
JPDA_ADDRESS=${PORT_PREFIX}91
JPDA_SUSPEND=
JPDA_OPTS=
export JPDA_TRANSPORT JPDA_ADDRESS JPDA_SUSPEND JPDA_OPTS

# configure max threads for the container, 200 is the tomcat default.
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


# automatically set the jvm route as the short host name, needs to be configured the same way on the front reverse proxy.
JVM_ROUTE="`hostname -s`"
#JVM_ROUTE="appserver1"


# Set runtime parameters for custom ports, logs dir, catalina_base, max_threads.
CUSTOM_PARAMETERS="-Dcustom.jvm.route=${JVM_ROUTE} -Dcustom.http.port=${HTTP_PORT} -Dcustom.https.port=${HTTPS_PORT} -Dcustom.ajp.port=${AJP_PORT} -Dcustom.shutdown.port=${SHUTDOWN_PORT} -Dcustom.logs.dir=${LOGS_DIR} -Dcustom.catalina.base=${CATALINA_BASE} -Dcustom.max.threads=${MAX_THREADS}"

# Other options you can enable/configure here:
GC_LOG_OPTS="-XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -Xloggc:${LOGS_DIR}/gc.log"
GC_OPTS="-XX:PermSize=<%= @java_permsize %> -XX:MaxPermSize=<%= @java_maxpermsize %> -XX:+UseParallelGC -XX:-UseGCOverheadLimit"
MEM_OPTS="-Xms<%= @java_min_heap %> -Xmx<%= @java_max_heap %> -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$LOGS_DIR"
#SNMP_OPTS="-Dcom.sun.management.snmp.port=${SNMP_PORT} -Dcom.sun.management.snmp.interface=0.0.0.0 -Dcom.sun.management.snmp.acl.file=whateversnmp.acl"
#JMX_OPTS should be reviewed for security requirements - ssl/authentication.
#JMX_OPTS="-Djmx.rmi.registry.port=${JMXRMI_PORT} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
OTHER_OPTS="-server -Dfile.encoding=utf8 -XX:+AggressiveOpts"
#SSL_OPTS="-Djavax.net.ssl.trustStore=ssl/mytruststore.jks -Djavax.net.ssl.trustStorePassword=somepassword"
#PROXY_OPTS="-Dhttp.nonProxyHosts=10.0.0.1|localhost -Dhttps.nonProxyHosts=10.0.0.1|whateversite.mydomain -Dhttp.proxyHost=myproxy.mydomain -Dhttp.proxyPort=3128"
#APP_OPTS="-javaagent:$CATALINA_BASE/lib/org.springframework.instrument-3.0.2.RELEASE.jar -Dexternal.config.dir=${CATALINA_BASE}/config"

# Glue together all the options that were set and export them as JAVA_OPTS
export JAVA_OPTS="${CUSTOM_PARAMETERS} ${GC_OPTS} ${GC_LOG_OPTS} ${MEM_OPTS} ${JMX_OPTS} ${SSL_OPTS} ${APP_OPTS} ${PROXY_OPTS} ${OTHER_OPTS} ${SNMP_OPTS} "

SCRIPTNAME=`basename $0`


### End of configuration section ###

#################################
tomcat_pid() {
	# find processes with $CATALINA_BASE in the command line as this is a unique identifier for this tomcat instance, corresponding to the config dir of the app.
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
		if [ `user_exists $TOMCAT_USER` = "1" ]
		then
			su $TOMCAT_USER -c $CATALINA_HOME/bin/startup.sh
		else
			sh $CATALINA_HOME/bin/startup.sh
		fi
		status
		emailnotify
	fi
	return 0
}
 
status(){
	pid=$(tomcat_pid)
	if [ -n "$pid" ];
	then 
		echo -e "\e[00;32mTomcat is running with pid: $pid\e[00m"
	else 
		echo -e "\e[00;31mTomcat is not running\e[00m"
	fi
}
 
stop() {
	pid=$(tomcat_pid)
	if [ -n "$pid" ]
	then
		echo -e "\e[00;31mStopping Tomcat\e[00m"
		# re-export the JAVA_OPTS variable without the ${SNMP_OPTS} and ${JMX_OPTS} environment variables to avoid "port already in use" error that prevents clean shutdown.
		export JAVA_OPTS="${CUSTOM_PARAMETERS} ${GC_OPTS} ${GC_LOG_OPTS} ${MEM_OPTS} ${SSL_OPTS} ${APP_OPTS} ${PROXY_OPTS} ${OTHER_OPTS}"
       	sh $CATALINA_HOME/bin/shutdown.sh
		let kwait=$SHUTDOWN_WAIT
		count=0;
                echo -n -e "\n\e[00;31mwaiting for processes to exit..\e[00m";
		until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
		do
			echo -n -e "\e[00;31m.\e[00m";
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
	echo "" 
	return 0
}
 
user_exists(){
	if id -u $1 >/dev/null 2>&1; then
		echo "1"
	else
		echo "0"
	fi
}

function emailnotify() {
    # First see if the email recipients list is empty.
    # Don't try to send email if there are no recipients specified.
    
    # If the variable set to a non-empty string, send an email notify.
    if [ -n "${EMAIL_RECIPIENTS}" ]; then
		# create a temp file to store the message body
		EMAIL_MESSAGE=`mktemp`

		# create the subject and message body, record who is logged in at the time of the restart and from where
		EMAIL_SUBJECT="${SCRIPTNAME} tomcat initiated on `hostname` at: `date +%Y-%m-%d.%H%M`"
		echo "${APP} ${SCRIPTNAME} tomcat initiated on `hostname` at: `date +%Y-%m-%d.%H%M`" > $EMAIL_MESSAGE
		echo "" >> $EMAIL_MESSAGE
		echo "Current logins:" >> $EMAIL_MESSAGE
		echo "`who -u -H`" >> $EMAIL_MESSAGE

		# Email the recipients
		cat $EMAIL_MESSAGE | /bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}"

		# remote the temp file after the email is sent
		rm $EMAIL_MESSAGE
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

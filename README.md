tomcatscripts
=============

Tomcat Scripts

Various scripts for Tomcat.

pete@geekpete.com

Notes on tomcat init script - tomcat.sh:

Custom port prefix to allow multi tennancy of tomcat containers

Debug_start for troubleshooting - enable jpda options

All config in one script at the top

Lots of other example configs

Optional email alert, not included, provided as separate snippet. Could be called on startup to alert of restart.

Needs to set ulimit as correct user

Still need to write force redeploy option, ensure exploded war dirs are wiped on restart, not an issue with deployer/manager.


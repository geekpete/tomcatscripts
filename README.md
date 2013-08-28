tomcatscripts
=============

Tomcat Scripts

Various scripts for Tomcat.

pete@geekpete.com

Notes on tomcat init script - tomcat.sh:
-custom port prefix to allow multi tennancy of tomcat containers
-debug_start for troubleshooting - enable jpda options
-all config in one script at the top
-lots of other example configs
-optional email alert, not included, provided as separate snippet. Could be called on startup to alert of restart.
-needs to set ulimit as correct user
-still need to write force redeploy option, ensure exploded war dirs are wiped on restart, not an issue with deployer/manager.
-

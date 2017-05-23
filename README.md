# Note: This project is no Longer Maintained

tomcatscripts
=============

Tomcat Scripts

Various scripts for Tomcat.

pete@geekpete.com

Notes on tomcat init script - tomcat.sh:

*   Custom port prefix to allow multi tennancy of tomcat containers
*   Debug_start for troubleshooting - enable jpda options
*   All config in one script at the top
*   Lots of other example configs
*   Optional email alert, not included, provided as separate snippet. Could be called on startup to alert of restart.
*   Does not needs to set ulimit as correct user - set this at host level instead, avoid giving a user rights to change limits, keep it simple.
*   Still need to write force redeploy option, ensure exploded war dirs are wiped on restart, not an issue with deployer/manager.
*   Better ways to solve this might be not exploding the war at all (setting in server.xml) or using a better deployment tool like Jenkins or others that ensure clean deploys.)
*   The last thing it does after starting is open the shutdown port, running a stop to quickly after startup will result in a connection refused then the pid will be killed rather than shutdown cleanly.
*   Need to find a way to ensure the instance stops even if the shutdown port is not available, wait the 20 second delay then kill.


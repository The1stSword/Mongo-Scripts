#!/bin/bash

# Title: enable-mongoAuthentication
# Enabling mongo authentication via salt in less than 5 mintues.
# Author: Kelly Collard


# Notes:  To enable mongo authentication.
#         This script assumes that all mongo conf files are in place and are in the new yaml format for 3.0+
#         and that the security & auth section is commented out of each mongo conf file.
#
#


# Need to give an environment argument for the script to work, load, beta, se, sw
EXPECTED_ARGS=1
E_BADARGS=65

if [ $# -ne $EXPECTED_ARGS ]; then
{
    echo "Usage: enable-mongoAuthentication [environment]"
    echo "example: enable-mongoAuthentication staging"
    exit $E_BADARGS
}
fi

ENV=$1




echo "*****************************************************************************************************************"
echo " WARNING!  WARNING!"
echo ""
read -r -p "Do you wish to proceed with enabling authentication for real?  This will bring down the platform!  [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then

export PS4='+(${BASH_SOURCE}:${LINENO}): '


##################################################################################################
#
#  Stop All Mongo Processes
#
#   This section will stop all mongos,mongodc,and mongod processes.
#   To make sure they are stopped it also issues a 'kill -9' to make sure.
#
#################################################################################################

	echo " "
	echo " "
	echo "Stopping All Mongo Processes "
	echo " "

        set -x
        salt -v -C  "tp-load-mongo[1-5]* or ( tp-load-*app* ) or ( tp-load-listener* ) or ( tp-load-*sso* ) " cmd.run '/etc/init.d/mongos stop'

        salt -v -C  "tp-load-mongo[1-5]*" cmd.run '/etc/init.d/mongod stop'

        salt -v -C  "tp-load-mongocfg*" cmd.run '/etc/init.d/mongodc stop'

        salt -v -C  "G@CONFIG_PROFILE:${ENV} and ( G@roles:app or G@roles:webapp or G@roles:sso or G@roles:mongodb-listener or G@roles:standalone or G@roles:mongodb or G@roles:mongodb-config-server )" cmd.run 'pgrep -u mongod | xargs kill -9'

        set +x

	echo " "
	echo " "
	echo " "
############################################################################################################################
#
#  Enable Mongo Authentication
#
#  All authentication is commented out of the mongod.conf files. Using sed to uncomment and enable auth.
#  After modifying the conf files then start mongo
#
#  Example of /etc/mongod.conf:
#
#
#
#        processManagement:
#            fork: true
#            pidFilePath: /var/run/mongodb/mongod.pid
#
#        storage:
#            dbPath: "/var/lib/mongo/data"
#            engine: mmapv1
#
#        systemLog:
#            destination: file
#            path: "/var/log/mongo/mongod.log"
#            logAppend: true
#            verbosity: 0
#            logRotate: rename
#
#        net:
#            port: 10010
#
#        #security:
#            #authorization: enabled
#            #clusterAuthMode: keyFile
#            #keyFile: /var/lib/mongo/mongodb-keyfile
#
#        replication:
#            replSetName: rs0
#
#
#
#
##########################################################################################################################

	echo " "
	echo " "
	echo "Enabling Mongo Authentication"
	echo " "

        set -x
        salt -v -C  "G@CONFIG_PROFILE:${ENV} and ( G@roles:app or G@roles:webapp or G@roles:sso or G@roles:mongodb-listener or G@roles:standalone or G@roles:mongodb )" cmd.run 'cp /etc/mongos.conf /etc/mongos.conf.OLD && sed -i -e 's/#//g' /etc/mongos.conf'

        salt -v -C  "tp-load-mongo[1-5]*" cmd.run 'cp /etc/mongod.conf /etc/mongod.conf.OLD && sed -i -e 's/#//g' /etc/mongod.conf'

        salt -v -C  "tp-load-mongocfg*" cmd.run 'cp /etc/mongodc.conf /etc/mongodc.conf.OLD && sed -i -e 's/#//g' /etc/mongodc.conf'

        salt -v -C  "tp-load-mongo[1-5]*" cmd.run '/etc/init.d/mongod start' && sleep 5

        salt -v -C  "tp-load-mongocfg*" cmd.run '/etc/init.d/mongodc start' && sleep 5

        salt -v -C  "G@CONFIG_PROFILE:${ENV} and ( G@roles:app or G@roles:webapp or G@roles:sso or G@roles:mongodb-listener or G@roles:standalone or G@roles:mongodb )" cmd.run '/etc/init.d/mongos start'

        set +x

	echo " "
	echo " "
	echo " "

fi
exit

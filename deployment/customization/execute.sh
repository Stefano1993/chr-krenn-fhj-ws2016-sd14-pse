#!/bin/bash
# Based on https://github.com/arun-gupta/docker-images/blob/master/wildfly-mysql-javaee7/customization/execute.sh
# Usage: execute.sh [WildFly mode] [configuration file]
#
# The default mode is 'standalone' and default configuration is based on the
# mode. It can be 'standalone.xml' or 'domain.xml'.

JBOSS_HOME=/opt/jboss/wildfly
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE=${1:-"standalone"}
JBOSS_CONFIG=${2:-"$JBOSS_MODE.xml"}

function wait_for_server() {
  until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do
    sleep 1
  done
}

echo "=> Starting WildFly server"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -c $JBOSS_CONFIG &

echo "=> Waiting for the server to boot"
wait_for_server

echo "=> Executing the commands"
echo "=> MYSQL_URI (docker with networking): " $MYSQL_URI
echo "=> MYSQL_DATABASE: " $MYSQL_DATABASE
echo "=> MYSQL_USER: " $MYSQL_USER
echo "=> MYSQL_PASSWORD: " $MYSQL_PASSWORD
echo "=> MYSQL_DRIVER_VERSION: " $MYSQL_DRIVER_VERSION
CONNECTION_URL=jdbc:mysql://$MYSQL_URI/$MYSQL_DATABASE
echo "=> Connection URL: " $CONNECTION_URL

$JBOSS_CLI -c << EOF
batch

# Add MySQL module
module add --name=com.mysql --resources=/opt/jboss/wildfly/customization/mysql-connector-java-$MYSQL_DRIVER_VERSION-bin.jar --dependencies=javax.api,javax.transaction.api

# Add MySQL driver
/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-xa-datasource-class-name=com.mysql.jdbc.jdbc2.optional.MysqlXADataSource)

# Add the datasource
data-source add --name=$MYSQL_DATABASE --driver-name=mysql --jndi-name=java:jboss/datasources/$MYSQL_DATABASE --connection-url=$CONNECTION_URL?useUnicode=true&characterEncoding=UTF-8&useSSL=false --user-name=$MYSQL_USER --password=$MYSQL_PASSWORD --use-ccm=false --max-pool-size=25 --blocking-timeout-wait-millis=5000 --enabled=true

# Add the security policy
/subsystem=security/security-domain=sep-policy:add(cache-type=default)
/subsystem=security/security-domain=sep-policy/authentication=classic:add()
/subsystem=security/security-domain=sep-policy/authentication=classic/login-module=Database:add(code=Database, flag=required, module-options={"dsJndiName"=>"java:jboss/datasources/SEP","principalsQuery"=>"SELECT Password FROM User WHERE Username=?","rolesQuery"=>"select Role, RoleGroup from User_Roles where Username=?","hashAlgorithm"=>"SHA-256","hashEncoding"=>"base64","unauthenticatedIdentity"=>"guest"})

# Execute the batch
run-batch
EOF

echo "=> Shutting down WildFly"
if [ "$JBOSS_MODE" = "standalone" ]; then
  $JBOSS_CLI -c ":shutdown"
else
  $JBOSS_CLI -c "/host=*:shutdown"
fi

echo "=> Moving application artifacts to wildfly autodeploy"
mv /opt/jboss/wildfly/customization/deployments/*.ear $JBOSS_HOME/$JBOSS_MODE/deployments/

echo "=> Restarting WildFly"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -b 0.0.0.0 -bmanagement 0.0.0.0 -c $JBOSS_CONFIG
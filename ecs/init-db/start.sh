#!/usr/bin/env bash

######################## .ssh/config ################################
# Host rls-db-proxy                                                 #
#  HostName ec2-54-255-234-240.ap-southeast-1.compute.amazonaws.com #
#  IdentityFile ~/.ssh/rls-bastion-kp.pem                           #
#  User ec2-user                                                    #
#  ControlPath ~/.ssh/rls-db-tunnel.ctl                             #
#####################################################################
HOST="$DATABASE_HOST"
if [[ "$USE_PROXY_TUNNEL" = true ]]; then
    echo "Using proxy tunnel..."
    ssh -f -N -T -M -L 3307:"$DATABASE_HOST":"$DATABASE_PORT" rls-db-proxy
    HOST=127.0.0.1
fi
mysql -h "$HOST" -P "$DATABASE_PORT" -u"$DATABASE_ROOT" -p"$DATABASE_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DATABASE_IDS_DB_NAME;
CREATE USER IF NOT EXISTS '$DATABASE_IDS_DB_USER'@'%' IDENTIFIED BY '$DATABASE_IDS_DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DATABASE_IDS_DB_USER'@'localhost' IDENTIFIED BY '$DATABASE_IDS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DATABASE_IDS_DB_NAME.* TO '$DATABASE_IDS_DB_USER'@'%';
GRANT ALL PRIVILEGES ON $DATABASE_IDS_DB_NAME.* TO '$DATABASE_IDS_DB_USER'@'localhost';

CREATE DATABASE IF NOT EXISTS $DATABASE_MDS_DB_NAME;
CREATE USER IF NOT EXISTS '$DATABASE_MDS_DB_USER'@'%' IDENTIFIED BY '$DATABASE_MDS_DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DATABASE_MDS_DB_USER'@'localhost' IDENTIFIED BY '$DATABASE_MDS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DATABASE_MDS_DB_NAME.* TO '$DATABASE_MDS_DB_USER'@'%';
GRANT ALL PRIVILEGES ON $DATABASE_MDS_DB_NAME.* TO '$DATABASE_MDS_DB_USER'@'localhost';

CREATE DATABASE IF NOT EXISTS $DATABASE_HDS_DB_NAME;
CREATE USER IF NOT EXISTS '$DATABASE_HDS_DB_USER'@'%' IDENTIFIED BY '$DATABASE_HDS_DB_PASSWORD';
CREATE USER IF NOT EXISTS '$DATABASE_HDS_DB_USER'@'localhost' IDENTIFIED BY '$DATABASE_HDS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DATABASE_HDS_DB_NAME.* TO '$DATABASE_HDS_DB_USER'@'%';
GRANT ALL PRIVILEGES ON $DATABASE_HDS_DB_NAME.* TO '$DATABASE_HDS_DB_USER'@'localhost';
GRANT SELECT, REFERENCES ON $DATABASE_IDS_DB_NAME.* TO '$DATABASE_HDS_DB_USER'@'%';
GRANT SELECT, REFERENCES ON $DATABASE_IDS_DB_NAME.* TO '$DATABASE_HDS_DB_USER'@'localhost';
MYSQL_SCRIPT

if [[ "$USE_PROXY_TUNNEL" = true ]]; then
    echo "Closing proxy tunnel..."
    ssh -T -O "exit" rls-db-proxy
fi


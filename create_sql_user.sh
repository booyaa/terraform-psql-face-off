#!/bin/bash

set -euo pipefail

dbhost="${SETUP_DBHOST:-}"
if [[ -z "${dbhost}" ]]; then
    read -rp "Enter postgresql host: " dbhost
fi

dbname="${SETUP_DBNAME:-}"
if [[ -z "${dbname}" ]]; then
    read -rp "Enter postgresql db name: " dbname
fi

dbadmin="${SETUP_DBADMIN:-}"
if [[ -z "${dbadmin}" ]]; then
    read -rp "Enter postgresql admin username: " dbadmin
fi

dbusername=dbuser

dbuserpass="${SETUP_DBUSERPASS:-}"
if [[ -z "${dbuserpass}" ]]; then
    read -rsp "Enter postgresql user password: " dbuserpass
fi

printf '\n'
echo "############################################################################"
echo "## Warning: when prompted for a password this will be for the admin user. ##"
echo "############################################################################"
psql --host "$dbhost" --user "$dbadmin" --db "$dbname" << EOF
CREATE ROLE $dbusername WITH 
LOGIN
NOSUPERUSER 
INHERIT 
NOCREATEDB 
NOCREATEROLE 
NOREPLICATION 
PASSWORD '$dbuserpass';

GRANT CONNECT 
ON DATABASE $dbname
         TO $dbusername;

\c $dbname

GRANT INSERT,SELECT,UPDATE 
ON ALL TABLES IN SCHEMA public 
    TO $dbusername;

GRANT SELECT,UPDATE 
ON ALL SEQUENCES IN SCHEMA public 
    TO $dbusername;
EOF

echo "Created $dbusername on $dbhost with access to $dbname."
exit 0
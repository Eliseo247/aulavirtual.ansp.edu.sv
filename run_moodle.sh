#!/bin/bash

source ${PHP_CONTAINER_SCRIPTS_PATH}/common.sh

export_vars=$(cgroup-limits); export $export_vars
export DOCUMENTROOT=${DOCUMENTROOT:-/}

# Default php.ini configuration values, all taken
# from php defaults.
export ERROR_REPORTING=${ERROR_REPORTING:-E_ALL & ~E_NOTICE}
export DISPLAY_ERRORS=${DISPLAY_ERRORS:-ON}
export DISPLAY_STARTUP_ERRORS=${DISPLAY_STARTUP_ERRORS:-OFF}
export TRACK_ERRORS=${TRACK_ERRORS:-OFF}
export HTML_ERRORS=${HTML_ERRORS:-ON}
export INCLUDE_PATH=${INCLUDE_PATH:-.:/opt/app-root/src:${PHP_DEFAULT_INCLUDE_PATH}}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-128M}
export SESSION_NAME=${SESSION_NAME:-PHPSESSID}
export SESSION_HANDLER=${SESSION_HANDLER:-files}
export SESSION_PATH=${SESSION_PATH:-/tmp/sessions}
export SESSION_COOKIE_DOMAIN=${SESSION_COOKIE_DOMAIN:-}
export SESSION_COOKIE_HTTPONLY=${SESSION_COOKIE_HTTPONLY:-}
export SESSION_COOKIE_SECURE=${SESSION_COOKIE_SECURE:-0}
export SHORT_OPEN_TAG=${SHORT_OPEN_TAG:-OFF}

# TODO should be dynamically calculated based on container memory limit/16
export OPCACHE_MEMORY_CONSUMPTION=${OPCACHE_MEMORY_CONSUMPTION:-128}

export OPCACHE_REVALIDATE_FREQ=${OPCACHE_REVALIDATE_FREQ:-2}

export PHPRC=${PHPRC:-${PHP_SYSCONF_PATH}/php.ini}
export PHP_INI_SCAN_DIR=${PHP_INI_SCAN_DIR:-${PHP_SYSCONF_PATH}/php.d}

#envsubst <  /opt/app-root/etc/php.ini.template > ${PHP_SYSCONF_PATH}/php.ini
envsubst <  /opt/app-root/etc/php.ini > ${PHP_SYSCONF_PATH}/php.ini
envsubst < /opt/app-root/etc/php.d/10-opcache.ini.template > ${PHP_SYSCONF_PATH}/php.d/10-opcache.ini

export HTTPD_START_SERVERS=${HTTPD_START_SERVERS:-8}
export HTTPD_MAX_SPARE_SERVERS=$((HTTPD_START_SERVERS+10))

if [ -n "${NO_MEMORY_LIMIT:-}" -o -z "${MEMORY_LIMIT_IN_BYTES:-}" ]; then
  #
  export HTTPD_MAX_REQUEST_WORKERS=${HTTPD_MAX_REQUEST_WORKERS:-256}
else
  # A simple calculation for MaxRequestWorkers would be: Total Memory / Size Per Apache process.
  # The total memory is determined from the Cgroups and the average size for the
  # Apache process is estimated to 15MB.
  max_clients_computed=$((MEMORY_LIMIT_IN_BYTES/1024/1024/15))
  # The MaxClients should never be lower than StartServers, which is set to 5.
  # In case the container has memory limit set to <64M we pin the MaxClients to 4.
  [[ $max_clients_computed -le 4 ]] && max_clients_computed=4
  export HTTPD_MAX_REQUEST_WORKERS=${HTTPD_MAX_REQUEST_WORKERS:-$max_clients_computed}
  echo "-> Cgroups memory limit is set, using HTTPD_MAX_REQUEST_WORKERS=${HTTPD_MAX_REQUEST_WORKERS}"
fi

# pre-start files
process_extending_files ${APP_DATA}/php-pre-start/ ${PHP_CONTAINER_SCRIPTS_PATH}/pre-start/


#############################################################################################################
# install wordpress if not in persistentvolume
if [ ! -f /opt/app-root/src/index.php ]; then
  #cp -rf /moodle-latest-38.tgz /opt/app-root/src
  cp /opt/app-root/moodledata/binarios/moodleConfigurado.tar /opt/app-root/src/moodleConfigurado.tar
  tar -xvf /opt/app-root/src/moodleConfigurado.tar
  mv /opt/app-root/src/opt/app-root/src/* /opt/app-root/src/
  fi
echo "openshift-wordpress:x:`id -u`:0:openshift-wordpress:/:/sbin/nologin" >> /etc/passwd
exec httpd -D FOREGROUND
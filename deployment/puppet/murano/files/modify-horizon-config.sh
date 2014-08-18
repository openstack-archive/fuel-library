#!/bin/bash


HORIZON_CONFIG=${HORIZON_CONFIG:-'/usr/share/openstack-dashboard/openstack_dashboard/settings.py'}

MURANO_SSL_ENABLED=${MURANO_SSL_ENABLED:-'False'}

MURANO_API_PROTOCOL=${MURANO_API_PROTOCOL:-'http'}
MURANO_API_HOST=${MURANO_API_HOST:-'localhost'}
MURANO_API_PORT=${MURANO_API_PORT:-'8082'}

USE_KEYSTONE_ENDPOINT=${USE_KEYSTONE_ENDPOINT:-'False'}

MURANO_DASHBOARD_CACHE=${MURANO_DASHBOARD_CACHE:-'/var/cache/muranodashboard-cache'}

USE_SQLITE_BACKEND=${USE_SQLITE_BACKEND:-'True'}
MURANO_DASHBOARD_DB_DIR=${MURANO_DASHBOARD_DB_DIR:-'/var/lib/openstack-dashboard'}

APACHE_USER=${APACHE_USER:-'apache'}
APACHE_GROUP=${APACHE_GROUP:-'apache'}


# /Functions/ ==================================================================

# Normalize config values to True or False
# Accepts as False: 0 no No NO false False FALSE
# Accepts as True: 1 yes Yes YES true True TRUE
# VAR=$(trueorfalse default-value test-value)
function trueorfalse() {
    local default=$1
    local testval=$2

    [[ -z "$testval" ]] && { echo "$default"; return; }
    [[ "0 no No NO false False FALSE" =~ "$testval" ]] && { echo "False"; return; }
    [[ "1 yes Yes YES true True TRUE" =~ "$testval" ]] && { echo "True"; return; }
    echo "$default"
}


# Insert content of one file into another before a string which mathes pattern
function insert_config_section() {
    local pattern="$1"
    local insert_file="$2"
    local target_file="$3"

    sed -ne "/$pattern/r  $insert_file" -e 1x  -e '2,${x;p}' -e '${x;p}' -i $target_file
}


# Remove Murano-related parts of configuration (code between special tags)
function remove_murano_config() {
    local config_file="$1"

    if [[ -f "$config_file" ]]; then
        sed -e '/^#MURANO_CONFIG_SECTION_BEGIN/,/^#MURANO_CONFIG_SECTION_END/ d' -i "$config_file"
    fi
}


# Insert Murano-related configuration into several Horizon config files
function insert_murano_config() {
    local horizon_config_part=$(mktemp)

    # Opening Murano Configuration Section
    cat << EOF >> "$horizon_config_part"

#MURANO_CONFIG_SECTION_BEGIN
#-------------------------------------------------------------------------------
EOF


    if [[ $(trueorfalse False $MURANO_SSL_ENABLED) = 'True' ]]; then
        cat << EOF >> "$horizon_config_part"
MURANO_API_INSECURE = $MURANO_API_INSECURE
EOF
    fi

    if [[ $(trueorfalse False $USE_KEYSTONE_ENDPOINT) = 'False' ]]; then
        cat << EOF >> "$horizon_config_part"
MURANO_API_URL = "$MURANO_API_PROTOCOL://$MURANO_API_HOST:$MURANO_API_PORT"
EOF
    fi

    if [[ $(trueorfalse False $USE_SQLITE_BACKEND) = 'True' ]]; then
        #if [[ ! -d "$MURANO_DASHBOARD_DB_DIR" ]]; then
        #    mkdir -p $MURANO_DASHBOARD_DB_DIR
        #fi
        #chmod -R 755 "$MURANO_DASHBOARD_DB_DIR"
        #chown -R $APACHE_USER:$APACHE_GROUP "$MURANO_DASHBOARD_DB_DIR"

        cat << EOF >> "$horizon_config_part"
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join('$MURANO_DASHBOARD_DB_DIR', 'openstack-dashboard.sqlite')
    }
}
SESSION_ENGINE = 'django.contrib.sessions.backends.db'
EOF
    fi

    cat << EOF >> "$horizon_config_part"
METADATA_CACHE_DIR = '$MURANO_DASHBOARD_CACHE'
HORIZON_CONFIG['dashboards'] += ('murano',)
INSTALLED_APPS += ('muranodashboard','floppyforms',)
MIDDLEWARE_CLASSES += ('muranodashboard.middleware.ExceptionMiddleware',)
EOF

    # Closing Murano Configuration Section
    cat << EOF >> "$horizon_config_part"
#-------------------------------------------------------------------------------
#MURANO_CONFIG_SECTION_END

EOF

    insert_config_section "from openstack_dashboard import policy" "$horizon_config_part" "$HORIZON_CONFIG"
}

# \Functions\ ==================================================================


# Script usage:
#   modify-horizon-config.sh <command>

case "$1" in
    install)
        insert_murano_config
    ;;
    uninstall)
        remove_murano_config "$HORIZON_CONFIG"
    ;;
    *)
        exit 1
    ;;
esac

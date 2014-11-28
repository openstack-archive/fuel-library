#!/usr/bin/env python

import json
import logging
import logging.handlers
import os
import requests
import yaml
import sys

log = logging.getLogger('fuel_notify')
log_handler = logging.handlers.SysLogHandler(address='/dev/log')
log_handler.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(log_handler)
log.setLevel(logging.INFO)

API_CONFIG_FILE = '/etc/fuel/client/config.yaml'
ASTUTE_CONFIG_FILE = '/etc/fuel/astute.yaml'

STATE_FILE_DIR = '/var/run'

ASTUTE_CONFIG = {}
with open(ASTUTE_CONFIG_FILE) as f:
    ASTUTE_CONFIG = yaml.load(f)

API_CONFIG = {}
with open(API_CONFIG_FILE) as f:
    API_CONFIG = yaml.load(f)

SERVER_URL = 'http://{SERVER_ADDRESS}:{SERVER_PORT}'.format(**API_CONFIG)
AUTH_URL = '{0}/keystone/v2.0/tokens/'.format(SERVER_URL)
NOTIFICATIONS_URL = '{0}/api/notifications/'.format(SERVER_URL)


class RequestFailed(Exception):
    pass


def api_notification(topic, message):
    headers = {
        'Content-Type': 'application/json',
    }

    response = requests.post(
        AUTH_URL,
        data=json.dumps({
            'auth': {
                'tenantName': 'services',
                'passwordCredentials': {
                    'username': ASTUTE_CONFIG['monitord']['user'],
                    'password': ASTUTE_CONFIG['monitord']['password'],
                }
            }
        }),
        headers=headers
    )

    if response.status_code != 200:
        log.critical('Could not authenticate with Keystone: %s', response)
        raise RequestFailed()

    headers['X-Auth-Token'] = response.json()['access']['token']['id']

    response = requests.post(
        NOTIFICATIONS_URL,
        data=json.dumps({
            'topic': topic,
            'message': message,
        }),
        headers=headers
    )

    if response.status_code != 201:
        log.critical('Could not create notification: %s', response)
        raise RequestFailed()


def notify(message, topic=None):
    # Only if request successful then write_state.
    # Otherwise report error and try again later.
    try:
        api_notification(topic, message)
    except RequestFailed:
        sys.exit(1)


def get_error(state='SUCCESS', mount_point='/'):
    s = os.statvfs(mount_point)
    # Convert to GB
    free_gb = s.f_bavail * s.f_frsize / (1024.0 ** 3)

    if state == 'ERROR':
        return ('Your disk space on {0} is running low ({1:.2f} GB '
                'currently available).').format(mount_point, free_gb)

    return ('Your free disk space on {0} is back to normal ({1:.2f} GB '
            'currently available).').format(mount_point, free_gb)


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] not in ['ERROR', 'SUCCESS']:
        print 'Syntax: {0} [ERROR|SUCCESS] <mount-point>'.format(sys.argv[0])
        sys.exit(1)

    state = sys.argv[1]
    mount_point = sys.argv[2]
    state_file_name = 'monit-{0}-state'.format(mount_point.replace('/', ''))
    state_file = os.path.join(STATE_FILE_DIR, state_file_name)

    message = get_error(state=state, mount_point=mount_point)

    if state == 'SUCCESS' and os.path.exists(state_file):
        # Notify about disk space back to normal
        notify(message, topic='done')
        # remove state file
        os.remove(state_file)
    if state == 'ERROR' and not os.path.exists(state_file):
        # Notify about disk space error
        notify(message, topic='error')
        # create state file
        open(state_file, 'a').close()


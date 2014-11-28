#!/usr/bin/env python

import logging
import logging.handlers
import os
import yaml
import subprocess
import sys

log = logging.getLogger('fuel_notify')
log_handler = logging.handlers.SysLogHandler(address='/dev/log')
log_handler.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(log_handler)
log.setLevel(logging.INFO)

ASTUTE_CONFIG_FILE = '/etc/fuel/astute.yaml'
ASTUTE_CONFIG = {}
with open(ASTUTE_CONFIG_FILE) as f:
    ASTUTE_CONFIG = yaml.load(f)

# NOTE(pkaminski): 'monitord' user is for sending notifications only
# We cannot use admin -- in case the end user changes admin's password
# we wouldn't be able to send notifications.
USER = ASTUTE_CONFIG['monitord']['user']
PASSWORD = ASTUTE_CONFIG['monitord']['password']

STATE_FILE_DIR = '/var/run'


def notify(message, topic=None):
    # Only if request successful then write_state.
    # Otherwise report error and try again later.
    try:
        command = [
            'fuel', '--user', USER, '--password', PASSWORD,
            'notifiy', '-m', message
        ]
        if topic:
            command.extend(['--topic', topic])
        subprocess.Popen(command)
    except OSError:
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


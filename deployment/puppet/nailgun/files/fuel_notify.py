#!/usr/bin/env python

import logging
import logging.handlers
import os
import subprocess
import sys
import yaml

log = logging.getLogger('fuel_notify')
log_handler = logging.handlers.SysLogHandler(address='/dev/log')
log_handler.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(log_handler)
log.setLevel(logging.INFO)

CONFIG_FILE = '/etc/fuel/free_disk_check.yaml'
STATE_FILE = '/var/run/free_disk_check_state.yaml'


def read_state():
    try:
        with open(STATE_FILE) as f:
            return yaml.load(f)
    except IOError:
        return {}


def get_credentials():
    with open(CONFIG_FILE) as f:
        config = yaml.load(f)

    if not config:
        log.error('Config empty, exiting')
        sys.exit(1)

    # NOTE(pkaminski): 'monitord' user is for sending notifications only
    # We cannot use admin -- in case the end user changes admin's password
    # we wouldn't be able to send notifications.
    return (
        config['monitord_user'],
        config['monitord_password'],
        config['monitord_tenant']
    )


def save_notify_state(mount_point, state):
    state_dict = read_state()

    state_dict[mount_point] = state

    with open(STATE_FILE, 'w') as f:
        f.write(yaml.dump(state_dict, default_flow_style=False))


def was_notified(mount_point, state):
    """Checks if user was notified of mount_point being in given state.
    """

    return read_state().get(mount_point, 'SUCCESS') == state


def notify(message, topic=None):
    user, password, tenant = get_credentials()
    try:
        command = [
            'fuel', '--user', user, '--password', password, '--tenant', tenant,
            'notify', '-m', message
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

    message = get_error(state=state, mount_point=mount_point)

    if state == 'SUCCESS' and not was_notified(mount_point, state):
        # Notify about disk space back to normal
        log.info('Notifying about SUCCESS state for {0}'.format(mount_point))
        notify(message, topic='done')
        save_notify_state(mount_point, state)
    if state == 'ERROR' and not was_notified(mount_point, state):
        # Notify about disk space error
        log.info('Notifying about ERROR state for {0}'.format(mount_point))
        notify(message, topic='error')
        save_notify_state(mount_point, state)


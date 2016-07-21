#!/usr/bin/env python

usage = """Help: this daemon fences dead rabbitmq nodes"""

import daemon
try:
    import daemon.pidfile as daemon_pidfile
except ImportError:
    import daemon.pidlockfile as daemon_pidfile
import dbus
import dbus.decorators
import dbus.mainloop.glib
import gobject
import logging
import logging.handlers
import os
import pwd
import re
import signal
import socket
import subprocess
import sys
import time

USER = 'rabbitmq'
MAIL = '/var/spool/mail/rabbitmq'
PWD = '/var/lib/rabbitmq'
HOME = '/var/lib/rabbitmq'
LOGNAME = 'rabbitmq'


def catchall_signal_lh(*args, **kwargs):

    def bash_command(cmd):
        p = subprocess.Popen(cmd, env=env, shell=True,
                             stderr=subprocess.PIPE,
                             stdout=subprocess.PIPE)
        out, err = p.communicate()
        my_logger.debug('Command %s' % cmd)
        if out != '':
            my_logger.debug('  Stdout: %s' % out)
        if err != '':
            my_logger.debug('  Stderr: %s' % err)
        return out.strip()

    message = kwargs['message']
    action = args[3]
    if kwargs['type'] == 'NodeStateChange' and action == 'left':
        node = args[0]
        this_node = socket.gethostname().split('.')[0]
        node_name = node.split('.')[0]
        cmd = 'cat /etc/node_name_prefix_for_messaging 2>/dev/null'
        node_name_prefix = bash_command(cmd)
        if node_name_prefix == 'nil' or node_name_prefix in node_name:
            node_name_prefix = ''
        node_to_remove = 'rabbit@%s%s' % (node_name_prefix, node_name)

        my_logger.info("Got %s that left cluster" % node)
        my_logger.debug(kwargs)
        for arg in message.get_args_list():
            my_logger.debug("        " + str(arg))
        my_logger.info("Preparing to fence node %s from rabbit cluster"
                       % node_to_remove)

        if node == '' or re.search('\\b%s\\b' % this_node, node_name):
            my_logger.debug('Ignoring the node %s' % node_to_remove)
            return

        # NOTE(bogdando) when the rabbit node went down, its status
        # remains 'running' for a while, so few retries are required
        count = 0
        while True:
            cmd = ('rabbitmqctl eval '
                   '"mnesia:system_info(running_db_nodes)."'
                   '| grep -o %s') % node_to_remove
            results = bash_command(cmd)
            is_running = results != ''

            if not is_running or count >= 5:
                break

            count += 1
            time.sleep(10)

        if is_running:
            my_logger.warn('Ignoring alive node %s' % node_to_remove)
            return

        cmd = ('rabbitmqctl eval '
               '"mnesia:system_info(db_nodes)."'
               '| grep -o %s') % node_to_remove

        results = bash_command(cmd)
        in_cluster = results != ''

        if not in_cluster:
            my_logger.debug('Ignoring forgotten node %s' % node_to_remove)
            return

        my_logger.info('Disconnecting node %s' % node_to_remove)
        cmd = ('rabbitmqctl eval "disconnect_node'
               '(list_to_atom(\\"%s\\"))."') % node_to_remove
        bash_command(cmd)

        my_logger.info('Forgetting cluster node %s' % node_to_remove)
        cmd = 'rabbitmqctl forget_cluster_node %s' % node_to_remove
        bash_command(cmd)


def sigterm_handler(_signo, _stack_frame):
    my_logger.info("Caught SIGTERM, terminating...")
    sys.exit(0)


def main():
    my_logger.info('Starting rabbit fence script main loop')
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()
    try:
        bus.get_object("org.freedesktop.DBus", "/org/corosync")
    except dbus.DBusException:
        my_logger.exception("Cannot get the DBus object")
        sys.exit(1)

    bus.add_signal_receiver(catchall_signal_lh,
                            member_keyword="type",
                            message_keyword="message",
                            dbus_interface="org.corosync")
    signal.signal(signal.SIGTERM, sigterm_handler)
    loop = gobject.MainLoop()
    loop.run()


if __name__ == '__main__':
    my_logger = logging.getLogger('rabbit-fence')
    my_logger.setLevel(logging.DEBUG)
    lh = logging.handlers.SysLogHandler(address='/dev/log',
                                        facility='daemon')
    formatter = logging.Formatter('%(name)-12s '
                                  '%(asctime)s '
                                  '%(levelname)-8s '
                                  '%(message)s')
    lh.setFormatter(formatter)
    my_logger.addHandler(lh)

    rabbit_pwd = pwd.getpwnam('rabbitmq')
    uid = rabbit_pwd.pw_uid
    gid = rabbit_pwd.pw_gid
    env = os.environ.copy()
    env['USER'] = USER
    env['MAIL'] = MAIL
    env['PWD'] = PWD
    env['HOME'] = HOME
    env['LOGNAME'] = LOGNAME

    pidfilename = '/var/run/rabbitmq/rabbit-fence.pid'
    pidfile = daemon_pidfile.TimeoutPIDLockFile(pidfilename, 10)
    try:
        with daemon.DaemonContext(files_preserve=[lh.socket.fileno()],
                                  pidfile=pidfile, uid=uid,
                                  gid=gid, umask=0o022):

            main()
    except Exception:
        my_logger.exception("A generic exception caught!")
        sys.exit(1)

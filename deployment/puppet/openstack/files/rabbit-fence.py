#!/usr/bin/env python

usage = """Help: this daemon fences dead rabbitmq nodes"""

import daemon
import daemon.pidlockfile
import dbus
import dbus.decorators
import dbus.mainloop.glib
import gobject
import lockfile
from lockfile import LockTimeout
import logging
import logging.handlers
import os
import pwd
import subprocess
import sys
import traceback


def handle_reply(msg):
    print msg


def handle_error(e):
    print str(e)


def catchall_signal_handler(*args, **kwargs):
    message = kwargs['message']
    action = args[3]
    if kwargs['type'] == 'NodeStateChange' and action == 'left':
        node = args[0]
        my_logger.info("Got %s that left cluster" % node)
        my_logger.debug(kwargs)
        for arg in message.get_args_list():
            my_logger.debug("        " + str(arg))
        my_logger.info("Preparing to fence node %s from rabbit cluster"
                       % node)
        subprocess.call(['/usr/bin/rabbitmq-kick.sh', str(node)])


def main():
    my_logger.info('Starting rabbit fence script main loop')
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()
    try:
        object = bus.get_object("org.freedesktop.DBus", "/org/corosync")
    except dbus.DBusException:
        traceback.print_exc()
        print usage
        sys.exit(1)

    bus.add_signal_receiver(catchall_signal_handler,
                            member_keyword="type",
                            message_keyword="message",
                            dbus_interface="org.corosync")
    loop = gobject.MainLoop()
    loop.run()

if __name__ == '__main__':
    my_logger = logging.getLogger('rabbit-fence')
    my_logger.setLevel(logging.DEBUG)
    handler = logging.handlers.SysLogHandler(address='/dev/log',
                                             facility='daemon')
    formatter = logging.Formatter('%(name)s: %(message)s')
    handler.setFormatter(formatter)
    my_logger.addHandler(handler)
    rabbit_pwd = pwd.getpwnam('rabbitmq')
    uid = rabbit_pwd.pw_uid
    gid = rabbit_pwd.pw_gid
    pidfilename = '/var/run/rabbitmq/rabbitmq-fence.pid'
    pidfile = daemon.pidlockfile.PIDLockFile(pidfilename)
    try:
        pidfile.acquire(timeout=5)
    except LockTimeout:
        try:
            pid = pidfile.read_pid()
            os.kill(pid, 0)
            my_logger.info("Process already running with PID %s" % pid)
            sys.exit(1)
        except OSError:
            my_logger.info('Stale PID file exists. Removing it.')
            pidfile.break_lock()
    try:
        with daemon.DaemonContext(pidfile=pidfile, uid=uid,
                                  gid=gid, umask=0022):
            main()
    except Exception:
        traceback.print_exc()
        sys.exit(1)

#!/usr/bin/python

import atexit
import sys, re, pexpect, exceptions
sys.path.append("/usr/share/fence")
from fencing import *

# BEGIN_VERSION_GENERATION
RELEASE_VERSION = "0.1.0"
BUILD_DATE = "(built Wed Oct 31 11:20:18 UTC 2012)"
MIRANTIS_COPYRIGHT = "Copyright (C) Mirantis, Inc. 2012 All rights reserved."
# END_VERSION_GENERATION


def get_power_status(conn, options):
    try:
        conn.sendline("/bin/echo 1")
        conn.log_expect(options, options["--command-prompt"],
                        int(options["--shell-timeout"]))
    except:
        return "off"
    return "on"

def set_power_status(conn, options):
    if options["--action"] == "off":
      try:
          conn.sendline("/sbin/reboot")
          conn.log_expect(options, options["--command-prompt"],
                          int(options["--power-timeout"]))
          time.sleep(2)
      except:
          pass

def main():
    device_opt = [  "help", "version", "agent", "verbose", "debug",
                    "action", "ipaddr", "login", "passwd", "passwd_script",
                    "secure", "identity_file", "port", "separator",
                    "inet4_only", "inet6_only", "ipport",
                    "power_timeout", "shell_timeout",
                    "login_timeout", "power_wait" ]

    atexit.register(atexit_handler)

    all_opt["login_timeout"]["default"] = 60

    pinput = process_input(device_opt)

    # use ssh to manipulate node
    pinput["--ssh"] = 1
    pinput["--command-prompt"] = ".*"

    options = check_input(device_opt, pinput)

    if options["--action"] != "off":
        sys.exit(0)

    options["-c"] = "\[EXPECT\]#\ "

    # this string will be appended to the end of ssh command
    options["ssh_options"] = "-t -o 'StrictHostKeyChecking=no' " \
                             "'/bin/bash -c \"PS1=%s  /bin/bash " \
                             "--noprofile --norc\"'" % options["-c"]
    options["-X"] = "-t -o 'StrictHostKeyChecking=no' " \
                    "'/bin/bash -c \"PS1=%s  /bin/bash " \
                    "--noprofile --norc\"'" % options["-c"]

    docs = {}
    docs["shortdesc"] = "Fence agent that can just reboot node via ssh"
    docs["longdesc"] = "fence_ssh is an I/O Fencing agent " \
                       "which can be used to reboot nodes via ssh."
    show_docs(options, docs)

    # Operate the fencing device

    # this method will actually launch ssh command
    conn = fence_login(options)

    result = fence_action(conn, options, set_power_status,
                          get_power_status, None)

    try:
        conn.close()
    except exceptions.OSError:
        pass
    except pexpect.ExceptionPexpect:
        pass

    sys.exit(result)
if __name__ == "__main__":
    main()

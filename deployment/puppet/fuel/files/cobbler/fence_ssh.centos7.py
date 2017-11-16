#!/usr/bin/python

#  Licensed under the Apache License, Version 2.0 (the "License"); you may
#  not use this file except in compliance with the License. You may obtain
#  a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.

import atexit
import pexpect
import sys
import time

sys.path.append("/usr/share/fence")
from fencing import all_opt
from fencing import atexit_handler
from fencing import check_input
from fencing import fence_action
from fencing import fence_login
from fencing import process_input
from fencing import show_docs

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
    except Exception:
        return "off"
    return "on"


def set_power_status(conn, options):
    if options["--action"] == "off":
        try:
            conn.sendline("sh -c '(sleep 1;/sbin/reboot -f)' &>/dev/null &")
            conn.log_expect(options, options["--command-prompt"],
                            int(options["--power-timeout"]))
            time.sleep(2)
        except Exception:
            pass


def main():
    device_opt = ["help", "version", "agent", "verbose", "debug",
                  "action", "ipaddr", "login", "passwd", "passwd_script",
                  "secure", "identity_file", "port", "separator",
                  "inet4_only", "inet6_only", "ipport",
                  "power_timeout", "shell_timeout",
                  "login_timeout", "power_wait"]

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
    strict = "-t -o 'StrictHostKeyChecking=no'"
    serveralive = "-o 'ServerAliveInterval 2'"
    no_stdin = "-n"
    options["ssh_options"] = "{0} {1} {2} '/bin/bash -c \"PS1={3} /bin/bash " \
                             "--noprofile --norc\"'".format(
                             strict, serveralive, no_stdin, options["-c"])
    options["-X"] = "{0} {1} {2} '/bin/bash -c \"PS1={3}  /bin/bash " \
                    "--noprofile --norc\"'".format(
                    strict, serveralive, no_stdin, options["-c"])

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
    except OSError:
        pass
    except pexpect.ExceptionPexpect:
        pass

    sys.exit(result)
if __name__ == "__main__":
    main()

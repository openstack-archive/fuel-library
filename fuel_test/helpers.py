import logging
import re

def execute(remote, command):
    chan, stdin, stderr, stdout = execute_async(remote, command)
    result = {
        'stdout': [],
        'stderr': [],
        'exit_code': 0
    }
    for line in stdout:
        result['stdout'].append(line)
        print line
    for line in stderr:
        result['stderr'].append(line)
        print line

    result['exit_code'] = chan.recv_exit_status()
    chan.close()

    return result

def udp_ping(remote, host, port):
    result = execute(remote,'nmap -PU -sU -p%s %s' % (port, host))
    for line in result['stdout']:
        if line.find('udp open') != -1:
            return True
    return False

def tcp_ping(remote, host, port):
    result = execute(remote,'nmap -PU -p%s %s' % (port, host))
    for line in result['stdout']:
        if line.find('tcp open') != -1:
            return True
    return False

def load(path):
    with open(path) as f:
        return f.read()

def execute_async(remote, command):
    logging.debug("Executing command: '%s'" % command.rstrip())
    chan = remote._ssh.get_transport().open_session()
    stdin = chan.makefile('wb')
    stdout = chan.makefile('rb')
    stderr = chan.makefile_stderr('rb')
    cmd = "%s\n" % command
    if remote.sudo_mode:
        cmd = 'sudo -S bash -c "%s"' % cmd.replace('"', '\\"')
    chan.exec_command(cmd)
    if stdout.channel.closed is False:
        stdin.write('%s\n' % remote.password)
        stdin.flush()
    return chan, stdin, stderr, stdout

def extract_virtual_ips(ipaout):
    pattern = '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*(eth\d{1,}):keepalived'
    return dict((v,k) for k, v in re.findall(pattern, ipaout))




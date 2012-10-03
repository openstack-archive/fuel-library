import logging
import re
from root import root
from settings import controllers

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

def tempest_build_config(host, image_ref, image_ref_alt):
    sample = load(root('fuel', 'fuel_test', 'config', 'tempest.conf.sample'))
    config = sample % {
        'HOST': host,
        'USERNAME': 'tempest1',
        'PASSWORD': 'secret',
        'TENANT_NAME': 'openstack',
        'ALT_USERNAME': 'tempest2',
        'ALT_PASSWORD': 'secret',
        'ALT_TENANT_NAME': 'openstack',
        'IMAGE_ID': image_ref,
        'IMAGE_ID_ALT': image_ref_alt,
        'ADMIN_USERNAME': 'tempest1',
        'ADMIN_PASSWORD': 'secret',
        'ADMIN_TENANT_NAME': 'openstack',
        }
    return config

def tempest_write_config(host, image_ref, image_ref_alt):
    with open(root('tempest.conf'), 'w') as f:
        f.write(tempest_build_config(host, image_ref, image_ref_alt))

def credentials(auth_host):
    auth_url = 'http://%s:5000/v2.0/' % auth_host
    return '--os_username nova --os_password admin --os_auth_url %s' % auth_url

def keystone_command(auth_host):
    return 'keystone ' + credentials(auth_host) + ' '

def glance_command(auth_host):
    return 'glance ' + credentials(auth_host) + ' '

def tempest_create_user(remote, auth_host, name, password, tenant_id):
    execute(remote, keystone_command(auth_host) +' user-create --name %s --pass %s --tenant_id %s '  %(name, password, tenant_id))

def tempest_create_tenant(remote, auth_host, name):
    pattern='id.*\|\s+(\S*)\s+.*'
    result = execute(remote, keystone_command(auth_host) + ' tenant-create --name %s' % name)
    tenant_id = re.findall(pattern, string='\n'.join(result['stdout']))
    print tenant_id
    return tenant_id

def tempest_add_images(remote, auth_host):
    execute(remote, 'wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img')
    result = execute(remote, glance_command(auth_host) +' add name=cirros_0.3.0 is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img')
    pattern = 'Added new image with ID: (\S*)'
    image_ref = re.findall(pattern, string='\n'.join(result['stdout']))
    print image_ref
    execute(remote, glance_command(auth_host) + ' add name=cirros_0.3.0 is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img')
    image_ref_any = re.findall(pattern, string='\n'.join(result['stdout']))
    print image_ref_any
    return image_ref, image_ref_any

def tempest_share_glance_images(remote, network):
    execute(remote, 'echo "/var/lib/glance/images %s(rw,no_root_squash)" >> /etc/exports' % network)
    execute(remote, '/etc/init.d/nfs restart')

def tempest_mount_glance_images(remote):
    execute(remote, 'mount %s:/var/lib/glance/images /var/lib/glance/images -o vers=3' % controllers[0])



import logging
from time import sleep
from devops.helpers import ssh, os
import keystoneclient.v2_0
import re
from fuel_test.settings import OS_FAMILY, PUPPET_CLIENT_PACKAGE
from root import root
#from glanceclient import Client

def get_file_as_string(path):
    with open(path) as f:
        return f.read()


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
    result = execute(remote, 'nmap -PU -sU -p%s %s' % (port, host))
    for line in result['stdout']:
        if line.find('udp open') != -1:
            return True
    return False


def tcp_ping(remote, host, port):
    result = execute(remote, 'nmap -PU -p%s %s' % (port, host))
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
    return dict((v, k) for k, v in re.findall(pattern, ipaout))


def tempest_build_config(host, image_ref, image_ref_alt):
    sample = load(
        root('fuel', 'fuel_test', 'config', 'tempest.conf.essex.sample'))
    config = sample % {
        'HOST': host,
        'USERNAME': 'tempest1',
        'PASSWORD': 'secret',
        'TENANT_NAME': 'tenant1',
        'ALT_USERNAME': 'tempest2',
        'ALT_PASSWORD': 'secret',
        'ALT_TENANT_NAME': 'tenant2',
        'IMAGE_ID': image_ref,
        'IMAGE_ID_ALT': image_ref_alt,
        'ADMIN_USERNAME': 'admin',
        'ADMIN_PASSWORD': 'nova',
        'ADMIN_TENANT_NAME': 'openstack',
    }
    return config


def tempest_write_config(host, image_ref, image_ref_alt):
    with open(root('tempest.conf'), 'w') as f:
        f.write(tempest_build_config(host, image_ref, image_ref_alt))


def get_auth_url(auth_host):
    auth_url = 'http://%s:5000/v2.0/' % auth_host
    print auth_url
    return auth_url


def credentials(auth_host, tenant_name):
    credentials = '--os_username admin --os_password nova --os_auth_url  "%s" --os_tenant_name %s' % (
        get_auth_url(auth_host), tenant_name)
    print credentials
    return credentials


def glance_command(auth_host, tenant_name):
    return 'glance ' + credentials(auth_host, tenant_name) + ' '


def tempest_add_images(remote, auth_host, tenant_name):
    execute(remote,
        'wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img')
    result = execute(remote, glance_command(auth_host,
        tenant_name) + ' add name=cirros_0.3.0 is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img')
    pattern = 'Added new image with ID: (\S*)'
    image_ref = re.findall(pattern, string='\n'.join(result['stdout']))[0]
    result = execute(remote, glance_command(auth_host,
        tenant_name) + ' add name=cirros_0.3.0 is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img')
    image_ref_any = re.findall(pattern, string='\n'.join(result['stdout']))[0]
    return image_ref, image_ref_any


def tempest_share_glance_images(remote, network):
    execute(remote, 'chkconfig rpcbind on')
    execute(remote, '/etc/init.d/rpcbind restart')
    execute(remote,
        'echo "/var/lib/glance/images %s(rw,no_root_squash)" >> /etc/exports' % network)
    execute(remote, '/etc/init.d/nfs restart')


def tempest_mount_glance_images(remote, host):
    execute(remote, 'chkconfig rpcbind on')
    execute(remote, '/etc/init.d/rpcbind restart')
    execute(remote,
        'mount %s:/var/lib/glance/images /var/lib/glance/images' % host)


def sync_time(remote):
    install_packages(remote, 'ntpdate')
    execute(remote, '/etc/init.d/ntpd stop')
    execute(remote, 'ntpdate 0.centos.pool.ntp.org')
    execute(remote, '/etc/init.d/ntpd start')


def write_config(remote, path, text):
    file = remote.open(path, 'w')
    file.write(text)
    logging.info('Write config %s' % text)
    file.close()


def retry(count, func, **kwargs):
    i = 0
    while True:
        try:
            return func(**kwargs)
        except:
            if i >= count:
                raise
            i += 1
            sleep(1)


def install_packages(remote, packages):
    if OS_FAMILY == "centos":
        execute(remote.sudo.ssh, 'yum -y install %s' % packages)
    else:
        execute(remote.sudo.ssh, 'apt-get -y install %s' % packages)


def add_nmap(remote):
    install_packages(remote, "nmap")


def add_epel_repo_yum(remote):
    execute(remote.sudo.ssh,
        'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm')


def delete_epel_repo_yum(remote):
    execute(remote.sudo.ssh,
        'rpm --erase epel-release-6-7.noarch.rpm')


def add_puppet_lab_repo(remote):
    if OS_FAMILY == "centos":
        execute(
            remote.sudo.ssh,
            'rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-5.noarch.rpm')
    else:
        execute(remote.sudo.ssh,
            'wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb -O /tmp/puppetlabs-release-precise.deb')
        execute(remote.sudo.ssh, 'dpkg -i puppetlabs-release-precise.deb')


def remove_puppetlab_repo(remote):
    if OS_FAMILY == "centos":
        execute(remote.sudo.ssh, 'rpm --erase puppetlabs-release-6-5.noarch')
    else:
        execute(remote.sudo.ssh, 'dpkg -r puppetlabs-release-precise.deb')


def setup_puppet_client(remote):
    add_puppet_lab_repo(remote)
    install_packages(remote, PUPPET_CLIENT_PACKAGE)
    remove_puppetlab_repo(remote)


def start_puppet_master(remote):
    remote.sudo.ssh.execute(
        'puppet resource service puppetmaster ensure=running enable=true')


def start_puppet_agent(remote):
    remote.sudo.ssh.execute(
        'puppet resource service puppet ensure=running enable=true')


def sign_all_node_certificates(remote):
    remote.sudo.ssh.execute('puppet cert sign --all')


def request_cerificate(remote):
    remote.sudo.ssh.execute('puppet agent --waitforcert 0')


def switch_off_ip_tables(remote):
    remote.sudo.ssh.execute('iptables -F')


def puppet_apply(remote, script, module_path="/tmp/puppet/modules/"):
    execute(remote.sudo.ssh,
        "puppet apply --modulepath %s -e '%s'" % (module_path, script))


def setup_puppet_master(remote):
    add_puppet_lab_repo(remote)
    add_epel_repo_yum(remote)
    install_packages(remote, PUPPET_CLIENT_PACKAGE)
    upload_recipes(remote.sudo.ssh, "/tmp/puppet/modules/")
    puppet_apply(remote.sudo.ssh,
        'class {puppet:}'
        '-> class {puppet::thin:}'
        '-> class {puppet::nginx: puppet_master_hostname => "master.mirantis.com"}')
    puppet_apply(remote.sudo.ssh,
        'class {puppetdb:}')
    puppet_apply(remote.sudo.ssh,
        'class {puppetdb::master::config:}')
    execute(remote.sudo.ssh, 'setenforce 0')


def upload_recipes(remote, remote_dir="/etc/puppet/modules/"):
    recipes_dir = root('fuel', 'deployment', 'puppet')
    for dir in os.listdir(recipes_dir):
        recipe_dir = os.path.join(recipes_dir, dir)
        remote.mkdir(remote_dir)
        remote.upload(recipe_dir, remote_dir)


def change_host_name(remote, short, long):
    remote.sudo.ssh.execute('hostname %s' % long)
    add_to_hosts(remote, '127.0.0.1', short, long)
    if OS_FAMILY == "centos":
        update_host_name_centos(remote, short)
    else:
        update_host_name_ubuntu(remote, short)


def update_host_name_centos(remote, short):
    execute(remote.sudo.ssh,
        'echo HOSTNAME=%s >> /etc/sysconfig/network' % short)


def update_host_name_ubuntu(remote, short):
    execute(remote.sudo.ssh,
        'echo %s > /etc/hostname' % short)


def add_to_hosts(remote, ip, short, long):
    remote.sudo.ssh.execute('echo %s %s %s >> /etc/hosts' % (ip, long, short))


def safety_revert_nodes(nodes, snapsot_name='openstack'):
    for node in nodes:
        try:
            node.stop()
        except:
            pass
    for node in nodes:
        node.restore_snapshot(snapsot_name)
        sleep(2)


def make_shared_storage(remote, host, client_nodes, access_network):
    tempest_share_glance_images(remote, access_network)
    execute(remote, '/etc/init.d/iptables stop')
    sleep(5)
    for controller in client_nodes:
        remote_controller = ssh(
            controller.ip_address, username='root',
            password='r00tme').sudo.ssh
        tempest_mount_glance_images(remote_controller, host)


def make_tempest_objects(auth_host, remote):
    keystone = retry(10, keystoneclient.v2_0.client.Client,
        username='admin', password='nova', tenant_name='openstack',
        auth_url=get_auth_url(auth_host))
    tenant1 = retry(10, keystone.tenants.create, tenant_name='tenant1')
    tenant2 = retry(10, keystone.tenants.create, tenant_name='tenant2')
    retry(10, keystone.users.create, name='tempest1', password='secret',
        email='tempest1@example.com', tenant_id=tenant1.id)
    retry(10, keystone.users.create, name='tempest2', password='secret',
        email='tempest1@example.com', tenant_id=tenant2.id)
    image_ref, image_ref_any = tempest_add_images(remote, auth_host,
        'openstack')
    return image_ref, image_ref_any


def write_static_ip(remote, ip, net_mask, gateway, interface='eth0'):
    path = '/etc/sysconfig/network-scripts/ifcfg-%s' % interface
    text = load(root('fuel', 'fuel_test', 'config', 'ifcfg-eth0.config')) % {
        'ip': str(ip), 'net_mask': str(net_mask),
        'gateway': str(gateway), 'interface': str(interface)}
    write_config(remote, path, text)
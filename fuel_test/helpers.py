import logging
import subprocess
from time import sleep
from devops.helpers import ssh, os
import keystoneclient.v2_0
import re
from fuel_test.settings import OS_FAMILY, PUPPET_CLIENT_PACKAGE, PUPPET_VERSION, PUPPET_MASTER_SERVICE, ADMIN_USERNAME, ADMIN_PASSWORD, ADMIN_TENANT_FOLSOM, ADMIN_TENANT_ESSEX, CIRROS_IMAGE
from root import root
import glanceclient.client

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

def tempest_build_config_folsom(host, image_ref, image_ref_alt,
                                path_to_private_key,
                                compute_db_uri='mysql://user:pass@localhost/nova'):
    sample = load(
        root('fuel', 'fuel_test', 'config', 'tempest.conf.folsom.sample'))

    config = sample % {
        'IDENTITY_USE_SSL': 'false',
        'IDENTITY_HOST': host,
        'IDENTITY_PORT': '5000',
        'IDENTITY_API_VERSION': 'v2.0',
        'IDENTITY_PATH': 'tokens',
        'IDENTITY_STRATEGY': 'keystone',
        'COMPUTE_ALLOW_TENANT_ISOLATION': 'true',
        'COMPUTE_ALLOW_TENANT_REUSE': 'true',
        'USERNAME': 'tempest1',
        'PASSWORD': 'secret',
        'TENANT_NAME': 'tenant1',
        'ALT_USERNAME': 'tempest2',
        'ALT_PASSWORD': 'secret',
        'ALT_TENANT_NAME': 'tenant2',
        'IMAGE_ID': image_ref,
        'IMAGE_ID_ALT': image_ref_alt,
        'FLAVOR_REF': '1',
        'FLAVOR_REF_ALT': '2',
        'COMPUTE_BUILD_INTERVAL': '10',
        'COMPUTE_BUILD_TIMEOUT': '600',
        'RUN_SSH':'true',
        'NETWORK_FOR_SSH':'novanetwork',
        'COMPUTE_CATALOG_TYPE': 'compute',
        'COMPUTE_CREATE_IMAGE_ENABLED': 'true',
        'COMPUTE_RESIZE_AVAILABLE': 'true',
        'COMPUTE_CHANGE_PASSWORD_AVAILABLE': 'true',
        'COMPUTE_LOG_LEVEL': 'DEBUG',
        'COMPUTE_WHITEBOX_ENABLED': 'true',
        'COMPUTE_SOURCE_DIR': '/opt/stack/nova',
        'COMPUTE_CONFIG_PATH': '/etc/nova/nova.conf',
        'COMPUTE_BIN_DIR': '/usr/local/bin',
        'COMPUTE_PATH_TO_PRIVATE_KEY': path_to_private_key,
        'COMPUTE_DB_URI': compute_db_uri,
        'IMAGE_CATALOG_TYPE': 'image',
        'IMAGE_API_VERSION': '1',
        'IMAGE_HOST': host,
        'IMAGE_PORT': '9292',
        'IMAGE_USERNAME': 'tempest1',
        'IMAGE_PASSWORD': 'secret',
        'IMAGE_TENANT_NAME': 'tenant1',
        'COMPUTE_ADMIN_USERNAME': ADMIN_USERNAME,
        'COMPUTE_ADMIN_PASSWORD': ADMIN_PASSWORD,
        'COMPUTE_ADMIN_TENANT_NAME': ADMIN_TENANT_FOLSOM,
        'IDENTITY_ADMIN_USERNAME': ADMIN_USERNAME,
        'IDENTITY_ADMIN_PASSWORD': ADMIN_PASSWORD,
        'IDENTITY_ADMIN_TENANT_NAME': ADMIN_TENANT_FOLSOM,
        'VOLUME_CATALOG_TYPE': 'volume',
        'VOLUME_BUILD_INTERVAL': '10',
        'VOLUME_BUILD_TIMEOUT': '300',
    }
    
    return config


def tempest_build_config_essex(host, image_ref, image_ref_alt):
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
        'ADMIN_USERNAME':  ADMIN_USERNAME,
        'ADMIN_PASSWORD': ADMIN_PASSWORD,
        'ADMIN_TENANT_NAME': ADMIN_TENANT_ESSEX,
    }
    return config


def tempest_write_config(config):
    with open(root('tempest.conf'), 'w') as f:
        f.write(config)


def get_auth_url(auth_host):
    auth_url = 'http://%s:5000/v2.0/' % auth_host
    print auth_url
    return auth_url


def _get_identity_client(auth_host, username, password, tenant_name):
    keystone = retry(10, keystoneclient.v2_0.client.Client,
        username=username, password=password, tenant_name=tenant_name,
        auth_url=get_auth_url(auth_host))
    return keystone

def _get_image_client(auth_host, username, password, tenant_name):
    keystone = _get_identity_client(auth_host, username, password, tenant_name)
    token = keystone.auth_token
    endpoint = keystone.service_catalog.url_for(service_type='image',
        endpoint_type='publicURL')
    return glanceclient.Client('1', endpoint=endpoint, token=token)

def make_tempest_objects(auth_host, username, password, tenant_name):
    keystone = _get_identity_client(auth_host, username, password, tenant_name)
    tenant1 = retry(10, keystone.tenants.create, tenant_name='tenant1')
    tenant2 = retry(10, keystone.tenants.create, tenant_name='tenant2')
    retry(10, keystone.users.create, name='tempest1', password='secret',
        email='tempest1@example.com', tenant_id=tenant1.id)
    retry(10, keystone.users.create, name='tempest2', password='secret',
        email='tempest2@example.com', tenant_id=tenant2.id)
    image_ref, image_ref_alt = tempest_add_images(
        auth_host,
        username,
        password,
        tenant_name)
    return image_ref, image_ref_alt

def upload(glance, name, path):
    image = glance.images.create(
        name=name,
        is_public=True,
        container_format='bare',
        disk_format='qcow2')
    image.update(data=open(path, 'rb'))
    return image.id

def tempest_add_images(auth_host, username, password, tenant_name):
    if not os.path.isfile('cirros-0.3.0-x86_64-disk.img'):
        subprocess.check_call(['wget', CIRROS_IMAGE])
    glance = _get_image_client(auth_host, username, password, tenant_name)
    return upload(glance, 'cirros_0.3.0', 'cirros-0.3.0-x86_64-disk.img'),\
           upload(glance, 'cirros_0.3.0', 'cirros-0.3.0-x86_64-disk.img')

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
        execute(remote.sudo.ssh, 'DEBIAN_FRONTEND=noninteractive apt-get -y install %s' % packages)

def update_pm(remote):
    if OS_FAMILY == "centos":
        execute(remote.sudo.ssh, 'yum makecache')
    else:
        execute(remote.sudo.ssh, 'apt-get update')

def add_nmap(remote):
    install_packages(remote, "nmap")


def add_epel_repo_yum(remote):
    if OS_FAMILY == "centos":
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
        execute(remote.sudo.ssh, 'dpkg -i /tmp/puppetlabs-release-precise.deb')


def remove_puppetlab_repo(remote):
    if OS_FAMILY == "centos":
        execute(remote.sudo.ssh, 'rpm --erase puppetlabs-release-6-5.noarch')
    else:
        execute(remote.sudo.ssh, 'dpkg -r puppetlabs-release-precise')


def setup_puppet_client(remote):
    add_puppet_lab_repo(remote)
    update_pm(remote)
    install_packages(remote, PUPPET_CLIENT_PACKAGE)
    remove_puppetlab_repo(remote)


def start_puppet_master(remote):
    remote.sudo.ssh.execute(
        'puppet resource service %s ensure=running enable=true' % PUPPET_MASTER_SERVICE)


def start_puppet_agent(remote):
    remote.sudo.ssh.execute(
        'puppet resource service puppet ensure=running enable=true')


def sign_all_node_certificates(remote):
    remote.sudo.ssh.execute('puppet cert sign --all')


def request_cerificate(remote):
    remote.sudo.ssh.execute('puppet agent --waitforcert 0 --test')


def switch_off_ip_tables(remote):
    remote.sudo.ssh.execute('iptables -F')


def puppet_apply(remote, script, module_path="/tmp/puppet/modules/"):
    execute(remote.sudo.ssh,
        "puppet apply --modulepath %s -e '%s'" % (module_path, script))


def setup_puppet_master(remote):
    add_puppet_lab_repo(remote)
    add_epel_repo_yum(remote)
    update_pm(remote)
    install_packages(remote, PUPPET_CLIENT_PACKAGE)
    upload_recipes(remote.sudo.ssh, "/tmp/puppet/modules/")
    execute(remote.sudo.ssh, 'setenforce 0')
    puppet_apply(remote.sudo.ssh,
        'class {puppet: puppet_master_version => "%s"}'
        '-> class {puppet::thin:}'
        '-> class {puppet::nginx: puppet_master_hostname => "master.mirantis.com"}'
         % PUPPET_VERSION)
    remote.mkdir('/var/lib/puppet/ssh_keys')
    puppet_apply(remote.sudo.ssh, 'class {puppet::fileserver_config:}')
    puppet_apply(remote.sudo.ssh,
        'class {puppetdb:}')
    puppet_apply(remote.sudo.ssh,
        'class {puppetdb::master::config: puppet_service_name=>"%s"}' % PUPPET_MASTER_SERVICE)
    execute(remote.sudo.ssh, "service %s restart" % PUPPET_MASTER_SERVICE)


def upload_recipes(remote, remote_dir="/etc/puppet/modules/"):
    recipes_dir = root('fuel', 'deployment', 'puppet')
    for dir in os.listdir(recipes_dir):
        recipe_dir = os.path.join(recipes_dir, dir)
        remote.mkdir(remote_dir)
        remote.upload(recipe_dir, remote_dir)

def upload_keys(remote, remote_dir="/var/lib/puppet"):
    ssh_keys_dir = root('fuel', 'fuel_test', 'config', 'ssh_keys')
    remote.upload(ssh_keys_dir, remote_dir)


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
    switch_off_ip_tables(remote)
    execute(remote, '/etc/init.d/iptables stop')
    sleep(15)
    for controller in client_nodes:
        remote_controller = ssh(
            controller.ip_address, username='root',
            password='r00tme').sudo.ssh
        tempest_mount_glance_images(remote_controller, host)
    sleep(60)

def write_static_ip(remote, ip, net_mask, gateway, interface='eth0'):
    path = '/etc/sysconfig/network-scripts/ifcfg-%s' % interface
    text = load(root('fuel', 'fuel_test', 'config', 'ifcfg-eth0.config')) % {
        'ip': str(ip), 'net_mask': str(net_mask),
        'gateway': str(gateway), 'interface': str(interface)}
    write_config(remote, path, text)

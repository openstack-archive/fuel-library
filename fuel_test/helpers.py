import logging
import subprocess
import tarfile
from time import sleep
from devops.helpers.helpers import _wait
import os
import re
from fuel_test.cobbler.cobbler_client import CobblerClient
from fuel_test.settings import OS_FAMILY, PUPPET_CLIENT_PACKAGE, PUPPET_VERSION, PUPPET_MASTER_SERVICE, EXIST_TAR, USE_ISO
from root import root

def get_file_as_string(path):
    with open(path) as f:
        return f.read()


def udp_ping(remote, host, port):
    result = remote.check_stderr('nmap -PU -sU -p%s %s' % (port, host))
    for line in result['stdout']:
        if line.find('udp open') != -1:
            return True
    return False


def tcp_ping(remote, host, port):
    result = remote.check_stderr('nmap -PU -p%s %s' % (port, host))
    for line in result['stdout']:
        if line.find('tcp open') != -1:
            return True
    return False

def load(path):
    with open(path) as f:
        return f.read()


def extract_virtual_ips(ipaout):
    pattern = '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}).*(eth\d{1,}):ka'
    return dict((v, k) for k, v in re.findall(pattern, ipaout))


def write_config(remote, path, text):
    config = remote.open(path, 'w')
    config.write(text)
    logging.info('Write config %s' % text)
    config.close()

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


def install_packages2(remotes, packages):
    if OS_FAMILY == "centos":
        cmd = 'yum -y install %s' % packages
    else:
        cmd = 'DEBIAN_FRONTEND=noninteractive apt-get -y install %s' % packages
    for remote in remotes:
        remote.execute(cmd)


def dhcp_checksum(remote):
    if OS_FAMILY == "centos" or USE_ISO:
        remote.sudo.ssh.execute("iptables -t mangle -A POSTROUTING -p udp --dport 68 -j CHECKSUM --checksum-fill; /etc/init.d/iptables save")
    else:
        remote.sudo.ssh.execute("iptables -t mangle -A POSTROUTING -p udp --dport 68 -j CHECKSUM --checksum-fill; iptables-save -c > /etc/iptables.rules")


def install_packages(remote, packages):
    if OS_FAMILY == "centos" or USE_ISO:
        remote.sudo.ssh.check_call('yum -y install %s' % packages)
    else:
        remote.sudo.ssh.check_call(
            'DEBIAN_FRONTEND=noninteractive apt-get -y install %s' % packages)


def update_pms(remotes):
    if OS_FAMILY == "centos":
        cmd = 'yum makecache'
    else:
        cmd = 'apt-get update'
    for remote in remotes:
        remote.execute(cmd)


def update_pm(remote):
    if OS_FAMILY == "centos":
        remote.sudo.ssh.check_call('yum makecache')
    else:
        remote.sudo.ssh.check_call('apt-get update')


def add_nmap(remote):
    install_packages(remote, "nmap")


def add_epel_repo_yum(remote):
    if OS_FAMILY == "centos":
        remote.sudo.ssh.check_call(
            'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm')


def delete_epel_repo_yum(remote):
    remote.sudo.ssh.check_call(
        'rpm --erase epel-release-6-8.noarch.rpm')


def add_puppet_lab_repo(remote):
    if OS_FAMILY == "centos":
        remote.sudo.ssh.check_call(
            'rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-5.noarch.rpm')
    else:
        remote.sudo.ssh.check_call(
            'wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb -O /tmp/puppetlabs-release-precise.deb')
        remote.sudo.ssh.check_call(
            'dpkg -i /tmp/puppetlabs-release-precise.deb')


def remove_puppetlab_repo(remote):
    if OS_FAMILY == "centos":
        remote.sudo.ssh.check_call('rpm --erase puppetlabs-release-6-5.noarch')
    else:
        remote.sudo.ssh.check_call('dpkg -r puppetlabs-release-precise')


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


#def sign_all_node_certificates(remote):
#    remote.sudo.ssh.execute('puppet cert sign --all')


def request_cerificate(remote):
    remote.sudo.ssh.execute('puppet agent --waitforcert 0 --test')


def switch_off_ip_tables(remote):
    remote.sudo.ssh.execute('iptables -F')


def puppet_apply(remote, script, module_path="/tmp/puppet/modules/"):
    remote.sudo.ssh.check_call(
        "puppet apply --modulepath %s -e '%s'" % (module_path, script))


def setup_puppet_master(remote):
    add_puppet_lab_repo(remote)
    add_epel_repo_yum(remote)
    update_pm(remote)
    install_packages(remote, PUPPET_CLIENT_PACKAGE)
    upload_recipes(remote.sudo.ssh, "/tmp/puppet/modules/")
    write_config(remote.sudo.ssh, '/etc/puppet/hiera.yaml', '')
    puppet_apply(remote.sudo.ssh,
        'class {puppet: puppet_master_version => "%s"}'
        '-> class {puppet::thin:}'
        '-> class {puppet::nginx: puppet_master_hostname => "master.localdomain"}'
        % PUPPET_VERSION)
    remote.mkdir('/var/lib/puppet/ssh_keys')
    puppet_apply(remote.sudo.ssh, 'class {puppet::fileserver_config:}')
    puppet_apply(remote.sudo.ssh, 'class {puppetdb:}')
    puppet_apply(remote.sudo.ssh, 'class {puppetdb::master::config: puppet_service_name=>"%s"}' % PUPPET_MASTER_SERVICE)
    remote.sudo.ssh.check_call("service %s restart" % PUPPET_MASTER_SERVICE)


def upload_recipes(remote, remote_dir="/etc/puppet/modules/"):
    recipes_dir = root('deployment', 'puppet')
    tar_file = None
    try:
        if EXIST_TAR:
            remote.upload(EXIST_TAR, '/tmp/recipes.tar')
        else:
            tar_file = remote.open('/tmp/recipes.tar', 'wb')
            with tarfile.open(fileobj=tar_file, mode='w', dereference=True) as tar:
                tar.add(recipes_dir, arcname='')
        remote.mkdir(remote_dir)
        remote.check_call('tar xmf /tmp/recipes.tar --overwrite -C %s' % remote_dir)
    finally:
        if tar_file:
            tar_file.close()


def upload_keys(remote, remote_dir="/var/lib/puppet/"):
    ssh_keys_dir = root('fuel_test', 'config', 'ssh_keys')
    remote.upload(ssh_keys_dir, remote_dir)


def change_host_name(remote, short, full):
    remote.sudo.ssh.execute('hostname %s' % full)
    add_to_hosts(remote, '127.0.0.1', short, full)
    if OS_FAMILY == "centos":
        update_host_name_centos(remote, short)
    else:
        update_host_name_ubuntu(remote, short)


def update_host_name_centos(remote, short):
    remote.sudo.ssh.check_stderr(
        'echo HOSTNAME=%s >> /etc/sysconfig/network' % short)


def update_host_name_ubuntu(remote, short):
    remote.sudo.ssh.check_stderr(
        'echo %s > /etc/hostname' % short)


def add_to_hosts(remote, ip, short, full):
    remote.sudo.ssh.execute('echo %s %s %s >> /etc/hosts' % (ip, full, short))


def check_node_ready(client, token, name):
    if client.get_system(name, token)['netboot_enabled']:
        raise Exception("Cobbler doesn't finish hode deploy", name)


def await_node_deploy(ip, name):
    client = CobblerClient(ip)
    token = client.login('cobbler', 'cobbler')
    _wait(lambda: check_node_ready(client, token, name), timeout=30 * 60)


def build_astute():
    subprocess.check_output(
        ['gem', 'build', 'astute.gemspec'],
        cwd=root('deployment', 'mcollective', 'astute'))


def install_astute(remote):
    remote.upload(
        root('deployment', 'mcollective', 'astute', 'astute-0.0.1.gem'),
        '/tmp/astute-0.0.1.gem')
    remote.check_stderr('gem install /tmp/astute-0.0.1.gem')


def is_not_essex():
    return os.environ.get('ENV_NAME', 'folsom').find('essex') == -1

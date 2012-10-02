import logging
from time import sleep
import traceback
import devops
from devops.model import Environment, Network, Node, Disk, Interface
from devops.helpers import tcp_ping, wait, ssh, http_server, os
from helpers import load
from settings import NODES
from root import root

logger = logging.getLogger('ci')

class Ci:
    def __init__(self, image=None):
        self.base_image = image
        self.environment = None
        self.environment_name = os.environ.get('ENV_NAME', 'recipes')
        try:
            self.environment = devops.load(self.environment_name)
            logger.info("Successfully loaded existing environment")
        except Exception, e:
            logger.info("Failed to load existing recipes environment: " + str(e) + "\n" + traceback.format_exc())
            pass

    def get_environment(self):
        return self.environment

    def add_nmap_yum(self, remote):
        remote.sudo.ssh.execute('yum -y install nmap')

    def add_epel_repo(self, remote):
        remote.sudo.ssh.execute('rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm')

    def add_puppetlab_repo(self, remote):
        remote.sudo.ssh.execute('rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-5.noarch.rpm')

    def setup_puppet_client_yum(self, remote):
        self.add_puppetlab_repo(remote)
        remote.sudo.ssh.execute('yum -y install puppet-2.7.19')

    def start_puppet_master(self, remote):
        remote.sudo.ssh.execute('puppet resource service puppetmaster ensure=running enable=true')

    def start_puppet_agent(self, remote):
        remote.sudo.ssh.execute('puppet resource service puppet ensure=running enable=true')

    def sign_all_node_certificates(self, remote):
        remote.sudo.ssh.execute('puppet cert sign --all')

    def wait_for_certificates(self, remote):
        remote.sudo.ssh.execute('puppet agent --waitforcert 0')

    def switch_off_ip_tables(self, remote):
        remote.sudo.ssh.execute('iptables -F')

    def setup_puppet_master_yum(self, remote):
        self.add_puppetlab_repo(remote)
        remote.sudo.ssh.execute('yum -y install puppet-server-2.7.19 mysql mysql-server mysql-devel rubygems ruby-devel make gcc')
        remote.sudo.ssh.execute('gem install rails -v 3.0.10')
        remote.sudo.ssh.execute('gem install mysql')
        remote.sudo.ssh.execute('chkconfig mysql on')
        remote.sudo.ssh.execute('service mysqld start')
        remote.sudo.ssh.execute('mysql -u root -e "create database puppet; grant all privileges on puppet.* to puppet@localhost identified by \'password\'; "')
        remote.sudo.ssh.execute('gem uninstall activerecord')
        remote.sudo.ssh.execute('gem install activerecord -v 3.0.10')
        remote.sudo.ssh.execute('setenforce 0')


    def change_host_name(self, remote, short, long):
        remote.sudo.ssh.execute('hostname %s' % long)
        self.add_to_hosts(remote, '127.0.0.1', short, short)

    def add_to_hosts(self, remote, ip, short, long):
        remote.sudo.ssh.execute('echo %s %s %s >> /etc/hosts' % (ip, long, short))

    def get_environment_or_create(self):
        if self.get_environment():
            return self.get_environment()
        self.setup_environment()
        return self.environment

    def describe_node(self, name, networks, memory=1024):
        node = Node(name)
        node.memory = memory
        node.vnc = True
        for network in networks:
            node.interfaces.append(Interface(network))
        #        node.bridged_interfaces.append(BridgedInterface('br0'))
        node.disks.append(Disk(base_image=self.base_image, format='qcow2'))
        node.boot = ['disk']
        return node

    def describe_environment(self):
        environment = Environment(self.environment_name)
        internal = Network(name='internal', dhcp_server=True)
        environment.networks.append(internal)
        private = Network(name='private', dhcp_server=False)
        environment.networks.append(private)
        public = Network(name='public', dhcp_server=True)
        environment.networks.append(public)
        master = self.describe_node('master', [internal, private, public])
        environment.nodes.append(master)
        keystone = self.describe_node('keystone', [internal, private, public])
        environment.nodes.append(keystone)
        for node_name in NODES[:2]:
            client = self.describe_node(node_name, [internal, private, public])
            environment.nodes.append(client)
        for node_name in NODES[2:4]:
            client = self.describe_node(
                node_name, [internal, private, public], memory=4096)
            environment.nodes.append(client)
        return environment

    def get_file_as_string(self, path):
        with open(path) as f:
            return f.read()

    def add_nodes_to_hosts(self, remote, nodes):
        for node in nodes:
            self.add_to_hosts(remote, node.ip_address, node.name, node.name)

    def setup_environment(self):
        if not self.base_image:
            raise Exception("Base image path is missing while trying to build recipes environment")

        logger.info("Building recipes environment")
        environment = self.describe_environment()
        self.environment = environment

        #       todo environment should be saved before build
        devops.build(environment)

        devops.save(environment)
        logger.info("Environment has been saved")
        logger.info("Starting test nodes ...")
        for node in environment.nodes:
            node.start()
        for node in environment.nodes:
            logger.info("Waiting ssh... %s" % node.ip_address)
            wait(lambda: tcp_ping(node.ip_address, 22), timeout=1800)
        for node in environment.nodes:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            self.change_host_name(remote, node.name, node.name)
            logger.info("Renamed %s" % node.name)
        master_node = environment.node['master']
        master_remote = ssh(master_node.ip_address, username='root', password='r00tme')
        self.setup_puppet_master_yum(master_remote)
        self.add_nmap_yum(master_remote)
        self.switch_off_ip_tables(master_remote)
        master_config = load(root('fuel', 'fuel_test', 'config', 'puppet.master.config'))
        write_config(master_remote, '/etc/puppet/puppet.conf', master_config)
        self.start_puppet_master(master_remote)
        agent_config = load(root('fuel', 'fuel_test', 'config', 'puppet.agent.config'))
        for node in environment.nodes:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            self.add_nodes_to_hosts(remote, environment.nodes)
            if node.name != 'master':
                self.setup_puppet_client_yum(remote)
                write_config(remote, '/etc/puppet/puppet.conf', agent_config)
                self.wait_for_certificates(remote)
        sleep(5)
        self.sign_all_node_certificates(master_remote)
        sleep(5)
        for node in environment.nodes:
            logger.info("Creating snapshot 'empty'")
            node.save_snapshot('empty')
            logger.info("Test node is ready at %s" % node.ip_address)

    def destroy_environment(self):
        if self.environment:
            devops.destroy(self.environment)

    def configure_repository(self, remote):
        repo = ("[mirantis]\n"
                "name=Mirantis repository\n"
                "baseurl=http://%s:%d\n"
                "enabled=1\n"
                "gpgcheck=0\n") % (
                   self.environment.networks[0].ip_addresses[1],
                   self.repository_server.port)
        write_config(remote,'/etc/yum/repos.d/mirantis.repo', repo)
        remote.execute('yum makecache')

    def start_rpm_repository(self):
        self.repository_server = http_server(
            root("build", "packages", "centos", "Packages")
        )

    def shutdown_rpm_repository(self):
        if hasattr(self, 'repository_server'):
            self.repository_server.stop()

def get_environment_or_create(image=None):
    ci = Ci(image)
    return ci.get_environment_or_create()

def get_environment():
    ci = Ci()
    my_environment = ci.describe_environment()
    my_environment.nodes[0].interfaces[0].ip_addresses = '172.18.8.56'
    return ci.get_environment() or my_environment

def write_config(remote, path, text):
    file = remote.open(path, 'w')
    file.write(text)
    logger.info('Write config %s' % text)
    file.close()

import os

OS_FAMILY = os.environ.get('OS_FAMILY', "centos")
PUPPET_GEN = os.environ.get('PUPPET_GEN', "2")

DEFAULT_IMAGES = {
    'centos': '/var/lib/libvirt/images/centos63-cobbler-base.qcow2',
    'ubuntu': '/var/lib/libvirt/images/ubuntu-12.04.1-server-amd64-base.qcow2',
}

BASE_IMAGE = os.environ.get('BASE_IMAGE', DEFAULT_IMAGES.get(OS_FAMILY))

PUPPET_VERSIONS = {
    'centos': {
        "2": '2.7.19-1.el6',
        "3": '3.0.1-1.el6',
    },
    'ubuntu': {
        "2": '2.7.19-1puppetlabs1',
        "3": '3.0.1-1puppetlabs1'
    },
}

PUPPET_VERSION = PUPPET_VERSIONS.get(OS_FAMILY).get(PUPPET_GEN)

PUPPET_CLIENT_PACKAGES = {
    'centos': {
        "2": 'puppet-2.7.19-1.el6',
        "3": 'puppet-3.0.1-1.el6',
    },
    'ubuntu': {
        "2": 'puppet=2.7.19-1puppetlabs1 puppet-common=2.7.19-1puppetlabs1',
        "3": 'puppet=3.0.1-1puppetlabs1 puppet-common=3.0.1-1puppetlabs1'
    },
}

PUPPET_CLIENT_PACKAGE = PUPPET_CLIENT_PACKAGES.get(OS_FAMILY).get(PUPPET_GEN)

ERROR_PREFIXES = {
    "2": "err: ",
    "3": "Error: ",
}

ERROR_PREFIX = ERROR_PREFIXES.get(PUPPET_GEN)

WARNING_PREFIXES = {
    "2": "warning: ",
    "3": "Warning: ",
}

WARNING_PREFIX = WARNING_PREFIXES.get(PUPPET_GEN)

PUPPET_MASTER_SERVICE = 'thin'

ADMIN_USERNAME = 'admin'
ADMIN_PASSWORD = 'nova'
ADMIN_TENANT_ESSEX = 'openstack'
ADMIN_TENANT_FOLSOM = 'admin'

CIRROS_IMAGE ='http://srv08-srt.srt.mirantis.net/cirros-0.3.0-x86_64-disk.img'
COBBLER_CONTROLLERS = int(os.environ.get('COBBLER_CONTROLLERS', 2))
COBBLER_COMPUTES = int(os.environ.get('COBBLER_COMPUTES', 2))


EMPTY_SNAPSHOT = os.environ.get('EMPTY_SNAPSHOT', 'empty')
OPENSTACK_SNAPSHOT = os.environ.get('OPENSTACK_SNAPSHOT', 'openstack')
PUBLIC_INTERFACE='eth0'
INTERNAL_INTERFACE = 'eth1'
PRIVATE_INTERFACE = 'eth2'

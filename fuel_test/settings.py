import os

BASE_IMAGE = os.environ.get('BASE_IMAGE',
    '/var/lib/libvirt/images/vgalkin_centos-base.qcow2')
OS_FAMILY = os.environ.get('OS_FAMILY', "centos")
PUPPET_GEN = os.environ.get('PUPPET_GEN', "2")

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


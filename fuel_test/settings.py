import os

BASE_IMAGE = os.environ.get('BASE_IMAGE',
    '/var/lib/libvirt/images/vgalkin_centos-base.qcow2')
OS_FAMILY = os.environ.get('OS_FAMILY', "centos")

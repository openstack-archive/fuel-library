#
# TODO - this is being deprecated
#
class keystone::repo::trunk {
  # update this to use adams repo which may require an upgrade to precise
  apt::ppa { 'ppa:openstack-ubuntu-testing/openstack-trunk-testing': }
}

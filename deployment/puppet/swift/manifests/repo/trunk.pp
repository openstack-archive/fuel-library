#
# sets up the swift trunk ppa
#
class swift::repo::trunk {
  apt::ppa { 'ppa:openstack-ubuntu-testing/openstack-trunk-testing': }
}

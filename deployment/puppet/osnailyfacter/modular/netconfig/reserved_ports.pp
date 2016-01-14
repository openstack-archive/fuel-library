notice('MODULAR: reserved_ports.pp')

# setting kernel reserved ports
# defaults are 49000,49001,35357,41055,41056,58882
class { 'openstack::reserved_ports': }


class firewall {

  case $::osfamily {
    'RedHat': {
      firewall::allow {[
          22,     # ssh
          80,     # http
          3306,   # mysql
          4567,   # mysql/galera
          5000,   # keystone/public
          35357,  # keystone/admin
          9292,   # glance/api
          9191,   # glance/reg
          8773,   # nova/api/ec2
          8774,   # nova/api/compute
          8775,   # nova/api/metadata
          8776,   # nova/api/volume
          6080,   # nova/vncproxy
          4369,   # erlang/epmd
          5672,   # erlang/rabbitmq
          11211,  # memcached
      ]: }
     }
     default: {
       warning("Unsupported platform: ${::operatingsystem}")
     }
  }

}

# With this define, we can configure a whole MMM cluster at once. The different
# machines will have this define assigned to them by the rest of the mmm and
# s_mmm module.
# This define supports multiple clusters on the same MMM monitor node

# ensure           => 'present',
#   currently only 'present' is supported
# cluster_interface    => "eth0:1",
#  the interface on which the mmm communication with nodes takes place
# replication_user     => "repl",
# replication_password => "my_pass",
#   mysql replication user and password
# agent_user           => "mmm_agent",
# agent_pass           => "my_pass",
#   credentials used for mmm agent
# monitor_user         => "mmm_monitor",
# monitor_pass         => "my_pass",
#   credentials used for mmm monitor
# monitor_ip           => '127.0.0.1',
#   IP on which monitor runs from perspective of monitor config, almost always 127.0.0.1
# masters              => [['master01','192.168.159.x', 'master02'], ['master02', '192.168.159.y', 'master01']],
#   two-dimensional array of masters, their physical ip and peer ip
# slaves            => [['slave01', '192.168.159.z'], ['slave02', '192.168.159.za']],
#   two-dimensional array of slaves and their physical ips
# readers          => ['master01', 'master02', 'slave01', 'slave02'],
#   list of nodes that can have reader roles
# writer_virtual_ip    => '192.168.159.xx',
#   the virtual ip used for the writer
# reader_virtual_ips   => ['192.168.159.yy','192.168.159.zz',..]
#   the virtual ip used for the readers
# localsubnet          => '192.168.159.%'.
#   the hostname or net, in mysql format, indicating where database connection can orginate from
# reader_user
#   the reader user used by the application. This user is created
# reader_pass
#   the password for the reader user
# writer_user
#   the writer user used by the application. This user is created
# writer_pass
#   the password for the writer user
# mmm_type
#   'agent' or 'monitor'
define mmm::cluster::config($ensure, $cluster_interface, $cluster_name = '', $port = '9988', $replication_user,
  $replication_password, $agent_user, $agent_password, $monitor_user,
  $monitor_password, $monitor_ip, $masters, $slaves = [], $readers = [],
  $writer_virtual_ip, $reader_virtual_ips = [], $localsubnet,
  $reader_user = '', $reader_pass = '', $writer_user, $writer_pass, $mmm_type,
  $server_id = '', $num_servers = '', $peer = '') {

  include mmm::params

  # $ipaddresses is a custom fact, defined in the mmm module. It greps ifconfig
  # and lists all ipaddresses in a semi-colon separated list
  $ipadd_array = split($::ipaddresses, ';')

  # bad way to get the mmm::common::config to create a non-renamed config
  # file when this is an agent node (on an agent node there is no need to be
  # aware of multiple clusters as an agent is always only part of one cluster)
  if $mmm_type == 'agent' {
    $real_cluster_name = ''
  } else {
    $real_cluster_name = $cluster_name
  }

  # This takes care of the configuration part for mmm::common. Note that this
  # has been separated from the class that installs mmm::common, since when
  # there are multiple clusters this define is called multiple times, and
  # pupept doesnt allow to specify resources multiple times
  mmm::common::config{ $name:
    replication_user     => $replication_user,
    replication_password => $replication_password,
    agent_user           => $agent_user,
    agent_password       => $agent_password ,
    cluster_interface    => $cluster_interface,
    cluster_name         => $real_cluster_name,
    masters              => $masters,
    slaves               => $slaves,
    readers              => $readers,
    writer_virtual_ip    => $writer_virtual_ip,
    reader_virtual_ips   => $reader_virtual_ips,
  }

  case $mmm_type {
    'agent': {
      mmm::agent::config{ $name:
        localsubnet          => $localsubnet,
        replication_user     => $replication_user,
        replication_password => $replication_password,
        agent_user           => $agent_user,
        agent_password       => $agent_password,
        monitor_user         => $monitor_user,
        monitor_password     => $monitor_password,
        reader_user          => $reader_user,
        reader_pass          => $reader_pass,
        writer_user          => $writer_user,
        writer_pass          => $writer_pass,
        writer_virtual_ip    => $writer_virtual_ip,
        reader_virtual_ips   => $reader_virtual_ips,
        server_id            => $server_id,
        num_servers          => $num_servers,
        peer                 => $peer,
      }
      include mmm::agent
    }
    'monitor': {
      mmm::monitor::config{ $name:
        port                 => $port,
        cluster_name         => $real_cluster_name,
        monitor_ip           => $monitor_ip,
        masters              => $masters,
        slaves               => $slaves,
        monitor_user         => $monitor_user,
        monitor_password     => $monitor_password,
      }
      include mmm::monitor
    }
    default: { err("No ${mmm_type} defined for this node") }
  }

}

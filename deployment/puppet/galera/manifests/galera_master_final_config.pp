# == Define: galera_master_final_config 
#
# Class for final configuring of galera master node.
#
# === Parameters
#
# [*primary_controller*]
#  Set to true if the node is primary controller/master of galera cluster.   
# [*node_addresses*]
#   Array of galera cluster node members IPs/hostnames.
#
# [*node_address*]
#   Name of the node used in galera cluster config. Can be IP/hostname.
#
# === Authors
#
# Mirantis Inc. <product@mirantis.com>
#
# === Copyright
#
# FIXME: Insert copyrights and licenses
#

class galera::galera_master_final_config ($primary_controller, $node_addresses, $node_address) {

  if $primary_controller {
    $galera_gcomm_string = inline_template("<%= @node_addresses.reject{|ip| ip == hostname || ip == @node_address || ip == l3_fqdn_hostname }.collect {|ip| ip + ':' + 4567.to_s }.join ',' %>"
    )
    $check_galera = "show status like 'wsrep_cluster_size';"
    $mysql_user = $::galera::params::mysql_user
    $mysql_password = $::galera::params::mysql_password

    exec { "first-galera-node-final-config":
      path      => "/usr/bin:/usr/sbin:/bin:/sbin",
      command   => "sed -i 's/wsrep_cluster_address=\"gcomm:\\/\\/\"\$/wsrep_cluster_address=\"gcomm:\\/\\/${galera_gcomm_string}\"/' /etc/mysql/conf.d/wsrep.cnf; sleep 15",
      onlyif    => "sleep 15; mysql -u${mysql_user} -p${mysql_password} -e \"${check_galera}\" && (mysql -u${mysql_user} -p${mysql_password} -e \"${check_galera}\" | awk '\$1 == \"wsrep_cluster_size\" {print \$2}' | awk '{if (\$0 > 1) exit 0; else exit 1}')",
      logoutput => true,
    }
  }
}


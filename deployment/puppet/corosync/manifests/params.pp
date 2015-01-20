class corosync::params {
  $enable_secauth    = true
  $authkey_source    = 'file'
  $authkey           = '/etc/puppet/ssl/certs/ca.pem'
  $threads           = $::processorcount
  $port              = '5405'
  $bind_address      = $::ipaddress
  $multicast_address = 'UNSET'
  $unicast_addresses = 'UNSET'
  $force_online      = false
  $check_standby     = false
  $debug             = false
  $rrp_mode          = 'none'
  $ttl               = false
  $packages          = ['corosync', 'pacemaker']
}

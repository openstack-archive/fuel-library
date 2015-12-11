# see http://tech.serbinn.net/2012/custom-script-on-interface-up-down-centos-and-rhel/
class l23network::l2::centos_upndown_scripts {
  file {'/sbin/ifup-local':
    ensure  => present,
    owner   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/l23network/centos_ifup-local',
  } ->
  file {'/sbin/ifdown-local':
    ensure  => present,
    owner   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/l23network/centos_ifdown-local',
  } ->
  file {'/sbin/ifup-pre-local':
    ensure  => present,
    owner   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/l23network/centos_ifup-pre-local',
  } ->
  anchor { 'l23network::l2::centos_upndown_scripts': }
}

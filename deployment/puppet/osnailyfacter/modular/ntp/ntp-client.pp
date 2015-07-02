notice('MODULAR: ntp-client.pp')

$management_vrouter_vip  = hiera('management_vrouter_vip')
$nodes_hash              = hiera('nodes', {})
$roles                   = node_roles($nodes_hash, hiera('uid'))

if !(member($roles, 'controller') or member($roles, 'primary-controller')) {
  class { 'ntp':
    servers        => [$management_vrouter_vip],
    interfaces     => ['lo'],
    service_ensure => running,
    service_enable => true,
    iburst_enable  => true,
    tinker         => true,
    panic          => 0,
    stepout        => 5,
    minpoll        => 3,
  }
}

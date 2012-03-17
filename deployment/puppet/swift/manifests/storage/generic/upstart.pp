# TODO this should be removed when the upstart packages are fixed.
define swift::storage::generic::upstart() {
  file { "/etc/init/swift-${name}.conf":
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    source => "puppet:///modules/swift/swift-${name}.conf.upstart",
    before => Service["swift-${name}"],
  }
}

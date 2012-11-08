class { 'nova': }
class { 'nova::volume': 
  enabled => true,
}
class {'nova::volume::iscsi': }

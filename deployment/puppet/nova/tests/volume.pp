class { 'nova': }

class { 'nova::volume': 
  enabled => true,
}

define osnailyfacter::apache_port {
  apache::listen { $name: }
  apache::namevirtualhost { "*:${name}": }
}


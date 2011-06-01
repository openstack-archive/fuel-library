class nova::controller (
   
) {

  class { 'nova': }

  class { 'nova::api': }

  class { 'nova::scheduler': }

  class { 'nova::network': }
}

class nova::controller (
   
) {

  class { 'nova::api': }

  class { 'nova::scheduler': }

  class { 'nova::network': }
}

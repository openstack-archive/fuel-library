class mmm::common {
  
  include mmm::params

  package { 'mysql-mmm-common':
    ensure => 'present'
  }

}
class puppet::mongrel(
  $puppet_master_ports = $puppet::params::puppet_master_ports
) inherits puppet::params
{
  
  package {  $puppet::params::mongrel_packages: ensure=>"installed"}

	file { $puppet::params::daemon_config_file:
	    content => template($puppet::params::daemon_config_template),
	    owner => 'root',
	    group => 'root',
	    mode => 0644,
	    require => [
	       Package[$puppet::params::puppet_master_packages],
	       Exec["puppetmaster_stopped"],
	    ],
	    notify => Service["puppetmaster"],
  }
  
}
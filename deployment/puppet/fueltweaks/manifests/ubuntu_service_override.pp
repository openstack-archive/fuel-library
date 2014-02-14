define fueltweaks::ubuntu_service_override ($service_name = $name, $package_name = $name )

{
   file { "/etc/init/${service_name}.override":
      replace => 'no',
      ensure  => 'present',
      content => 'manual',
      mode    => '0644',
    } -> Package["$package_name"]
    Package["$package_name"] ->
    exec { "rm-${service_name}-override":
      path      => '/sbin:/bin:/usr/bin:/usr/sbin',
      command   => "rm -f /etc/init/${service_name}.override",
    }
}

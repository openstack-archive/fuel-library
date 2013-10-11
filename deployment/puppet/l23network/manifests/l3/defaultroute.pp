# == Define: l23network::l3::defaultroute
#
# Do not use this directly,
# use l23network::l3::route instead
#
define l23network::l3::defaultroute (
    $gateway = $name,
    $metric  = undef,
){
  case $::osfamily {
    /(?i)debian/: {
        exec {'Default route':
            path    => '/bin:/usr/bin:/sbin:/usr/sbin',
            command => "ip route replace default via ${gateway} || true",
            unless  => "netstat -r | grep -q 'default.*${gateway}'",
        }
    }
    /(?i)redhat/: {
        if ! defined(Cfg[$gateway]) {
          cfg { $gateway:
              file  => '/etc/sysconfig/network',
              key   => 'GATEWAY',
              value => $gateway,
          } ->
          # FIXME: we should not nuke the system with 'service network restart'...
          # FIXME: but we should ensure default route will be created somehow
          exec {'Default route':
              path    => '/bin:/usr/bin:/sbin:/usr/sbin',
              command => "ip route replace default via ${gateway} || true",
              unless  => "netstat -r | grep -q 'default.*${gateway}'",
          }
        }
    }
    default: {
        fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

}
#
###

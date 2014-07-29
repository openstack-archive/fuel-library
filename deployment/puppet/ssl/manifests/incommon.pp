# == Define: incommon
#
# Installs an incommon certificate
#
# === Parameters:
# [*id*]
#  InCommon certificate ID number, provided in the email notifying us
#  that its ready 
# [*cn*]
#  Certificate Common Name.  If it doesn't match an ssl::cert entry with the
#  same CN, this will fail non-destructively.
#
# === Notes:
# This code only executes if an id is provided, otherwise, the code is skipped.
# When an $id is provide, this will go out and download url with $id embedded in
# it.  If the resulting file appears to be a certificate file, it will mv the
# certificate into place and place a lock to prevent unnecessary curl calls.
# Otherwise, it'll try again the next time puppet runs, until it gets a cert.
#
define ssl::incommon (
  $id = '',
  $cn = $name
) {
  validate_re( $id, '^([0-9]+|)$' )
  include ssl::params

  file { '/usr/local/sbin/check-incommon-cert':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0550',
    source => 'puppet:///ssl/check-incommon-cert.sh',
  }

  # Only try to obtain the cert if we have an id
  if $id != "" {
    $url = "https://cert-manager.com/customer/InCommon/ssl?action=download&sslId=${id}"
    $format_x509 = "&format=x509CO"
    $format_int = "&format=x509IO"
    $url_x509 = shellquote( "${url}${format_x509}" )
    $url_int = shellquote( "${url}${format_int}" )
    $grab_int = "curl -q --silent ${url_int} -o ${ssl::params::crt_dir}/intermediate.crt"
    $grab_x509 =  "mv -f ${ssl::params::crt_dir}/meta/${cn}.crt.tmp ${ssl::params::crt_dir}/${cn}.crt; 
                   touch ${ssl::params::crt_dir}/meta/${cn}.lock" 

    # check if the cert is ready
    exec { "get-cert-${cn}":
      command => $grab_x509,
      onlyif  => "/usr/local/sbin/check-incommon-cert ${id} ${ssl::params::crt_dir} ${cn}",
      path    => [ '/bin', '/usr/bin' ],
      require => File['/usr/local/sbin/check-incommon-cert'],
    }

    # grab our intermediate cert
    exec { "get-int-${cn}":
      creates  => "${ssl::params::crt_dir}/intermediate.crt",
      command  => $grab_int,
      path     => [ '/bin', '/usr/bin' ],
    }
  }
}

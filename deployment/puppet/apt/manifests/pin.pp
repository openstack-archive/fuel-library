# pin.pp
# pin a release in apt, useful for unstable repositories

define apt::pin(
  $ensure     = present,
  $packages   = '*',
  $priority   = 0,
  $release    = '',
  $origin     = '',
  $originator = '',
  $version    = '',
  $order ='',
  $releasecustom = ''
) {

  include apt::params

  $preferences_d = $apt::params::preferences_d
  if $releasecustom != '' {
    $pin = "release $releasecustom"
  }
  elsif $release != '' {
    $pin = "release a=${release}"
  } elsif $origin != '' {
    $pin = "origin \"${origin}\""
  } elsif $originator != '' {
    $pin = "release o=${originator}"
  } elsif $version != ''
  {
    $pin = "version ${version}"
  }
  else {
    $pin = "release a=${name}"
  }

  $path = $order ? {
    '' => "${preferences_d}/${name}.pref",
    default => "${preferences_d}/${order}-${name}.pref",
  }

  file { "${name}.pref":
    ensure  => $ensure,
    path    => $path,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("apt/pin.pref.erb"),
  }
}

# == Define: apt::key
#
# The apt::key defined type allows for keys to be added to apt's keyring
# which is used for package validation. This defined type uses the apt_key
# native type to manage keys. This is a simple wrapper around apt_key with
# a few safeguards in place.
#
# === Parameters
#
# [*id*]
#   _default_: +$title+, the title/name of the resource
#
#   Is a GPG key ID or full key fingerprint. This value is validated with
#   a regex enforcing it to only contain valid hexadecimal characters, be
#   precisely 8 or 16 hexadecimal characters long and optionally prefixed
#   with 0x for key IDs, or 40 hexadecimal characters long for key
#   fingerprints.
#
# [*ensure*]
#   _default_: +present+
#
#   The state we want this key in, may be either one of:
#   * +present+
#   * +absent+
#
# [*content*]
#   _default_: +undef+
#
#   This parameter can be used to pass in a GPG key as a
#   string in case it cannot be fetched from a remote location
#   and using a file resource is for other reasons inconvenient.
#
# [*source*]
#   _default_: +undef+
#
#   This parameter can be used to pass in the location of a GPG
#   key. This URI can take the form of a:
#   * +URL+: ftp, http or https
#   * +path+: absolute path to a file on the target system.
#
# [*server*]
#   _default_: +undef+
#
#   The keyserver from where to fetch our GPG key. It can either be a domain
#   name or url. It defaults to +keyserver.ubuntu.com+.
#
# [*options*]
#   _default_: +undef+
#
#   Additional options to pass on to `apt-key adv --keyserver-options`.
define apt::key (
  $id      = $title,
  $ensure  = present,
  $content = undef,
  $source  = undef,
  $server  = $::apt::keyserver,
  $options = undef,
) {

  validate_re($id, ['\A(0x)?[0-9a-fA-F]{8}\Z', '\A(0x)?[0-9a-fA-F]{16}\Z', '\A(0x)?[0-9a-fA-F]{40}\Z'])
  validate_re($ensure, ['\Aabsent|present\Z',])

  if $content {
    validate_string($content)
  }

  if $source {
    validate_re($source, ['\Ahttps?:\/\/', '\Aftp:\/\/', '\A\/\w+'])
  }

  if $server {
    validate_re($server,['\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$'])
  }

  if $options {
    validate_string($options)
  }

  case $ensure {
    present: {
      if defined(Anchor["apt_key ${id} absent"]){
        fail("key with id ${id} already ensured as absent")
      }

      if !defined(Anchor["apt_key ${id} present"]) {
        apt_key { $title:
          ensure  => $ensure,
          id      => $id,
          source  => $source,
          content => $content,
          server  => $server,
          options => $options,
        } ->
        anchor { "apt_key ${id} present": }
      }
    }

    absent: {
      if defined(Anchor["apt_key ${id} present"]){
        fail("key with id ${id} already ensured as present")
      }

      if !defined(Anchor["apt_key ${id} absent"]){
        apt_key { $title:
          ensure  => $ensure,
          id      => $id,
          source  => $source,
          content => $content,
          server  => $server,
          options => $options,
        } ->
        anchor { "apt_key ${id} absent": }
      }
    }

    default: {
      fail "Invalid 'ensure' value '${ensure}' for apt::key"
    }
  }
}

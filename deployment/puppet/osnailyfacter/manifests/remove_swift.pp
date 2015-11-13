# A workaround to remove badly packaged swift-object
# that prevents other swift packages from upgrading
class osnailyfacter::remove_swift {
  if $::osfamily == 'Debian' {
    exec { 'remove-swift-object' :
      command   => '/usr/bin/dpkg -r --force-all swift swift-account swift-object swift-container',
      onlyif    => "/usr/bin/test \"$(/usr/bin/dpkg-query --show -f='${Status}|${Version}' swift-object)\" == 'install ok installed|1.13.1.fuel5.0~mira1'",
      logoutput => 'on_failure',
    }
    Exec['remove-swift-object'] -> Package <| title == 'swift' |>
    Exec['remove-swift-object'] -> Package <| title == 'swift-account' |>
    Exec['remove-swift-object'] -> Package <| title == 'swift-object' |>
    Exec['remove-swift-object'] -> Package <| title == 'swift-container' |>
  }
}

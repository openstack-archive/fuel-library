# == Define: osnailyfacter::dependency_package
#
# Create/override definition of Openstack dependency package.
# Mark it with the given tag to simplify collection.
#
define osnailyfacter::dependency_package(
  $ensure = latest,
  $tag    = 'openstack-dependency',
){
  if !defined(Package[$title]) {
    package { $title :
      ensure => $ensure,
      tag    => $tag,
    }
  } else {
    Package <| title == $title |> {
      ensure => $ensure,
      tag    => $tag,
    }
  }
}

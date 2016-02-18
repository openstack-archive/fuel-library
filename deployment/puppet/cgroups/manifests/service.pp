#
class cgroups::service {

  service {
    'cgroup-lite':
       ensure  => running,
       enable  => true,
       name    => 'cgroup-lite',
       require => Package['cgroup-bin'],
       notify  => Exec['parser'];
     'cgrulesengd':
       ensure  => running,
       name    => 'cgrulesengd',
       require => File['cgrules.conf'];
   }
}

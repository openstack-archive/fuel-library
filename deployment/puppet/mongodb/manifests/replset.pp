# This installs a MongoDB replica set configuration tool
# foe now works only winhout auth
class mongodb::replset (
  $replset_setup         = $mongodb::params::replset_setup,
  $replset_members       = undef,

) inherits mongodb::params {

  if ($replset_setup  == true) {
    anchor { 'before-mongodb-replset' :}
    ->
    class { 'mongodb::replset::install': 
      require  => Class['mongodb::server', 'mongodb::client'],
    }
    ->
    anchor { 'after-mongodb-replset' :}
  }

}

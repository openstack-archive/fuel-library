$stompuser="mcollective"
$stomppassword="AeN5mi5thahz2Aiveexo"
$pskey="un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi"
$stomphost="127.0.0.1"
$stompport="61613"

stage { 'puppetlabs-repo': before => Stage['main'] }
class { 'openstack::puppetlabs_repos': stage => 'puppetlabs-repo'}

node /fuel-mcollective.mirantis.com/ {

  class { mcollective::rabbitmq:
    stompuser => $stompuser,
    stomppassword => $stomppassword,
  }

  class { mcollective::client:
    pskey => $pskey,
    stompuser => $stompuser,
    stomppassword => $stomppassword,
    stomphost => $stomphost,
    stompport => $stompport
  }

}

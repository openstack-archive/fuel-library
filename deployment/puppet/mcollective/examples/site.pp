$stompuser="mcollective"
$stomppassword="AeN5mi5thahz2Aiveexo"
$pskey="un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi"
$stomphost="127.0.0.1"
$stompport="61613"
$mirror_type="external"

stage { 'puppetlabs-repo': before => Stage['main'] }
class { 'openstack::puppetlabs_repos': stage => 'puppetlabs-repo'}
class { 'openstack::mirantis_repos':
  stage => 'puppetlabs-repo',
  type=>$mirror_type,
  disable_puppet_labs_repos => false,
}

node /fuel-mcollective.your-domain-name.com/ {

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
  
  include ntpd

}

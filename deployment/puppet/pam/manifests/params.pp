# == Class: pam::params
#
class pam::params {

  case $::osfamily {

    'Debian' : {
      $packages    = [ 'libpam-ldap' ]
      $prefix_pamd = '/etc/pam.d'
      $owner       = 'root'
      $group       = 'root'

      $package_pam_ldap      = 'libpam-ldap'
      $pam_ldap_account      = '[default=bad success=ok user_unknown=ignore] pam_ldap.so'
      $pam_ldap_auth         = 'sufficient    pam_ldap.so use_first_pass'
      $pam_ldap_password     = 'sufficient    pam_ldap.so use_authtok'
      $pam_ldap_session      = 'optional      pam_ldap.so'

      $pam_ldapd_account     = false
      $pam_ldapd_auth        = false
      $pam_ldapd_password    = false
      $pam_ldapd_session     = false

      $ldap_conf             = '/etc/ldap/ldap.conf'

      $pam_tally_account     = 'required      pam_tally.so'
      $pam_tally_auth        = 'required      pam_tally.so deny=3 onerr=fail'

      $pam_tally2_account    = 'required      pam_tally2.so'
      $pam_tally2_auth       = 'required      pam_tally2.so deny=3 onerr=fail unlock_time=60'

      $pam_cracklib_password = 'requisite     pam_cracklib.so try_first_pass retry=3 minlen=9 dcredit=-1'

      $pam_mkhomedir_session = 'requisite     pam_mkhomedir.so skel=/etc/skel/ umask=0022'

    }

    'Redhat' : {
      $packages    = [ 'pam' ]
      $prefix_pamd = '/etc/pam.d'
      $owner       = 'root'
      $group       = 'root'

      case $::operatingsystemmajrelease {
        5 : {
          $package_pam_ldap = 'nss_ldap'
        }

        6 : {
          $package_pam_ldap = 'nss-pam-ldapd'
        }
      
        default : {
          notice("${::operatingsystem} version ${::operatingsystemmajrelease} not handled")
        }
      }

      $pam_ldap_account      = '[default=bad success=ok user_unknown=ignore] pam_ldap.so'
      $pam_ldap_auth         = 'sufficient    pam_ldap.so use_first_pass'
      $pam_ldap_password     = 'sufficient    pam_ldap.so use_authtok'
      $pam_ldap_session      = 'optional      pam_ldap.so'

      $pam_ldapd_account     = false
      $pam_ldapd_auth        = false
      $pam_ldapd_password    = false
      $pam_ldapd_session     = false

      $ldap_conf             = '/etc/openldap/ldap.conf'

      $pam_tally_account     = 'required      pam_tally.so'
      $pam_tally_auth        = 'required      pam_tally.so deny=3 onerr=fail'

      $pam_tally2_account    = 'required      pam_tally2.so'
      $pam_tally2_auth       = 'required      pam_tally2.so deny=3 onerr=fail unlock_time=60'

      $pam_cracklib_password = 'requisite     pam_cracklib.so try_first_pass retry=3 minlen=9 dcredit=-1'

      $pam_mkhomedir_session = 'requisite     pam_mkhomedir.so skel=/etc/skel/ umask=0022'

    }

    'Suse' : {
      $packages    = [ 'pam' ]
      $prefix_pamd = '/etc/pam.d'
      $owner       = 'root'
      $group       = 'root'

      $package_pam_ldap      = 'pam_ldap'
      $pam_ldap_account      = '[default=bad success=ok user_unknown=ignore] pam_ldap.so'
      $pam_ldap_auth         = 'sufficient    pam_ldap.so use_first_pass'
      $pam_ldap_password     = 'sufficient    pam_ldap.so use_authtok'
      $pam_ldap_session      = 'optional      pam_ldap.so'

      $pam_ldapd_account     = false
      $pam_ldapd_auth        = false
      $pam_ldapd_password    = false
      $pam_ldapd_session     = false

      $ldap_conf             = '/etc/openldap/ldap.conf'

      $pam_tally_account     = 'required      pam_tally.so'
      $pam_tally_auth        = 'required      pam_tally.so deny=3 onerr=fail'

      $pam_tally2_account    = 'required      pam_tally2.so'
      $pam_tally2_auth       = 'required      pam_tally2.so deny=3 onerr=fail unlock_time=60'

      $pam_cracklib_password = 'requisite     pam_cracklib.so try_first_pass retry=3 minlen=9 dcredit=-1'

      $pam_mkhomedir_session = 'requisite     pam_mkhomedir.so skel=/etc/skel/ umask=0022'

    }

    default: {
      fail("Operating system ${::operatingsystem} (${::osfamily}) not supported")
    }

  }

}

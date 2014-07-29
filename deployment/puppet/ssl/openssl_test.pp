#notify { "**** add pam_tally2 start:*****": }
#
#class { 'pam' : }
#
#class { 'pam::pamd' :
#  pam_tally2            => true,
#  pam_tally2_account    => 'required      pam_tally2.so',
#  pam_tally2_auth       => 'required      pam_tally2.so  file=/var/log/tallylog deny=3 even_deny_root unlock_time=300',
#}
#notify { "***** add pam_tally2 end:*****": }
#
include ssl

ssl::cert { 'www.example.com':
  alt_names => [ 'www2.example.com' ],
  country   => 'US',
  org       => 'Example.com, LLC',
  org_unit  => 'Web Team',
  state     => 'CA',
  city      => 'KH',
}

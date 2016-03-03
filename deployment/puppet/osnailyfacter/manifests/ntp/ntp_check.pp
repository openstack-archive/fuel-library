class osnailyfacter::ntp::ntp_check {

  notice('MODULAR: ntp/ntp_check.pp')
  # get the ntp configuration from hiera
  $ntp_servers = hiera('external_ntp')

  # take the comma seperated list and turn it into an array of servers and then
  # pass it to the ntp_available function to check that at least 1 server works
  if is_array($ntp_servers['ntp_list']) {
    $external_ntp = $ntp_servers['ntp_list']
  } else {
    $external_ntp = strip(split($ntp_servers['ntp_list'], ','))
  }
  ntp_available($external_ntp)

}

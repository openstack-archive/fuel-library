notice('MODULAR: ntp-check.pp')
# get the ntp configuration from hiera
$ntp_servers = hiera('external_ntp')
# take the comma seperated list and turn it into an array of servers and then
# pass it to the ntp_available function to check that at least 1 server works
ntp_available(strip(split($ntp_servers['ntp_list'], ',')))

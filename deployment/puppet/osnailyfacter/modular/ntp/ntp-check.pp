notice('MODULAR: ntp-check.pp')

$ntp_servers = hiera('external_ntp')

ntp_available(strip(split($ntp_servers['ntp_list'], ',')))

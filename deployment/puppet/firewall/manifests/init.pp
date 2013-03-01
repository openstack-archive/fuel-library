# Class: firewall
#
# This module manages firewall
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class firewall (
  $port   = '5432',
  $chain  = 'INPUT',
  $action = 'accept',
  $proto  = 'tcp',
  $dport  = $title,
  $table  = 'filter',) {
}

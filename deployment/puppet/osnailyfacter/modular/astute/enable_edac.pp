require 'camptocamp-kmod'
notice('MODULAR: enable_edac.pp')

kmod::load { 'edac_core' }

$check_pci_errors_file = '/sys/devices/system/edac/pci/check_pci_errors'

exec { 'enable_check_pci_errors':
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    command => "echo "1" > '${check_pci_errors_file}'",
    only_if => "test -e '${check_pci_errors_file}'"
}

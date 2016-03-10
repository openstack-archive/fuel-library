notice('MODULAR: sriov_iommu_check.pp')
# TODO: (adidenko) Remove this puppet wrapper aroung exec and move task into
# plain "shell" type when role-based deployment is deprecated or at least
# "shell" tasks are allowed in "deploy" stage
$script = '/etc/puppet/modules/osnailyfacter/modular/netconfig/sriov_iommu_check.rb'

exec {"sriov_iommu_check":
  command => "ruby $script",
  path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin']
}

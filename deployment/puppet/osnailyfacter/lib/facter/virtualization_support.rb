require 'facter'

Facter.add(:virtualization_support) do
  setcode do
    support = "false"
    if File.exists?('/proc/cpuinfo')
      cpuinfo = open('/proc/cpuinfo').read
      if cpuinfo.match(/(vmx|svm)/)
        support = "true"
      end
    end
    support
  end
end

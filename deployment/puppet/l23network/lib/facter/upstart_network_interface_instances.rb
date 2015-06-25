
# This fact collects interfaces for which network-interface job is started
require 'facter'
Facter.add(:upstart_network_interface_instances) do
  setcode do
    interface_regxp = /^network-interface\s+\((\w+.*)\)\s+start\/running$/
    interfaces = []
    # Check if it is Upstart
    if File.exists?('/sbin/initctl')
      upstart_job_list = Facter::Util::Resolution.exec("initctl list")
    else
      interfaces
      exit
    end
    upstart_job_list.split("\n").each do |job|
      if job.match(/^network-interface\s+\(\w+.*\)\s+start\/running$/)
#      p "Job #{job}"
        interface = job.match(interface_regxp).captures[0]
#        p "Interface #{interface}"
        interfaces << interface
      end
    end
    interfaces.join(',')
  end
end


Facter.add("nova_compute") do

	setcode do

		File.exists? '/etc/nova/nova-compute.conf'

	end

end

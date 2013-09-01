Facter.add("keystone_conf") do

	setcode do

		File.exists? '/etc/keystone/keystone.conf'

	end

end

Facter.add("glance_api_conf") do

	setcode do

		File.exists? '/etc/glance/glance-api.conf'

	end

end

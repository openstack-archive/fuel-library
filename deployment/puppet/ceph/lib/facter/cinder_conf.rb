Facter.add("cinder_conf") do

	setcode do

		File.exists? '/etc/cinder/cinder.conf'

	end

end

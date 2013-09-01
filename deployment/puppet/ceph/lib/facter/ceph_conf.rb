Facter.add("ceph_conf") do

	setcode do

		File.exists? '/etc/ceph/ceph.conf'

	end

end

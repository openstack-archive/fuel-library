Facter.add(:mountpoints) do
	confine :kernel => :linux
	setcode do
		mountpoints = []
		if FileTest.exists?("/proc/mounts")
			File.readlines("/proc/mounts").each do |str|
				if str =~ /(ext2|ext3|ext4|reiserfs|xfs)/
					mountpoints.push(str.split(/ /)[1])
				end
			end
		end
		mountpoints.join(",")
	end
end

Facter.add(:disks) do
	confine :kernel => :linux
	setcode do
		disks = []
		if FileTest.exists?("/proc/partitions")
			File.readlines("/proc/partitions").each do |str|
				if str =~ (/(hd|sd).$/)
					disks.push(str.split(/\s+/)[4])
				end
			end
		end
		disks.join(",")
	end
end

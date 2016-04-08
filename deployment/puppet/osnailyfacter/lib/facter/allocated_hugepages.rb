# This fact returns a hash with numbers of allocated 1G and 2M huge pages
# Currently Nailgun doesn't provide this informaion due to LP #1560532

hugepages = {}
hugepages_path_1G = '/sys/kernel/mm/hugepages/hugepages-1048576kB'
hugepages_path_2M = '/sys/kernel/mm/hugepages/hugepages-2048kB'

if File.exists? hugepages_path_1G
  hugepages['1G'] = File.open("#{hugepages_path_1G}/nr_hugepages").read.strip.to_i
else
  hugepages['1G'] = 0
end

if File.exists? hugepages_path_2M
  hugepages['2M'] = File.open("#{hugepages_path_2M}/nr_hugepages").read.strip.to_i
else
  hugepages['2M'] = 0
end

Facter.add(:allocated_hugepages) do
  setcode do
    hugepages
  end
end

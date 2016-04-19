# This fact returns a hash with numbers of allocated 1G and 2M huge pages
# Currently Nailgun doesn't provide this informaion due to LP #1560532

hugepages = {"1G"=>false, "2M"=>false}

hps_path = {
  '1G' => '/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages',
  '2M' => '/sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'
}
hps_path.each do |hp, path|
  hugepages[hp] = File.read(path).to_i != 0 rescue false
end

Facter.add(:allocated_hugepages) do
  setcode do
    hugepages.to_json
  end
end

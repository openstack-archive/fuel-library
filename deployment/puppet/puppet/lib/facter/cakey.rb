Facter.add("cakey") do
  setcode do
    require 'puppet'
    Puppet[:cakey]
  end
end
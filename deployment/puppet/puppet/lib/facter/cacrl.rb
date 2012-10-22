Facter.add("cacrl") do
  setcode do
    require 'puppet'
    Puppet[:cacrl]
  end
end
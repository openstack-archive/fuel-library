Facter.add("certname") do
  setcode do
    require 'puppet'
    Puppet[:certname]
  end
end
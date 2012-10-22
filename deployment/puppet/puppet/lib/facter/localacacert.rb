Facter.add("localcacert") do
  setcode do
    require 'puppet'
    Puppet[:localcacert]
  end
end
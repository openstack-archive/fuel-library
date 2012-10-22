Facter.add("cacert") do
  setcode do
    require 'puppet'
    Puppet[:cacert]
  end
end
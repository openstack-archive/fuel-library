Puppet::Type.newtype(:nova_floating) do

  @doc = "Manage creation/deletion of nova floating ip ranges. "

  ensurable

  newparam(:network, :namevar => true) do
    desc "Network (ie, 192.168.1.0/24 or 192.168.1.128/25 etc.)"  
    newvalues(/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$/)
  end

end

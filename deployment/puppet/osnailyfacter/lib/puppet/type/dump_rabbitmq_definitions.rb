Puppet::Type.newtype(:dump_rabbitmq_definitions) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:user) do
    defaultto 'nova'
  end

  newparam(:password) do
    defaultto 'pass'
  end

  newparam(:url) do
    defaultto 'http://localhost:15672/api/definitions'
  end

  newparam(:dump_file) do
    isnamevar
  end

end

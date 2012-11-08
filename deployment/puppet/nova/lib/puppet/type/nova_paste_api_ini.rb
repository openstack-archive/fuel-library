Puppet::Type.newtype(:nova_paste_api_ini) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Section/setting name to manage from nova/paste-api.ini'
    newvalues(/\S+\/\S+/)
  end

  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |v|
      v.to_s.strip
    end
  end


end

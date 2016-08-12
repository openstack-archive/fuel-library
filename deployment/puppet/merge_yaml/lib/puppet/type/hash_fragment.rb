Puppet::Type.newtype(:hash_fragment) do
  newparam(:name) do
    desc 'The name of this hash file fragment.'
    isnamevar
  end

  newparam(:hash_name) do
    desc 'The name of the hash file this fragment belongs.'
    isrequired
  end

  newparam(:priority) do
    desc 'The merge ordering number this fragment.'
    newvalues /\d+/
    munge do |value|
      value.to_i
    end
  end

  newparam(:data) do
    desc 'The content passed as a hash.'
    validate do |value|
      fail "The value should be a hash! Got: #{value.inspect}" unless value.is_a? Hash
    end
  end

  newparam(:type) do
    desc 'The type of serialization this hash is using.'
    newvalues :yaml, :json
    defaultto :yaml
  end

  newparam(:content) do
    desc 'The content passed as a serialized hash text.'
    validate do |value|
      fail "Content should be a text value! Got: #{value.inspect}" unless value.is_a? String
    end
  end
end

Puppet::Parser::Functions::newfunction(
    :radosgw_user,
    :type => :rvalue,
    :doc  => 'Create radosgw users with roles and all permissions.'
) do |args|
  require 'json'

  user = args[0]
  role = args[1]
  keys = { 'access_key' => false, 'secret_key' => false }

  caps = { 'users' => '*', 'buckets' => '*', 'metadata' => '*', 'usage' => '*', 'zone' => '*' }

  out = `which radosgw-admin`
  radosgw_cmd = out.to_s.gsub(/$\n/, '')

  if !radosgw_cmd or radosgw_cmd == ''
    fail 'radosgw-admin command is not found'
  end

  out = `#{radosgw_cmd} user create --uid=#{user} --display-name=#{user}`

  caps.keys.each do |key|
    out = `#{radosgw_cmd} caps add --uid=#{user} --caps="#{key}=#{caps[key]}"`
  end

  hash_as_string = `#{radosgw_cmd} user info --uid=#{user}`
  hash = JSON.parse hash_as_string.to_s.gsub('=>', ':')

  if !hash['keys']
    fail 'User keys are not found'
  end

  hash['keys'].each do |key|
    if key['user'] == "#{user}"
      keys['access_key'] = key['access_key']
      keys['secret_key'] = key['secret_key']
      break
    end
  end

  if !keys['access_key'] and !keys['secret_key']
    fail 'Keys are not found'
  end
  keys
end

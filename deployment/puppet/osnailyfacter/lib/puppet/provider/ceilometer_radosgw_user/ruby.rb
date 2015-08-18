require 'puppet/util/inifile'
require 'json'

Puppet::Type.type(:ceilometer_radosgw_user).provide(:bla) do

  desc "Manage Ceilometer user in RadosGW"

  commands :rgw_adm => 'radosgw-admin'

  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end

  def create
    set_access_keys
  end

  def destroy
    cmd = ['user', 'rm', "--uid=#{@resource[:name]}"]
    rgw_adm(cmd)
  end

  def section
    'rgw_admin_credentials'
  end

  def key_settings
    ['access_key', 'secret_key']
  end

  def set_access_keys
    user_keys = get_user_keys
    keys = get_access_keys_from_config

    conf = Puppet::Util::IniConfig::File.new
    conf.read(ceilometer_config_file)

    if user_keys != keys
      user_keys.keys.each do |key|
        conf[section][key] = user_keys[key]
      end
      conf.store
    end
  end

  def ceilometer_config_file
    '/etc/ceilometer/ceilometer.conf'
  end

  def get_access_keys_from_config
    keys = Hash.new
    ini_file = Puppet::Util::IniConfig::File.new
    ini_file.read(ceilometer_config_file)
    key_settings.each do |setting|
      keys[setting] = ini_file[section][setting]
    end
    keys
  end

  def get_user_keys
    cmd = ['user', 'info', "--uid=#{@resource[:name]}"]
    begin
      hash_as_string = rgw_adm(cmd)
    rescue Exception => e
      if e.message =~ /could not fetch user info: no user info saved/
        hash_as_string = create_radosgw_user
      else
        raise e
      end
    end

    hash = JSON.parse hash_as_string.to_s.gsub('=>', ':')
    keys = {}
    hash['keys'].each do |key|
      if key['user'] == "#{@resource[:name]}"
        keys['access_key'] = key['access_key']
        keys['secret_key'] = key['secret_key']
      end
    end

    keys
  end

  def create_radosgw_user
    cmd = ['user', 'create', "--uid=#{@resource[:name]}", "--display-name=#{@resource[:name]}"]
    rgw_adm(cmd)
    @resource[:caps].keys.each do |key|
      cmd = ['caps', 'add', "--uid=#{@resource[:name]}", "--caps=#{key}=#{@resource[:caps][key]}"]
      rgw_adm(cmd)
    end
    cmd = ['user', 'info', "--uid=#{@resource[:name]}"]
    return rgw_adm(cmd)
  end
end

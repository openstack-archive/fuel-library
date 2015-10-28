require 'puppet/util/inifile'
require 'json'

Puppet::Type.type(:ceilometer_radosgw_user).provide(:user) do

  desc "Manage Ceilometer user in RadosGW"

  commands :rgw_adm => 'radosgw-admin'

  INI_FILENAME = '/etc/ceilometer/ceilometer.conf'

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
    if ceilometer_file and user_keys != keys
      ceilometer_file.add_section(section, ini_filename) unless ceilometer_file.include?(section)
      user_keys.keys.each do |key|
        ceilometer_file[section][key] = user_keys[key]
      end
      ceilometer_file.store
    end
  end

  def ini_filename
    INI_FILENAME
  end

  def ceilometer_file
    return @ceilometer_file if @ceilometer_file
    if File.exists?(ini_filename)
      @ceilometer_file = Puppet::Util::IniConfig::File.new
      @ceilometer_file.read(ini_filename)
      @ceilometer_file
    end
  end

  def get_access_keys_from_config
    keys = Hash.new
    if ceilometer_file
      key_settings.each do |setting|
        keys[setting] = ceilometer_file[section][setting] if ceilometer_file[section] && ceilometer_file[section][setting]
      end
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

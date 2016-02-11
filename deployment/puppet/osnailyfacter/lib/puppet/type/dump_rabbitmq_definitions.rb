require 'net/http'
require 'digest'

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

  def get_definitions(user, password, url)
    uri = URI(url)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth user, password
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    return res.body
  end

  def exists?
    definitions = get_definitions(self[:user], self[:password], self[:url]) rescue nil
    definitions_digest = Digest::SHA256.hexdigest definitions
    dump_digest = Digest::SHA256.file(self[:dump_file]).hexdigest rescue nil
    if dump_digest != definitions_digest
      return false
    end
    return true
  end

  def create
    definitions = get_definitions(self[:user], self[:password], self[:url])
    File.write(self[:dump_file], definitions)
  end
end

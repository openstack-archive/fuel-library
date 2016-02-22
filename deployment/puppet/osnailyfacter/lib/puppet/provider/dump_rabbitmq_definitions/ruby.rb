require 'net/http'
require 'digest'

Puppet::Type.type(:dump_rabbitmq_definitions).provide(:ruby) do

  def get_definitions
    return @definitions if @definitions
    debug "Trying to get definitions from #{@resource[:url]}"
    uri = URI(@resource[:url])
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth @resource[:user], @resource[:password]
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    @definitions = res.body
  end

  def exists?
    definitions_digest = Digest::SHA256.hexdigest get_definitions
    dump_digest = Digest::SHA256.file(@resource[:dump_file]).hexdigest rescue nil
    return dump_digest == definitions_digest
  end

  def create
    File.write(@resource[:dump_file], get_definitions)
  end

end

require 'json'
require 'net/http'
class Puppet::Provider::Zabbix < Puppet::Provider

  @@auth_hash = ""

  def self.message_json(body)
    message = {
      :method => body[:method],
      :params => body[:params],
      :auth => auth_hash,
      :id => rand(9000),
      :jsonrpc => '2.0'
    }
    JSON.generate(message)
  end

  def self.make_request(api, body)
    uri = URI.parse(api["endpoint"])
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field("Content-Type", "application/json-rpc")
    request.body = message_json(body)
    response = http.request(request)
    puts "DEBUG request = #{request.body}"
    puts "DEBUG response = #{response.body}"
    response.value
    result = JSON.parse(response.body)
    result
  end

  def self.api_request(api, body)
    result = make_request(api, body)
    if result.has_key? "error"
      raise(Puppet::Error, "Zabbix API returned error code #{result["error"]["code"]}: #{result["error"]["message"]}, #{result["error"]["data"]}")
    end
    result["result"]
  end

  def self.auth(api)
    body = {:method => "user.authenticate",
            :params => {:user => api["username"],
                        :password => api["password"]}}
    @@auth_hash = api_request(api, body)
  end

  def auth(api)
    self.class.auth(api)
  end

  def api_request(api, body)
    self.class.api_request(api, body)
  end

  def self.auth_hash
    @@auth_hash
  end

  def auth_hash
    self.class.auth_hash
  end

  def self.get_host(api, name)
    puts "DEBUG gethost #{name}"
    api_request(api,
                {:method => "host.get",
                 :params => {:filter => {:name => [name]}}})
  end

  def self.get_hostgroup(api, name)
    puts "DEBUG gethostgroup #{name}"
    api_request(api,
                {:method => "hostgroup.get",
                 :params => {:filter => {:name => [name]}}})
  end

  def get_host(api, name)
    self.class.get_host(api, name)
  end

  def get_hostgroup(api, name)
    self.class.get_hostgroup(api, name)
  end

end

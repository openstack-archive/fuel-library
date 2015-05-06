require 'pp'
require 'timeout'
require 'net/http'
require 'uri'

Puppet::Parser::Functions::newfunction(:url_available, :doc => <<-EOS
EOS
) do |argv|
  url = argv[0]

  def fetch(url)
    if url.instance_of? Hash
      if url.has_key?('uri')
        uri = url['uri']
      end
    elsif url.instance_of? String
      uri = url
    end
    puts "Checking #{uri}"
    begin
      out = Timeout::timeout(15) do
        u = URI.parse(uri)
        http = Net::HTTP.new(u.host, u.port)
        http.open_timeout = 5
        http.read_timeout = 5
        request = Net::HTTP::Get.new(u.request_uri)
        response = http.request(request)
        #puts response.code
      end
    rescue OpenURI::HTTPError => error
      raise Puppet::Error, "Unable to fetch url #{uri}, error #{error.io}"
    rescue Exception => e
      raise Puppet::Error, "Unable to fetch url #{uri}, error #{e}"
    end
  end

  if url.instance_of? Array
    url.each do |u|
      fetch(u)
    end
  else
    fetch(url)
  end
  return true
end
# vim: set ts=2 sw=2 et :

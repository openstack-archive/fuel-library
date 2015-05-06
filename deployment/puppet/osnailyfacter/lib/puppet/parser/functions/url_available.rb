require 'pp'
require 'timeout'
require 'net/http'
require 'uri'

Puppet::Parser::Functions::newfunction(:url_available, :doc => <<-EOS
The url_available function attempts to make a http request to a url and throws
a puppet error if the URL is unavailable.  The url_available function takes
a single parameter that can be one of the following:
1) String - a single url string
3) Hash - a hash with the url set to the key of 'uri'
2) Array - an array of url strings or an array of hashes that match the
previous format.

Examples:
url_available('http://www.google.com')
url_available(['http://www.google.com', 'http://www.mirantis.com'])
url_available({ 'uri' => 'http://www.google.com' })
url_available([{ 'uri' => 'http://www.google.com' },
               { 'uri' => 'http://www.mirantis.com' }]
EOS
) do |argv|
  url = argv[0]

  def fetch(url)
    # check the type of url being passed, if hash look for the uri key
    if url.instance_of? Hash
      if url.has_key?('uri')
        uri = url['uri']
      end
    elsif url.instance_of? String
      uri = url
    else
      raise Puppet::ParseError, "Invalid url type passed to the url_available
function. Must be of type String or Hash."
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
      end
    rescue OpenURI::HTTPError => error
      raise Puppet::Error, "Unable to fetch url #{uri}, error #{error.io}.
Please verify node connectivity to this URL, or remove it from the
settings page if it invalid."
    rescue Exception => e
      raise Puppet::Error, "Unable to fetch url #{uri}, error #{e}.
Please verify node connectivity to this URL, or remove it from the
settings page if it invalid."
    end
  end

  # if passed an array, iterate through the array an check each element
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

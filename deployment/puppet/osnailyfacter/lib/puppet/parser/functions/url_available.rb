require 'pp'
require 'timeout'
require 'net/http'
require 'uri'

Puppet::Parser::Functions::newfunction(:url_available, :doc => <<-EOS
The url_available function attempts to make a http request to a url and throws
a puppet error if the URL is unavailable.  The url_available function can take
up to two paramters. The first paramter is the URL which is required and can be
one of the following:
1) String - a single url string
3) Hash - a hash with the url set to the key of 'uri'
2) Array - an array of url strings or an array of hashes that match the
previous format.

The second paramter is a proxy url. It should be a valid uri and will be parsed
to ensure it is properly formated. It should be noted that if the url provided
to the url_available function is a hash, the proxy can be specified using a key
named 'proxy'. The hostname, port, username and password will be parsed from
this uri to be used when issuing a request via the proxy.

Examples:
# no proxy
url_available('http://www.google.com')
url_available(['http://www.google.com', 'http://www.mirantis.com'])
url_available({ 'uri' => 'http://www.google.com' })
url_available([{ 'uri' => 'http://www.google.com' },
               { 'uri' => 'http://www.mirantis.com' }]
# with a proxy
url_available('http://www.google.com', 'http://proxy.example.com:3128/')
url_available({ 'uri' => 'http://www.google.com',
                'proxy' => 'http://proxy.example.com:3128'})

# with a proxy with authentication
url_available('http://www.google.com', 'http://user:pass@proxy.example.com:3128/')
url_available({ 'uri'   => 'http://www.google.com',
                'proxy' => 'http://user:pass@proxy.example.com:3128/'})

EOS
) do |argv|
  debug 'Call: url_available'
  url = argv[0]
  http_proxy = argv[1]

  def fetch(url, http_proxy = nil)
    # proxy variables, set later if http_proxy is provided or there is a proxy
    # element provided as part of the a url that is a Hash
    proxy_host = nil
    proxy_port = nil
    proxy_user = nil
    proxy_pass = nil

    # check the type of url being passed, if hash look for the uri key
    if url.instance_of? Hash
      if url.has_key?('uri')
        uri = url['uri']
      end
      if url.has_key?('proxy')
        http_proxy = url['proxy']
      end
    elsif url.instance_of? String
      uri = url
    else
      raise Puppet::ParseError, "Invalid url type passed to the url_available function. Must be of type String or Hash."
    end

    # attempt to parse the proxy if it's not nil or a blank string
    unless [nil, ''].include?(http_proxy)
      begin
        proxy = URI.parse(http_proxy)
        proxy_host = proxy.host
        proxy_port = proxy.port
        proxy_user, proxy_pass = proxy.userinfo.split(/:/) if proxy.userinfo
      rescue Exception => e
        debug "Unable to parse proxy settings from: '#{http_proxy}', will ignore proxy setting. Error: '#{e}'"
      end
    end

    message = nil
    retry_count = 3
    begin
      debug "Checking: #{uri}"
      Timeout::timeout(180) do
        u = URI.parse(uri)
        http = Net::HTTP.new(u.host, u.port, proxy_host, proxy_port, proxy_user, proxy_pass)
        http.open_timeout = 60
        http.read_timeout = 60
        request = Net::HTTP::Get.new(u.request_uri)
        http.request(request)
      end
    rescue Exception => e
      message = "ERROR: Unable to fetch url: '#{uri}', error: '#{e.message}'. Please verify node connectivity to this URL, or remove it from the settings page if it is invalid."
      retry_count -= 1
      if retry_count >= 1
        debug message
        retry
      else
        raise Puppet::Error, message
      end
    end
  end

  # if passed an array, iterate through the array an check each element
  if url.instance_of? Array
    url.each do |u|
      fetch(u, http_proxy)
    end
  else
    fetch(url, http_proxy)
  end
  return true
end
# vim: set ts=2 sw=2 et :

require 'net/https'
require 'uri'
require 'openssl'

Puppet::Type.type(:haproxy_backend_status).provide(:http) do
  desc 'Wait for HTTP backend to become online'

  # get the current backend status value
  # @return [:up, :down, :absent, :present]
  def ensure
    debug 'Call: ensure'
    out = status
    debug "Return: #{out}"
    out
  end

  # get backend status based on HTTP reply
  # @return [:up, :down, :present, :absent]
  def status
    status = get_url
    return :absent unless status
    return :present if [:present, :absent].include? @resource[:ensure]
    return :up if status.kind_of? Net::HTTPSuccess or status.kind_of? Net::HTTPRedirection or status.kind_of? Net::HTTPUnauthorized
    return :down if status.kind_of? Net::HTTPServerError or status.kind_of? Net::HTTPClientError
    :present
  end

  # check backend using HTTP request
  # @return [false, Net::HTTP Constant]
  def get_url
    begin
      uri = URI.parse(@resource[:url])
      http = Net::HTTP.new(uri.host, uri.port)
      if @resource[:url].start_with?('https')
        http.use_ssl = true
        case  @resource[:ssl_verify_mode]
        when 'none'
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        when 'peer'
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
      end
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request)
    rescue Exception => e
      debug "Got error while checking backend: #{e}"
      false
    end
  end

  # wait for backend status to change into specified value
  # @param value [:up, :down]
  def ensure=(value)
    debug "Call: ensure=(#{value})"
    debug "Waiting for backend: '#{@resource[:name]}' to change its status to: '#{value}'"
    @resource[:count].times do
      if self.status == value
        return true
      end
      sleep @resource[:step]
    end
    fail "Timeout waiting for backend: '#{@resource[:name]}' status to become: '#{value}' after #{@resource[:count] * @resource[:step]} seconds!"
  end

end

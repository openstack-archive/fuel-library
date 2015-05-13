require 'pp'
require 'socket'
require 'timeout'

Puppet::Parser::Functions::newfunction(:ntp_available, :doc => <<-EOS
The ntp_available function attempts to make an NTP request to a server or
servers and throws a puppet error if unable to make at least one successful
request. The ntp_available function takes a single parameter that can be one
of the following:
1) String - a single hostname
2) Array - an array of hostname strings

Examples:
ntp_available('pool.ntp.org')
ntp_available(['0.pool.ntp.org', '1.pool.ntp.org', '2.pool.ntp.org'])
EOS
) do |argv|
  host = argv[0]

  def ntp_query(host)
    # time since unix epoch, RFC 868
    time_offset = 2208988800
    # timeout to wait for a response
    timeout = 10
    # an ntp packet
    # http://blog.mattcrampton.com/post/88291892461/query-an-ntp-server-from-python
    ntp_msg = "\x1b" + ("\0" * 47)
    # our UDP socket
    sock = UDPSocket.new
    begin
      # open up a socket to connect to the ntp host
      sock.connect(host, 'ntp')
      # send our ntp message to the ntp server
      sock.print ntp_msg
      sock.flush
      # read the response
      read, write, error = IO.select [sock], nil, nil, timeout
      if read.nil?
        raise Timeout::Error
      else
        data, _ = sock.recvfrom(960)
        # un pack the response
        # https://github.com/zencoder/net-ntp/blob/master/lib/net/ntp/ntp.rb#L194
        parsed_data = data.unpack("a C3   n B16 n B16 H8   N B32 N B32   N B32 N B32")
        # attempt to parse the time we got back
        t = Time.at(parsed_data[13] - time_offset)
        puts "Time from #{host} is #{t}"
      end
      sock.close if sock
    rescue
      sock.close if sock
      return false
    end
    true
  end

  # our check boolean used to indicate we had at least one successful request
  ok = false
  # if passed an array, iterate throught he array and check each element
  if host.instance_of? Array
    host.each do |h|
      if (ntp_query(h))
        ok = true
      end
    end
  else
    ok = ntp_query(host)
  end
  # we need at least one successful request
  if !ok
    raise Puppet::Error, "ERROR: Unable to communicate with at least one of NTP server, checked the following host(s): #{host}"
  end
  return ok
end
# vim: set ts=2 sw=2 et :

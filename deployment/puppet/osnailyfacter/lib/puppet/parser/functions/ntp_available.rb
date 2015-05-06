#require 'open-uri'
require 'pp'
require 'socket'
require 'timeout'

Puppet::Parser::Functions::newfunction(:ntp_available, :doc => <<-EOS
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

  ok = false
  if host.instance_of? Array
    host.each do |h|
      if (ntp_query(h))
        ok = true
      end
    end
  else
    ok = ntp_query(host)
  end
  if !ok
    raise Puppet::Error, "Unable to communicate with the NTP server(s) (#{host})"
  end
  return ok
end
# vim: set ts=2 sw=2 et :

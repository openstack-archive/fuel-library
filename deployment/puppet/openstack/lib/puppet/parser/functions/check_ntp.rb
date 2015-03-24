Puppet::Parser::Functions::newfunction(:check_ntp, :type => :rvalue, :doc =>
<<-EOS
Check if NTP server is available. Args: ntp_server.
EOS

) do |argv|
  ntp_server = argv[0]
  command = "ntpdate -du #{ntp_server}"
  Puppet::Util::Execution.execute(command, {:failonfail => false})
  $?.exitstatus == 0
end

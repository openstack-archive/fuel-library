# zabbixversion.rb

cmd = 'zabbix_agent -V'
cmd_out = Facter::Util::Resolution.exec(cmd)
unless cmd_out.nil?
  Facter.add('zabbixversion') do
    setcode do
      $1 if cmd_out.split(/\n/)[0] =~ /Zabbix agent v(.*?)\s+.*/
    end
  end
end

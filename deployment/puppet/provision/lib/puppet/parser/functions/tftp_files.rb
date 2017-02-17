module Puppet::Parser::Functions
  newfunction(:tftp_files, :type => :rvalue) do |args|
    # args[0] is a path prefix, e.g. /var/lib/tftpboot/pxelinux.cfg
    # args[1] is a list of hosts
    # - hostname: node-1
    #   macs:
    #     - aa:bb:cc:dd:ee:ff
    #     - 00:11:22:33:44:55
    #   ip: 10.20.0.10
    # result is a list of file names
    # - /var/lib/tftpboot/pxelinux.cfg/01-aa-bb-cc-dd-ee-ff
    # - /var/lib/tftpboot/pxelinux.cfg/01-00-11-22-33-44-55
    args[1].map{|host| host["macs"]}.flatten.map{|mac| args[0] + "/01-" + mac.gsub(":", "-")}
  end
end

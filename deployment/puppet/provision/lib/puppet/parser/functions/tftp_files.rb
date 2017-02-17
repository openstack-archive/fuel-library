module Puppet::Parser::Functions
  newfunction(:tftp_files, :type => :rvalue) do |args|
    # args[0] is a path prefix, e.g. /var/lib/tftpboot/pxelinux.cfg
    # args[1] is a dict of hosts
    # node-1:
    #   dhcp_binding_params:
    #     name: node-1
    #     mac:
    #       - aa:bb:cc:dd:ee:ff
    #       - 00:11:22:33:44:55
    #     ip_address: 10.20.0.10
    # result is a list of file names
    # - /var/lib/tftpboot/pxelinux.cfg/01-aa-bb-cc-dd-ee-ff
    # - /var/lib/tftpboot/pxelinux.cfg/01-00-11-22-33-44-55
    files = []
    args[1].each {|host_name, host_data|
      mac = host_data["dhcp_binding_params"]["mac"]
      files << (args[0] + "/01-" + mac.gsub(":", "-"))
    }
    files
  end
end

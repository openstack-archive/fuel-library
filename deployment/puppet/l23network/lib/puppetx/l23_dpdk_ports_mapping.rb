require 'puppetx/l23_network_scheme'

module L23network
  def self.get_dpdk_ports_mapping()
    # returns hash, which map dpdk ports to real ports
    # i.e {
    #       'dpdk0'    => { # generated name
    #         :interface => "enp1s0f0", # real name
    #         :port_type => [],
    #         :type => "dpdk",
    #         :provider => "dpdkovs",
    #         :vendor_specific => {
    #           "dpdk_driver" => "igb_uio"
    #           "dpdk_port" => "dpdk0"
    #         }
    #       }
    #     }
    # This function scans PCI for ethernet devices, and filters only those
    # that bounded to dpdk drivers (it works exactly as dpdk_nic_bind --status).
    # Then devices mapped to network scheme via bus_info to retrieve original
    # names. DPDK devices is sorted by bus_info and numbered from 0.
    #
    # dpdk_drivers contains list of dpdk drivers
    #

    dpdk_drivers = %w[ igb_uio vfio-pci uio_pci_generic ]
    ethernet_class = 0x020000

    cfg = L23network::Scheme.get_config(Facter.value(:l3_fqdn_hostname))
    return {} unless cfg

    interfaces = cfg[:interfaces].map { |i,p| [p[:vendor_specific][:bus_info], i] if p.has_key?(:vendor_specific) }
    bus_info_map = Hash[interfaces.compact]

    devices = Dir['/sys/bus/pci/devices/*/class'].map do |class_file|
      next unless File.read(class_file).to_i(16) == ethernet_class
      dev_dir = File.dirname(class_file)
      bus_info = File.basename(dev_dir)
      next unless File.exists?("#{dev_dir}/driver")
      driver = File.basename(File.readlink("#{dev_dir}/driver"))
      next unless dpdk_drivers.include? driver
      next unless bus_info_map.has_key? bus_info
      {
        :interface    => bus_info_map[bus_info].to_s,
        :port_type    => [],
        :type         => 'dpdk',
        :provider     => 'dpdkovs',
        :vendor_specific => {
          'dpdk_driver' => driver
        }
      }
    end
    dpdk_devices = devices.compact.each_with_index.map do |port_info,i|
      dpdk_port = "dpdk#{i}"
      port_info[:vendor_specific]['dpdk_port'] = dpdk_port
      [dpdk_port, port_info]
    end
    Hash[dpdk_devices]
  end

end
module L23network

  def self.ethtool_name_commands_mapping()
    {
    'offload' => {
        '__section_key_set__'          => '-K',
        '__section_key_get__'          => '-k',
        'rx-checksumming'              => 'rx',
        'tx-checksumming'              => 'tx',
        'scatter-gather'               => 'sg',
        'tcp-segmentation-offload'     => 'tso',
        'udp-fragmentation-offload'    => 'ufo',
        'generic-segmentation-offload' => 'gso',
        'generic-receive-offload'      => 'gro',
        'large-receive-offload'        => 'lro',
        'rx-vlan-offload'              => 'rxvlan',
        'tx-vlan-offload'              => 'txvlan',
        'ntuple-filters'               => 'ntuple',
        'receive-hashing'              => 'rxhash',
        'rx-fcs'                       => 'rx-fcs',
        'rx-all'                       => 'rx-all',
        'highdma'                      => 'highdma',
        'rx-vlan-filter'               => 'rx-vlan-filter',
        'fcoe-mtu'                     => 'fcoe-mtu',
        'l2-fwd-offload'               => 'l2-fwd-offload',
        'loopback'                     => 'loopback',
        'tx-nocache-copy'              => 'tx-nocache-copy',
        'tx-gso-robust'                => 'tx-gso-robust',
        'tx-fcoe-segmentation'         => 'tx-fcoe-segmentation',
        'tx-gre-segmentation'          => 'tx-gre-segmentation',
        'tx-ipip-segmentation'         => 'tx-ipip-segmentation',
        'tx-sit-segmentation'          => 'tx-sit-segmentation',
        'tx-udp_tnl-segmentation'      => 'tx-udp_tnl-segmentation',
        'tx-mpls-segmentation'         => 'tx-mpls-segmentation',
        'tx-vlan-stag-hw-insert'       => 'tx-vlan-stag-hw-insert',
        'rx-vlan-stag-hw-parse'        => 'rx-vlan-stag-hw-parse',
        'rx-vlan-stag-filter'          => 'rx-vlan-stag-filter',
      }
    }
  end

end
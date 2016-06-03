module L23network
  class Scheme
    def self.set_config(h, v)
      @network_scheme_hash ||= {}
      @network_scheme_hash[h.to_sym] = v
    end
    def self.get_config(h)
      @network_scheme_hash ||= {}
      @network_scheme_hash[h.to_sym]
    end
    def self.has_config?
      @network_scheme_hash.is_a? Hash
    end
  end

  def self.get_phys_dev_by_transformation(trans_name, host_name)
    cfg = L23network::Scheme.get_config(host_name)
    interfaces = cfg[:interfaces]
    transformations = cfg[:transformations]

    rv = []
    phy_interfaces = interfaces.keys.map(&:to_s)
    ifaces = []

    if phy_interfaces.include? trans_name
      ifaces.push(trans_name)
      return ifaces
    end

    for i in 0..transformations.size-1  do
      transform = transformations[i]
      if transform[:name] == trans_name
        if transform[:vlandev] != nil
          ifaces.push(transform[:vlandev])
        else
          trans_name = transform[:name].split(".")[0]
          if phy_interfaces.include? trans_name or transform[:action] == 'add-bond'
            ifaces.push(trans_name.to_s)
            break
          end
          if transform[:name] != trans_name
            ifaces.push(L23network.get_phys_dev_by_transformation(trans_name, host_name))
          end
        end
      elsif transform[:bridge] == trans_name
        ifaces.push(transform[:name].split(".")[0])
      elsif transform[:bridges] != nil and transform[:bridges][0] == trans_name
        trans_name = transform[:bridges][1]
        ifaces.push(L23network.get_phys_dev_by_transformation(trans_name, host_name))
      end
    end

    if ifaces.flatten.uniq.any? { |dev| /^bond/ =~ dev }
      for i in 0..transformations.size-1
         transform = transformations[i]
         name = transform[:name]
         if transform[:name] == ifaces[0]
           ifaces.push(transform[:interfaces])
         end
      end
    end
    return ifaces.flatten.uniq
  end

  def self.get_property_for_transformation(prop_name, trans_name, host_name)
    cfg = L23network::Scheme.get_config(host_name)

    transformations = cfg[:transformations]
    ifaces = cfg[:interfaces]
    rv = nil

    case prop_name
      when 'MTU'
        mtu = []
        all_ifaces = ifaces.keys.map(&:to_s)
        if all_ifaces.include? trans_name and ifaces[trans_name.to_sym][:mtu] != nil
          mtu.push(ifaces[trans_name.to_sym][:mtu])
        else
          for i in 0..transformations.size-1 do
            transform = cfg[:transformations][i]
            if transform[:name] == trans_name and transform[:mtu] != nil
              mtu.push(transform[:mtu])
            end
          end
        end
        rv = (mtu.empty?  ?  nil  :  mtu.min()  )
      when 'PROVIDER'
        transformations.each do |transform|
          if transform[:name] == trans_name and transform[:provider] != nil
            rv = transform[:provider]
          end
        end
      else
        rv = nil
    end
    return rv
  end

  def self.override_transformations(network_scheme)
    org_tranformations = network_scheme.fetch(:transformations,[])
    transformations = org_tranformations.reject{|x| x[:action]=='override'}
    org_tranformations.select{|x| x[:action]=='override'}.each do |ov|
      next if ov[:override].nil?
      tr_index = transformations.index{|x| x[:name]==ov[:override]}
      next if tr_index.nil?
      ov.reject{|k,v| [:override, :action].include? k}.each do |k,v|
        if k == :'override-action' and v.to_s!=''
          transformations[tr_index][:action] = v
        elsif v == ''
          transformations[tr_index].delete(k)
        else
          transformations[tr_index][k] = v
        end
      end
    end
    network_scheme[:transformations] = transformations
    return network_scheme
  end

  def self.remove_empty_members(network_scheme)
    network_scheme[:endpoints] = network_scheme[:endpoints].is_a?(Hash)  ?  network_scheme[:endpoints].reject{|k,v| !v.is_a?(Hash)}  :  {}
    network_scheme[:interfaces] = network_scheme[:interfaces].is_a?(Hash)  ?  network_scheme[:interfaces].reject{|k,v| !v.is_a?(Hash)}  :  {}
    return network_scheme
  end
end
# vim: set ts=2 sw=2 et :
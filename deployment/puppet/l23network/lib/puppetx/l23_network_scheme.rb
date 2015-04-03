module L23network
  class Scheme
    def self.set_config(h, v)
      @network_scheme_hash ||= {}
      @network_scheme_hash[h.to_sym] = v
    end
    def self.get_config(h)
      @network_scheme_hash[h.to_sym]
    end
    def self.get_phys_dev_by_endpoint(endpoint, interfaces, transformations)
      rv = []
      all_ifaces = interfaces.keys.map(&:to_s)
      ifaces = []

      if all_ifaces.include? endpoint
        ifaces.push(endpoint)
        return ifaces
      end

      for i in 0..transformations.size-1  do
        transform = transformations[i]
        if transform[:name] != nil and transform[:name].include? endpoint
          if transform[:vlandev] != nil
            ifaces.push(transform[:vlandev])
          else
            endpoint = transform[:name].split(".")[0]
            if all_ifaces.include? endpoint
              ifaces.push(endpoint.to_s)
            end
          end
        elsif transform[:bridge] == endpoint
          ifaces.push(transform[:name].split(".")[0])
        elsif transform[:bridges] != nil and transform[:bridges][0] == endpoint
          endpoint = transform[:bridges][1]
          ifaces.push(get_phys_dev_by_endpoint(endpoint, interfaces, transformations))
        end
      end
      return ifaces.flatten.uniq
    end
  end
end
# vim: set ts=2 sw=2 et :

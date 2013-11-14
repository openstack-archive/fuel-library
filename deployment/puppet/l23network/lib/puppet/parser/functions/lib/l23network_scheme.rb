module L23network
  class Scheme
    def self.set_config(h, v)
      @network_scheme_hash ||= {}
      @network_scheme_hash[h.to_sym] = v
    end
    def self.get_config(h)
      @network_scheme_hash[h.to_sym]
    end
  end
end
# vim: set ts=2 sw=2 et :
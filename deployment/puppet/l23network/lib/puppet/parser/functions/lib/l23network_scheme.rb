module L23network
  class Scheme
    def self.set=(v)
      @network_scheme_hash = v
    end
    def self.get
      @network_scheme_hash
    end
  end
end
# vim: set ts=2 sw=2 et :
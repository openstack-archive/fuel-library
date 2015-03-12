module L23network

  def self.process_array4keys(aa)
    rv = []
    aa.each do |v|
      if v.is_a? Hash
        rv.insert(-1, self.sanitize_keys_in_hash(v))
      elsif v.is_a? Array
        rv.insert(-1, self.process_array4keys(v))
      else
        rv.insert(-1, v)
      end
    end
    return rv
  end
  def self.sanitize_keys_in_hash(hh)
    rv = {}
    hh.each do |k, v|
      if v.is_a? Hash
        rv[k.to_sym] = self.sanitize_keys_in_hash(v)
      elsif v.is_a? Array
        rv[k.to_sym] = self.process_array4keys(v)
      else
        rv[k.to_sym] = v
      end
    end
    return rv
  end


  def self.process_array4bool(aa)
    rv = []
    aa.each do |v|
      if v.is_a? Hash
        rv.insert(-1, self.sanitize_bool_in_hash(v))
      elsif v.is_a? Array
        rv.insert(-1, self.process_array4bool(v))
      else
        rv.insert(-1, v)
      end
    end
    return rv
  end
  def self.sanitize_bool_in_hash(hh)
    rv = {}
    hh.each do |k, v|
      if (v.is_a? String or v.is_a? Symbol)
        rv[k] = case v.upcase()
          when 'TRUE', :TRUE then true
          when 'FALSE', :FALSE then false
          when 'NONE', :NONE, 'NULL', :NULL, 'NIL', :NIL, 'NILL', :NILL then nil
          else v
        end
      elsif v.is_a? Hash
        rv[k] = self.sanitize_bool_in_hash(v)
      elsif v.is_a? Array
        rv[k] = self.process_array4bool(v)
      else
        rv[k] = v
      end
    end
    return rv
  end

end
# vim: set ts=2 sw=2 et :
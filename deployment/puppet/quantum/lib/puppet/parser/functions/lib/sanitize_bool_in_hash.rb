def sanitize_bool_in_hash(cfg)
  def process_array(aa)
    rv = []
    aa.each do |v|
      if v.is_a? Hash
        rv.insert(-1, process_hash(v))
      elsif v.is_a? Array
        rv.insert(-1, process_array(v))
      else
        rv.insert(-1, v)
      end
    end
    return rv
  end
  def process_hash(hh)
    rv = {}
    hh.each do |k, v|
      #info("xx>>#{k}--#{k.to_sym}<<")
      if v.is_a? Hash
        rv[k] = process_hash(v)
      elsif v.is_a? Array
        rv[k] = process_array(v)
      else
        rv[k] = v
      end
    end
    return rv
  end
  process_hash(cfg)
end
# vim: set ts=2 sw=2 et :
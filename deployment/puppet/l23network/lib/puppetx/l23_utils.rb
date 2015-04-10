module L23network
  def self.reccursive_sanitize_hash(data)
    if data.is_a? Hash
      new_data = {}
      data.each do |key, value|
        new_data.store(reccursive_sanitize_hash(key), reccursive_sanitize_hash(value))
      end
      new_data
    elsif data.is_a? Array
      data.map do |element|
        reccursive_sanitize_hash(element)
      end
    elsif ['true', 'on', 'yes'].include? data.to_s.downcase
      true
    elsif ['false', 'off', 'no'].include? data.to_s.downcase
      false
    elsif data.nil?
      nil
    else
      data.to_s
    end
  end

  def self.get_patch_name(bridges)
    # bridges should be an array of two string
    "patch__#{bridges.map{|s| s.to_s}.sort.join('--')}"
  end

  def self.ovs_jack_name_len
    13
  end

  def self.get_ovs_jack_name(bridge)
    # bridges should be an array of two string
    tail = bridge[0..ovs_jack_name_len-1]
    "p_#{tail}"
  end

  def self.lnx_jack_name_len
    11
  end

  def self.get_lnx_jack_name(bridge, num=0)
    # bridges should be an array of two string
    tail = bridge[0..lnx_jack_name_len-1]
    "p_#{tail}-#{num}"
  end

  def self.get_pair_of_jack_names(bridges)
    if bridges.is_a? String
      j1 = get_lnx_jack_name(bridges,0)
      j2 = get_lnx_jack_name(bridges,1)
    elsif bridges.is_a? Array and bridges.length==1
      j1 = get_lnx_jack_name(bridges[0],0)
      j2 = get_lnx_jack_name(bridges[0],1)
    else
      j1 = get_lnx_jack_name(bridges[0],0)
      j2 = get_lnx_jack_name(bridges[1],1)
    end
    return [j1, j2]
  end

# def self.reccursive_merge_hash(a,b)
#   rv = {}

#   a.keys.each do |key|
#     if data.is_a? Hash
#       new_data = {}
#       data.each do |key, value|
#         new_data.store(reccursive_sanitize_hash(key), reccursive_sanitize_hash(value))
#       end
#       new_data
#     else
#       data.to_s
#     end
#   end

#   if data.is_a? Hash
#     new_data = {}
#     data.each do |key, value|
#       new_data.store(reccursive_sanitize_hash(key), reccursive_sanitize_hash(value))
#     end
#     new_data
#   elsif data.is_a? Array
#     data.map do |element|
#       reccursive_sanitize_hash(element)
#     end
#   elsif ['true', 'on', 'yes'].include? data.to_s.downcase
#     true
#   elsif ['false', 'off', 'no'].include? data.to_s.downcase
#     false
#   elsif data.nil?
#     nil
#   else
#     data.to_s
#   end

#   return rv
# end

  def self.get_route_resource_name(dest, metric=0)
    (metric.to_i > 0  ?  "#{dest},metric:#{metric}"  :  rv = "#{dest}")
  end
end
# vim: set ts=2 sw=2 et :
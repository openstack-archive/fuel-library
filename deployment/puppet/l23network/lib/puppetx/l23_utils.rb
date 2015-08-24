require 'zlib'

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

  def self.get_normalized_bridges_order(bridges)
    bridges[0..1].map{|s| s.to_s}.sort()
  end

  def self.get_patch_name(bridges)
    # bridges should be an array of two string
    bridges_sorted = get_normalized_bridges_order(bridges)
    "patch__#{bridges_sorted.join('--')}"
  end

  def self.lnx_jack_name_len
    11
  end

  def self.get_base_name_for_jacks(bridges)
    sprintf("p_%08x",Zlib::crc32(get_patch_name(bridges)).to_i)
  end

  def self.get_jack_name(bridges, num=0)
    # ideally, bridges should be an array of two string
    if bridges.is_a? String
      jj = [bridges,bridges]
    elsif bridges.is_a? Array and bridges.length==1
      jj = [bridges[0],bridges[0]]
    else
      jj = bridges
    end
    base_name=get_base_name_for_jacks(jj)
    return "#{base_name}-#{num}"
  end

  def self.get_pair_of_jack_names(bridges)
    # we need normalize here, because indexes used below
    bridges_sorted = get_normalized_bridges_order(bridges)
    [get_jack_name(bridges_sorted,0), get_jack_name(bridges_sorted,1)]
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
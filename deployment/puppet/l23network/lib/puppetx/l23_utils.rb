def reccursive_sanitize_hash(data)
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

# def reccursive_merge_hash(a,b)
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

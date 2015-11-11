module Puppet::Parser::Functions
  newfunction(:extend_kopts, :type => rvalue, :doc => <<-EOS
This function are changing "kopts" parameter if user modifyed it
   EOS
   ) do |arguments|

   begin
   kopts = YAML::load(argument[0]) || argument[1]

   default_kopts = argument[2].split(" ")
   new_kopts = kopts.split(" ")

   hash_default_kopts = {}
   hash_new_kopts = {}

   default_kopts.each do |e|
     key_value_d = e.split("=")
     hash_default_kopts[key_value_d[0]] = key_value_d[1]
     end

   new_kopts.each do |e|
     key_value_n = e.split("=")
     hash_new_kopts[key_value_n[0]] = key_value_n[1]
     end

   keys_intersection = hash_default_kopts.keys & hash_new_kopts.keys
   merged = hash_default_kopts.dup.update(hash_new_kopts)

   keys_intersection.each do |k|
      merged[k] = hash_new_kopts[k]
   end

   modify_kopts = merged.collect {|key, value| "#{key}=#{value}"}.join(' ')

   return modify_kopts
  end
end


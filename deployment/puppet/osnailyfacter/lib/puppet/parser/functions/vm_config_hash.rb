module Puppet::Parser::Functions
  newfunction(:vm_config_hash, :type => :rvalue) do |args|
    vms = args.first
    next {} unless vms.is_a? Array
    vm_config_hash = {}
    vms.each do |vm|
      next unless vm.is_a? Hash
      id = vm['id']
      next unless id
      vm_config_hash.store id, { 'details' => vm }
    end
    vm_config_hash
  end
end
#!/usr/bin/env ruby
#
# This script checks thats SR-IOV and IOMMU are properly configured
# for using in virtual machines.
#
# Example of network scheme with SR-IOV enabled NIC
#
# network_scheme:
#   transformations:
#   - action: add-port
#     name: em1
#     provider: sriov

require 'hiera'

ENV['LANG'] = 'C'
errors = 0

hiera = Hiera.new(:config => '/etc/hiera.yaml')
transformations = hiera.lookup(
                    'network_scheme', {}, {},
                    order_override = nil,
                    resolution_type = :hash
                  )['transformations']

unless transformations.is_a?(Array)
  puts "ERROR: Network tranformations not found in Hiera"
  exit 1
end

transformations.each do |t|
  if t["action"] == "add-port" and t["provider"] == "sriov"
    int = t["name"]
    begin
      if File.exist?("/sys/class/net/#{int}/device/sriov_totalvfs") and
        File.readlink("/sys/class/net/#{int}/device/iommu_group") !=
        File.readlink("/sys/class/net/#{int}/device/virtfn0/iommu_group") and
        Dir["/sys/class/net/#{int}/device/virtfn0/iommu_group/devices/*:*"].length == 1

        puts "OK: SR-IOV and IOMMU are properly configured for #{int} interface"
      else
        puts "ERROR: SR-IOV and IOMMU are not properly configured for #{int} interface"
        errors += 1
      end
    rescue
      puts "ERROR: Was not able to check SR-IOV and IOMMU for #{int} interface"
      errors += 1
    end
  end
end

exit 1 unless errors == 0

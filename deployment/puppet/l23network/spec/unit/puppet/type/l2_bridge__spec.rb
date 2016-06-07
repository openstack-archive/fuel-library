require 'spec_helper'

describe Puppet::Type.type(:l2_bridge) do
  context 'Create bridge with wrong name' do
    before(:each) do
      puppet_debug_override()
    end

    [ 'bond4', 'bond-ovs',                             # bridge is not a bond
      'wlan34', 'wlan-public',                         # names for hw wifi cards
      'lo', 'lo2', 'lo-true',                          # loopback not allowed
      'eth', 'eth1',                                   # old style interface naming. bridge != HW interface
      'eno3ac5', 'ensc65d', 'enp334', 'enx00adbc3421', # new style interface naming. bridge != HW interface
      'em', 'em4',                                     # new style interface naming. bridge != HW interface
      'p0p1',                                          # new style interface naming. bridge != HW interface
      'ib', 'ib23', 'ib4.1001', 'ibX.ABCD.E',          # infiniband-based names
      'qwe4567890123456', '5fgtr', 'br32-', 'br_32',   # wrong length, start from digit, wrong end or char inside name
    ].each do |iname|

      it "should be failed for name #{iname}" do
        expect { described_class.new({
          :name   => "#{iname}",
        })}.to raise_error(Puppet::ResourceError, /Wrong\s+bridge\s+name/)
      end

    end
  end
end

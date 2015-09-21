require 'spec_helper'

describe Puppet::Type.type(:l2_bond) do
  context 'Create bond with wrong name' do
    before(:each) do
      puppet_debug_override()
    end

    [ 'br2', 'br-2',                                   # bond is not an bridge
      'wlan34', 'wlan-public',                         # names for hw wifi cards
      'lo', 'lo2', 'lo-true',                          # loopback not allowed
      'eth', 'eth1',                                   # old style interface naming. bridge != HW interface
      'eno3ac5', 'ensc65d', 'enp334', 'enx00adbc3421', # new style interface naming. bridge != HW interface
      'em', 'em4',                                     # new style interface naming. bridge != HW interface
      'p0p1',                                          # new style interface naming. bridge != HW interface
      'ib', 'ib23', 'ib4.1001', 'ibA.ABCD.E',          # infiniband-based names
      'qwe4567890123456', '5fgtr', 'br32-', 'br_32',   # wrong length, start from digit, wrong end or char inside name
    ].each do |iname|

      it "should be failed for name #{iname}" do
        expect { described_class.new({
          :name   => "#{iname}",
        })}.to raise_error(Puppet::ResourceError, %r{Wrong\s+bond\s+name})
      end

    end

  end
end
# vim: set ts=2 sw=2 et

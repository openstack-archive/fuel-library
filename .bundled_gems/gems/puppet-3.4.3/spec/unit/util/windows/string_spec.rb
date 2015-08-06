# encoding: UTF-8
#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/windows'

describe "Puppet::Util::Windows::String", :if => Puppet.features.microsoft_windows? do
  UTF16_NULL = [0, 0]

  def wide_string(str)
    Puppet::Util::Windows::String.wide_string(str)
  end

  def converts_to_wide_string(string_value)
    expected = string_value.encode(Encoding::UTF_16LE)
    expected_bytes = expected.bytes.to_a + UTF16_NULL

    wide_string(string_value).bytes.to_a.should == expected_bytes
  end

  context "wide_string" do
    it "should return encoding of UTF-16LE" do
      wide_string("bob").encoding.should == Encoding::UTF_16LE
    end

    it "should return valid encoding" do
      wide_string("bob").valid_encoding?.should be_true
    end

    it "should convert an ASCII string" do
      converts_to_wide_string("bob".encode(Encoding::US_ASCII))
    end

    it "should convert a UTF-8 string" do
      converts_to_wide_string("bob".encode(Encoding::UTF_8))
    end

    it "should convert a UTF-16LE string" do
      converts_to_wide_string("bob\u00E8".encode(Encoding::UTF_16LE))
    end

    it "should convert a UTF-16BE string" do
      converts_to_wide_string("bob\u00E8".encode(Encoding::UTF_16BE))
    end

    it "should convert an UTF-32LE string" do
      converts_to_wide_string("bob\u00E8".encode(Encoding::UTF_32LE))
    end

    it "should convert an UTF-32BE string" do
      converts_to_wide_string("bob\u00E8".encode(Encoding::UTF_32BE))
    end
  end
end

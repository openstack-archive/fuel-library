#!/usr/bin/env ruby
require 'spec_helper'

require 'puppet/settings'
require 'puppet/settings/duration_setting'

describe Puppet::Settings::DurationSetting do
  subject { described_class.new(:settings => mock('settings'), :desc => "test") }

  describe "when munging the setting" do
    it "should return the same value if given an integer" do
      subject.munge(5).should == 5
    end

    it "should return an integer if given a decimal string" do
      subject.munge("12").should == 12
    end

    it "should fail if given anything but a well-formed string or integer" do
      [ '', 'foo', '2 d', '2d ', true, Time.now, 8.3, [] ].each do |value|
        expect { subject.munge(value) }.to raise_error(Puppet::Settings::ValidationError)
      end
    end

    it "should parse strings with units of 'y', 'd', 'h', 'm', or 's'" do
      # Note: the year value won't jive with most methods of calculating
      # year due to the Julian calandar having 365.25 days in a year
      {
        '3y' => 94608000,
        '3d' => 259200,
        '3h' => 10800,
        '3m' => 180,
        '3s' => 3
      }.each do |value, converted_value|
        # subject.munge(value).should == converted_value
        subject.munge(value).should == converted_value
      end
    end

    # This is to support the `filetimeout` setting
    it "should allow negative values" do
      subject.munge(-1).should == -1
    end
  end
end

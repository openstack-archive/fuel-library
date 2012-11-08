require 'spec_helper'
require 'puppet/util/ini_file'

describe Puppet::Util::IniFile do
  let(:subject) { Puppet::Util::IniFile.new("/my/ini/file/path") }

  before :each do
    File.should_receive(:file?).with("/my/ini/file/path") { true }
    described_class.should_receive(:readlines).once.with("/my/ini/file/path") do
      sample_content
    end
  end

  context "when parsing a file" do
    let(:sample_content) {
      template = <<-EOS
# This is a comment
[section1]
; This is also a comment
foo=foovalue

bar = barvalue
[section2]

foo= foovalue2
baz=bazvalue
    #another comment
 ; yet another comment
 zot = multi word value
      EOS
      template.split("\n")
    }

    it "should parse the correct number of sections" do
      # there is always a "global" section, so our count should be 3.
      subject.section_names.length.should == 3
    end

    it "should parse the correct section_names" do
      # there should always be a "global" section named "" at the beginning of the list
      subject.section_names.should == ["", "section1", "section2"]
    end

    it "should expose settings for sections" do
      subject.get_value("section1", "foo").should == "foovalue"
      subject.get_value("section1", "bar").should == "barvalue"
      subject.get_value("section2", "foo").should == "foovalue2"
      subject.get_value("section2", "baz").should == "bazvalue"
      subject.get_value("section2", "zot").should == "multi word value"
    end

  end

  context "when parsing a file whose first line is a section" do
    let(:sample_content) {
      template = <<-EOS
[section1]
; This is a comment
foo=foovalue
      EOS
      template.split("\n")
    }

    it "should parse the correct number of sections" do
      # there is always a "global" section, so our count should be 2.
      subject.section_names.length.should == 2
    end

    it "should parse the correct section_names" do
      # there should always be a "global" section named "" at the beginning of the list
      subject.section_names.should == ["", "section1"]
    end

    it "should expose settings for sections" do
      subject.get_value("section1", "foo").should == "foovalue"
    end

  end

  context "when parsing a file with a 'global' section" do
    let(:sample_content) {
      template = <<-EOS
foo = bar
[section1]
; This is a comment
foo=foovalue
      EOS
      template.split("\n")
    }

    it "should parse the correct number of sections" do
      # there is always a "global" section, so our count should be 2.
      subject.section_names.length.should == 2
    end

    it "should parse the correct section_names" do
      # there should always be a "global" section named "" at the beginning of the list
      subject.section_names.should == ["", "section1"]
    end

    it "should expose settings for sections" do
      subject.get_value("", "foo").should == "bar"
      subject.get_value("section1", "foo").should == "foovalue"
    end

  end
end

require 'spec_helper'
require 'puppet/face'
require 'puppet/interface'

describe Puppet::Interface do
  subject { Puppet::Interface }

  before :each do
    @faces = Puppet::Interface::FaceCollection.
      instance_variable_get("@faces").dup
    @dq = $".dup
    $".delete_if do |path| path =~ %r{/face/.*\.rb$} end
    Puppet::Interface::FaceCollection.instance_variable_get("@faces").clear
  end

  after :each do
    Puppet::Interface::FaceCollection.instance_variable_set("@faces", @faces)
    $".clear ; @dq.each do |item| $" << item end
  end

  describe "#[]" do
    it "should fail when no version is requested" do
      expect { subject[:huzzah] }.to raise_error ArgumentError
    end

    it "should raise an exception when the requested version is unavailable" do
      expect { subject[:huzzah, '17.0.0'] }.to raise_error(Puppet::Error, /Could not find version/)
    end

    it "should raise an exception when the requested face doesn't exist" do
      expect { subject[:burrble_toot, :current] }.to raise_error(Puppet::Error, /Could not find Puppet Face/)
    end

    describe "version matching" do
      { '1'     => '1.1.1',
        '1.0'   => '1.0.1',
        '1.0.1' => '1.0.1',
        '1.1'   => '1.1.1',
        '1.1.1' => '1.1.1'
      }.each do |input, expect|
        it "should match #{input.inspect} to #{expect.inspect}" do
          face = subject[:version_matching, input]
          face.should be
          face.version.should == expect
        end
      end

      %w{1.0.2 1.2}.each do |input|
        it "should not match #{input.inspect} to any version" do
          expect { subject[:version_matching, input] }.
            to raise_error Puppet::Error, /Could not find version/
        end
      end
    end
  end

  describe "#define" do
    it "should register the face" do
      face  = subject.define(:face_test_register, '0.0.1')
      face.should == subject[:face_test_register, '0.0.1']
    end

    it "should load actions" do
      subject.any_instance.expects(:load_actions)
      subject.define(:face_test_load_actions, '0.0.1')
    end

    it "should require a version number" do
      expect { subject.define(:no_version) }.to raise_error ArgumentError
    end

    it "should support summary builder and accessor methods" do
      subject.new(:foo, '1.0.0').should respond_to(:summary).with(0).arguments
      subject.new(:foo, '1.0.0').should respond_to(:summary=).with(1).arguments
    end

    # Required documentation methods...
    { :summary     => "summary",
      :description => "This is the description of the stuff\n\nWhee",
      :examples    => "This is my example",
      :short_description => "This is my custom short description",
      :notes       => "These are my notes...",
      :author      => "This is my authorship data",
    }.each do |attr, value|
      it "should support #{attr} in the builder" do
        face = subject.new(:builder, '1.0.0') do
          self.send(attr, value)
        end
        face.send(attr).should == value
      end
    end
  end

  describe "#initialize" do
    it "should require a version number" do
      expect { subject.new(:no_version) }.to raise_error ArgumentError
    end

    it "should require a valid version number" do
      expect { subject.new(:bad_version, 'Rasins') }.
        to raise_error ArgumentError
    end

    it "should instance-eval any provided block" do
      face = subject.new(:face_test_block, '0.0.1') do
        action(:something) do
          when_invoked {|_| "foo" }
        end
      end

      face.something.should == "foo"
    end
  end

  it "should have a name" do
    subject.new(:me, '0.0.1').name.should == :me
  end

  it "should stringify with its own name" do
    subject.new(:me, '0.0.1').to_s.should =~ /\bme\b/
  end

  # Why?
  it "should create a class-level autoloader" do
    subject.autoloader.should be_instance_of(Puppet::Util::Autoload)
  end

  it "should try to require faces that are not known" do
    subject::FaceCollection.expects(:load_face).with(:foo, :current)
    subject::FaceCollection.expects(:load_face).with(:foo, '0.0.1')
    expect { subject[:foo, '0.0.1'] }.to raise_error Puppet::Error
  end

  it_should_behave_like "things that declare options" do
    def add_options_to(&block)
      subject.new(:with_options, '0.0.1', &block)
    end
  end

  describe "with face-level display_global_options" do
    it "should not return any action level display_global_options" do
      face = subject.new(:with_display_global_options, '0.0.1') do
        display_global_options "environment"
        action :baz do
          when_invoked {|_| true }
          display_global_options "modulepath"
        end
      end
      face.display_global_options =~ ["environment"]
    end

    it "should not fail when a face d_g_o duplicates an action d_g_o" do
      expect {
        subject.new(:action_level_display_global_options, '0.0.1') do
          action :bar do
            when_invoked {|_| true }
            display_global_options "environment"
          end
          display_global_options "environment"
        end
      }.to_not raise_error
    end

    it "should work when two actions have the same d_g_o" do
      face = subject.new(:with_display_global_options, '0.0.1') do
        action :foo do when_invoked {|_| true} ; display_global_options "environment" end
        action :bar do when_invoked {|_| true} ; display_global_options "environment" end
      end
      face.get_action(:foo).display_global_options =~ ["environment"]
      face.get_action(:bar).display_global_options =~ ["environment"]
    end
      
  end
  
  describe "with inherited display_global_options" do
  end

  describe "with face-level options" do
    it "should not return any action-level options" do
      face = subject.new(:with_options, '0.0.1') do
        option "--foo"
        option "--bar"
        action :baz do
          when_invoked {|_| true }
          option "--quux"
        end
      end
      face.options.should =~ [:foo, :bar]
    end

    it "should fail when a face option duplicates an action option" do
      expect {
        subject.new(:action_level_options, '0.0.1') do
          action :bar do
            when_invoked {|_| true }
            option "--foo"
          end
          option "--foo"
        end
      }.to raise_error ArgumentError, /Option foo conflicts with existing option foo on/i
    end

    it "should work when two actions have the same option" do
      face = subject.new(:with_options, '0.0.1') do
        action :foo do when_invoked {|_| true } ; option "--quux" end
        action :bar do when_invoked {|_| true } ; option "--quux" end
      end

      face.get_action(:foo).options.should =~ [:quux]
      face.get_action(:bar).options.should =~ [:quux]
    end

    it "should only list options and not aliases" do
      face = subject.new(:face_options, '0.0.1') do
        option "--bar", "-b", "--foo-bar"
      end
      face.options.should =~ [:bar]
    end

  end

  describe "with inherited options" do
    let :parent do
      parent = Class.new(subject)
      parent.option("--inherited")
      parent.action(:parent_action) do when_invoked {|_| true } end
      parent
    end

    let :face do
      face = parent.new(:example, '0.2.1')
      face.option("--local")
      face.action(:face_action) do when_invoked {|_| true } end
      face
    end

    describe "#options" do
      it "should list inherited options" do
        face.options.should =~ [:inherited, :local]
      end

      it "should see all options on face actions" do
        face.get_action(:face_action).options.should =~ [:inherited, :local]
      end

      it "should see all options on inherited actions accessed on the subclass" do
        face.get_action(:parent_action).options.should =~ [:inherited, :local]
      end

      it "should not see subclass actions on the parent class" do
        parent.options.should =~ [:inherited]
      end

      it "should not see subclass actions on actions accessed on the parent class" do
        parent.get_action(:parent_action).options.should =~ [:inherited]
      end
    end

    describe "#get_option" do
      it "should return an inherited option object" do
        face.get_option(:inherited).should be_an_instance_of subject::Option
      end
    end
  end

  it_should_behave_like "documentation on faces" do
    subject do
      Puppet::Interface.new(:face_documentation, '0.0.1')
    end
  end
end

require 'spec_helper'
require 'semver'

describe SemVer do

  describe 'MAX should be +Infinity' do
    SemVer::MAX.major.infinite?.should == 1
  end

  describe '::valid?' do
    it 'should validate basic version strings' do
      %w[ 0.0.0 999.999.999 v0.0.0 v999.999.999 ].each do |vstring|
        SemVer.valid?(vstring).should be_true
      end
    end

    it 'should validate special version strings' do
      %w[ 0.0.0-foo 999.999.999-bar v0.0.0-a v999.999.999-beta ].each do |vstring|
        SemVer.valid?(vstring).should be_true
      end
    end

    it 'should fail to validate invalid version strings' do
      %w[ nope 0.0foo 999.999 x0.0.0 z.z.z 1.2.3beta 1.x.y ].each do |vstring|
        SemVer.valid?(vstring).should be_false
      end
    end
  end

  describe '::pre' do
    it 'should append a dash when no dash appears in the string' do
      SemVer.pre('1.2.3').should == '1.2.3-'
    end

    it 'should not append a dash when a dash appears in the string' do
      SemVer.pre('1.2.3-a').should == '1.2.3-a'
    end
  end

  describe '::find_matching' do
    before :all do
      @versions = %w[
        0.0.1
        0.0.2
        1.0.0-rc1
        1.0.0-rc2
        1.0.0
        1.0.1
        1.1.0
        1.1.1
        1.1.2
        1.1.3
        1.1.4
        1.2.0
        1.2.1
        2.0.0-rc1
      ].map { |v| SemVer.new(v) }
    end

    it 'should match exact versions by string' do
      @versions.each do |version|
        SemVer.find_matching(version, @versions).should == version
      end
    end

    it 'should return nil if no versions match' do
      %w[ 3.0.0 2.0.0-rc2 1.0.0-alpha ].each do |v|
        SemVer.find_matching(v, @versions).should be_nil
      end
    end

    it 'should find the greatest match for partial versions' do
      SemVer.find_matching('1.0', @versions).should == 'v1.0.1'
      SemVer.find_matching('1.1', @versions).should == 'v1.1.4'
      SemVer.find_matching('1', @versions).should   == 'v1.2.1'
      SemVer.find_matching('2', @versions).should   == 'v2.0.0-rc1'
      SemVer.find_matching('2.1', @versions).should == nil
    end


    it 'should find the greatest match for versions with placeholders' do
      SemVer.find_matching('1.0.x', @versions).should == 'v1.0.1'
      SemVer.find_matching('1.1.x', @versions).should == 'v1.1.4'
      SemVer.find_matching('1.x', @versions).should   == 'v1.2.1'
      SemVer.find_matching('1.x.x', @versions).should == 'v1.2.1'
      SemVer.find_matching('2.x', @versions).should   == 'v2.0.0-rc1'
      SemVer.find_matching('2.x.x', @versions).should == 'v2.0.0-rc1'
      SemVer.find_matching('2.1.x', @versions).should == nil
    end
  end

  describe '::[]' do
    it "should produce expected ranges" do
      tests = {
        '1.2.3-alpha'          => SemVer.new('v1.2.3-alpha')  ..  SemVer.new('v1.2.3-alpha'),
        '1.2.3'                => SemVer.new('v1.2.3-')       ..  SemVer.new('v1.2.3'),
        '>1.2.3-alpha'         => SemVer.new('v1.2.3-alpha-') ..  SemVer::MAX,
        '>1.2.3'               => SemVer.new('v1.2.4-')       ..  SemVer::MAX,
        '<1.2.3-alpha'         => SemVer::MIN                 ... SemVer.new('v1.2.3-alpha'),
        '<1.2.3'               => SemVer::MIN                 ... SemVer.new('v1.2.3-'),
        '>=1.2.3-alpha'        => SemVer.new('v1.2.3-alpha')  ..  SemVer::MAX,
        '>=1.2.3'              => SemVer.new('v1.2.3-')       ..  SemVer::MAX,
        '<=1.2.3-alpha'        => SemVer::MIN                 ..  SemVer.new('v1.2.3-alpha'),
        '<=1.2.3'              => SemVer::MIN                 ..  SemVer.new('v1.2.3'),
        '>1.2.3-a <1.2.3-b'    => SemVer.new('v1.2.3-a-')     ... SemVer.new('v1.2.3-b'),
        '>1.2.3 <1.2.5'        => SemVer.new('v1.2.4-')       ... SemVer.new('v1.2.5-'),
        '>=1.2.3-a <= 1.2.3-b' => SemVer.new('v1.2.3-a')      ..  SemVer.new('v1.2.3-b'),
        '>=1.2.3 <=1.2.5'      => SemVer.new('v1.2.3-')       ..  SemVer.new('v1.2.5'),
        '1.2.3-a - 2.3.4-b'    => SemVer.new('v1.2.3-a')      ..  SemVer.new('v2.3.4-b'),
        '1.2.3 - 2.3.4'        => SemVer.new('v1.2.3-')       ..  SemVer.new('v2.3.4'),
        '~1.2.3'               => SemVer.new('v1.2.3-')       ... SemVer.new('v1.3.0-'),
        '~1.2'                 => SemVer.new('v1.2.0-')       ... SemVer.new('v2.0.0-'),
        '~1'                   => SemVer.new('v1.0.0-')       ... SemVer.new('v2.0.0-'),
        '1.2.x'                => SemVer.new('v1.2.0')        ... SemVer.new('v1.3.0-'),
        '1.x'                  => SemVer.new('v1.0.0')        ... SemVer.new('v2.0.0-'),
      }

      tests.each do |vstring, expected|
        SemVer[vstring].should == expected
      end
    end

    it "should suit up" do
      suitability = {
        [ '1.2.3',         'v1.2.2' ] => false,
        [ '>=1.2.3',       'v1.2.2' ] => false,
        [ '<=1.2.3',       'v1.2.2' ] => true,
        [ '>= 1.2.3',      'v1.2.2' ] => false,
        [ '<= 1.2.3',      'v1.2.2' ] => true,
        [ '1.2.3 - 1.2.4', 'v1.2.2' ] => false,
        [ '~1.2.3',        'v1.2.2' ] => false,
        [ '~1.2',          'v1.2.2' ] => true,
        [ '~1',            'v1.2.2' ] => true,
        [ '1.2.x',         'v1.2.2' ] => true,
        [ '1.x',           'v1.2.2' ] => true,

        [ '1.2.3',         'v1.2.3-alpha' ] => true,
        [ '>=1.2.3',       'v1.2.3-alpha' ] => true,
        [ '<=1.2.3',       'v1.2.3-alpha' ] => true,
        [ '>= 1.2.3',      'v1.2.3-alpha' ] => true,
        [ '<= 1.2.3',      'v1.2.3-alpha' ] => true,
        [ '>1.2.3',        'v1.2.3-alpha' ] => false,
        [ '<1.2.3',        'v1.2.3-alpha' ] => false,
        [ '> 1.2.3',       'v1.2.3-alpha' ] => false,
        [ '< 1.2.3',       'v1.2.3-alpha' ] => false,
        [ '1.2.3 - 1.2.4', 'v1.2.3-alpha' ] => true,
        [ '1.2.3 - 1.2.4', 'v1.2.4-alpha' ] => true,
        [ '1.2.3 - 1.2.4', 'v1.2.5-alpha' ] => false,
        [ '~1.2.3',        'v1.2.3-alpha' ] => true,
        [ '~1.2.3',        'v1.3.0-alpha' ] => false,
        [ '~1.2',          'v1.2.3-alpha' ] => true,
        [ '~1.2',          'v2.0.0-alpha' ] => false,
        [ '~1',            'v1.2.3-alpha' ] => true,
        [ '~1',            'v2.0.0-alpha' ] => false,
        [ '1.2.x',         'v1.2.3-alpha' ] => true,
        [ '1.2.x',         'v1.3.0-alpha' ] => false,
        [ '1.x',           'v1.2.3-alpha' ] => true,
        [ '1.x',           'v2.0.0-alpha' ] => false,

        [ '1.2.3',         'v1.2.3' ] => true,
        [ '>=1.2.3',       'v1.2.3' ] => true,
        [ '<=1.2.3',       'v1.2.3' ] => true,
        [ '>= 1.2.3',      'v1.2.3' ] => true,
        [ '<= 1.2.3',      'v1.2.3' ] => true,
        [ '1.2.3 - 1.2.4', 'v1.2.3' ] => true,
        [ '~1.2.3',        'v1.2.3' ] => true,
        [ '~1.2',          'v1.2.3' ] => true,
        [ '~1',            'v1.2.3' ] => true,
        [ '1.2.x',         'v1.2.3' ] => true,
        [ '1.x',           'v1.2.3' ] => true,

        [ '1.2.3',         'v1.2.4' ] => false,
        [ '>=1.2.3',       'v1.2.4' ] => true,
        [ '<=1.2.3',       'v1.2.4' ] => false,
        [ '>= 1.2.3',      'v1.2.4' ] => true,
        [ '<= 1.2.3',      'v1.2.4' ] => false,
        [ '1.2.3 - 1.2.4', 'v1.2.4' ] => true,
        [ '~1.2.3',        'v1.2.4' ] => true,
        [ '~1.2',          'v1.2.4' ] => true,
        [ '~1',            'v1.2.4' ] => true,
        [ '1.2.x',         'v1.2.4' ] => true,
        [ '1.x',           'v1.2.4' ] => true,
      }

      suitability.each do |arguments, expected|
        range, vstring = arguments
        actual = SemVer[range] === SemVer.new(vstring)
        actual.should == expected
      end
    end
  end

  describe 'instantiation' do
    it 'should raise an exception when passed an invalid version string' do
      expect { SemVer.new('invalidVersion') }.to raise_exception ArgumentError
    end

    it 'should populate the appropriate fields for a basic version string' do
      version = SemVer.new('1.2.3')
      version.major.should   == 1
      version.minor.should   == 2
      version.tiny.should    == 3
      version.special.should == ''
    end

    it 'should populate the appropriate fields for a special version string' do
      version = SemVer.new('3.4.5-beta6')
      version.major.should   == 3
      version.minor.should   == 4
      version.tiny.should    == 5
      version.special.should == '-beta6'
    end
  end

  describe '#matched_by?' do
    subject { SemVer.new('v1.2.3-beta') }

    describe 'should match against' do
      describe 'literal version strings' do
        it { should be_matched_by('1.2.3-beta') }

        it { should_not be_matched_by('1.2.3-alpha') }
        it { should_not be_matched_by('1.2.4-beta') }
        it { should_not be_matched_by('1.3.3-beta') }
        it { should_not be_matched_by('2.2.3-beta') }
      end

      describe 'partial version strings' do
        it { should be_matched_by('1.2.3') }
        it { should be_matched_by('1.2') }
        it { should be_matched_by('1') }
      end

      describe 'version strings with placeholders' do
        it { should be_matched_by('1.2.x') }
        it { should be_matched_by('1.x.3') }
        it { should be_matched_by('1.x.x') }
        it { should be_matched_by('1.x') }
      end
    end
  end

  describe 'comparisons' do
    describe 'against a string' do
      it 'should just work' do
        SemVer.new('1.2.3').should == '1.2.3'
      end
    end

    describe 'against a symbol' do
      it 'should just work' do
        SemVer.new('1.2.3').should == :'1.2.3'
      end
    end

    describe 'on a basic version (v1.2.3)' do
      subject { SemVer.new('v1.2.3') }

      it { should == SemVer.new('1.2.3') }

      # Different major versions
      it { should > SemVer.new('0.2.3') }
      it { should < SemVer.new('2.2.3') }

      # Different minor versions
      it { should > SemVer.new('1.1.3') }
      it { should < SemVer.new('1.3.3') }

      # Different tiny versions
      it { should > SemVer.new('1.2.2') }
      it { should < SemVer.new('1.2.4') }

      # Against special versions
      it { should > SemVer.new('1.2.3-beta') }
      it { should < SemVer.new('1.2.4-beta') }
    end

    describe 'on a special version (v1.2.3-beta)' do
      subject { SemVer.new('v1.2.3-beta') }

      it { should == SemVer.new('1.2.3-beta') }

      # Same version, final release
      it { should < SemVer.new('1.2.3') }

      # Different major versions
      it { should > SemVer.new('0.2.3') }
      it { should < SemVer.new('2.2.3') }

      # Different minor versions
      it { should > SemVer.new('1.1.3') }
      it { should < SemVer.new('1.3.3') }

      # Different tiny versions
      it { should > SemVer.new('1.2.2') }
      it { should < SemVer.new('1.2.4') }

      # Against special versions
      it { should > SemVer.new('1.2.3-alpha') }
      it { should < SemVer.new('1.2.3-beta2') }
    end
  end
end

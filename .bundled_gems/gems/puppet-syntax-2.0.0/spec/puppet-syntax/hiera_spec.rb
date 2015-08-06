require 'spec_helper'

describe PuppetSyntax::Hiera do
  let(:subject) { PuppetSyntax::Hiera.new }

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it "should return nothing from valid YAML" do
    files = fixture_hiera('hiera_good.yaml')
    res = subject.check(files)
    expect(res).to be == []
  end

  it "should return an error from invalid YAML" do
    case RUBY_VERSION
    when /1.8/
      files = fixture_hiera('hiera_bad_18.yaml')
      expected = /syntax error on line 3, col -1: `'/
    else
      files = fixture_hiera('hiera_bad.yaml')
      expected = /scanning a directive at line 1 column 1/
    end
    res = subject.check(files)
    expect(res.size).to be == 1
    expect(res.first).to match(expected)
  end
end

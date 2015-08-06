require 'spec_helper'

describe PuppetSyntax do
  after do
    PuppetSyntax.exclude_paths = []
  end

  it 'should default exclude_paths to empty array' do
    expect(PuppetSyntax.exclude_paths).to be_empty
  end

  it 'should support setting exclude_paths' do
    PuppetSyntax.exclude_paths = ["foo", "bar/baz"]
    expect(PuppetSyntax.exclude_paths).to eq(["foo", "bar/baz"])
  end

  it 'should support appending exclude_paths' do
    PuppetSyntax.exclude_paths << "foo"
    expect(PuppetSyntax.exclude_paths).to eq(["foo"])
  end

  it 'should support future parser setting' do
    PuppetSyntax.future_parser = true
    expect(PuppetSyntax.future_parser).to eq(true)
  end

  it 'should support a fail_on_deprecation_notices setting' do
    PuppetSyntax.fail_on_deprecation_notices = false
    expect(PuppetSyntax.fail_on_deprecation_notices).to eq(false)
  end

end

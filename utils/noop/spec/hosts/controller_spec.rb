require 'spec_helper'
manifest = 'controller.pp'

describe manifest do
  let :facts do
    Noop.facts
  end

  before :all do
    Noop.set_manifest manifest
  end

  it { should compile }

end

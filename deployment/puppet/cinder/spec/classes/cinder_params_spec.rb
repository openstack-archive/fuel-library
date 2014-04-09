require 'spec_helper'

describe 'cinder::params' do

  let :facts do
    {:osfamily => 'Debian'}
  end
  it 'should compile' do
    subject
  end

end

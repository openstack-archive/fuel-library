require 'spec_helper'

describe 'extend_kopts' do

  it 'number args' do
    is_expected.to run.with_params('foo').\
      and_raise_error(Puppet::ParseError, /extend_kopts(): wrong number of arguments 1; must be 2)/)
  end

end

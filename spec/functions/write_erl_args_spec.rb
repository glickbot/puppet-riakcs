# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'spec_helper'

describe 'write_erl_args', :type => :puppet_function do
  it { subject.call([{
    '-name' => 'riakcs-5',
    '-env'  => {
      :ERL_MAX_PORTS => 4096
    }
  }]).
    should eq(
"-env ERL_MAX_PORTS 4096
-name riakcs-5") }
end

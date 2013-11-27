# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'spec_helper'
require 'shared_contexts'

describe 'riakcs', :type => :class do

  let(:title) { "riakcs" }

  include_context 'hieradata'
end

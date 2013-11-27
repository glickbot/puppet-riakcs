# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'spec_helper'
require 'shared_contexts'

describe 'riakcs', :type => :class do

  let(:title) { "riakcs" }

  include_context 'hieradata'

  describe 'at baseline with defaults' do
    let(:params) {{}}
    it { should contain_class('riakcs') }
    # we're defaulting to repos now, not http files
    it { should contain_package('riak-cs').with_ensure('installed') }
    it { should contain_service('riak-cs').with({
        :ensure => 'running',
        :enable => 'true'
      }) }
    it { should contain_file('/etc/riak-cs/app.config').with_ensure('present') }
    it { should contain_file('/etc/riak-cs/vm.args').with_ensure('present') }
    it { should contain_riakcs__vmargs().with_notify('Service[riak-cs]') }
  end

  describe 'custom package configuration' do
    let(:params) { { :version => '1.2.0', :package => 'custom_riak-cs',
                     :download_hash => 'abcd', :use_repos => false } }
    it 'should be downloading the package to be installed' do
      subject.should contain_httpfile('/tmp/custom_riak-cs-1.2.0.deb').
        with({
          :path => '/tmp/custom_riak-cs-1.2.0.deb',
          :hash => 'abcd' })
    end
    it { should contain_package('custom_riak-cs').
        with({
          :ensure => 'installed',
          :source =>'/tmp/custom_riak-cs-1.2.0.deb'}) }

    context 'with :use_repos => true' do
      let(:params) { {:use_repos => true, :package => 'riak-cs-1.2.1-1.el6'} }

      it do
        should contain_service('riak-cs').with_require(%Q([Class[Riakcs::Appconfig]\
{:name=>"Riakcs::Appconfig"}, Class[Riakcs::Vmargs]{:name=>"Riakcs::Vmargs\
"}, Class[Riakcs::Config]{:name=>"Riakcs::Config"}, User[riak]{:name=>\
"riak"}, Package[riak-cs-1.2.1-1.el6]{:name=>"riak-cs-1.2.1-1.el6"}, Anc\
hor[riak-cs::start]{:name=>"riak-cs::start"}]))
      end
    end
  end

  def res t, n
    catalogue.resource(t, n).send(:parameters)
  end

  describe 'when changing configuration' do
    #before(:all) { puts catalogue.resources }
    it("will restart Service") {
      res('class', 'Riakcs::Appconfig')[:notify].
        should eq('Service[riak-cs]') }
  end

  describe 'when changing configuration, the service' do
    let(:params) { { :service_autorestart => false } }
    it('will not restart') {
      res('class', 'Riakcs::Appconfig')[:notify].nil?.should be_true }
  end

  describe 'when decommissioning (absent):' do
    let(:params) { { :absent => true } }
    it("should remove the riak-cs package") {
      should contain_package('riak-cs').with_ensure('absent') }
    it("should remove configuration file File[/etc/riak-cs/vm.args]") {
      should contain_file('/etc/riak-cs/vm.args').with_ensure('absent') }
    it("remove configuration File[/etc/riak-cs/app.config]") {
      should contain_file('/etc/riak-cs/app.config').with_ensure('absent') }
    it("should stop Service[riak-cs]") {
      should contain_service('riak-cs').with_ensure('stopped') }
    it("should disable boot of Service[riak-cs]") {
      should contain_service('riak-cs').with_enable('false') }
  end

end

# == Class: riakcs::params
#
# This class implements the module params pattern, but it's loaded using hiera
# as opposed to the 'default' usage of coding the parameter values in your
# manifest.
#
# == Usage
#
# Don't use this class directly; it's being used where it is needed.
# Hiera will try and inject overrides where these properties are being used.
#
class riakcs::params {

  $package = $::operatingsystem ? {
    default => 'riak-cs',
  }

  $deps = $::operatingssytem ? {
    /(?i:centos|redhat|Amazon)/ => [],
    default                     => [],
  }

  $package_type = $::operatingsystem ? {
    /(?i:centos|redhat|Amazon)/ => 'rpm',
    default                     => 'deb',
  }

  $package_provider = $::operatingsystem ? {
    /(?i:centos|redhat|Amazon)/ => 'rpm',
    default                     => 'dpkg',
  }

  $architecture = $::operatingsystem ? {
    /(?i:centos|redhat|Amazon)/ => 'x86_64',
    default                     => 'amd64',
  }

  $has_restart = $::operatingsystem ? {
    /(?i:centos|redhat|Amazon)/ => true,
    default                     => false,
  }

  $version = '1.4.2'
  $version_maj_min = semver_maj_min($version)
  $use_repos = true
  $get = $::operatingsystem ? {
    /(?i:centos|redhat|Amazon)/ => "/riakcs/${version_maj_min}/${version}/rhel/6/riak-cs-${version}-1.el6.${architecture}.${package_type}",
    default                     => "/riakcs/${version_maj_min}/${version}/ubuntu/precise/riak-cs_${version}-1_${architecture}.${package_type}",
  }

  $download = "http://downloads.basho.com.s3-website-us-east-1.amazonaws.com${get}"

  $download_hash = "${download}.sha"

  $log_dir = '/var/log/riak-cs'
  $error_log = "${log_dir}/error.log"
  $info_log = "${log_dir}/console.log"
  $crash_log = "${log_dir}/crash.log"

  $erl_log_dir = '/var/log/riak-cs'
  $data_dir = '/var/lib/riak-cs'
  $lib_dir = '/usr/lib/riak-cs'
  $bin_dir = '/usr/sbin'
  $etc_dir = '/etc/riak-cs'

  $service_autorestart = true
}

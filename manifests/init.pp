# Class: riakcs
#
# This module manages Riakcs, the dynamo-based NoSQL database.
#
# == Parameters
#
# version:
#   Version of package to fetch.
#
# package:
#   Name of package as known by OS.
#
# package_hash:
#   A URL of a hash-file or sha2-string in hexdigest
#
# manage_repos:
#   If +true+ it will try to setup the repositories provided by basho.com to
#   install Riakcs. If you manage your own repositories for whatever reason you
#   probably want to set this to +false+.
#
# source:
#   Sets the content of source parameter for main configuration file
#   If defined, riakcs's app.config file will have the param: source => $source.
#   Mutually exclusive with $template.
#
# template:
#   Sets the content of the content parameter for the main configuration file
#
# architecture:
#   What architecture to fetch/run on
#
# == Requires
#
# * stdlib (module)
# * hiera-puppet (module)
# * hiera (package in 2.7.x, but included inside Puppet 3.0)
#
# == Usage
#
# === Default usage:
#   This gives you all the defaults:
#
# class { 'riakcs': }
#
# === Overriding configuration
#
#   In this example, we're adding HTTPS configuration
#   with a certificate file / public key and a private
#   key, both placed in the /etc/riakcs folder.
#
#   When you add items to the 'cfg' parameter, they will override the
#   already defined defaults with those keys defined. The hash is not
#   hard-coded, so you don't need to change the manifest when new config
#   options are made available.
#
#   You can probably benefit from using hiera's hierarchical features
#   in this case, by defining defaults in a yaml file for all nodes
#   and only then configuring specifics for each node.
#
#  class { 'riakcs':
#    cfg => {
#      riakcs_core => {
#        https => {
#          "__string_${$::ipaddress}" => 8443
#        },
#        ssl => {
#          certfile => "${etc_dir}/cert.pem",
#          keyfile  => "${etc_dir}/key.pem",
#        }
#      }
#    }
#  }
#
# == Author
#   Henrik Feldt, github.com/basho/puppet-riakcs.
#
class riakcs (
  $version             = hiera('version', $riakcs::params::version),
  $package             = hiera('package', $riakcs::params::package),
  $download            = hiera('download', $riakcs::params::download),
  $use_repos           = hiera('use_repos', $riak::params::use_repos),
  $manage_repos        = hiera('manage_repos', true),
  $download_hash       = hiera('download_hash', $riakcs::params::download_hash),
  $source              = hiera('source', ''),
  $template            = hiera('template', ''),
  $architecture        = hiera('architecture', $riakcs::params::architecture),
  $log_dir             = hiera('log_dir', $riakcs::params::log_dir),
  $erl_log_dir         = hiera('erl_log_dir', $riakcs::params::erl_log_dir),
  $etc_dir             = hiera('etc_dir', $riakcs::params::etc_dir),
  $data_dir            = hiera('data_dir', $riakcs::params::data_dir),
  $service_autorestart = hiera('service_autorestart', $riakcs::params::service_autorestart),
  $cfg                 = hiera_hash('cfg', {}),
  $vmargs_cfg          = hiera_hash('vmargs_cfg', {}),
  $disable             = false,
  $disableboot         = false,
  $absent              = false,
  $ulimit              = $riakcs::params::ulimit,
  $limits_template     = $riakcs::params::limits_template,
) inherits riakcs::params {

  include stdlib

  $pkgfile = "/tmp/${$package}-${$version}.${$riakcs::params::package_type}"

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  $manage_package = $absent ? {
    true    => 'absent',
    default => 'installed',
  }

  $manage_repos_real = $use_repos ? {
    true    => $manage_repos,
    default => false
  }

  $manage_service_ensure = $disable ? {
    true    => 'stopped',
    default => $absent ? {
      true    => 'stopped',
      default => 'running',
    },
  }

  $manage_service_enable = $disableboot ? {
    true    => false,
    default => $disable ? {
      true    => false,
      default => $absent ? {
        true    => false,
        default => true,
      },
    },
  }

  $manage_file = $absent ? {
    true    => 'absent',
    default => 'present',
  }

  $manage_service_autorestart = $service_autorestart ? {
    /true/  => 'Service[riak-cs]',
    default => undef,
  }

  anchor { 'riakcs::start': }

  package { $riakcs::params::deps:
    ensure  => $manage_package,
    require => Anchor['riakcs::start'],
    before  => Anchor['riakcs::end'],
  }

  if $use_repos == true {
    package { $package:
      ensure  => $manage_package,
      require => [
        Class[riak::config],
        Package[$riakcs::params::deps],
        Anchor['riakcs::start'],
      ],
      before  => Anchor['riakcs::end'],
    }
  } else {
    httpfile {  $pkgfile:
      ensure  => present,
      source  => $download,
      hash    => $download_hash,
      require => Anchor['riakcs::start'],
      before  => Anchor['riakcs::end'],
    }
    package { $package:
      ensure   => $manage_package,
      source   => $pkgfile,
      provider => $riakcs::params::package_provider,
      require  => [
        Httpfile[$pkgfile],
        Package[$riakcs::params::deps],
        Anchor['riakcs::start'],
      ],
      before   => Anchor['riakcs::end'],
    }
  }

  file { $etc_dir:
    ensure  => directory,
    mode    => '0755',
    require => Anchor['riakcs::start'],
    before  => Anchor['riakcs::end'],
  }

  file { "/usr/sbin/create_cs_user": 
    owner   => 'root',
    group   => 'root',
    mode    => '755',
    content => template('riakcs/create_cs_user.escript.erb'),
    require => [
      Package[$package],
    ],
  }

  class { 'riakcs::appconfig':
    absent   => $absent,
    source   => $source,
    template => $template,
    cfg      => $cfg,
    require  => [
      File[$etc_dir],
      Anchor['riakcs::start'],
    ],
    notify   => $manage_service_autorestart,
    before   => Anchor['riakcs::end'],
  }

  class { 'riakcs::vmargs':
    absent  => $absent,
    cfg     => $vmargs_cfg,
    require => [
      File[$etc_dir],
      Anchor['riakcs::start'],
    ],
    before  => Anchor['riakcs::end'],
    notify  => $manage_service_autorestart,
  }

  group { 'riakcs':
    ensure => present,
    system => true,
    require => Anchor['riakcs::start'],
    before  => Anchor['riakcs::end'],
  }

  user { 'riakcs':
    ensure  => ['present'],
    system => true,
    gid     => 'riakcs',
    home    => $data_dir,
    require => [
      Group['riakcs'],
      Anchor['riakcs::start'],
    ],
    before  => Anchor['riak::end'],
  }

  service { 'riak-cs':
    ensure     => $manage_service_ensure,
    enable     => $manage_service_enable,
    hasrestart => $riakcs::params::has_restart,
    require    => [
      Class['riakcs::appconfig'],
      Class['riakcs::vmargs'],
      User['riak'],
      Package[$package],
      Anchor['riakcs::start'],
    ],
    before  => Anchor['riakcs::end'],
  }

  anchor { 'riakcs::end': }
}

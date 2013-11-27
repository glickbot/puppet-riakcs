# For docs, see
# http://wiki.basho.com/Configuration-Files.html#app.config
#
# == Parameters
#
# cfg:
#   A configuration hash of erlang to be written to
#   File[/etc/riakcs/app.config]. It's recommended to browse
#   the 'appconfig.pp' file to see sample values.
#
# source:
#   The source of the app.config file, if you wish to define it
#   explicitly rather than rely on the hash. This parameter
#   is mutually exclusive with 'template'.
#
# template:
#   An ERB template file for app.config, if you wish to define it
#   explicitly rather than rely on the hash. This parameter
#   is mutually exclusive with 'source'.
#
# absent:
#   If true, the configuration file is ensured to be absent from
#   the system.
#
class riakcs::appconfig(
  $cfg = {},
  $source = hiera('source', ''),
  $template = hiera('template', ''),
  $absent = false
) {

  require riakcs::params

  # merge the given $cfg parameter with the default,
  # favoring the givens, rather than the defaults
  $appcfg = merge_hashes({
    riak_cs  => {
      cs_ip => $::ipaddress,
      cs_port => 8080,
      riak_ip => "127.0.0.1",
      riak_pb_port => 8087,
      stanchion_ip => "127.0.0.1",
      stanchion_port => 8085,
      stanchion_ssl => "false",
      anonymous_user_creation => "false",
      admin_key => "admin-key",
      admin_secret => "admin-secret",
      cs_root_host => "s3.amazonaws.com",
      connection_pools => {
        request_pool => [ '__tuple', 128, 0 ],
        bucket_list_pool => [ '__tuple', 5, 0 ],
      },
      rewrite_module => "__atom_riak_cs_s3_rewrite",
      auth_module => "riak_cs_s3_auth",
      fold_objects_for_list_keys => "false",
      n_val_1_get_requests => "true",
      cs_version => 10300,
      access_log_flush_factor => 1,
      access_log_flush_size => 1000000,
      access_archive_period => 3600,
      access_archiver_max_backlog => 2,
      stroage_schedule => [],
      storage_archive_period => 86400,
      usage_request_limit => 744,
      leeway_seconds => 86400,
      gc_interval => 900,
      gc_retry_interval => 21600,
      trust_x_forwarded_for => "false",
      dtrace_support => "false",
    },
    webmachine => {
      server_name => "Riak CS",
      log_handlers => {
        webmachine_log_handler => ["/var/log/riak-cs"],
        riak_cs_access_log_handler => [],
      },
    },
    lager => {
      handlers => {
        lager_console_backend   => '__atom_info',
        lager_file_backend => {
          file => $riakcs::params::error_log,
          level => '__atom_error',
          size => 10485760,
          date => "$D0",
          count => 5,
        },
        lager_file_backend => {
          file => $riakcs::params::console_log,
          level => '__atom_info',
          size => 10485760,
          date => "$D0",
          count => 5,
        },
      },
      crash_log             => $riakcs::params::crash_log,
      crash_log_msg_side    => 65536,
      crash_log_size        => 10485760,
      crash_log_date        => '$D0',
      crash_log_count       => 5,
      error_logger_redirect => true,
    },
    sasl => {
      sasl_error_logger => false,
    },
  }, $cfg)

  $manage_file = $absent ? {
    true    => 'absent',
    default => 'present',
  }

  $manage_template = $template ? {
    ''      => write_erl_config($appcfg),
    default => template($template),
  }

  $manage_source = $source ? {
    ''      => undef,
    default => $source,
  }

  anchor { 'riakcs::appconfig::start': }

  file { [
      "/var/log/riak-cs",
    ]:
    ensure  => directory,
    mode    => '0644',
    owner   => 'riakcs',
    group   => 'riakcs',
    require => Anchor['riakcs::appconfig::start'],
    before  => Anchor['riakcs::appconfig::end'],
  }

  file { "/etc/riak-cs/app.config":
    ensure  => $manage_file,
    content => $manage_template,
    source  => $manage_source,
    require => [
      Anchor['riakcs::appconfig::start'],
    ],
    before  => Anchor['riakcs::appconfig::end'],
  }

  anchor { 'riakcs::appconfig::end': }
}

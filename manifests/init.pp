# Installs and configures heartbeat
#
# @summary Installs and configures heartbeat
#
# @example Basic configuration with two modules and output to Elasticsearch
#  class{'heartbeat':
#    monitors => [
#      {
#       'type' => 'icmp',
#       'schedule' => '*/5 * * * * * *',
#       'hosts' => ['myhost', 'myotherhost'],
#      },
#    ],
#    outputs => {
#     'elasticsearch' => {
#       'hosts' => ['http://localhost:9200'],
#       'index' => 'heartbeat-%{+YYYY.MM.dd}',
#     },
#    },
#  }
#
# @param beat_name the name of the shipper (defaults to the hostname).
# @param fields_under_root whether to add the custom fields to the root of the document.
# @param queue heartbeat's internal queue.
# @param logging the heartbeat's logfile configuration.
# @param outputs the mandatory "outputs" section of the configuration file.
# @param major_version the major version of the package to install.
# @param ensure whether Puppet should manage heartbeat or not.
# @param service_provider which boot framework to use to install and manage the service.
# @param manage_repo whether to add the elastic upstream repo to the package manager.
# @param service_ensure the status of the heartbeat service.
# @param package_ensure the package version to install.
# @param config_file_mode the permissions of the main configuration file.
# @param disable_configtest whether to check if the configuration file is valid before running the service.
# @param tags the tags to add to each document.
# @param fields the fields to add to each document.
# @param monitoring adds internal monitoring. Works with both xpack.monitoring and monitoring.
# @param monitors the monitors to watch for example icmp/tcp/http.
# @param processors the optional processors for events enhancement.
#
class heartbeat (
  String $beat_name                                                   = $::hostname,
  Boolean $fields_under_root                                          = false,
  Hash $queue                                                         = {
    'mem' => {
      'events' => 4096,
      'flush' => {
        'min_events' => 0,
        'timeout' => '0s',
      },
    },
  },
  Hash $logging                                                       = {
    'level' => 'info',
    'selectors'  => undef,
    'to_syslog' => false,
    'to_eventlog' => false,
    'json' => false,
    'to_files' => true,
    'files' => {
      'path' => '/var/log/heartbeat',
      'name' => 'heartbeat',
      'keepfiles' => 7,
      'rotateeverybytes' => 10485760,
      'permissions' => '0600',
    },
    'metrics' => {
      'enabled' => true,
      'period' => '30s',
    },
  },
  Hash $outputs                                                       = {},
  Enum['5', '6', '7'] $major_version                                  = '7',
  Enum['present', 'absent'] $ensure                                   = 'present',
  Enum['systemd', 'init'] $service_provider                           = 'systemd',
  Boolean $manage_repo                                                = true,
  Optional[Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl]] $apt_repo_url  = undef,
  Optional[Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl]] $yum_repo_url  = undef,
  Optional[Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl]] $gpg_key_url   = undef,
  String $gpg_key_id                                                  = '',
  Enum['enabled', 'running', 'disabled', 'unmanaged'] $service_ensure = 'enabled',
  String $package_ensure                                              = 'present',
  String $config_file_mode                                            = '0644',
  Boolean $disable_configtest                                         = false,
  Optional[Array[String]] $tags                                       = undef,
  Optional[Hash] $fields                                              = undef,
  Optional[Array[Hash]] $monitors                                     = undef,
  Optional[Array[Hash]] $processors                                   = undef,
  Optional[Hash] $monitoring                                          = undef,
  Optional[Hash] $setup                                               = undef,
) {

  contain heartbeat::repo
  contain heartbeat::install
  contain heartbeat::config
  contain heartbeat::service

  if $manage_repo {
    Class['heartbeat::repo']
    ->Class['heartbeat::install']
  }

  case $ensure {
    'present': {
      Class['heartbeat::install']
      ->Class['heartbeat::config']
      ~>Class['heartbeat::service']
    }
    default: {
      Class['heartbeat::service']
      ->Class['heartbeat::config']
      ->Class['heartbeat::install']
    }
  }
}

# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::elastic
class grayloginstall::elastic (
  # Graylog 3 does not work with Elasticsearch 7.x!
  String  $version              = '6.8.10',
  # Any site-local addresses on the system, for example 192.168.0.1
  Grayloginstall::NetworkHost
          $network_host         = '_site_',
  # default is 2 (avoiding split brain in case of 2-3 nodes)
  Integer $minimum_master_nodes = 2,
  # default is ["127.0.0.1", "[::1]"]
  Array[Stdlib::IP::Address]
          $discovery_seed_hosts = ['127.0.0.1', '::1'],
)
{
  $remote_discovery_seed_hosts = $discovery_seed_hosts.filter |$addr| {
    $addr in ['127.0.0.1', '::1'] or
    ! grayloginstall::selfaddr($addr)
  }
  $config_discovery_seed_hosts = grayloginstall::configaddr($remote_discovery_seed_hosts)

  # https://www.elastic.co/guide/en/elasticsearch/reference/6.7/rpm.html
  class { 'elasticsearch':
    version           => $version,
    manage_repo       => false,
    config            => {
      'cluster.name'             => 'graylog',
      'action.auto_create_index' => '.watches,.triggered_watches,.watcher-history-*',
    },
    restart_on_change => true
  }

  class { 'elastic_stack::repo':
    version => 6,
  }

  # file resource to not purge repo in case if /etc/yum.repos.d are managed with purge => true
  file { '/etc/yum.repos.d/elastic.repo':
    mode => '0600',
  }

  elasticsearch::instance { 'graylog':
    config => {
      'network.host'                       => $network_host,
      'discovery.zen.ping.unicast.hosts'   => $config_discovery_seed_hosts,
      'discovery.zen.minimum_master_nodes' => $minimum_master_nodes,
    },
  }

  Class['elastic_stack::repo']
      -> Class['elasticsearch::package']
}

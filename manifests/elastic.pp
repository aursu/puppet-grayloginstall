# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::elastic
class grayloginstall::elastic (
  # Graylog 3 does not work with Elasticsearch 7.x!
  String  $version      = '6.7.2',
  Stdlib::IP::Address
          $network_host = '127.0.0.1',
)
{
  # https://www.elastic.co/guide/en/elasticsearch/reference/6.7/rpm.html
  class { 'elasticsearch':
    version     => $version,
    manage_repo => false,
    config      => {
      'cluster.name'             => 'graylog',
      'action.auto_create_index' => false,
    }
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
      'network.host' => $network_host,
    },
  }

  Class['elastic_stack::repo']
      -> Class['elasticsearch::package']
}

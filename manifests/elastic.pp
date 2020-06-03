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
    manage_repo => true,
    config      => {
      'cluster.name'             => 'graylog',
      'action.auto_create_index' => false,
    }
  }

  elasticsearch::instance { 'graylog':
    config => {
      'network.host' => $network_host,
    },
  }
}

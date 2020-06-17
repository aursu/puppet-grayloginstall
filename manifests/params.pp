# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::params
class grayloginstall::params {
  $cluster_name    = 'graylog'
  $elastic_version = '6.8.10'
  $elastic_network_host = '_site_'
  $elastic_discovery_seed_hosts = ['127.0.0.1', '::1']

  $mongodb_version = '4.2.7'
  $mongodb_bind_ip = ['127.0.0.1']

  $graylog_version = '3.3.0'

  $rel = split($graylog_version, '[.]')
  $graylog_major = join($rel[0,2], '.')

  $http_bind_ip = '127.0.0.1'
}

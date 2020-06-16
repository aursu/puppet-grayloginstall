# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::params
class grayloginstall::params {
  $elastic_version = '6.8.10'
  $elastic_network_host = '_site_'
  $elastic_discovery_seed_hosts = ['127.0.0.1', '::1']
}

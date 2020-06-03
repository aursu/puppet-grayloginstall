# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::java
class grayloginstall::java {
  class { 'java':
    distribution => 'jre',
  }
}

# @summary Install Java Runtime
#
# Install Java Runtime
#
# @example
#   include grayloginstall::java
class grayloginstall::java {
  class { 'java':
    distribution => 'jre',
  }
}

require 'spec_helper'

describe 'grayloginstall::configaddr' do
  it {
    is_expected.to run.with_params('2001:1810:1040:3::26').and_return('[2001:1810:1040:3::26]')
  }

  it {
    is_expected.to run.with_params('104.134.91.209').and_return('104.134.91.209')
  }

  it {
    is_expected.to run.with_params(['127.0.0.1', '::1']).and_return(['127.0.0.1', '[::1]'])
  }

  it {
    is_expected.to run.with_params(['192.168.200.225', '104.134.88.225', 'fe80::c252:fce7:8638:1604']).and_return(['192.168.200.225', '104.134.88.225', '[fe80::c252:fce7:8638:1604]'])
  }
end

# frozen_string_literal: true

require 'spec_helper'

describe 'grayloginstall::mongodb_host' do
  let(:title) { 'namevar' }
  let(:params) do
    {
      'ip'           => '192.168.200.225',
      'cluster_name' => 'graylog',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end

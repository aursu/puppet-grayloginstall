# frozen_string_literal: true

require 'spec_helper'

describe 'grayloginstall::web' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'server_name' => 'graylog.domain.tld',
        }
      end

      it { is_expected.to compile }
    end
  end
end

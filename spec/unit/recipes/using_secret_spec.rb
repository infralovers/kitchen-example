#
# Cookbook:: kitchen-example
# Spec:: using_secret
#
# Copyright:: 2017, The Authors, All Rights Reserved.

require 'spec_helper'

describe 'kitchen-example::using_secret' do
  context 'When all attributes are default, on an Oracle 7.2' do
    let(:chef_run) do
      # for a complete list of available platforms and versions see:
      # https://github.com/customink/fauxhai/blob/master/PLATFORMS.md
      ChefSpec::ServerRunner.new(platform: 'oracle', version: '7.2') do |_node, server|
        server.create_data_bag('mydatabag',
          'secretstuff' => { firstsecret: 'must remain secret' }
                              )
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end

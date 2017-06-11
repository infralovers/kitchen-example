#
# Cookbook:: kitchen-example
# Spec:: using_secret
#
# Copyright:: 2017, The Authors, All Rights Reserved.

secret = data_bag_item('mydatabag', 'secretstuff')

log "secret: #{secret['firstsecret']}"

file '/etc/special_config_with_secret_data' do
  content secret['firstsecret']
end

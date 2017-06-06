# # encoding: utf-8

# Inspec test for recipe kitchen-example::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe file('/etc/special_config_with_search_data') do
  its('content') { should match /10\.0\.0\.3/ }
end

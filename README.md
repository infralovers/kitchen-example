# Depricated

Keep this until we decide on doing the next Chef Training ... 

# Collection of Test Kitchen Examples

This repository contains examples for very common usecases for Chefspec as well as Test Kitchen. Examples were created/tested with

```
chef -v
Chef Development Kit Version: 1.4.3
chef-client version: 12.19.36
delivery version: master (41b94ffb5efd33723cf72a89bf4d273c8151c9dc)
berks version: 5.6.4
kitchen version: 1.16.0
inspec version: 1.25.1
```

## Using Search

Given a default recipe with search `./recipes/default.rb`

```
host = search(:node, "roles:#{role} AND chef_environment:#{environment}").sort.first
```

### ChefSpec for Search

to test it with ChefSpec we can use the ServerRunner `./spec/unit/recipes/default_spec.rb` and create nodes for the run.

```
ChefSpec::ServerRunner.new(platform: 'oracle', version: '7.2') do |_node, server|
  server.create_node('node-1', name: 'node-1', roles: 'role1')
end.converge(described_recipe)
```

run

```
rspec spec/unit/recipes/default_spec.rb --format documentation

kitchen-example::default
  When all attributes are default, on an Oracle 7.2
    converges successfully

Finished in 5.74 seconds (files took 6.61 seconds to load)
1 example, 0 failures
```

### Test Kitchen for Search

we can populate stub nodes from disk to chef_zero `./test/smoke/test-a/nodes/node-1.json`

```
{
  "id": "node-1",
  "run_list": ["role[role1]"],
  "automatic": {
    "ipaddress": "10.0.0.2",
    "roles": ["role1"]
  }
}
```

```
suites:
  - name: test-a
    run_list:
      - recipe[kitchen-example::default]
    verifier:
      inspec_tests:
        - test/smoke/test-a
    attributes:
    provisioner:
        nodes_path: test/smoke/test-a/nodes
```

run

```
kitchen test test-a-oracle-73
```

## Using Encrypted Data Bags

Given an encrypted data bag item

```
secret = data_bag_item('mydatabag', 'secretstuff')
```

### ChefSpec for Encrypted Data Bags

to test it with ChefSpec we can use the ServerRunner `./spec/unit/recipes/using_secret_spec.rb` and create data bags for the run.

```
ChefSpec::ServerRunner.new(platform: 'oracle', version: '7.2') do |_node, server|
  server.create_data_bag('mydatabag',
    'secretstuff' => { firstsecret: 'must remain secret' }
                        )
end.converge(described_recipe)
```

We omit the encrypt/decrypt here since the signature of the data_bag_item in the recipe is the same for plain as well as encrypted items and in this case we are not interested in testing the encrypt/decrypt code path in Chef.

run

```
rspec spec/unit/recipes/using_secret_spec.rb --format documentation

kitchen-example::using_secret
  When all attributes are default, on an Oracle 7.2
    converges successfully

Finished in 5.74 seconds (files took 6.63 seconds to load)
1 example, 0 failures
```

### Test Kitchen for Encrypted Data Bags

Ee can populate encrypted data_bags from disk to chef_zero. Consider keeping the
secret as well as the unencrypted data safe, wither by excluding them from git, or
by using something like [git-crypt](https://github.com/AGWA/git-crypt) to safely add it to the git repository.

First we need a secret:

```
mkdir test/fixtures
openssl rand -base64 512 | tr -d '\r\n' > test/fixtures/encrypted_data_bag_secret
```
then we need the unecrypted data:
```
cat test/fixtures/not_encrypted_secret_stuff.json
{
  "id": "secretstuff",
  "firstsecret": "must remain secret",
  "secondsecret": "also very secret"
}
```

*Important: `test/fixtures/not_encrypted_secret_stuff.json` as well as `test/fixtures/encrypted_data_bag_secret` are included in this repo as an example only!*

 Next we need to populate the encrypted data as a file for chef-zero usage. We can do so by creating it with knife in zero mode (`-z`).

```
  suites:
  - name: test-secret
    run_list:
      - recipe[kitchen-example::using_secret]
    verifier:
      inspec_tests:
        - test/smoke/test-using_secret
    attributes:
    provisioner:
      data_bags_path: test/smoke/test-using_secret/data_bags
      encrypted_data_bag_secret_key_path: test/fixtures/encrypted_data_bag_secret
```
knife will use the current dirctory as root of the _fake_ chef-repo, so cd into the test-root:

```
cd test/smoke/test-using_secret/
```

Using data bags with a real chef server is always a two step operation.

1. create data bag
2. create item

if we skip step one, we get an error message:

```
knife data bag from file mydatabag ../../fixtures/not_encrypted_secret_stuff.json -z --secret-file ../../fixtures/encrypted_data_bag_secret
WARNING: No knife configuration file found
WARN: No cookbooks directory found at or above current directory.  Assuming /Users/ehaselwanter/repositories/hhla/kitchen-example/test/smoke/test-using_secret.
ERROR: The object you are looking for could not be found
Response: Parent not found: chefzero://localhost:8889/data/mydatabag
```

since the knife [Chef Zero](https://github.com/chef/chef-zero) integration is basically using the file system as a source we can use that information to _create_ the data bag first by creating a directory.

```
mkdir -p data_bags/mydatabag
```

followed by (mind the `-z`) creating the encrypted data bag item:

```
knife data bag from file mydatabag ../../fixtures/not_encrypted_secret_stuff.json -z --secret-file ../../fixtures/encrypted_data_bag_secret
WARNING: No knife configuration file found
WARN: No cookbooks directory found at or above current directory.  Assuming /Users/ehaselwanter/repositories/hhla/kitchen-example/test/smoke/test-using_secret.
Updated data_bag_item[mydatabag::secretstuff]

tree data_bags
data_bags
└── mydatabag
    └── secretstuff.json

1 directory, 1 file
```

now we can run our kitchen test with an actual secret:

```
kitchen test test-secret-oracle-73

-----> Starting Kitchen (v1.16.0)
-----> Cleaning up any prior instances of <test-secret-oracle-73>
 .... ... ..

 Profile: tests from test/smoke/test-using_secret
 Version: (not specified)
 Target:  ssh://vagrant@127.0.0.1:2222


   File /etc/special_config_with_secret_data
      ✔  content should match /secret/

 Test Summary: 1 successful, 0 failures, 0 skipped

 ....

```

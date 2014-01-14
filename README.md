[![Built on Travis](https://secure.travis-ci.org/ranjib/etcd-ruby.png?branch=master)](http://travis-ci.org/ranjib/etcd-ruby)
# Etcd

A ruby client for [etcd](https://github.com/coreos/etcd)
## Installation

Add this line to your application's Gemfile:

    gem 'etcd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install etcd

## Usage
### Create a client object
```ruby
client = Etcd.client # this will create a client against etcd server running on localhost on port 4001
client = Etcd.client(port: 4002)
client = Etcd.client(host: '127.0.0.1', port: 4003)
client = Etcd.client(host: '127.0.0.1', port: 4003, allow_redirect: false) # wont let you run sensitive commands on non-leader machines, default is true
```
### Set a key
```ruby
client.set('/nodes/n1', 1)
# with ttl
client.set('/nodes/n2', 2, 4)  # sets the ttl to 4 seconds
```
### Get a key
```ruby
client.get('/nodes/n2').value

```
### Delete a key
```ruby
client.delete('/nodes/n1')
client.delete('/nodes/', recursive: true)
```

### Test and set
```ruby
client.test_and_set('/nodes/n2', 2, 4) # will set /nodes/n2 's value to 2 only if its previous value was 4

```

### Watch a key
```ruby
client.watch('/nodes/n1') # will wait till the key is changed, and return once its changed
```

### List sub keys
```ruby
client.get('/nodes')
```

### Get machines in the cluster
```ruby
client.machines
```

### Get leader of the cluster
```ruby
client.leader
```
More examples and api details can be found in the [wiki](https://github.com/ranjib/etcd-ruby/wiki)

## Contributors 
* Ranjib Dey
* [Jesse Nelson](https://github.com/spheromak)
* [Nilesh Bairagi](https://github.com/Bairagi)
* [Dr Nic Williams](https://github.com/drnic)
* [Eric Buth] (https://github.com/buth)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. If applicable, update the README.md

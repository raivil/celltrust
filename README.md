# Celltrust


A Ruby wrapper for the [Celltrust API](http://www.celltrust.com/docs/CellTrust_SoftwareDevelopmentKit.pdf).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'celltrust'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install celltrust

## Usage

Quick start (sending a message)
-------------------------------

First you need to load up the gem and construct a Celltrust::Client object
with your API credentials, like this:

```ruby
require 'celltrust'

# simple sms
celltrust = Celltrust::SimpleSMSClient.new('username', 'password', 'nickname')

#secure sms
celltrust = Celltrust::SecureSMSClient.new('username', 'password', 'nickname')
```

Sending a SMS

```ruby
response = celltrust.send_sms('number', 'message', params = {})

if response.ok?
  # do something with response.object
else
  puts response.error?
  puts response.error_details
  # handle the error
end
```


Troubleshooting
---------------

Remember that phone numbers should be specified in international format.

The Celltrust documentation contains a [list of error codes](http://www.celltrust.com/docs/CellTrust_SoftwareDevelopmentKit.pdf)
which may be useful if you have problems sending a message.

Please report all bugs/issues via the GitHub issue tracker.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/celltrust/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

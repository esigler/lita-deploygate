# lita-deploygate

[![Build Status](https://travis-ci.org/esigler/lita-deploygate.png?branch=master)](https://travis-ci.org/esigler/lita-deploygate)
[![Code Climate](https://codeclimate.com/github/esigler/lita-deploygate.png)](https://codeclimate.com/github/esigler/lita-deploygate)
[![Coverage Status](https://coveralls.io/repos/esigler/lita-deploygate/badge.png?branch=master)](https://coveralls.io/r/esigler/lita-deploygate?branch=master)

DeployGate (http://deploygate.com) handler for inviting and removing application collaborators.

## Installation

Add lita-deploygate to your Lita instance's Gemfile:

``` ruby
gem "lita-deploygate"
```

## Configuration

You'll need to get an API key, which you can find at the bottom of this page: https://deploygate.com/settings

Add the following variables to your Lita config file:
``` ruby
config.handlers.deploygate.user_name = '_user_name_here_'
config.handlers.deploygate.api_key = '_api_key_here_'
config.handlers.deploygate.app_names = { 'ios' => 'platforms/ios/apps/com.yourappname.YourAppName',
                                         'android' => 'apps/com.yourappname.android',
                                         'short_name' => 'path component' }
```

Apologies for the odd syntax, DeployGate has slightly different behavior for iOS vs. Android.  You'll need to determine which URL path your app is using.

## Usage

### Inviting users

```
deploygate add <username or email> <short name> - Add <username or email> to <short name>
```

### Removing users

```
deploygate remove <username or email> <short name> - Remove <username or email> from <short name>
```

### Listing Users

```
deploygate list <short name> - List all users associated with <short name>
```

## License

[MIT](http://opensource.org/licenses/MIT)

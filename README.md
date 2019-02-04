# WillowSword
A Ruby on Rails engine for the Sword V2 server. The Sword server is currently integrated with Hyrax V2.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'willow_sword', git: 'https://github.com/CottageLabs/willow_sword.git'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install willow_sword
```

Mount the engine. Add this line to config/routes.rb

```ruby
mount WillowSword::Engine => '/sword'
```
## Configuration
The plugin has a few configuration options. To view the current default options and override these, see [configuration options](https://github.com/CottageLabs/willow_sword/wiki/Configuring-willow-sword)

## Enable authorization
If you would like to authorize all Sword requests using an Api-key header, see [Enabling authorization](https://github.com/CottageLabs/willow_sword/wiki/Enabling-Authorization-In-Willow-Sword)

## Usage
To use the plugin see [usage](https://github.com/CottageLabs/willow_sword/wiki/Usage)

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

# WillowSword
A Ruby on Rails engine for the Sword V2 server. The Sword server is currently integrated with Hyrax V2.

The operational version of this code is on gitlab.bodleian.ox.ac.uk/ORA4/willow_sword

## Important note for ORA users

This project uses git flow conventions for code management, with a major wrinkle: 
the production/master branch of this code is feature/ora_customizations

The development branch is still develop, and the release branches are tagged release/ as normal.

The major/minor version numbers of releases will follow the Hyrax/ora.reviewinterface version 
number that corresponds to the release cycle under which they were released, e.g. release v3.4.0 will correspond
to ora4.reviewinteface's v3.4.0 release. If no updates to the Sword gem are being released at the time of
an ora4.reviewinterface release, then that version will be skipped in Sword, e.g. if a new version of the Sword gem is being released with 
ora4.reviewinterface v3.7.0, then the Sword gem version will be v3.7.0, even if there was no v3.6.0. 

This means that release numbers will not necessarily be sequential, as the number does not have 
to be updated unless code has been updated. 
 
Hotfix/bugfix version numbers may not directly correspond (e.g. v3.4.1 vs v3.4.2). 

## Deployment to ORA4 QA

At present, we have no way to configure that branch used in the ora4.reviewinterface gemfile. Therefore a release
into QA should be followed by an update to the ora4-qa-symp gemfile from 

```ruby
gem 'willow_sword', git: 'https://github.com/tomwrobel/willow_sword', branch: 'feature/ora_customizations'
```

To

```ruby
gem 'willow_sword', git: 'https://github.com/tomwrobel/willow_sword', branch: 'develop'
```

(amend develop to release/v{release number} as appropriate). And a bundle update and apache reboot should be run.

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

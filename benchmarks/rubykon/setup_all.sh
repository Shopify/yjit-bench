#!/bin/bash --login

declare -a RUBIES=( "2.4.10" "2.5.8" "2.6.6" "2.7.1" "2.8.0-dev" "jruby-9.1.17.0" "jruby-9.2.11.1" "truffleruby-20.1.0" "truffleruby-1.0.0-rc16")

asdf plugin-update ruby

for ruby in "${RUBIES[@]}"
do
  echo Running $ruby
  asdf install ruby $ruby
  asdf local ruby $ruby
  ruby -v
  gem install bundler

  # the install of jruby 9.2 seems to need this
  asdf reshim ruby $ruby
  bundle install
  bundle exec rspec
  echo
  echo
done

# Also get me some javas


declare -a JVMS=( "adoptopenjdk-8.0.265+1" "adoptopenjdk-8.0.265+1.openj9-0.21.0" "adoptopenjdk-14.0.2+12" "adoptopenjdk-14.0.2+12.openj9-0.21.0" "java-se-ri-8u41-b04" "java-se-ri-14+36" "corretto-8.265.01.1" "corretto-11.0.8.10.1" "dragonwell-8.4.4" "dragonwell-11.0.7.2+9" "graalvm-20.1.0+java8" "graalvm-20.1.0+java11")

asdf plugin-update java

for java in "${JVMS[@]}"
do
  echo Installing $java
  asdf install java $java

  echo
  echo
done

# Setup GraalVM non native

asdf local java graalvm-20.1.0+java11
gu install ruby
~/.asdf/installs/java/graalvm-20.1.0+java11/languages/ruby/lib/truffle/post_install_hook.sh
ruby_home=$(/home/tobi/.asdf/installs/java/graalvm-20.1.0+java11/languages/ruby/bin/ruby -e 'print RbConfig::CONFIG["prefix"]')
ln -s "$ruby_home" "$HOME/.asdf/installs/ruby/trufflerubyVM"
asdf reshim ruby trufflerubyVM
asdf local ruby trufflerubyVM
ruby -v
ruby --jvm -v

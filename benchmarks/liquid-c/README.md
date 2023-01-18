# Liquid::C
[![Build Status](https://travis-ci.org/Shopify/liquid-c.svg?branch=master)](https://travis-ci.org/Shopify/liquid-c)

Partial native implementation of the liquid ruby gem in C.

## Installation

Add these lines to your application's Gemfile:

    gem 'liquid', github: 'Shopify/liquid', branch: 'master'
    gem 'liquid-c', github: 'Shopify/liquid-c', branch: 'master'

And then execute:

    $ bundle

## Usage

    require 'liquid/c'

then just use the documented API for the liquid Gem.

## Restrictions

* Input strings are assumed to be UTF-8 encoded strings
* Tag#parse(tokens) is given a Liquid::Tokenizer object, instead
  of an array of strings, which only implements the shift method
  to get the next token.

## Performance

To compare Liquid-C's performance with plain Liquid run

    bundle exec rake compare:lax

The latest benchmark results are shown below:

```
$ bundle exec rake compare:lax
/home/spin/.rubies/ruby-3.0.2/bin/ruby ./performance.rb bare benchmark lax

Running benchmark for 10 seconds (with 5 seconds warmup).

Warming up --------------------------------------
              parse:     2.000  i/100ms
             render:     8.000  i/100ms
     parse & render:     2.000  i/100ms
Calculating -------------------------------------
              parse:     29.527  (± 3.4%) i/s -    296.000  in  10.034520s
             render:     89.403  (± 6.7%) i/s -    896.000  in  10.072939s
     parse & render:     20.474  (± 4.9%) i/s -    206.000  in  10.072806s

/home/spin/.rubies/ruby-3.0.2/bin/ruby ./performance.rb c benchmark lax

Running benchmark for 10 seconds (with 5 seconds warmup).

Warming up --------------------------------------
              parse:    10.000  i/100ms
             render:    18.000  i/100ms
     parse & render:     5.000  i/100ms
Calculating -------------------------------------
              parse:     90.672  (± 3.3%) i/s -    910.000  in  10.051124s
             render:    163.871  (± 4.9%) i/s -      1.638k in  10.018105s
     parse & render:     50.165  (± 4.0%) i/s -    505.000  in  10.077377s
```

## Developing

    bundle install
    # run tests
    bundle exec rake

## Contributing

1. Fork it ( http://github.com/Shopify/liquid-c/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Rubykon [![Gem Version](https://badge.fury.io/rb/rubykon.svg)](https://badge.fury.io/rb/rubykon)[![Build Status](https://secure.travis-ci.org/PragTob/rubykon.png?branch=master)](https://travis-ci.org/PragTob/rubykon)[![Code Climate](https://codeclimate.com/github/PragTob/Rubykon.png)](https://codeclimate.com/github/PragTob/Rubykon)[![Test Coverage](https://codeclimate.com/github/PragTob/Rubykon/badges/coverage.svg)](https://codeclimate.com/github/PragTob/Rubykon/coverage)
A Go-Engine being built in Ruby.

## Status?

_mostly not updated any more, if there's new work then it's focussed on bencharmks_

There is a CLI with which you can play, it does a full UCT MCTS. Still work to do on making move generation and scoring faster. Also there is no AMAF/RAVE implementation yet (which would make it a lot stronger) and it also does not use any expert knowledge right now. So still a lot to do, but it works.


## Sub gems
Right now the `mcts` and `benchmark/avg` gem that I wrote for this are still embedded in here. They are bound to be broken out and released as separate gems to play with. If you want to use them now, just use rubykon and you can require `mcts` or `benchmark/avg` :)

## Why would you build a Go-Bot in Ruby?
Cause it's fun.

## Setting up

It should work with any standard ruby implementation. `bundle install` and you're ready to go.

## Benchmarking

If you're here for the benchmarking, then there are a couple of useful scripts.
Assuming you have [`asdf`](https://github.com/asdf-vm/asdf) with both the [ruby](https://github.com/asdf-vm/asdf-ruby) and [java](https://github.com/halcyon/asdf-java) plugins you can run `setup_all.sh` which installs all rubies and JVMs for the benchmark.

You can then:

```shell
cd benchmark/
benchmark.sh mcts_avg.rb
```

This runs the mcts_avg.rb (adjust timings as necessary) benchmark with all the configured ruby installations. This can take a _long_ while so you might want to comment out certain rubies/JVMs or entire sections.

## Contributing

While not actively developped contributions are welcome.

Especially performance related contributions should ideally come with before/after benchmark results. Not for all ruby versions mentioned in `benchmark.sh` but a fair subset of them. At best you'd run [`mcts_avg`](https://github.com/PragTob/rubykon/blob/main/benchmark/mcts_avg.rb) - feel free to adjust the warmup times to be massively smaller for implementations that don't need it ([see Warmup section for indications](https://pragtob.wordpress.com/2020/08/24/the-great-rubykon-benchmark-2020-cruby-vs-jruby-vs-truffleruby/)).

Ideally it'd have benchmarks for:

* recent CRuby (plus points: also with --jit)
* recent JRuby with invokedynamic
* recent truffleruby (ideally both native and jvm but one is enough)

If that's too much ruby setup (I understand) feel free to PR and let me run the benchmarks for the missing implementations. Might take me a while though ;)

The goal of this is to make sure two things:

a.) We don't accidentally make performance worse (I had ideas for great optimizations that actually made it worse...)
b.) We don't implement optimizations that benefit one implementation while making the others worse

## Blog Posts

These days this is mostly used for writing performance blog posts. You can find all of them at https://pragtob.wordpress.com/tag/rubykon/

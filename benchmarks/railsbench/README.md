# railsbench

This is a Rails benchmark created with Rails's scafold generator. It's not
very real-world, but it still shares some code with real-world Rails apps.

## Setup

Make sure to have `yarn`, the JavaScript package manager installed. See
https://classic.yarnpkg.com/en/docs/install/.

Run these commands in the root of this application:

```sh
cd benchmarks/railsbench/
chruby ruby-yjit
bundle install
yarn
bin/rails assets:precompile RAILS_ENV=production
bin/rails db:create db:migrate db:seed RAILS_ENV=production
```

## About

This benchmark is inspired by https://github.com/k0kubun/railsbench/.

It's lightly modified from an app generated with the following commands:

```
rails new railsbench --database=sqlite3
rails g scaffold post title:string body:text published:boolean
```

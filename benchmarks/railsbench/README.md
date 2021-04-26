# railsbench

This is a Rails benchmark created with Rails's scafold generator. It's not
very real-world, but it still shares some code with real-world Rails apps.

## Setup

Run these commands in the root of this application:

```sh
cd benchmarks/railsbench/
chruby ruby-yjit
bundle install
bin/rails db:create db:migrate db:seed RAILS_ENV=production
```

## About

This benchmark is inspired by https://github.com/k0kubun/railsbench/.

It's modified from an app generated with the following commands:

```
rails new railsbench --database=sqlite3
rails g scaffold post title:string body:text published:boolean
```

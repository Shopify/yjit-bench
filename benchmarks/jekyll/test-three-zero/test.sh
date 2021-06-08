#!/bin/sh

# Note: this file is retained from https://github.com/agbell/jekyll-perf, but it's not how we want to benchmark

bundle exec jekyll clean
bundle exec jekyll serve --incremental -H 0.0.0.0 -P 4001 &
sleep 20
for i in $(seq 1 20)
do
   echo "$i\n" >> ./_posts/2009-05-15-edge-case-nested-and-mixed-lists.md
   sleep 10
done
trap 'kill $(jobs -p)' EXIT

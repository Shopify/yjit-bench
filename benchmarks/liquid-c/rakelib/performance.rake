# frozen_string_literal: true

namespace :benchmark do
  desc "Run the liquid benchmark with lax parsing"
  task :run do
    ruby "./performance.rb c benchmark lax"
  end

  desc "Run the liquid benchmark with strict parsing"
  task :strict do
    ruby "./performance.rb c benchmark strict"
  end
end

namespace :c_profile do
  [:run, :compile, :render].each do |task_name|
    task(task_name) do
      ruby "./performance/c_profile.rb #{task_name}"
    end
  end
end

namespace :profile do
  desc "Run the liquid profile/performance coverage"
  task :run do
    ruby "./performance.rb c profile lax"
  end

  desc "Run the liquid profile/performance coverage with strict parsing"
  task :strict do
    ruby "./performance.rb c profile strict"
  end
end

namespace :compare do
  ["lax", "warn", "strict"].each do |type|
    desc "Compare Liquid to Liquid-C in #{type} mode"
    task type.to_sym do
      ruby "./performance.rb bare benchmark #{type}"
      ruby "./performance.rb c benchmark #{type}"
    end
  end
end

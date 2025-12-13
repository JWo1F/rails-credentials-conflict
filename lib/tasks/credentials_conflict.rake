# frozen_string_literal: true

require "rails/credentials/conflict/resolver"

namespace :credentials do
  namespace :conflict do
    desc "Resolve credentials conflict by decrypting and merging (usage: rails credentials:conflict:resolve[environment])"
    task :resolve, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).resolve
    end

    desc "Resolve credentials conflict by keeping yours (usage: rails credentials:conflict:yours[environment])"
    task :yours, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).yours
    end

    desc "Resolve credentials conflict by keeping theirs (usage: rails credentials:conflict:theirs[environment])"
    task :theirs, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).theirs
    end

    desc "Resolve credentials conflict by keeping base version (usage: rails credentials:conflict:base[environment])"
    task :base, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).base
    end
  end
end

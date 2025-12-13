# frozen_string_literal: true

require "rails/credentials/conflict/resolver"

namespace :credentials do
  namespace :conflict do
    desc "Resolve credentials conflict by decrypting and merging"
    task :resolve => :environment do
      environment = ENV["ENVIRONMENT"] || ENV["e"]
      Rails::Credentials::Conflict::Resolver.new(environment).resolve
    end

    desc "Resolve credentials conflict by keeping yours"
    task :yours => :environment do
      environment = ENV["ENVIRONMENT"] || ENV["e"]
      Rails::Credentials::Conflict::Resolver.new(environment).yours
    end

    desc "Resolve credentials conflict by keeping theirs"
    task :theirs => :environment do
      environment = ENV["ENVIRONMENT"] || ENV["e"]
      Rails::Credentials::Conflict::Resolver.new(environment).theirs
    end

    desc "Resolve credentials conflict by keeping base version"
    task :base => :environment do
      environment = ENV["ENVIRONMENT"] || ENV["e"]
      Rails::Credentials::Conflict::Resolver.new(environment).base
    end
  end
end

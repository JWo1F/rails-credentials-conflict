# frozen_string_literal: true

require "rails/credentials/conflict/resolver"

namespace :credentials do
  namespace :conflict do
    desc "Resolve credentials conflict by decrypting and merging"
    task :resolve, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).resolve
    rescue Rails::Credentials::Conflict::Error => e
      abort e.message
    end

    desc "Resolve credentials conflict by keeping yours (usage: rails credentials:conflict:yours[environment])"
    task :yours, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).yours
    rescue Rails::Credentials::Conflict::Error => e
      abort e.message
    end

    desc "Resolve credentials conflict by keeping theirs (usage: rails credentials:conflict:theirs[environment])"
    task :theirs, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).theirs
    rescue Rails::Credentials::Conflict::Error => e
      abort e.message
    end

    desc "Resolve credentials conflict by keeping base version (usage: rails credentials:conflict:base[environment])"
    task :base, [:environment] => :environment do |_t, args|
      Rails::Credentials::Conflict::Resolver.new(args[:environment]).base
    rescue Rails::Credentials::Conflict::Error => e
      abort e.message
    end

    desc "Install git merge driver for automatic credentials conflict resolution"
    task install: :environment do
      require "open3"

      # Configure git merge driver
      commands = [
        ["git", "config", "merge.rails-credentials.name", "Rails encrypted credentials merge driver"],
        ["git", "config", "merge.rails-credentials.driver",
         "bundle exec rails runner \"Rails::Credentials::Conflict::MergeDriver.call('%O', '%A', '%B', '%P')\""]
      ]

      commands.each do |cmd|
        _, status = Open3.capture2(*cmd)
        abort "Failed to run: #{cmd.join(" ")}" unless status.success?
      end

      puts "Configured git merge driver 'rails-credentials' in .git/config"

      # Update .gitattributes
      gitattributes_path = Rails.root.join(".gitattributes")
      existing_content = File.exist?(gitattributes_path) ? File.read(gitattributes_path) : ""

      lines_to_add = [
        "config/credentials.yml.enc merge=rails-credentials",
        "config/credentials/*.yml.enc merge=rails-credentials"
      ]

      new_lines = lines_to_add.reject { |line| existing_content.include?(line) }

      if new_lines.any?
        File.open(gitattributes_path, "a") do |f|
          f.puts unless existing_content.empty? && !existing_content.end_with?("\n")
          new_lines.each { |line| f.puts(line) }
        end
        puts "Added merge driver entries to .gitattributes"
      else
        puts ".gitattributes already configured"
      end

      puts "Done! Credentials conflicts will now be auto-merged when possible."
    end
  end
end

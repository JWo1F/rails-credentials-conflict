# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      # Integrates the gem with Rails by loading the rake tasks
      # when the application boots.
      class Railtie < Rails::Railtie
        rake_tasks do
          load "tasks/credentials_conflict.rake"
        end
      end
    end
  end
end

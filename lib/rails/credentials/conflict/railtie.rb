# frozen_string_literal: true

module Rails
  module Credentials
    module Conflict
      class Railtie < Rails::Railtie
        rake_tasks do
          load "tasks/credentials_conflict.rake"
        end
      end
    end
  end
end

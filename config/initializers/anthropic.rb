# config/initializers/anthropic.rb
ENV["ANTHROPIC_API_KEY"] ||= Rails.application.credentials.anthropic_api_key

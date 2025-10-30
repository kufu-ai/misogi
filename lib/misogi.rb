# frozen_string_literal: true

require_relative "misogi/version"
require_relative "misogi/violation"
require_relative "misogi/parsed_content"
require_relative "misogi/parser/base"
require_relative "misogi/parser/ruby"
require_relative "misogi/rule/base"
require_relative "misogi/rule/ruby_standard"
require_relative "misogi/rule/rails"
require_relative "misogi/rule/rspec"
require_relative "misogi/validator"
require_relative "misogi/configuration"
require_relative "misogi/cli"

module Misogi
  class Error < StandardError; end
end

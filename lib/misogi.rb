# frozen_string_literal: true

# 基本的な型定義は即座にロード
require_relative "misogi/version"
require_relative "misogi/violation"
require_relative "misogi/parsed_content"

module Misogi
  class Error < StandardError; end

  # 遅延ロードするクラス/モジュールをautoloadで定義
  autoload :CLI, "misogi/cli"
  autoload :Configuration, "misogi/configuration"
  autoload :Validator, "misogi/validator"

  module Parser
    autoload :Base, "misogi/parser/base"
    autoload :Ruby, "misogi/parser/ruby"
  end

  module Rule
    autoload :Base, "misogi/rule/base"
    autoload :RubyStandard, "misogi/rule/ruby_standard"
    autoload :Rails, "misogi/rule/rails"
    autoload :RSpec, "misogi/rule/rspec"
  end
end

# frozen_string_literal: true

# 基本的な型定義は即座にロード
require_relative "misogi/version"
require_relative "misogi/violation"
require_relative "misogi/parsed_content"

# Misogiはファイルの内容を解析して、ファイル名やディレクトリ配置が適切かをチェックするlintツールを提供します
module Misogi
  class Error < StandardError; end

  # 遅延ロードするクラス/モジュールをautoloadで定義
  autoload :CLI, "misogi/cli"
  autoload :Configuration, "misogi/configuration"
  autoload :Validator, "misogi/validator"

  # ファイルの内容を解析するパーサー
  module Parser
    autoload :Base, "misogi/parser/base"
    autoload :Ruby, "misogi/parser/ruby"
  end

  # ファイルパスとコード内容の整合性をチェックするルール
  module Rule
    autoload :Base, "misogi/rule/base"
    autoload :RubyStandard, "misogi/rule/ruby_standard"
    autoload :Rails, "misogi/rule/rails"
    autoload :RSpec, "misogi/rule/rspec"
  end
end

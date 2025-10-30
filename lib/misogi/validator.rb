# frozen_string_literal: true

module Misogi
  # ファイルに対してルールを適用し、違反を検出するクラス
  class Validator
    attr_reader :rules, :parser

    # @param rules [Array<Rule::Base>] 適用するルールのリスト
    # @param parser [Parser::Base] 使用するパーサー（デフォルト: Parser::Ruby）
    def initialize(rules: [], parser: Parser::Ruby.new)
      @rules = rules
      @parser = parser
    end

    # ファイルを検証する
    # @param file_path [String] 検証対象のファイルパス
    # @return [Array<Violation>] 検出された違反のリスト
    def validate_file(file_path)
      return [] unless parser.parsable?(file_path)
      return [] unless File.exist?(file_path)

      content = File.read(file_path)
      parsed_content = parser.parse(content)

      violations = []
      rules.each do |rule|
        violations.concat(rule.validate(file_path, parsed_content))
      end

      violations
    end

    # 複数のファイルを検証する
    # @param file_paths [Array<String>] 検証対象のファイルパスのリスト
    # @return [Array<Violation>] 検出された違反のリスト
    def validate_files(file_paths)
      file_paths.flat_map { |file_path| validate_file(file_path) }
    end
  end
end

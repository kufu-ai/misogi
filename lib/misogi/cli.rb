# frozen_string_literal: true

require "optparse"
require "fileutils"

module Misogi
  # コマンドラインインターフェース
  class CLI
    attr_reader :options

    def initialize(argv = ARGV)
      @argv = argv
      @options = {
        rules: nil, # nilの場合は設定ファイルを使用
        base_path: nil,
        pattern: nil,
        config_path: ".misogi.yml",
        format: "text",
        fix: false
      }
    end

    # CLIを実行
    # @return [Integer] 終了コード
    def run
      parse_options

      # Railsルールが必要な場合はRails環境を読み込む
      load_rails_environment_if_needed

      files = collect_files
      if files.empty?
        warn "検証対象のファイルが見つかりませんでした"
        return 1
      end

      # CLIオプションでルールが明示的に指定されている場合は従来通りの動作
      violations = if @options[:rules]
                     validate_with_cli_rules(files)
                   else
                     validate_with_config(files)
                   end

      if @options[:fix]
        fix_violations(violations)
      else
        display_violations(violations)
      end

      violations.empty? ? 0 : 1
    end

    # 違反を修正する
    # @param violations [Array<Violation>] 違反のリスト
    def fix_violations(violations)
      fixable_violations = violations.select(&:suggest_path)
      unfixable_violations = violations.reject(&:suggest_path)

      display_unfixable_violations(unfixable_violations, fixable_violations)

      if fixable_violations.empty?
        puts "✅ 修正可能な違反はありませんでした"
        return
      end

      display_fixable_violations(fixable_violations)

      return unless confirmed?

      fixed_count = apply_fixes(fixable_violations)
      puts "\n✅ #{fixed_count}件のファイルを移動しました"
    end

    # 修正不可能な違反を表示する
    # @param unfixable_violations [Array<Violation>] 修正不可能な違反のリスト
    # @param fixable_violations [Array<Violation>] 修正可能な違反のリスト
    def display_unfixable_violations(unfixable_violations, fixable_violations)
      return unless unfixable_violations.any?

      puts "⚠️  #{unfixable_violations.size}件の違反は自動修正できません:"
      unfixable_violations.each { |v| puts "  #{v}" }
      puts if fixable_violations.any?
    end

    # 修正可能な違反を表示する
    # @param fixable_violations [Array<Violation>] 修正可能な違反のリスト
    def display_fixable_violations(fixable_violations)
      puts "🔧 以下の #{fixable_violations.size}件の違反を修正します:"
      fixable_violations.each { |v| puts "  #{v.file_path} -> #{v.suggest_path}" }

      print "\n実行しますか? [y/N] "
    end

    # 実行確認を取得する
    # @return [Boolean] ユーザーが実行を承認した場合true
    def confirmed?
      response = gets.chomp.downcase
      %w[y yes].include?(response)
    end

    # 修正を適用する
    # @param fixable_violations [Array<Violation>] 修正可能な違反のリスト
    # @return [Integer] 修正されたファイルの数
    def apply_fixes(fixable_violations)
      fixed_count = 0
      fixable_violations.each do |violation|
        if move_file(violation.file_path, violation.suggest_path)
          fixed_count += 1
          puts "✓ #{violation.file_path} -> #{violation.suggest_path}"
        else
          puts "✗ #{violation.file_path} の移動に失敗しました"
        end
      end
      fixed_count
    end

    # ファイルを移動する
    # @param source_path [String] 移動元のパス
    # @param target_path [String] 移動先のパス
    # @return [Boolean] 成功した場合true
    def move_file(source_path, target_path)
      # ターゲットディレクトリが存在しない場合は作成
      target_dir = File.dirname(target_path)
      FileUtils.mkdir_p(target_dir)

      # ターゲットファイルが既に存在する場合は上書きしない
      if File.exist?(target_path)
        warn "警告: #{target_path} は既に存在するため移動をスキップしました"
        return false
      end

      # ファイルを移動
      FileUtils.mv(source_path, target_path)
      true
    rescue StandardError => e
      warn "エラー: #{source_path} の移動に失敗しました: #{e.message}"
      false
    end

    private

    # Railsルールが使用される場合にRails環境を読み込む
    def load_rails_environment_if_needed
      needs_rails = if @options[:rules]
                      @options[:rules].include?(:rails)
                    else
                      # 設定ファイルをチェック
                      config = load_configuration
                      config.rules.key?(:rails) || config.rules.key?("rails")
                    end

      return unless needs_rails

      load_rails_environment
    end

    # Rails環境を読み込む
    def load_rails_environment
      # config/boot.rbが存在するかチェック
      boot_file = "config/boot.rb"
      environment_file = "config/environment.rb"

      unless File.exist?(boot_file)
        warn "警告: #{boot_file} が見つかりません。Railsプロジェクトのルートディレクトリで実行してください。"
        return
      end

      unless File.exist?(environment_file)
        warn "警告: #{environment_file} が見つかりません。Railsプロジェクトのルートディレクトリで実行してください。"
        return
      end

      # Rails環境を読み込む
      require File.expand_path(boot_file)
      require File.expand_path(environment_file)

      # Rails アプリケーションを初期化（既に初期化されていない場合）
      ::Rails.application.eager_load! if defined?(::Rails)
    rescue StandardError => e
      warn "警告: Rails環境の読み込みに失敗しました: #{e.message}"
    end

    # オプションをパース
    def parse_options
      parser = OptionParser.new do |opts|
        setup_option_parser(opts)
      end

      parser.parse!(@argv)
    rescue OptionParser::InvalidOption => e
      warn "エラー: #{e.message}"
      warn parser.help
      exit 1
    end

    # OptionParserのオプションを設定する
    # @param parser [OptionParser] OptionParserインスタンス
    def setup_option_parser(parser)
      parser.banner = "使い方: misogi [オプション] [ファイル...]"

      parser.on("-r", "--rules RULES", Array, "使用するルール (ruby_standard,rails,rspec)") do |rules|
        @options[:rules] = rules.map(&:to_sym)
      end

      parser.on("-b", "--base-path PATH", "ベースパス (デフォルト: lib)") do |path|
        @options[:base_path] = path
      end

      parser.on("-p", "--pattern PATTERN", "検証するファイルパターン") do |pattern|
        @options[:pattern] = pattern
      end

      parser.on("-c", "--config PATH", "設定ファイルのパス (デフォルト: .misogi.yml)") do |path|
        @options[:config_path] = path
      end

      parser.on("-f", "--format FORMAT", "出力フォーマット(text|json)") do |format|
        @options[:format] = format
      end

      parser.on("--fix", "違反を自動修正する") do
        @options[:fix] = true
      end

      parser.on("-h", "--help", "ヘルプを表示") do
        puts parser
        exit 0
      end

      parser.on("-v", "--version", "バージョンを表示") do
        puts "Misogi #{Misogi::VERSION}"
        exit 0
      end
    end

    # 検証対象のファイルを収集
    # @return [Array<String>] ファイルパスのリスト
    def collect_files
      if @argv.any?
        # コマンドライン引数で指定されたファイル
        @argv
      elsif @options[:pattern]
        # パターンで指定されたファイル
        Dir.glob(@options[:pattern])
      else
        # デフォルト: lib, app, spec配下のRubyファイル
        default_pattern = "{lib,app,spec}/**/*.rb"
        Dir.glob(default_pattern)
      end
    end

    # CLIルールで検証
    # @param files [Array<String>] ファイルパスのリスト
    # @return [Array<Violation>] 違反のリスト
    def validate_with_cli_rules(files)
      rules = @options[:rules].map do |rule_name|
        create_rule(rule_name)
      end.compact

      validator = Validator.new(rules: rules)
      validator.validate_files(files)
    end

    # 設定ファイルベースで検証
    # @param files [Array<String>] ファイルパスのリスト
    # @return [Array<Violation>] 違反のリスト
    def validate_with_config(files)
      config = load_configuration

      # 除外パターンを適用
      files = files.reject { |file| config.excluded?(file) }

      # ファイルごとに適用するルールを決定して検証
      files.flat_map do |file|
        applicable_rules_config = config.rules_for(file)
        next [] if applicable_rules_config.empty?

        rules = applicable_rules_config.map do |rule_name, rule_config|
          create_rule_from_config(rule_name, rule_config[:config])
        end.compact

        validator = Validator.new(rules: rules)
        validator.validate_file(file)
      end
    end

    # 設定ファイルをロード
    # @return [Configuration]
    def load_configuration
      config = if File.exist?(@options[:config_path])
                 Configuration.new(config_path: @options[:config_path])
               else
                 Configuration.default
               end

      # CLIオプションでbase_pathが指定されている場合は設定を上書き
      if @options[:base_path] && config.rules.key?(:ruby_standard)
        config.rules[:ruby_standard][:config]["base_path"] = @options[:base_path]
      end

      config
    end

    # ルールを作成（CLIオプションから）
    # @param rule_name [Symbol] ルール名
    # @return [Rule::Base, nil] ルールインスタンス
    def create_rule(rule_name)
      case rule_name
      when :ruby_standard
        Rule::RubyStandard.new(base_path: @options[:base_path] || "lib")
      when :rails
        Rule::Rails.new
      when :rspec
        Rule::RSpec.new
      else
        warn "警告: 不明なルール '#{rule_name}' がスキップされました"
        nil
      end
    end

    # ルールを作成（設定ファイルから）
    # @param rule_name [String, Symbol] ルール名
    # @param config [Hash] ルール設定
    # @return [Rule::Base, nil] ルールインスタンス
    def create_rule_from_config(rule_name, config)
      rule_name_sym = rule_name.to_sym

      case rule_name_sym
      when :ruby_standard
        base_path = config["base_path"] || config[:base_path] || "lib"
        Rule::RubyStandard.new(base_path: base_path)
      when :rails
        inflections_path = config["inflections_path"] || config[:inflections_path]
        Rule::Rails.new(inflections_path: inflections_path)
      when :rspec
        Rule::RSpec.new
      else
        warn "警告: 不明なルール '#{rule_name}' がスキップされました"
        nil
      end
    end

    # 違反を表示
    # @param violations [Array<Violation>] 違反のリスト
    def display_violations(violations)
      case @options[:format]
      when "json"
        require "json"
        puts JSON.pretty_generate(violations.map(&:to_h))
      when "text"
        if violations.empty?
          puts "✓ 違反は見つかりませんでした"
        else
          puts "✗ #{violations.size}件の違反が見つかりました:\n\n"
          violations.each do |violation|
            puts violation
          end
        end
      end
    end
  end
end

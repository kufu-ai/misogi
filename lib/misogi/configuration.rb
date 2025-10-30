# frozen_string_literal: true

require "yaml"

module Misogi
  # 設定を管理するクラス
  class Configuration
    DEFAULT_CONFIG = {
      "rules" => {
        "ruby_standard" => {
          "patterns" => ["lib/**/*.rb"],
          "base_path" => "lib"
        }
      },
      "exclude" => []
    }.freeze

    attr_reader :rules, :exclude

    # @param config_path [String, nil] 設定ファイルのパス
    def initialize(config_path: ".misogi.yml")
      @config_path = config_path
      @config = load_config
      @rules = parse_rules(@config["rules"] || {})
      @exclude = @config["exclude"] || []
    end

    # ファイルが除外対象かどうかをチェック
    # @param file_path [String] ファイルパス
    # @return [Boolean]
    def excluded?(file_path)
      @exclude.any? { |pattern| File.fnmatch?(pattern, file_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
    end

    # 指定されたファイルに適用すべきルールを取得
    # @param file_path [String] ファイルパス
    # @return [Hash] ルール名とその設定のハッシュ
    def rules_for(file_path)
      @rules.select do |_rule_name, rule_config|
        rule_config[:patterns].any? do |pattern|
          File.fnmatch?(pattern, file_path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
        end
      end
    end

    # デフォルト設定を使用
    # @return [Configuration]
    def self.default
      config = new(config_path: nil)
      config.instance_variable_set(:@config, DEFAULT_CONFIG)
      config.instance_variable_set(:@rules, parse_rules(DEFAULT_CONFIG["rules"]))
      config.instance_variable_set(:@exclude, DEFAULT_CONFIG["exclude"])
      config
    end

    # ルール設定をパース
    # @param rules_config [Hash] ルール設定
    # @return [Hash] パースされたルール設定
    def self.parse_rules(rules_config)
      rules_config.transform_keys(&:to_sym).transform_values do |config|
        {
          patterns: Array(config["patterns"] || config[:patterns]),
          config: config.except("patterns", :patterns)
        }
      end
    end

    private

    # 設定ファイルを読み込む
    # @return [Hash]
    def load_config
      if @config_path && File.exist?(@config_path)
        YAML.load_file(@config_path) || {}
      else
        DEFAULT_CONFIG.dup
      end
    rescue Psych::SyntaxError => e
      warn "警告: 設定ファイルの読み込みに失敗しました: #{e.message}"
      warn "デフォルト設定を使用します"
      DEFAULT_CONFIG.dup
    end

    def parse_rules(rules_config)
      self.class.parse_rules(rules_config)
    end
  end
end

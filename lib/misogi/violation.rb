# frozen_string_literal: true

module Misogi
  # ファイルパスとコンテンツの検証違反を表すクラス
  class Violation
    attr_reader :file_path, :message, :rule_name, :suggest_path

    # @param file_path [String] 違反が見つかったファイルパス
    # @param message [String] 違反の詳細メッセージ
    # @param rule_name [String] 違反を検出したルール名
    # @param suggest_path [String|] 修正案のパス
    def initialize(file_path:, message:, rule_name:, suggest_path: nil)
      @file_path = file_path
      @message = message
      @rule_name = rule_name
      @suggest_path = suggest_path
    end

    # 違反情報を文字列として表現
    # @return [String]
    def to_s
      "#{file_path}: [#{rule_name}] #{message}"
    end

    # 違反情報をハッシュとして表現
    # @return [Hash]
    def to_h
      {
        file_path:,
        message:,
        rule_name:,
        suggest_path:
      }
    end
  end
end

# frozen_string_literal: true

module Misogi
  module Rule
    # すべてのルールの基底クラス
    # カスタムルールを作成する場合は、このクラスを継承して#validateメソッドを実装する
    class Base
      # ルール名を返す（デフォルトはクラス名）
      # @return [String]
      def name
        self.class.name.split("::").last
      end

      # ファイルパスとパース結果を検証する
      # @param file_path [String] 検証対象のファイルパス
      # @param parsed_content [ParsedContent] パース結果
      # @return [Array<Violation>] 検出された違反のリスト
      def validate(file_path, parsed_content)
        raise NotImplementedError, "#{self.class}#validateを実装してください"
      end

      protected

      # 違反を作成するヘルパーメソッド
      # @param file_path [String] ファイルパス
      # @param message [String] 違反メッセージ
      # @return [Violation]
      def violation(file_path:, message:)
        Violation.new(file_path: file_path, message: message, rule_name: name)
      end
    end
  end
end

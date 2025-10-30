# frozen_string_literal: true

module Misogi
  module Parser
    # すべてのパーサーの基底クラス
    class Base
      # ファイル内容をパースする
      # @param content [String] ファイルの内容
      # @return [ParsedContent] パース結果
      def parse(content)
        raise NotImplementedError, "#{self.class}#parseを実装してください"
      end

      # ファイルをパースできるか判定する
      # @param file_path [String] ファイルパス
      # @return [Boolean]
      def parsable?(file_path)
        raise NotImplementedError, "#{self.class}#parsable?を実装してください"
      end
    end
  end
end

# frozen_string_literal: true

module Misogi
  # ファイルのパース結果を保持するクラス
  class ParsedContent
    attr_reader :namespaces

    # @param namespaces [Array<String>] ファイル内で定義されている名前空間のリスト
    #   例: ["Misogi::Rule::Base"] は Misogi::Rule::Base クラスが定義されていることを示す
    def initialize(namespaces: [])
      @namespaces = namespaces
    end

    # 指定された名前空間が定義されているかチェック
    # @param namespace [String] チェックする名前空間
    # @return [Boolean]
    def include?(namespace)
      namespaces.include?(namespace)
    end

    # パース結果が空かどうか
    # @return [Boolean]
    def empty?
      namespaces.empty?
    end
  end
end

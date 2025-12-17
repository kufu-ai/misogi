# frozen_string_literal: true

module Misogi
  module Rule
    # Ruby一般の規約に従ってファイルパスとクラス/モジュール名の対応をチェックするルール
    # 例:
    #   lib/foo/bar.rb -> Foo::Bar
    #   lib/foo.rb -> Foo
    class RubyStandard < Base
      # @param base_path [String] 基準となるディレクトリパス（デフォルト: "lib"）
      def initialize(base_path: "lib")
        super()
        @base_path = base_path
      end

      # @param file_path [String] 検証対象のファイルパス
      # @param parsed_content [ParsedContent] パース結果
      # @return [Array<Violation>] 検出された違反のリスト
      def validate(file_path, parsed_content)
        return [] unless file_path.start_with?(@base_path)

        violations = []

        if parsed_content.empty?
          violations << violation(
            file_path: file_path,
            message: "ファイルにクラスまたはモジュールが定義されていません"
          )
          return violations
        end

        # 定義されている各名前空間について期待されるパスを計算
        expected_paths = parsed_content.namespaces.map do |namespace|
          namespace_to_path(namespace)
        end

        # 実際のファイルパスが期待されるパスのいずれかと一致するか確認
        unless expected_paths.include?(file_path)
          expected_paths_str = expected_paths.map { |p| "`#{p}`" }.join(" または ")
          defined_namespaces = parsed_content.namespaces.join(", ")

          # 候補が1つの場合のみ修正案を提示
          suggest_path = expected_paths.size == 1 ? expected_paths.first : nil

          violations << violation(
            file_path: file_path,
            message: "名前空間 '#{defined_namespaces}' は #{expected_paths_str} に配置すべきです",
            suggest_path: suggest_path
          )
        end

        violations
      end

      private

      # 名前空間から期待されるファイルパスを生成する
      # @param namespace [String] 名前空間（例: "Foo::Bar"）
      # @return [String] 期待されるファイルパス
      def namespace_to_path(namespace)
        # 名前空間をパーツに分割
        parts = namespace.split("::")

        # 各パーツをスネークケースに変換
        snake_parts = parts.map { |part| underscore(part) }

        # base_pathと結合して.rbを追加
        "#{File.join(@base_path, *snake_parts)}.rb"
      end

      # キャメルケースをスネークケースに変換
      # @param str [String] キャメルケースの文字列
      # @return [String] スネークケースの文字列
      def underscore(str)
        str
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
      end
    end
  end
end

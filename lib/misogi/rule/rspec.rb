# frozen_string_literal: true

module Misogi
  module Rule
    # RSpecの規約に従ってspecファイルとテスト対象の対応をチェックするルール
    # 例:
    #   spec/models/user_spec.rb -> Userクラスのテストを含むべき
    #   spec/services/admin/user_creator_spec.rb -> Admin::UserCreatorクラスのテストを含むべき
    class RSpec < Base
      def initialize
        super
        @active_support_available = check_active_support
      end

      # RSpecのディレクトリとソースディレクトリのマッピング
      DIRECTORY_MAPPINGS = {
        "spec/models" => "app/models",
        "spec/controllers" => "app/controllers",
        "spec/helpers" => "app/helpers",
        "spec/mailers" => "app/mailers",
        "spec/jobs" => "app/jobs",
        "spec/services" => "app/services",
        "spec/decorators" => "app/decorators",
        "spec/presenters" => "app/presenters",
        "spec/validators" => "app/validators",
        "spec/policies" => "app/policies",
        "spec/channels" => "app/channels",
        "spec/mailboxes" => "app/mailboxes",
        "spec/lib" => "lib"
      }.freeze

      # @param file_path [String] 検証対象のファイルパス
      # @param parsed_content [ParsedContent] パース結果（RSpecでは使用しない）
      # @return [Array<Violation>] 検出された違反のリスト
      def validate(file_path, _parsed_content)
        return [] unless file_path.start_with?("spec/") && file_path.end_with?("_spec.rb")
        return [] unless File.exist?(file_path)

        content = File.read(file_path)
        violations = []

        # ファイル内容からdescribeの対象を抽出
        described_namespaces = extract_described_namespaces(content)

        if described_namespaces.empty?
          violations << violation(
            file_path: file_path,
            message: "RSpec.describe または describe が見つかりません"
          )
          return violations
        end

        # 各describe対象について期待されるspecファイルパスを計算
        spec_base_path = find_spec_base_path(file_path)
        return [] unless spec_base_path

        expected_paths = described_namespaces.map do |namespace|
          namespace_to_spec_path(namespace, spec_base_path)
        end

        # 実際のファイルパスが期待されるパスのいずれかと一致するか確認
        unless expected_paths.include?(file_path)
          expected_paths_str = expected_paths.map { |p| "`#{p}`" }.join(" または ")
          described_str = described_namespaces.join(", ")

          # 候補が1つの場合のみ修正案を提示
          suggest_path = expected_paths.size == 1 ? expected_paths.first : nil

          violations << violation(
            file_path: file_path,
            message: "テスト対象 '#{described_str}' のspecファイルは #{expected_paths_str} に配置すべきです",
            suggest_path: suggest_path
          )
        end

        violations
      end

      private

      # ファイル内容からdescribeの対象（テスト対象のクラス/モジュール）を抽出
      # @param content [String] ファイルの内容
      # @return [Array<String>] 抽出された名前空間のリスト
      def extract_described_namespaces(content)
        namespaces = []

        # RSpec.describe ClassName または describe ClassName の形式を抽出
        # 定数名（::で区切られた大文字始まりの識別子）をキャプチャ
        pattern = /(?:RSpec\.)?describe\s+([A-Z][A-Za-z0-9]*(?:::[A-Z][A-Za-z0-9]*)*)/

        content.scan(pattern) do |match|
          namespaces << match[0]
        end

        namespaces.uniq
      end

      # specファイルのベースパスを見つける
      # @param file_path [String] specファイルのパス
      # @return [String, nil] ベースパス
      def find_spec_base_path(file_path)
        DIRECTORY_MAPPINGS.each_key do |spec_path|
          return spec_path if file_path.start_with?(spec_path)
        end
        nil
      end

      # 名前空間から期待されるspecファイルパスを生成する
      # @param namespace [String] 名前空間（例: "Foo::Bar"）
      # @param spec_base_path [String] specのベースパス（例: "spec/models"）
      # @return [String] 期待されるspecファイルパス
      def namespace_to_spec_path(namespace, spec_base_path)
        # 名前空間をパーツに分割
        parts = namespace.split("::")

        # 各パーツをスネークケースに変換
        snake_parts = parts.map { |part| underscore(part) }

        # spec_base_pathと結合して_spec.rbを追加
        "#{File.join(spec_base_path, *snake_parts)}_spec.rb"
      end

      # ActiveSupportが利用可能かチェック
      # @return [Boolean] ActiveSupportが利用可能かどうか
      def check_active_support
        # Rails環境が読み込まれている場合は、ActiveSupportも利用可能
        return true if defined?(::Rails)

        # Rails環境がない場合は、ActiveSupportを直接読み込んでみる
        require "active_support/inflector"
        true
      rescue LoadError
        false
      end

      # キャメルケースをスネークケースに変換
      # @param str [String] キャメルケースの文字列
      # @return [String] スネークケースの文字列
      def underscore(str)
        if @active_support_available
          # ActiveSupportが利用可能な場合はそれを使用（inflectionsを考慮）
          ActiveSupport::Inflector.underscore(str)
        else
          # フォールバック: 単純な変換
          str
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .downcase
        end
      end
    end
  end
end

# frozen_string_literal: true

module Misogi
  module Rule
    # Railsの規約に従ってファイルパスとクラス/モジュール名の対応をチェックするルール
    # 例:
    #   app/models/user.rb -> User
    #   app/controllers/users_controller.rb -> UsersController
    #   app/services/foo/bar_service.rb -> Foo::BarService
    class Rails < Base
      # Railsのディレクトリとその規約のマッピング
      DIRECTORY_PATTERNS = {
        "app/models" => { suffix: "" },
        "app/controllers" => { suffix: "" },
        "app/helpers" => { suffix: "" },
        "app/mailers" => { suffix: "" },
        "app/jobs" => { suffix: "" },
        "app/services" => { suffix: "" },
        "app/decorators" => { suffix: "" },
        "app/presenters" => { suffix: "" },
        "app/validators" => { suffix: "" },
        "app/policies" => { suffix: "" },
        "app/channels" => { suffix: "" },
        "app/mailboxes" => { suffix: "" }
      }.freeze

      def initialize(inflections_path: nil)
        super()
        @inflections_path = inflections_path # 後方互換性のため残すが使用しない
        @active_support_available = check_active_support
      end

      # @param file_path [String] 検証対象のファイルパス
      # @param parsed_content [ParsedContent] パース結果
      # @return [Array<Violation>] 検出された違反のリスト
      def validate(file_path, parsed_content)
        pattern_info = find_matching_pattern(file_path)
        return [] unless pattern_info

        violations = []

        if parsed_content.empty?
          violations << violation(
            file_path: file_path,
            message: "ファイルにクラスまたはモジュールが定義されていません"
          )
          return violations
        end

        # concernsディレクトリ内のファイルでは、名前空間に"Concerns::"を含んではいけない
        if file_path.include?("/concerns/")
          concerns_violation = check_concerns_namespace(file_path, parsed_content)
          violations << concerns_violation if concerns_violation
          return violations if concerns_violation
        end

        # 定義されている各名前空間について期待されるパスを計算
        base_path = pattern_info[:base_path]
        expected_paths = parsed_content.namespaces.flat_map do |namespace|
          namespace_to_paths(namespace, base_path, file_path)
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

      # concernsディレクトリ内のファイルの名前空間をチェック
      # @param file_path [String] ファイルパス
      # @param parsed_content [ParsedContent] パース結果
      # @return [Violation, nil] 違反がある場合はViolationオブジェクト
      def check_concerns_namespace(file_path, parsed_content)
        # concernsディレクトリ内のファイルでは、名前空間に"Concerns::"を含んではいけない
        invalid_namespaces = parsed_content.namespaces.select do |namespace|
          namespace.start_with?("Concerns::") || namespace.include?("::Concerns::")
        end

        return nil if invalid_namespaces.empty?

        violation(
          file_path: file_path,
          message: "concernsディレクトリ内のファイルでは、名前空間に 'Concerns::' を含めるべきではありません。" \
                   "定義されている名前空間: #{invalid_namespaces.join(", ")}"
        )
      end

      # ファイルパスに一致するパターンを見つける
      # @param file_path [String] ファイルパス
      # @return [Hash, nil] パターン情報
      def find_matching_pattern(file_path)
        DIRECTORY_PATTERNS.each do |base_path, options|
          return { base_path: base_path, **options } if file_path.start_with?(base_path)
        end
        nil
      end

      # 名前空間から期待されるファイルパスを生成する（複数の可能性を返す）
      # @param namespace [String] 名前空間（例: "Foo::Bar"）
      # @param base_path [String] ベースパス（例: "app/models"）
      # @param current_file_path [String] 現在検証中のファイルパス
      # @return [Array<String>] 期待されるファイルパスのリスト
      def namespace_to_paths(namespace, base_path, current_file_path)
        # 名前空間をパーツに分割
        parts = namespace.split("::")

        # 各パーツをスネークケースに変換
        snake_parts = parts.map { |part| underscore(part) }

        paths = []

        # 通常のパス
        paths << "#{File.join(base_path, *snake_parts)}.rb"

        # concernsディレクトリ内のパス
        # 現在のファイルがconcernsディレクトリ内にある場合、
        # かつ名前空間が"Concerns::"で始まらない場合のみ、concernsパスも候補に含める
        # （concernsディレクトリは名前空間に含めないRailsの規約のため）
        if current_file_path.include?("/concerns/") && !namespace.start_with?("Concerns::")
          paths << "#{File.join(base_path, "concerns", *snake_parts)}.rb"
        end

        paths
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

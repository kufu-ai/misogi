# frozen_string_literal: true

require "ripper"

module Misogi
  module Parser
    # Rubyファイルのパーサー
    # Ripperを使用してRubyコードを解析し、定義されているクラス/モジュールを抽出する
    class Ruby < Base
      # @param file_path [String] ファイルパス
      # @return [Boolean] .rbファイルかどうか
      def parsable?(file_path)
        File.extname(file_path) == ".rb"
      end

      # @param content [String] Rubyファイルの内容
      # @return [ParsedContent] パース結果
      def parse(content)
        namespaces = extract_namespaces(content)
        ParsedContent.new(namespaces: namespaces)
      end

      private

      # Rubyコードから名前空間を抽出する
      # @param content [String] Rubyコードの内容
      # @return [Array<String>] 名前空間のリスト
      def extract_namespaces(content)
        sexp = Ripper.sexp(content)
        return [] unless sexp

        namespaces = []
        traverse_sexp(sexp, [], namespaces)
        namespaces
      end

      # S式を再帰的に走査して、クラス/モジュール定義を見つける
      # @param node [Array] S式のノード
      # @param current_namespace [Array<String>] 現在の名前空間のスタック
      # @param namespaces [Array<String>] 見つかった名前空間を格納する配列
      def traverse_sexp(node, current_namespace, namespaces)
        return unless node.is_a?(Array)

        case node[0]
        when :class
          # クラス定義: [:class, [:const_ref, [:@const, "ClassName", ...]], ...]
          class_name = extract_const_path(node[1])
          if class_name
            full_name = (current_namespace + [class_name]).join("::")
            namespaces << full_name
            # クラス本体を再帰的に処理
            traverse_sexp(node[3], current_namespace + [class_name], namespaces) if node[3]
          end
        when :module
          # モジュール定義: [:module, [:const_ref, [:@const, "ModuleName", ...]], ...]
          module_name = extract_const_path(node[1])
          if module_name
            full_name = (current_namespace + [module_name]).join("::")
            namespaces << full_name
            # モジュール本体を再帰的に処理
            traverse_sexp(node[2], current_namespace + [module_name], namespaces) if node[2]
          end
        else
          # その他のノードは子ノードを再帰的に処理
          node.each do |child|
            traverse_sexp(child, current_namespace, namespaces) if child.is_a?(Array)
          end
        end
      end

      # 定数パスから名前を抽出する
      # @param node [Array] 定数パスのノード
      # @return [String, nil] 定数名
      def extract_const_path(node)
        return nil unless node.is_a?(Array)

        case node[0]
        when :const_ref
          # [:const_ref, [:@const, "Name", ...]]
          node[1][1] if node[1] && node[1][0] == :@const
        when :const_path_ref
          # [:const_path_ref, parent, [:@const, "Name", ...]]
          # 例: Foo::Bar の場合
          parent = extract_const_path(node[1])
          child = node[2][1] if node[2] && node[2][0] == :@const
          parent && child ? "#{parent}::#{child}" : nil
        when :const_path_field
          # [:const_path_field, parent, [:@const, "Name", ...]]
          # クラス定義でのコンパクト記法の場合
          parent = extract_const_path(node[1])
          child = node[2][1] if node[2] && node[2][0] == :@const
          parent && child ? "#{parent}::#{child}" : nil
        when :top_const_ref
          # [:top_const_ref, [:@const, "Name", ...]]
          # 例: ::Foo の場合
          node[1][1] if node[1] && node[1][0] == :@const
        when :top_const_field
          # [:top_const_field, [:@const, "Name", ...]]
          # トップレベル定数のフィールド
          node[1][1] if node[1] && node[1][0] == :@const
        when :var_ref
          # [:var_ref, [:@const, "Name", ...]]
          # 定数の参照
          node[1][1] if node[1] && node[1][0] == :@const
        end
      end
    end
  end
end

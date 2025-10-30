# CLAUDE.md

このファイルは、このリポジトリで作業する際にClaude Code (claude.ai/code) に提供されるガイダンスです。

## 言語設定

**このプロジェクトでは日本語で対応してください。**すべての説明、コメント、コミットメッセージ、ドキュメントは日本語で記述します。

## プロジェクト概要

Misogiは、ファイルの内容を解析して、そのファイル名やディレクトリ配置が適切かをチェックするlintツールを提供するRuby gemです（現在、初期開発段階）。

### 目的
コードの内容とファイルパスの整合性を保ち、プロジェクトの構造を整理された状態に保つことを目的としています。ファイル内で定義されているクラスやモジュールの名前空間と、実際のファイルパスが一致しているかを検証します。

標準的な Ruby gem の規約に従い、gem 管理には Bundler を使用しています。

## 開発コマンド

### セットアップ
```bash
bin/setup
```
依存関係をインストールし、開発環境を準備します。

### テスト
```bash
rake spec                    # すべてのテストを実行
bundle exec rspec            # RSpecを直接実行
bundle exec rspec spec/path/to/file_spec.rb  # 単一のテストファイルを実行
```

### コード品質チェック
```bash
rake rubocop                 # RuboCopリンターを実行
bundle exec rubocop          # RuboCopを直接実行
bundle exec rubocop -a       # 違反を自動修正
```

### デフォルトタスク
```bash
rake                         # specとrubocopの両方を実行
```

### インタラクティブコンソール
```bash
bin/console                  # gemをロードした状態でIRBを起動
```

### Gem管理
```bash
bundle exec rake install     # gemをローカルにインストール
bundle exec rake release     # gitタグを作成してRubyGemsにプッシュ（バージョンアップが必要）
```

## コードアーキテクチャ

### 構造
- `lib/misogi.rb` - メインエントリーポイント、`Misogi`モジュールを定義
- `lib/misogi/version.rb` - gemのバージョン定数
- `sig/misogi.rbs` - 静的型チェック用のRBS型シグネチャ
- `spec/` - RSpecテストファイル

### コードスタイル
- Ruby 3.2以上が必要
- RuboCopは文字列リテラルにダブルクォートを強制（補間内も含む）
- EditorConfigでフォーマットを定義: 2スペースインデント、UTF-8、LF改行

### テスト
- モンキーパッチを無効化したRSpec
- テストステータスの永続化が有効（`.rspec_status`）
- expectシンタックスのみ使用（`should`シンタックスは使用しない）

## バージョン管理

リリース前に `lib/misogi/version.rb` でバージョンを更新してください。バージョンはセマンティックバージョニングに従います。

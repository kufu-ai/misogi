# CLAUDE.md

このファイルは、このリポジトリで作業する際にClaude Code (claude.ai/code) に提供されるガイダンスです。

## 言語設定

**このプロジェクトでは日本語で対応してください。**すべての説明、コメント、コミットメッセージ、ドキュメントは日本語で記述します。

## プロジェクト概要

Misogiは、ファイルの内容を解析して、そのファイル名やディレクトリ配置が適切かをチェックするlintツールを提供するRuby gemです（現在、初期開発段階）。

### 目的
コードの内容とファイルパスの整合性を保ち、プロジェクトの構造を整理された状態に保つことを目的としています。ファイル内で定義されているクラスやモジュールの名前空間と、実際のファイルパスが一致しているかを検証します。

標準的な Ruby gem の規約に従い、gem 管理には Bundler を使用しています。

## CLIコマンド

### 使い方

```bash
# ヘルプを表示
./exe/misogi --help

# デフォルト設定でチェック（lib, app, spec配下のファイル）
./exe/misogi

# 特定のファイルをチェック
./exe/misogi lib/foo.rb

# ルールを指定してチェック
./exe/misogi --rules ruby_standard,rails,rspec

# パターンを指定してチェック
./exe/misogi --pattern "lib/**/*.rb"
```

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

## アーキテクチャ設計

### 概要

Misogiは、ファイルの内容を解析して、ファイル名やディレクトリ配置が適切かをチェックするlintツールです。様々なルールセット（Ruby一般、Rails、RSpecなど）に対応し、カスタムルールも定義できる拡張可能な設計を採用しています。

### コアコンポーネント

#### 1. Rule（ルール）
- 基底クラス: `Misogi::Rule::Base`
- 各ルールは`validate(file_path, parsed_content)`メソッドを実装
- 検証結果を`Misogi::Violation`オブジェクトとして返す
- ルールは独立して動作し、組み合わせ可能

#### 2. Parser（パーサー）
- ファイル内容を解析してクラス/モジュールの定義を抽出
- `Misogi::Parser::Ruby`が基本的なRubyファイルの解析を担当
- 解析結果は`Misogi::ParsedContent`オブジェクトとして返す
- 名前空間のネストも正しく解析

#### 3. Validator（バリデーター）
- `Misogi::Validator`がルールの実行とViolationの収集を担当
- 複数のルールを同時に適用可能
- ファイルパスとパース結果を各ルールに渡して検証

#### 4. Configuration（設定）
- `.misogi.yml`でプロジェクト固有の設定を管理
- 有効にするルールセットの指定
- カスタムルールのパス指定
- 除外パターンの指定

#### 5. Built-in Rules（組み込みルール）
- `Misogi::Rule::RubyStandard`: Ruby一般の規約（ファイル名とクラス名の対応）
- `Misogi::Rule::Rails`: Railsの規約（app/models、app/controllersなど）
- `Misogi::Rule::RSpec`: RSpecの規約（spec/ファイルパスとテスト対象の対応）

#### 6. Custom Rules（カスタムルール）
- `Misogi::Rule::Base`を継承してカスタムルールを作成
- `.misogi.yml`で外部ルールファイルを指定
- プロジェクト固有のディレクトリ構造ルールを定義可能

### ディレクトリ構造

```
lib/
├── misogi.rb                    # メインエントリーポイント
├── misogi/
│   ├── version.rb               # バージョン定数
│   ├── violation.rb             # 違反情報を保持するクラス
│   ├── parsed_content.rb        # パース結果を保持するクラス
│   ├── configuration.rb         # 設定を管理するクラス
│   ├── parser/
│   │   ├── base.rb              # パーサーの基底クラス
│   │   └── ruby.rb              # Rubyファイルのパーサー
│   ├── rule/
│   │   ├── base.rb              # ルールの基底クラス
│   │   ├── ruby_standard.rb     # Ruby一般の規約ルール
│   │   ├── rails.rb             # Railsの規約ルール
│   │   └── rspec.rb             # RSpecの規約ルール
│   ├── validator.rb             # バリデーション実行クラス
│   └── cli.rb                   # コマンドラインインターフェース（将来実装）
```

### 設定ファイル例（.misogi.yml）

```yaml
# 有効にするルールセット
rules:
  - ruby_standard
  - rails
  - rspec

# カスタムルールのパス
custom_rules:
  - lib/custom_rules/my_rule.rb

# 除外パターン
exclude:
  - vendor/**/*
  - tmp/**/*
  - db/migrate/**/*
```

### 実装の優先順位

1. `Misogi::Rule::Base` - ルールの基底クラス
2. `Misogi::Parser::Ruby` - Rubyファイルのパーサー
3. `Misogi::Validator` - バリデーター
4. `Misogi::Rule::RubyStandard` - Ruby一般ルール
5. `Misogi::Rule::Rails` - Railsルール
6. `Misogi::Rule::RSpec` - RSpecルール
7. `Misogi::Configuration` - 設定管理
8. カスタムルールのロード機能

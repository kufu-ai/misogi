# Misogi

Misogiは、ファイルの内容を解析して、そのファイル名やディレクトリ配置が適切かをチェックするlintツールです。コードの内容とファイルパスの整合性を保ち、プロジェクトの構造を整理された状態に保つことを目的としています。

> [!WARNING]
> このプロジェクトは現在開発段階にあり、多くのコードがAIによって生成されています。そのため、すべての機能の動作を完全には保証できません。本番環境での使用前に、十分なテストと検証を行うことをお勧めします。

## インストール

次のコマンドを実行して、gemをインストールし、アプリケーションのGemfileに追加します：

```bash
bundle add misogi
```

Bundlerを使用していない場合は、次のコマンドでgemをインストールします：

```bash
gem install misogi
```

## 使い方

### コマンドラインから使う

gemをインストール後、`misogi`コマンドが使えるようになります。

```bash
# デフォルト（lib, app, spec配下のファイルをチェック）
misogi

# 特定のファイルをチェック
misogi lib/foo.rb

# 複数のファイルをチェック
misogi lib/**/*.rb

# パターンを指定してチェック
misogi --pattern "lib/**/*.rb"

# 使用するルールを指定
misogi --rules ruby_standard,rails,rspec

# ベースパスを変更
misogi --base-path src

# ヘルプを表示
misogi --help

# 出力フォーマット指定
misogi --format json

# バージョンを表示
misogi --version
```

#### オプション

- `-r, --rules RULES` - 使用するルール（カンマ区切り）
  - `ruby_standard`: Ruby一般の規約
  - `rails`: Railsの規約
  - `rspec`: RSpecの規約
- `-b, --base-path PATH` - Ruby一般ルールのベースパス（デフォルト: lib）
- `-p, --pattern PATTERN` - 検証するファイルパターン
- `-c, --config PATH` - 設定ファイルのパス（デフォルト: .misogi.yml）
- `-h, --help` - ヘルプを表示
- `-v, --version` - バージョンを表示

#### 終了コード

- `0`: 違反が見つからなかった
- `1`: 違反が見つかった、またはエラーが発生した

### 設定ファイル

プロジェクトのルートに`.misogi.yml`を配置することで、ルールごとに適用するファイルパターンや除外パターンを設定できます。

#### 設定ファイルの作成

サンプル設定ファイルをコピーして使用できます：

```bash
cp .misogi.yml.example .misogi.yml
```

#### 設定例

```yaml
# 使用するルールと適用パターン
rules:
  # Ruby一般ルール: lib配下のファイルに適用
  ruby_standard:
    patterns:
      - "lib/**/*.rb"
    base_path: "lib"

  # Railsルール: app配下のファイルに適用
  rails:
    patterns:
      - "app/**/*.rb"

  # RSpecルール: spec配下のファイルに適用
  rspec:
    patterns:
      - "spec/**/*_spec.rb"

# 検証から除外するファイルパターン
exclude:
  - "tmp/**/*"
  - "vendor/**/*"
  - "db/schema.rb"
```

#### 設定ファイルの優先順位

1. コマンドラインオプション（最優先）
2. 設定ファイル（`.misogi.yml`）
3. デフォルト設定

`--rules`オプションを指定した場合は、設定ファイルのルール設定を無視して、指定されたルールを全ファイルに適用します。

### Rubyコードから使う

#### 基本的な使い方

```ruby
require "misogi"

# Ruby一般ルールを使用
rule = Misogi::Rule::RubyStandard.new
validator = Misogi::Validator.new(rules: [rule])

# ファイルを検証
violations = validator.validate_file("lib/foo/bar.rb")

violations.each do |violation|
  puts violation.to_s
  # => lib/foo/bar.rb: [RubyStandard] 期待される名前空間 'Foo::Bar' が見つかりません。定義されている名前空間: Baz
end
```

### 利用可能なルール

#### Ruby一般ルール (`Misogi::Rule::RubyStandard`)

Rubyの一般的な規約に従ってファイルパスとクラス/モジュール名の対応をチェックします。

```ruby
# lib/foo.rb -> Foo
# lib/foo/bar.rb -> Foo::Bar
# lib/foo_bar.rb -> FooBar

rule = Misogi::Rule::RubyStandard.new(base_path: "lib")
```

#### Railsルール (`Misogi::Rule::Rails`)

Railsの規約に従ってファイルパスとクラス/モジュール名の対応をチェックします。

```ruby
# app/models/user.rb -> User
# app/controllers/users_controller.rb -> UsersController
# app/services/admin/user_creator.rb -> Admin::UserCreator

rule = Misogi::Rule::Rails.new
```

対応しているディレクトリ：
- `app/models`
- `app/controllers`
- `app/helpers`
- `app/mailers`
- `app/jobs`
- `app/services`
- `app/decorators`
- `app/presenters`
- `app/validators`
- `app/policies`
- `app/channels`
- `app/mailboxes`

#### RSpecルール (`Misogi::Rule::RSpec`)

RSpecの規約に従ってspecファイルとテスト対象の対応をチェックします。

```ruby
# spec/models/user_spec.rb -> Userのテスト
# spec/controllers/users_controller_spec.rb -> UsersControllerのテスト
# spec/lib/foo/bar_spec.rb -> Foo::Barのテスト

rule = Misogi::Rule::RSpec.new
```

### 複数のルールを組み合わせる

```ruby
rules = [
  Misogi::Rule::RubyStandard.new(base_path: "lib"),
  Misogi::Rule::Rails.new,
  Misogi::Rule::RSpec.new
]

validator = Misogi::Validator.new(rules: rules)
violations = validator.validate_files(Dir.glob("{lib,app,spec}/**/*.rb"))
```

### カスタムルールの作成

独自のルールを作成することもできます。`Misogi::Rule::Base`を継承して実装します。

```ruby
class MyCustomRule < Misogi::Rule::Base
  def validate(file_path, parsed_content)
    violations = []

    # カスタムロジック
    if some_condition?(file_path, parsed_content)
      violations << violation(
        file_path: file_path,
        message: "カスタムルールに違反しています"
      )
    end

    violations
  end
end

# 使用例
rule = MyCustomRule.new
validator = Misogi::Validator.new(rules: [rule])
```

## 開発

リポジトリをチェックアウト後、`bin/setup`を実行して依存関係をインストールします。その後、`rake spec`でテストを実行できます。また、`bin/console`で対話的なプロンプトを起動して実験することもできます。

このgemをローカルマシンにインストールするには、`bundle exec rake install`を実行します。新しいバージョンをリリースするには、`version.rb`でバージョン番号を更新してから、`bundle exec rake release`を実行します。これにより、バージョンのgitタグが作成され、gitコミットと作成されたタグがプッシュされ、`.gem`ファイルが[rubygems.org](https://rubygems.org)にプッシュされます。

## コントリビューション

バグレポートやプルリクエストは、GitHubの https://github.com/kufu-ai/misogi で受け付けています。このプロジェクトは、安全で歓迎される協力の場であることを目指しており、コントリビューターは[行動規範](https://github.com/kufu-ai/misogi/blob/main/CODE_OF_CONDUCT.md)を遵守することが期待されます。

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件の下でオープンソースとして利用可能です。

## 行動規範

Misogiプロジェクトのコードベース、イシュートラッカー、チャットルーム、メーリングリストでやり取りするすべての人は、[行動規範](https://github.com/kufu-ai/misogi/blob/main/CODE_OF_CONDUCT.md)に従うことが期待されます。

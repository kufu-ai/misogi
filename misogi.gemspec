# frozen_string_literal: true

require_relative "lib/misogi/version"

Gem::Specification.new do |spec|
  spec.name = "misogi"
  spec.version = Misogi::VERSION
  spec.authors = ["iyuuya"]
  spec.email = ["yuya.ito@kufu.co.jp"]

  spec.summary = "ファイルの内容とパスの整合性をチェックするlintツール"
  spec.description = "ファイル内で定義されているクラスやモジュールの名前空間と、実際のファイルパスが一致しているかを検証するlintツールです。"
  spec.homepage = "https://github.com/iyuuya/misogi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # gemがリリースされる際に追加するファイルを指定します。
  # `git ls-files -z`はgitに追加されているファイルを読み込みます。
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # gemの依存関係を登録する場合は以下のコメントを解除してください
  # spec.add_dependency "example-gem", "~> 1.0"
end

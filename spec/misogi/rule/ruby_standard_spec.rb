# frozen_string_literal: true

RSpec.describe Misogi::Rule::RubyStandard do
  let(:rule) { described_class.new(base_path: "lib") }
  let(:parser) { Misogi::Parser::Ruby.new }

  describe "#validate" do
    context "正しい名前空間が定義されている場合" do
      it "違反を検出しない" do
        file_path = "lib/foo.rb"
        content = <<~RUBY
          class Foo
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされた名前空間でも違反を検出しない" do
        file_path = "lib/foo/bar.rb"
        content = <<~RUBY
          module Foo
            class Bar
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "コンパクトな名前空間記法でも違反を検出しない" do
        file_path = "lib/foo/bar.rb"
        content = <<~RUBY
          class Foo::Bar
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "スネークケースのファイル名をキャメルケースに変換する" do
        file_path = "lib/foo_bar.rb"
        content = <<~RUBY
          class FooBar
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "期待される名前空間が定義されていない場合" do
      it "違反を検出する" do
        file_path = "lib/foo.rb"
        content = <<~RUBY
          class Bar
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to include("名前空間 'Bar' は")
        expect(violations.first.message).to include("`lib/bar.rb` に配置すべきです")
        expect(violations.first.suggest_path).to eq("lib/bar.rb")
      end

      it "ネストが間違っている場合も違反を検出する" do
        file_path = "lib/foo/bar.rb"
        content = <<~RUBY
          class Bar
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to include("名前空間 'Bar' は")
        expect(violations.first.message).to include("`lib/bar.rb` に配置すべきです")
        expect(violations.first.suggest_path).to eq("lib/bar.rb")
      end
    end

    context "ファイルにクラス/モジュールが定義されていない場合" do
      it "違反を検出する" do
        file_path = "lib/foo.rb"
        content = "# 空のファイル"
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to eq("ファイルにクラスまたはモジュールが定義されていません")
      end
    end

    context "base_path外のファイルの場合" do
      it "検証をスキップする" do
        file_path = "spec/foo_spec.rb"
        content = <<~RUBY
          RSpec.describe Foo do
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "深いネストの場合" do
      it "正しく検証する" do
        file_path = "lib/foo/bar/baz.rb"
        content = <<~RUBY
          module Foo
            module Bar
              class Baz
              end
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end
  end
end

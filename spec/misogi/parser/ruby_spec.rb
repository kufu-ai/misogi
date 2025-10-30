# frozen_string_literal: true

RSpec.describe Misogi::Parser::Ruby do
  let(:parser) { described_class.new }

  describe "#parsable?" do
    it ".rbファイルの場合はtrueを返す" do
      expect(parser.parsable?("lib/foo.rb")).to be true
    end

    it ".rbファイル以外の場合はfalseを返す" do
      expect(parser.parsable?("README.md")).to be false
      expect(parser.parsable?("lib/foo.js")).to be false
    end
  end

  describe "#parse" do
    it "単一のクラス定義を抽出する" do
      content = <<~RUBY
        class Foo
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to eq(["Foo"])
    end

    it "単一のモジュール定義を抽出する" do
      content = <<~RUBY
        module Foo
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to eq(["Foo"])
    end

    it "ネストされた名前空間を抽出する" do
      content = <<~RUBY
        module Foo
          class Bar
          end
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to contain_exactly("Foo", "Foo::Bar")
    end

    it "複数の独立したクラス定義を抽出する" do
      content = <<~RUBY
        class Foo
        end

        class Bar
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to contain_exactly("Foo", "Bar")
    end

    it "コンパクトな名前空間記法を抽出する" do
      content = <<~RUBY
        class Foo::Bar
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to eq(["Foo::Bar"])
    end

    it "深くネストされた名前空間を抽出する" do
      content = <<~RUBY
        module Foo
          module Bar
            class Baz
            end
          end
        end
      RUBY

      result = parser.parse(content)
      expect(result.namespaces).to contain_exactly("Foo", "Foo::Bar", "Foo::Bar::Baz")
    end

    it "空のファイルの場合は空の結果を返す" do
      content = ""
      result = parser.parse(content)
      expect(result.namespaces).to be_empty
    end
  end
end

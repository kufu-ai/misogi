# frozen_string_literal: true

RSpec.describe Misogi::Rule::Rails do
  let(:rule) { described_class.new }
  let(:parser) { Misogi::Parser::Ruby.new }

  describe "#validate" do
    context "app/modelsの場合" do
      it "正しい名前空間が定義されていれば違反を検出しない" do
        file_path = "app/models/user.rb"
        content = <<~RUBY
          class User < ApplicationRecord
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされたモデルも正しく検証する" do
        file_path = "app/models/admin/user.rb"
        content = <<~RUBY
          module Admin
            class User < ApplicationRecord
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "間違った名前空間の場合は違反を検出する" do
        file_path = "app/models/user.rb"
        content = <<~RUBY
          class Person < ApplicationRecord
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to include("名前空間 'Person' は")
        expect(violations.first.message).to include("`app/models/person.rb` に配置すべきです")
      end
    end

    context "app/controllersの場合" do
      it "正しい名前空間が定義されていれば違反を検出しない" do
        file_path = "app/controllers/users_controller.rb"
        content = <<~RUBY
          class UsersController < ApplicationController
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされたコントローラも正しく検証する" do
        file_path = "app/controllers/admin/users_controller.rb"
        content = <<~RUBY
          module Admin
            class UsersController < ApplicationController
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "app/servicesの場合" do
      it "正しい名前空間が定義されていれば違反を検出しない" do
        file_path = "app/services/user_creator.rb"
        content = <<~RUBY
          class UserCreator
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされたサービスも正しく検証する" do
        file_path = "app/services/admin/user_creator.rb"
        content = <<~RUBY
          module Admin
            class UserCreator
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "Rails以外のディレクトリの場合" do
      it "検証をスキップする" do
        file_path = "lib/foo.rb"
        content = <<~RUBY
          class Foo
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "concernsディレクトリの場合" do
      it "modelsのconcernが正しく検証される" do
        file_path = "app/models/concerns/readable.rb"
        content = <<~RUBY
          module Readable
            extend ActiveSupport::Concern
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "controllersのconcernが正しく検証される" do
        file_path = "app/controllers/concerns/authenticatable.rb"
        content = <<~RUBY
          module Authenticatable
            extend ActiveSupport::Concern
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされたconcernも正しく検証される" do
        file_path = "app/models/concerns/admin/searchable.rb"
        content = <<~RUBY
          module Admin
            module Searchable
              extend ActiveSupport::Concern
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "concernsを名前空間に含めた場合は違反を検出する" do
        file_path = "app/models/concerns/readable.rb"
        content = <<~RUBY
          module Concerns
            module Readable
              extend ActiveSupport::Concern
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to include("concernsディレクトリ内のファイルでは")
        expect(violations.first.message).to include("'Concerns::' を含めるべきではありません")
      end
    end

    context "inflections対応" do
      it "ActiveSupportが利用可能な場合、通常のクラス名を変換できる" do
        # ActiveSupportがない環境でもテストが失敗しないようにスキップできるようにする
        begin
          require "active_support/inflector"
          active_support_available = true
        rescue LoadError
          active_support_available = false
        end

        skip "ActiveSupportが利用できません" unless active_support_available

        # スネークケースからキャメルケースへの変換をテスト
        # これは既に動作しているはず
        file_path = "app/models/user_profile.rb"
        content = <<~RUBY
          class UserProfile < ApplicationRecord
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "ファイルにクラス/モジュールが定義されていない場合" do
      it "違反を検出する" do
        file_path = "app/models/user.rb"
        content = "# 空のファイル"
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to eq("ファイルにクラスまたはモジュールが定義されていません")
      end
    end
  end
end

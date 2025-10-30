# frozen_string_literal: true

RSpec.describe Misogi::Rule::RSpec do
  let(:rule) { described_class.new }
  let(:parser) { Misogi::Parser::Ruby.new }

  describe "#validate" do
    context "spec/modelsの場合" do
      it "正しいテスト対象が含まれていれば違反を検出しない" do
        file_path = "spec/models/user_spec.rb"
        content = <<~RUBY
          RSpec.describe User do
            it "works" do
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "ネストされたモデルのテストも正しく検証する" do
        file_path = "spec/models/admin/user_spec.rb"
        content = <<~RUBY
          RSpec.describe Admin::User do
            it "works" do
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end

      it "間違ったテスト対象の場合は違反を検出する" do
        file_path = "spec/models/user_spec.rb"
        content = <<~RUBY
          RSpec.describe Person do
            it "works" do
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations.size).to eq(1)
        expect(violations.first.message).to include("テスト対象 'Person' のspecファイルは")
        expect(violations.first.message).to include("`spec/models/person_spec.rb` に配置すべきです")
      end
    end

    context "spec/controllersの場合" do
      it "正しいテスト対象が含まれていれば違反を検出しない" do
        file_path = "spec/controllers/users_controller_spec.rb"
        content = <<~RUBY
          RSpec.describe UsersController do
            it "works" do
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "spec/libの場合" do
      it "正しいテスト対象が含まれていれば違反を検出しない" do
        file_path = "spec/lib/foo/bar_spec.rb"
        content = <<~RUBY
          RSpec.describe Foo::Bar do
            it "works" do
            end
          end
        RUBY
        parsed_content = parser.parse(content)

        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "spec配下でも_spec.rbで終わらないファイルの場合" do
      it "検証をスキップする" do
        file_path = "spec/support/helper.rb"
        content = <<~RUBY
          module Helper
          end
        RUBY
        parsed_content = parser.parse(content)

        violations = rule.validate(file_path, parsed_content)
        expect(violations).to be_empty
      end
    end

    context "spec以外のディレクトリの場合" do
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
  end
end

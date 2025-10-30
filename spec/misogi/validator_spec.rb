# frozen_string_literal: true

RSpec.describe Misogi::Validator do
  let(:rule) { Misogi::Rule::RubyStandard.new }
  let(:validator) { described_class.new(rules: [rule]) }

  describe "#validate_file" do
    it "ファイルを検証する" do
      file_path = "lib/foo.rb"
      content = <<~RUBY
        class Bar
        end
      RUBY

      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:read).with(file_path).and_return(content)

      violations = validator.validate_file(file_path)
      expect(violations).not_to be_empty
      expect(violations.first.message).to include("名前空間 'Bar' は")
      expect(violations.first.message).to include("`lib/bar.rb` に配置すべきです")
    end

    it ".rbファイル以外はスキップする" do
      file_path = "lib/foo.txt"

      violations = validator.validate_file(file_path)
      expect(violations).to be_empty
    end

    it "存在しないファイルはスキップする" do
      violations = validator.validate_file("nonexistent.rb")
      expect(violations).to be_empty
    end
  end

  describe "#validate_files" do
    it "複数のファイルを検証する" do
      file1_path = "lib/foo.rb"
      file2_path = "lib/bar.rb"

      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(file1_path).and_return("class Baz; end")
      allow(File).to receive(:read).with(file2_path).and_return("class Qux; end")

      violations = validator.validate_files([file1_path, file2_path])
      expect(violations.size).to eq(2) # 両方とも違反がある
    end
  end
end

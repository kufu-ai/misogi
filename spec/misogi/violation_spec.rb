# frozen_string_literal: true

RSpec.describe Misogi::Violation do
  describe "#initialize" do
    it "ファイルパス、メッセージ、ルール名を保持する" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule"
      )

      expect(violation.file_path).to eq("lib/foo.rb")
      expect(violation.message).to eq("テストメッセージ")
      expect(violation.rule_name).to eq("TestRule")
    end
  end

  describe "#to_s" do
    it "違反情報を文字列として表現する" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule"
      )

      expect(violation.to_s).to eq("lib/foo.rb: [TestRule] テストメッセージ")
    end
  end
end

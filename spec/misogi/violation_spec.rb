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

    it "suggest_pathを保持する" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule",
        suggest_path: "lib/bar.rb"
      )

      expect(violation.suggest_path).to eq("lib/bar.rb")
    end

    it "suggest_pathが指定されない場合はnilになる" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule"
      )

      expect(violation.suggest_path).to be_nil
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

  describe "#to_h" do
    it "違反情報をハッシュとして表現する" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule",
        suggest_path: "lib/bar.rb"
      )

      expect(violation.to_h).to eq({
                                     file_path: "lib/foo.rb",
                                     message: "テストメッセージ",
                                     rule_name: "TestRule",
                                     suggest_path: "lib/bar.rb"
                                   })
    end

    it "suggest_pathがnilの場合もハッシュに含まれる" do
      violation = described_class.new(
        file_path: "lib/foo.rb",
        message: "テストメッセージ",
        rule_name: "TestRule"
      )

      expect(violation.to_h).to eq({
                                     file_path: "lib/foo.rb",
                                     message: "テストメッセージ",
                                     rule_name: "TestRule",
                                     suggest_path: nil
                                   })
    end
  end
end

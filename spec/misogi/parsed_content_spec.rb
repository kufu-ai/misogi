# frozen_string_literal: true

RSpec.describe Misogi::ParsedContent do
  describe "#include?" do
    it "指定された名前空間が含まれているかチェックする" do
      parsed_content = described_class.new(namespaces: ["Foo::Bar", "Baz"])

      expect(parsed_content.include?("Foo::Bar")).to be true
      expect(parsed_content.include?("Baz")).to be true
      expect(parsed_content.include?("Qux")).to be false
    end
  end

  describe "#empty?" do
    it "名前空間が空の場合はtrueを返す" do
      parsed_content = described_class.new(namespaces: [])
      expect(parsed_content.empty?).to be true
    end

    it "名前空間がある場合はfalseを返す" do
      parsed_content = described_class.new(namespaces: ["Foo"])
      expect(parsed_content.empty?).to be false
    end
  end
end

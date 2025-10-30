# frozen_string_literal: true

RSpec.describe Misogi::Configuration do
  describe "#initialize" do
    context "設定ファイルが存在する場合" do
      it "設定ファイルを読み込む" do
        config_content = <<~YAML
          rules:
            ruby_standard:
              patterns:
                - "lib/**/*.rb"
              base_path: "lib"
          exclude:
            - "tmp/**/*"
        YAML

        allow(File).to receive(:exist?).with(".misogi.yml").and_return(true)
        allow(YAML).to receive(:load_file).with(".misogi.yml").and_return(YAML.safe_load(config_content))

        config = described_class.new(config_path: ".misogi.yml")

        expect(config.rules).to have_key(:ruby_standard)
        expect(config.exclude).to eq(["tmp/**/*"])
      end
    end

    context "設定ファイルが存在しない場合" do
      it "デフォルト設定を使用する" do
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)

        config = described_class.new(config_path: ".misogi.yml")

        expect(config.rules).to have_key(:ruby_standard)
        expect(config.exclude).to eq([])
      end
    end

    context "設定ファイルの構文エラーがある場合" do
      it "警告を表示してデフォルト設定を使用する" do
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(true)
        allow(YAML).to receive(:load_file).with(".misogi.yml").and_raise(Psych::SyntaxError.new("", 1, 1, 0, "test",
                                                                                                "test"))

        expect { described_class.new(config_path: ".misogi.yml") }.to output(/警告/).to_stderr

        config = described_class.new(config_path: ".misogi.yml")
        expect(config.rules).to have_key(:ruby_standard)
      end
    end
  end

  describe ".default" do
    it "デフォルト設定を返す" do
      config = described_class.default

      expect(config.rules).to have_key(:ruby_standard)
      expect(config.exclude).to eq([])
    end
  end

  describe "#rules_for" do
    it "ファイルパスに一致するルールを返す" do
      config_content = <<~YAML
        rules:
          ruby_standard:
            patterns:
              - "lib/**/*.rb"
            base_path: "lib"
          rails:
            patterns:
              - "app/**/*.rb"
        exclude: []
      YAML

      allow(File).to receive(:exist?).with(".misogi.yml").and_return(true)
      allow(YAML).to receive(:load_file).with(".misogi.yml").and_return(YAML.safe_load(config_content))

      config = described_class.new(config_path: ".misogi.yml")

      rules = config.rules_for("lib/foo.rb")
      expect(rules).to have_key(:ruby_standard)
      expect(rules).not_to have_key(:rails)

      rules = config.rules_for("app/models/user.rb")
      expect(rules).to have_key(:rails)
      expect(rules).not_to have_key(:ruby_standard)
    end

    it "複数のルールに一致する場合は両方を返す" do
      config_content = <<~YAML
        rules:
          rule1:
            patterns:
              - "lib/**/*.rb"
          rule2:
            patterns:
              - "**/*.rb"
        exclude: []
      YAML

      allow(File).to receive(:exist?).with(".misogi.yml").and_return(true)
      allow(YAML).to receive(:load_file).with(".misogi.yml").and_return(YAML.safe_load(config_content))

      config = described_class.new(config_path: ".misogi.yml")

      rules = config.rules_for("lib/foo.rb")
      expect(rules).to have_key(:rule1)
      expect(rules).to have_key(:rule2)
    end

    it "一致するルールがない場合は空のハッシュを返す" do
      config = described_class.default

      rules = config.rules_for("app/models/user.rb")
      expect(rules).to be_empty
    end
  end

  describe "#excluded?" do
    it "除外パターンに一致する場合はtrueを返す" do
      config_content = <<~YAML
        rules:
          ruby_standard:
            patterns:
              - "lib/**/*.rb"
        exclude:
          - "tmp/**/*"
          - "vendor/**/*"
      YAML

      allow(File).to receive(:exist?).with(".misogi.yml").and_return(true)
      allow(YAML).to receive(:load_file).with(".misogi.yml").and_return(YAML.safe_load(config_content))

      config = described_class.new(config_path: ".misogi.yml")

      expect(config.excluded?("tmp/foo.rb")).to be true
      expect(config.excluded?("vendor/bundle/bar.rb")).to be true
      expect(config.excluded?("lib/foo.rb")).to be false
    end

    it "除外パターンがない場合は常にfalseを返す" do
      config = described_class.default

      expect(config.excluded?("lib/foo.rb")).to be false
      expect(config.excluded?("tmp/foo.rb")).to be false
    end
  end
end

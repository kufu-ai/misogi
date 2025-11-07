# frozen_string_literal: true

RSpec.describe Misogi::CLI do
  describe "#run" do
    context "ヘルプオプションの場合" do
      it "--helpでヘルプを表示して終了する" do
        cli = described_class.new(["--help"])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "-hでヘルプを表示して終了する" do
        cli = described_class.new(["-h"])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context "バージョンオプションの場合" do
      it "--versionでバージョンを表示して終了する" do
        cli = described_class.new(["--version"])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "-vでバージョンを表示して終了する" do
        cli = described_class.new(["-v"])
        expect { cli.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context "ファイルを指定した場合" do
      it "指定されたファイルを検証する" do
        file_path = "lib/foo.rb"
        content = "class Foo; end"

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new([file_path])
        expect(cli.run).to eq(0)
      end

      it "違反がある場合は終了コード1を返す" do
        file_path = "lib/foo.rb"
        content = "class Bar; end"

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new([file_path])
        expect(cli.run).to eq(1)
      end
    end

    context "パターンを指定した場合" do
      it "パターンに一致するファイルを検証する" do
        allow(Dir).to receive(:glob).with("lib/**/*.rb").and_return(["lib/foo.rb"])
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:read).and_return("class Foo; end")

        cli = described_class.new(["--pattern", "lib/**/*.rb"])
        expect(cli.run).to eq(0)
      end
    end

    context "ルールを指定した場合" do
      it "指定されたルールを使用する" do
        file_path = "app/models/user.rb"
        content = "class User; end"

        allow(Dir).to receive(:glob).and_return([file_path])
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:exist?).with("config/boot.rb").and_return(false)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new(["--rules", "rails"])
        expect(cli.run).to eq(0)
      end

      it "複数のルールを指定できる" do
        allow(Dir).to receive(:glob).and_return([])

        cli = described_class.new(["--rules", "ruby_standard,rails,rspec"])
        cli.run
        expect(cli.options[:rules]).to eq(%i[ruby_standard rails rspec])
      end
    end

    context "ベースパスを指定した場合" do
      it "指定されたベースパスを使用する" do
        allow(Dir).to receive(:glob).and_return([])

        cli = described_class.new(["--base-path", "src"])
        cli.run
        expect(cli.options[:base_path]).to eq("src")
      end
    end

    context "検証対象のファイルがない場合" do
      it "警告を表示して終了コード1を返す" do
        allow(Dir).to receive(:glob).and_return([])

        cli = described_class.new([])
        expect { cli.run }.to output(/検証対象のファイルが見つかりませんでした/).to_stderr
        expect(cli.run).to eq(1)
      end
    end

    context "出力フォーマットを指定した場合" do
      it "--formatオプションでJSON形式を指定できる" do
        allow(Dir).to receive(:glob).and_return([])

        cli = described_class.new(["--format", "json"])
        cli.run
        expect(cli.options[:format]).to eq("json")
      end

      it "-fオプションでJSON形式を指定できる" do
        allow(Dir).to receive(:glob).and_return([])

        cli = described_class.new(["-f", "json"])
        cli.run
        expect(cli.options[:format]).to eq("json")
      end

      it "違反がない場合にJSON形式で空配列を出力する" do
        file_path = "lib/foo.rb"
        content = "class Foo; end"

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new([file_path, "--format", "json"])
        expect { cli.run }.to output("[]\n").to_stdout
      end

      it "違反がある場合にJSON形式で違反情報を出力する" do
        file_path = "lib/foo.rb"
        content = "class Bar; end"

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new([file_path, "--format", "json"])
        expect { cli.run }.to output(/\[\s*\{.*"file_path".*"message".*"rule_name".*"suggest_path".*\}\s*\]/m).to_stdout
      end

      it "text形式の場合は通常の出力を行う" do
        file_path = "lib/foo.rb"
        content = "class Foo; end"

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".misogi.yml").and_return(false)
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(content)

        cli = described_class.new([file_path, "--format", "text"])
        expect { cli.run }.to output(/違反は見つかりませんでした/).to_stdout
      end
    end
  end
end

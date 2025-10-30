# Misogi

Misogiは、ファイルの内容を解析して、そのファイル名やディレクトリ配置が適切かをチェックするlintツールです。コードの内容とファイルパスの整合性を保ち、プロジェクトの構造を整理された状態に保つことを目的としています。

## インストール

次のコマンドを実行して、gemをインストールし、アプリケーションのGemfileに追加します：

```bash
bundle add misogi
```

Bundlerを使用していない場合は、次のコマンドでgemをインストールします：

```bash
gem install misogi
```

## 使い方

TODO: 使用方法をここに記述してください

## 開発

リポジトリをチェックアウト後、`bin/setup`を実行して依存関係をインストールします。その後、`rake spec`でテストを実行できます。また、`bin/console`で対話的なプロンプトを起動して実験することもできます。

このgemをローカルマシンにインストールするには、`bundle exec rake install`を実行します。新しいバージョンをリリースするには、`version.rb`でバージョン番号を更新してから、`bundle exec rake release`を実行します。これにより、バージョンのgitタグが作成され、gitコミットと作成されたタグがプッシュされ、`.gem`ファイルが[rubygems.org](https://rubygems.org)にプッシュされます。

## コントリビューション

バグレポートやプルリクエストは、GitHubの https://github.com/iyuuya/misogi で受け付けています。このプロジェクトは、安全で歓迎される協力の場であることを目指しており、コントリビューターは[行動規範](https://github.com/iyuuya/misogi/blob/main/CODE_OF_CONDUCT.md)を遵守することが期待されます。

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件の下でオープンソースとして利用可能です。

## 行動規範

Misogiプロジェクトのコードベース、イシュートラッカー、チャットルーム、メーリングリストでやり取りするすべての人は、[行動規範](https://github.com/iyuuya/misogi/blob/main/CODE_OF_CONDUCT.md)に従うことが期待されます。

# inventor-on-linux

Autodesk Inventor Professional 2027 日本語版をLinuxで動かすための実験的なWine Runnerと導入ツールです。NixでWine Staging 11.8を固定し、必要なDLLの修正をビルドします。Bottlesの専用環境で利用します。

日本語UI、Autodesk IDサインイン、スケッチ・押し出し、応力解析環境、新規スタディのメッシュ生成を確認しました。**構造解析の計算結果は未検証です。** 対応状況は[検証記録](VALIDATION.md)を参照してください。Autodesk公式の対応製品ではありません。

## Nixパッケージとして使う

`nix run . -- --help`、`nix build .#inventor-on-linux`に対応しています。別のflakeの`inputs`、NixOSの`environment.systemPackages`、Home Managerの`home.packages`からも参照できます。公開URLの指定例、Output一覧、パッケージ版の設定・保存先は[Nix利用手順](nix/README.md)を参照してください。

ソースからRunner単体を作る場合は、以下の`nix build .#runner`を使用します。

## 必要なもの

- x86_64 Linux、Nix（flakes / nix-commandを有効化）、Bottles。検証環境はNixOS / KDE / XWaylandです。
- Vulkan対応GPUとドライバ。BottlesのDXVK / VKD3Dを利用した環境で検証しています。ネイティブWaylandは未検証です。
- 正式に入手したInventor 2027のインストールメディア、Autodesk IDと有効な利用資格。
- ネイティブのブラウザ、`xdg-open` / `xdg-mime` / `update-desktop-database`、インターネット接続と十分な空き容量。初回のWineビルドには時間とディスク容量が必要です。

このリポジトリにはInventor本体、ライセンス、インストールメディアを含めません。

## ビルドと設定

```bash
nix build .#runner -L --cores 8 --max-jobs 1
cp config.example.sh config.local.sh
```

`config.local.sh`で`INVENTOR_PREFIX`を専用Bottleの絶対パスに設定してください。既定値は`~/.local/share/bottles/bottles/Inventor2027`です。Flatpak版Bottlesではパスやサンドボックスからのアクセスが異なるため、実際のパスを指定してください。`INVENTOR_PREFIX`環境変数でも指定できます。

Bottlesで専用の64bit Bottleを作成・初期化し、Windows 10、DXVK / VKD3Dを設定します。他のアプリが入ったBottleを流用しないでください。

```bash
./scripts/register-bottles-runner.sh
```

Bottlesを開き直し、専用BottleのRunnerに`inventor-unsafe-11.8`を選択します。登録先が既にある場合、スクリプトは上書きせず終了します。更新時はアプリを閉じて既存Runnerを別名で退避してから再登録してください。コピーしたRunnerもNixストアを参照するため、そのPC専用です。ビルドの`result`リンクを保持してください。

## メディアの準備と導入

Autodeskのインストーラーで展開されたディレクトリ（`setup.xml`と`manifest/app.*.xml`を含むインストールイメージ）を用意します。小さなwebinstall.exe自体は完全なメディアではありません。展開済みディレクトリの例は、Bottle内の`drive_c/Autodesk/WI/.../INVPROSA_2027_ja-JP`です。入手方法はAutodeskの提供する手段に従ってください。

```bash
./scripts/prepare-media.sh /absolute/path/to/extracted-media
./scripts/install-cached-media.sh --dry-run
./scripts/install-cached-media.sh
```

メディアは`build/install-media`へコピーします。マニフェストが参照するペイロードは公式配布先から取得し、サイズとSHA-256を照合します。ダウンロードは`build/payloads`へ保存します。再開時の準備コマンドは引数なしで実行できます。導入済み工程はPrefix内の`.odis-install-state.json`で管理します。

この導入ツールは準備済みの専用Prefixへのインストールを許可します。Content Centerを省略し、日本語の本体を導入する設定です。2027.2更新の適用は検証していません。新規環境での全工程を自動保証するものではありません。

終了後、Inventorを起動する前に次を実行します。

```bash
./scripts/repair-vc-runtime.sh
./scripts/disable-sharedviews.sh
./scripts/setup-japanese-fonts.sh
./scripts/setup-browser-integration.sh
./scripts/launch-inventor.sh
```

VCランタイム修復は導入キャッシュのMicrosoft VC++ 14.50.35719を使います。該当CABがない場合は終了します。SharedViews / InteractiveTutorialはWine Monoでクラッシュするため退避します。日本語にはNixから取得したIPAexフォントを設定します。既に起動している場合は保存後に再起動してください。

## サインインと起動

`launch-inventor.sh`はIdentity Managerと実際のAutodesk Licensing Serviceを起動し、RealDWG初期化に必要な設定XMLがなければ作成します。Wine内ユーザー名がLinuxのユーザー名と違う場合は`INVENTOR_WINE_USER`を設定してください。

ブラウザ連携はLinux側の`adskidmgr:` / `adsk.idmgr:`ハンドラーと専用PrefixのWineBrowser設定を登録します。Autodesk IDサインインを押し、ブラウザで認証後に「開く」を許可してください。プロジェクトを移動した場合は連携登録をやり直してください。コールバックURIや認証コードは専用ログに記録しません。

ブラウザはFirefox、なければ`xdg-open`を使います。`config.local.sh`の`INVENTOR_BROWSER`で実行ファイルを指定できます（引数は含めません）。認証やライセンス検証を回避する機能はありません。

## 変更内容と制約

- WinVerifyTrust: BLOB検証を成功扱いにする回避処理。起動スクリプトは`INVENTOR_WINTRUST_PRESERVE_FILE_ERRORS=1`を設定し、通常ファイルの検証エラーを維持します。**この変数を外すと通常ファイルの失敗も成功扱いになります。署名検証を弱める実験版のため、専用Prefixに限定してください。** DLLはPrefixにコピーされ、終了後も残ります。
- comctl32 / ntdll / rpcrt4 / combase: ステータスバー描画、アクティベーションコンテキスト、COMスタブの互換性修正。
- oleaut32: Inventorタイプライブラリの型情報の読み取りを修正。応力解析環境の起動時クラッシュを回避します。
- msxml3 / msxml6: `NamedNodeMap.setNamedItem`の戻り値を修正。メッシュ設定の数値が消える問題に対応します。修正前のスタディは新規作成し、拘束・荷重も設定し直してください。
- X11補助プロセス: メインウィンドウに残る古い矩形マスクをイベントに応じて解除し、拡大・最大化時の表示欠けを補正します。起動を無効にするには`INVENTOR_WINDOW_SHAPE_FIX=0`、既存プロセスの停止には`pkill -x inventor-shape`を使います。

ライセンスサービス導入で`1053`と`LIC-INST-ERROR-69009748`が同時に記録された場合に限り、`repair-licensing-install.py`が診断付きの復旧処理を提供します。通常の導入で無条件に実行しないでください。共通設定を読み込んだ環境で次を実行できます。

```bash
bash -c 'source scripts/common.sh; tools=$(media_tools); export PATH="$project_dir/result/bin:$tools/bin:$PATH"; "$tools/bin/python3" scripts/repair-licensing-install.py'
```

## 通常のWineへ戻す

保存してInventorを閉じ、対象Prefixを明示して実行します。このコマンドは対象PrefixのWineプロセスを終了し、バックアップしたwintrust.dllを戻します。

```bash
./scripts/restore-prefix.sh /absolute/path/to/dedicated-prefix
```

Bottles側のRunnerも通常版に戻してください。フォント設定、VCランタイム、アドインの退避は別の変更として残ります。完全に戻す必要がある場合は、作業前に保存したBottleのバックアップを復元してください。

## 開発とライセンス

[CONTRIBUTING.md](CONTRIBUTING.md)に検証手順を記載しています。ログ・モデル・メディア・個別設定はGit管理から除外します。報告時も認証URL、トークン、シリアル番号を含めないでください。

独自コードは[MIT](LICENSE)。**Wineを変更するパッチはLGPL-2.1-or-later**です。取り込んだ導入ツールのMIT表記も保持しています。詳細は[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)と[パッチの出典](patches/UPSTREAM.md)を参照してください。

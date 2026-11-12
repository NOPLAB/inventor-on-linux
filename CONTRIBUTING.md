# 開発・検証

独自コードへの変更はMITで提供してください。Wineパッチの変更はLGPL-2.1-or-laterで扱い、出典・著作権表示を保持してください。Autodeskのファイルやアカウント情報は追加しないでください。

```bash
nix flake check -L --cores 8 --max-jobs 1
nix build .#inventor-on-linux --out-link result-package
./result-package/bin/inventor-on-linux --help
```

`flake check`はシェル/Python構文と、パッケージのヘルプ・設定・メディア準備のCLIを確認します。InventorのGUI、認証、解析処理を自動テストするものではありません。通常のCIでは構文を確認し、重いWineビルドを含むNix検証は手動起動にしています。

Wine APIの回帰確認には、ビルド済みの`result`（`nix build .#runner`）と開発用Xセッションを使います。

```bash
./scripts/test-api.sh
./scripts/test-actctx.sh
./scripts/test-msxml-attribute.sh
```

これらは`test-prefix/`を使用します。`test-inventor-typelib.sh`にはInventor導入済みの診断用Prefixを`INVENTOR_PREFIX`で明示してください。普段の作業用Prefixでテストを実行しないでください。`tests/inventor-commands.c`や`wine-dialog.c`はドキュメントやダイアログを操作する開発ツールです。

パッチ追加時は`flake.nix`の対象DLL・アーキテクチャを確認し、最小の再現ケースと検証結果を追加してください。メッシュ生成成功と解析結果の正確性は別々に報告してください。

公開前には`git diff --cached --stat`で対象を確認してください。`build/`、`logs/`、`test-prefix/`、`config.local.sh`、ダンプ、CADモデル、インストーラーは配布対象ではありません。

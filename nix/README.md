# Nixからの利用

対応するsystemは`x86_64-linux`です。公開URLが決まるまでは、ローカルのflakeを次のように参照できます。

```bash
nix run /absolute/path/to/inventor-on-linux -- --help
nix build /absolute/path/to/inventor-on-linux#inventor-on-linux
nix profile add /absolute/path/to/inventor-on-linux#inventor-on-linux
```

公開後はパスを`github:OWNER/inventor-on-linux`へ置き換えてください。`OWNER`は公開先のアカウント名です。

```nix
{
  inputs.inventor-on-linux.url = "github:OWNER/inventor-on-linux";

  outputs = { self, nixpkgs, inventor-on-linux, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          inventor-on-linux.packages.x86_64-linux.inventor-on-linux
        ];
      }];
    };
  };
}
```

既存のflakeでは`inputs`と`environment.systemPackages`へ該当部分を追加してください。Home Managerでも`home.packages`から同じパッケージを参照できます。`overlays.default`も提供しています。Overlayを使った場合も、Runnerは検証済みのNixpkgsに固定されます。Wine DLLのABIを揃えるため、無条件に`inputs.nixpkgs.follows`を設定しないでください。

| Output | 内容 |
| --- | --- |
| `packages.x86_64-linux.default` / `inventor-on-linux` | CLI・デスクトップエントリー・Runnerと導入ツールの参照 |
| `packages.x86_64-linux.runner` | Wine Runner単体 |
| `packages.x86_64-linux.wintrust` | wintrust等の修正DLL（単体での起動用ではない） |
| `packages.x86_64-linux.window-shape` | X11サイズ変更補助ツール |
| `packages.x86_64-linux.media-tools` | Pythonと7-Zip |
| `packages.x86_64-linux.fonts` | IPAexフォント |
| `apps.x86_64-linux.default` / `inventor-on-linux` | `nix run`のエントリーポイント |

パッケージにはInventor本体・認証情報を含みません。インストール時にネットワークからInventorを自動取得するNix derivationでもありません。ユーザーが取得したメディアの準備と導入は、コマンド実行時に行います。

設定は`~/.config/inventor-on-linux/config.sh`（`XDG_CONFIG_HOME`対応）に置きます。

```bash
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-$HOME/.local/share/bottles/bottles/Inventor2027}"
# export INVENTOR_BROWSER=firefox
```

パッケージ版のメディア、ログ、バックアップの保存先は`$XDG_STATE_HOME/inventor-on-linux`（既定`~/.local/state/inventor-on-linux`）です。`INVENTOR_STATE_DIR`で変更できます。`inventor-on-linux paths`で実際の値を確認してください。ソースツリーのスクリプトは従来どおりリポジトリ内の`build/`・`logs/`を使います。

```bash
inventor-on-linux register-runner
inventor-on-linux prepare-media /absolute/path/to/extracted-media
inventor-on-linux install --dry-run
inventor-on-linux install
inventor-on-linux repair-vc-runtime
inventor-on-linux disable-addins
inventor-on-linux setup-fonts
inventor-on-linux setup-browser
inventor-on-linux launch
```

先にBottlesで専用Prefixを初期化し、Runner・DXVK等を設定してください。詳しい条件と制約はルートのREADMEを参照してください。パッケージ更新後はブラウザ連携の`setup-browser`を再実行し、古いストアパスを更新してください。

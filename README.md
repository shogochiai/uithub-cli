# uithub-cli

GitHub repos を LLM-friendly な Markdown として取得・キャッシュする CLI ツール。

[uithub.com](https://uithub.com) の API を利用して、リポジトリ全体を単一の Markdown ファイルとしてローカルにキャッシュします。

## Requirements

- [Idris2](https://github.com/idris-lang/Idris2) 0.8.0+
- [pack](https://github.com/stefan-hoeck/idris2-pack) (Idris2 package manager)
- uithub.com API key ([https://uithub.com](https://uithub.com) で取得)

## Build & Install

```bash
# Clone
git clone https://github.com/shogochiai/uithub-cli.git
cd uithub-cli

# Build
pack build uithub-cli.ipkg

# Install to ~/.local/bin (PATH に含まれている前提)
cp build/exec/uithub-cli ~/.local/bin/
cp -r build/exec/uithub-cli_app ~/.local/bin/

# Verify
uithub-cli
```

## Setup

### API Key の設定

```bash
# uithub.com で API key を取得後
uithub-cli config set-key uitk_xxxxxxxxxxxxxxxx

# 確認
uithub-cli config show
```

## Usage

### 基本コマンド

```bash
# リポジトリを取得してキャッシュ
uithub-cli fetch owner/repo

# キャッシュから取得 (なければ自動 fetch)
uithub-cli get owner/repo

# 強制再取得
uithub-cli update owner/repo

# キャッシュ一覧
uithub-cli list
```

### uithub.toml によるリポジトリ管理

プロジェクトごと、またはマシン全体で関心のあるリポジトリを `uithub.toml` で管理できます。

#### プロジェクトローカル (./uithub.toml)

```bash
# fetch と同時にローカル uithub.toml に追記
uithub-cli fetch -s owner/repo
uithub-cli fetch --save owner/repo

# ローカル uithub.toml の一覧表示
uithub-cli repos

# ローカル uithub.toml の全リポを一括取得
uithub-cli install
```

#### マシングローバル (~/.uithub-cli/uithub.toml)

```bash
# fetch と同時にグローバル uithub.toml に追記
uithub-cli fetch -g owner/repo
uithub-cli fetch --global owner/repo

# グローバル uithub.toml の一覧表示
uithub-cli repos -g

# グローバル uithub.toml の全リポを一括取得
uithub-cli install -g
```

### uithub.toml フォーマット

```toml
# uithub.toml - repos of interest

anthropics/claude-code
shogochiai/idris2-coverage
idris-lang/Idris2
```

## Example: プロジェクトセットアップ

新しいプロジェクトで依存ライブラリのソースを参照したい場合:

```bash
cd my-project

# 関連リポを fetch して uithub.toml に記録
uithub-cli fetch -s idris-lang/Idris2
uithub-cli fetch -s stefan-hoeck/idris2-pack
uithub-cli fetch -s stefan-hoeck/idris2-elab-util

# uithub.toml を確認
uithub-cli repos
# local uithub.toml:
#   idris-lang/Idris2
#   stefan-hoeck/idris2-pack
#   stefan-hoeck/idris2-elab-util

# 別環境で一括取得
uithub-cli install
```

## Example: グローバルライブラリ

よく参照するリポジトリをグローバルに登録:

```bash
# グローバルに登録
uithub-cli fetch -g anthropics/anthropic-cookbook
uithub-cli fetch -g anthropics/courses

# どこからでも参照可能
uithub-cli get anthropics/anthropic-cookbook | head -100
```

## Cache Location

- Config: `~/.uithub-cli/config`
- Cache: `~/.uithub-cli/cache/<owner>/<repo>/content.md`
- Global repo list: `~/.uithub-cli/uithub.toml`

## Notes

- 大きなリポジトリは uithub.com 側でタイムアウトすることがあります
- プライベートリポジトリは 404 を返します
- キャッシュは手動削除まで永続化されます

## License

MIT

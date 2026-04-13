# alt-ime-rev

> **Windows で Mac ライクに日本語 IME を切り替える — 特に US キーボードユーザー向け**

左右の Alt キーの空打ちで日本語 IME を ON / OFF する AutoHotkey v2 スクリプトです。
US 配列キーボードの Windows で「英数 / かな」をワンキーで直感的に切り替えられるようにし、
Mac から Windows に移ってきた人でも馴染みやすい入力体験を提供します。

> **原作との違い** — 原作 [karakaram/alt-ime-ahk](https://github.com/karakaram/alt-ime-ahk)
> (AutoHotkey v1 系) の流れを汲む **AutoHotkey v2 世代のフォーク** です。ARM64 ポインタ幅対応、
> DllCall 全戻り値チェック + 自動リトライ、ファイルログ + 10MB 自動ローテーション、
> New Outlook (`olk.exe`) 専用ハンドリング、Razer Synapse 共存、タグ push → 自動 .exe ビルド
> → GitHub Release までの CI パイプラインなどを独自に追加しています
> (詳細は [CHANGELOG.md](./CHANGELOG.md))。

## 🎯 こんな人向け

- **Windows を US 配列キーボードで使っている人** — US 配列には JIS の「英数」「かな」キーが無く、
  既定の IME 切替は `半角/全角` キー（物理位置が遠い）や `Ctrl + Space` など。左右 Alt を
  空打ちでワンキー切替にできると小指と思考の負担が激減します。
- **Mac から Windows に移ってきた人** — Mac の JIS キーボードでは「英数 / かな」キー、
  US 配列 Mac では定番の [Karabiner-Elements](https://karabiner-elements.pqrs.org/) 設定
  **「左 ⌘ = 英数 / 右 ⌘ = かな」** を使っていた人向け。Windows でも左右 Alt を同じ感覚で使えます。
- **既存の Windows IME 切替に不満がある人全般** — `半角/全角` キーや `Ctrl + Space` などの
  既定切替が指に馴染まない／物理位置が遠すぎる、と感じている人。

## 🔁 Mac の Karabiner 設定との対応

US 配列 Mac ユーザーの定番設定 **「左 ⌘ → 英数 / 右 ⌘ → かな」**
（[Karabiner-Elements](https://karabiner-elements.pqrs.org/) で `left_command` / `right_command`
を単独押下時に `japanese_eisuu` / `japanese_kana` にマップする設定）を、Windows の左右 Alt で
置き換えたのがこのツールの基本発想です。Space バー両脇の親指・手首が届く位置で英数/かなを
トグルできるので、Mac での入力感覚をそのまま Windows に持ち込めます。

| 目的 | Mac (JIS) | Mac (US + Karabiner) | **Windows (このツール)** |
|---|---|---|---|
| IME OFF（英数） | `英数` キー | 左 `⌘` 単独押下 | **左 `Alt` 空打ち** |
| IME ON（かな） | `かな` キー | 右 `⌘` 単独押下 | **右 `Alt` 空打ち** |

> ⚠️ Alt を押しながら他のキー（例: `Alt+F4`, `Alt+Tab`）を叩いた場合は通常の Alt として動作します。
> 既存のショートカットは壊れません。発動するのは「Alt を単独で押して離した時」だけです。

詳しい変更履歴は [CHANGELOG.md](./CHANGELOG.md) を参照してください。

---

## インストール

### A. .exe を使う（通常のインストール）

1. [Releases ページ](https://github.com/yuki0ueda/alt-ime-rev/releases/latest) から
   **`alt-ime-rev-x64.exe`** をダウンロード
2. 任意のフォルダに配置（例: `%USERPROFILE%\Tools\alt-ime-rev\`）
3. ダブルクリックで起動 — タスクトレイに常駐します
4. 動作確認: メモ帳などを開いて、左 `Alt` を空打ち → 英数入力、右 `Alt` を空打ち → 日本語入力に切り替わることを確認
5. 終了するにはタスクトレイアイコン右クリック → `Exit`

> 💡 **Windows 11 on ARM マシン（Copilot+ PC / Surface Pro X 等）について** —
> 配布している `.exe` は x64 ビルドですが、Microsoft Prism エミュレーション経由で
> そのまま動作します。alt-ime-rev はホットキー処理だけを行う軽量ユーティリティで
> API 呼び出しのオーバーヘッドも小さいため、Prism のエミュレーションコストは実用上
> ほぼ気にならないレベルです。(AutoHotkey v2 本家配布に ARM64 ネイティブの base
> ファイルが存在しないため、現状はネイティブ ARM64 .exe は提供していません)

### Windows 起動時に自動常駐させる（任意）

1. `Win + R` → `shell:startup` を入力して Enter → スタートアップフォルダが開く
2. 配置した `alt-ime-rev-x64.exe` を右クリック → `ショートカットの作成`
3. 作成したショートカットをスタートアップフォルダへ移動
4. 次回 Windows 起動時から自動で常駐開始

### B. .ahk をそのまま動かす（開発者向け）

1. [AutoHotkey v2](https://www.autohotkey.com/) をインストール
2. このリポジトリを clone、または Releases のソース zip を展開
3. `src/alt-ime-rev.ahk` をダブルクリック（`src/IME.ahk` が同じフォルダにある必要あり）

---

## 🔄 バージョンアップ（新しいリリースへの更新）

alt-ime-rev は設定ファイルを持たない単体 .exe なので、**ダウンロード → 置き換え → 起動** の 3 ステップで更新できます。

1. **現行版を終了**
   - タスクトレイの alt-ime-rev アイコンを右クリック → `Exit`
   - または タスクマネージャー (`Ctrl+Shift+Esc`) で `alt-ime-rev-x64.exe` プロセスを終了
2. **新しい .exe をダウンロード**
   - [Releases ページ](https://github.com/yuki0ueda/alt-ime-rev/releases/latest) から
     最新の `alt-ime-rev-x64.exe` を入手
3. **古い .exe を上書き**
   - 既存の `alt-ime-rev-x64.exe` を新しいファイルで上書き
   - スタートアップにショートカットを置いている場合、ファイル名が同じなら再設定不要
4. **新しい .exe を起動**
   - ダブルクリック、または次回 Windows 起動時にスタートアップから自動起動

### 📌 バージョンアップ時の補足

- **設定は引き継がれます** — alt-ime-rev は設定ファイルを読まないため、バージョンアップで失うものはありません
- **ログは継続** — `ime_debug.log` / `ime_debug_old.log` は .exe と同じフォルダにあり、バージョンアップしても残ります
- **複数起動防止** — 内部で `#SingleInstance Force` を指定しているため、新しい .exe を起動すると古いインスタンスは自動で終了します（ただしファイル上書きはプロセス終了後のみ可能）

### 最新版の確認

- [Releases ページ](https://github.com/yuki0ueda/alt-ime-rev/releases/latest) の最新タグを手元の .exe と比較
- .exe を右クリック → `プロパティ` → `詳細` タブの `ファイルバージョン` を参照（ビルド時に埋め込まれる場合）
- GitHub リポジトリを [Watch](https://github.com/yuki0ueda/alt-ime-rev/subscription) しておくと新リリース通知を受け取れます

---

## ホットキー一覧

| キー | 動作 |
|---|---|
| 左 Alt（空打ち） | IME OFF |
| 右 Alt（空打ち） | IME ON |
| Win + CapsLock | 無効化 |
| Ctrl+Shift+F12 | デバッグモード切替 |

New Outlook（`olk.exe`）では Alt キーの挙動が特殊なため専用の処理を組み込み済みです。

---

## 動作環境

- **OS**: Windows 10 / Windows 11(x64 ネイティブ)
- **Windows 11 on ARM**(Copilot+ PC / Surface Pro X 等): Microsoft Prism エミュレーション経由で動作
- **AutoHotkey v2**(開発者向け、`.ahk` を直接実行する場合): **v2.0.23 以降を推奨**
  - v2.0.22 / v2.0.23 には、本スクリプトが依存する左右修飾キー (LAlt/RAlt) の
    key-up イベント相関処理・prefix/suffix 併用時の発火に関する修正が含まれています。
    v2.0.21 以前では LAlt/RAlt 空打ち判定が不安定になる可能性があります
  - 配布 .exe は GitHub Actions 上で AHK v2.0.23 を用いてビルドされるため、
    .exe をそのまま使う場合はユーザー側で AHK を別途インストールする必要はありません

---

## デバッグ / ログ

デバッグモード ON の間、IME の状態変化が `ime_debug.log`（実行ファイルと同じフォルダ）に
`Before → After [SUCCESS/ERROR]` 形式で記録されます。10MB を超えると
`ime_debug_old.log` にローテーションされます。

詳細は [docs/DEBUG_SETUP.md](./docs/DEBUG_SETUP.md) を参照してください。

---

## プロジェクトの系譜 / クレジット

- **原作**: [karakaram 氏の alt-ime-ahk](https://github.com/karakaram/alt-ime-ahk)
  — AutoHotkey v1 版の日本語 IME 制御スクリプト
- **中間フォーク（出発点）**: nekocodeX 氏の `alt-ime-ahk-mod`（現在は非公開化）
- **本フォーク**: [yuki0ueda](https://github.com/yuki0ueda/alt-ime-rev) が長期間プライベートで
  カスタマイズしてきたものを一般公開のため整備。ARM64 ポインタ幅対応(`DllCall` 型指定整理)、
  エラーハンドリング強化、リトライ、デバッグモード、ファイルログ、自動ローテーション等の拡張を含みます。

### IME 制御ライブラリ（`src/IME.ahk`）の出自

[eamat 氏](https://github.com/eamat-dot) が 2008 年に公開した AutoHotkey v1 版（原典）を、
[Ken'ichiro Ayaki (k-ayaki) 氏](https://github.com/k-ayaki/IMEv2.ahk) が AutoHotkey v2 にポート
（2023-07-17、NYSL として宣言）し、それを起点に本フォークで独自改修しています。
完全な系譜は [LICENSE](./LICENSE) 末尾の NOTICE セクションを参照してください。

---

## ライセンス

**MIT License** — 詳細は [LICENSE](./LICENSE) を参照してください。

本プロジェクトは派生物です。上流の `src/IME.ahk` は k-ayaki 氏による v2 ポート公開時
（2023-07-17）に NYSL <http://www.kmonos.net/nysl/> として宣言されており、NYSL A-3 / A-4 が
改変・再ライセンスを明示的に許可しているため、本フォークは MIT License で再配布しています。
上流貢献者のクレジットは [LICENSE](./LICENSE) 末尾の NOTICE セクションを参照してください。

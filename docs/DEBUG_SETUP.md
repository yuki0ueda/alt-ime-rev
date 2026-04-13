# デバッグ / ログ確認ガイド

alt-ime-rev はデバッグモード ON 中の IME 操作を詳細ログとして記録します。
ログは以下の 2 経路で並行出力されます:

1. **ファイル** (`ime_debug.log`) — .exe と同じフォルダに自動保存(既定で有効)
2. **OutputDebug** — 開発・診断時に [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) でリアルタイム確認

通常運用ではファイルログだけで十分です。開発中・問題調査時に DebugView を併用すると便利です。

---

## 🔧 方法1: ファイルログを見る(通常の運用向け)

デバッグモードを ON にすると、IME 操作のログが `ime_debug.log` に自動保存されます。

### 有効化の手順

1. alt-ime-rev を起動(タスクトレイに常駐)
2. **`Ctrl+Shift+F12`** を押してデバッグモードを ON
3. `Alt` キーで IME を切り替えて動作させる
4. .exe と同じフォルダにある `ime_debug.log` をメモ帳や VSCode で開いて確認

デバッグモード ON 時にはツールチップで `Log file: <パス>` が 3 秒間表示されるので、
実際の保存場所がその場で確認できます。

### ファイルの場所

```
(alt-ime-rev-x64.exe と同じフォルダ)/
├── alt-ime-rev-x64.exe
├── ime_debug.log          ← 現在のログ(最大 10MB)
└── ime_debug_old.log      ← ローテーション後の前世代ログ
```

### ログローテーション

ログファイルは **10MB を超えると自動ローテーション** されます:

- 現在の `ime_debug.log` を `ime_debug_old.log` にリネーム
- 次のログからは新しい `ime_debug.log` に書き出し
- 長期運用でもディスク容量を圧迫しません

---

## 🔧 方法2: DebugView でリアルタイム確認(開発・診断向け)

開発中やエラー発生時の即時確認には [Sysinternals DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) を使うと、ファイルを開かずに流れるログをその場で見られます。

### セットアップ

1. [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) をダウンロード
2. `Dbgview.exe` を **管理者権限** で起動
3. メニュー設定:
   - `Capture` → `Capture Win32` ✓
   - `Capture` → `Capture Global Win32` ✓
4. alt-ime-rev を起動し、`Ctrl+Shift+F12` でデバッグモード ON
5. DebugView のウィンドウに `[INFO]` `[SUCCESS]` などのログが流れ始める

---

## 📋 ログ出力例

### 正常時(IME ON への切替成功)

```
[2026-04-13 12:34:56] [INFO] IME_SET called: ON (1) for: A
[2026-04-13 12:34:56] [INFO] GetGUIThreadInfo succeeded, hwndFocus: 1772284
[2026-04-13 12:34:56] [INFO] IME window handle: 331122
[2026-04-13 12:34:56] [INFO] SendMessage returned: 0
[2026-04-13 12:34:56] [SUCCESS] IME_SET: OFF -> ON [SUCCESS]
```

### すでに目的の状態だった場合

```
[2026-04-13 12:35:00] [INFO] IME_SET called: ON (1) for: A
[2026-04-13 12:35:00] [INFO] IME_SET: ON -> ON [ALREADY SET]
```

### 失敗時(リトライ後に成功)

```
[2026-04-13 12:35:10] [INFO] IME_SET called: ON (1) for: A
[2026-04-13 12:35:10] [WARN] IME_SET: OFF -> OFF [FAILED] Expected: ON
[2026-04-13 12:35:10] [WARN] Retry 1/2
[2026-04-13 12:35:10] [SUCCESS] IME_SET: OFF -> ON [SUCCESS]
```

ログレベルは `INFO` / `WARN` / `ERROR` / `SUCCESS` の 4 種類です。
`SUCCESS` は「期待した状態遷移が起きた」、`[ALREADY SET]` は「最初から目的の状態だった」を意味します。

---

## 🎯 よくある質問

**Q: ログファイルが作られない**
- `Ctrl+Shift+F12` でデバッグモードを ON にしていますか?(既定は OFF)
- タスクトレイに alt-ime-rev アイコンが表示されていますか?
- `src/IME.ahk` の先頭の `IME_LOG_TO_FILE` が `false` に変更されていませんか?(既定は `true`)

**Q: DebugView に何も表示されない**
- DebugView を **管理者権限** で起動していますか?
- `Capture Win32` と `Capture Global Win32` の両方にチェックが入っていますか?
- alt-ime-rev 側でデバッグモード ON になっていますか?

**Q: ログファイルはどこにある?**
- .exe と同じフォルダです(`alt-ime-rev-x64.exe` の隣)
- .ahk を直接実行している場合は `src/IME.ahk` と同じフォルダ
- デバッグモード ON 切替時にツールチップで正確なパスが表示されます

**Q: ログファイルが大きくなりすぎないか心配**
- 10MB を超えたら自動ローテーションされるので最大でも 20MB 程度に収まります
- 通常運用ではデバッグモードは OFF にしておき、問題調査時のみ ON にすることを推奨

**Q: パフォーマンスへの影響は?**
- デバッグモード OFF 時はほぼ影響なし(`if` 文のチェックのみ)
- デバッグモード ON 時はファイル書き込みのオーバーヘッドが発生しますが、通常は気にならないレベル

---

## ⚙️ カスタマイズ(開発者向け)

`src/IME.ahk` の先頭に以下の設定があります。永続的に挙動を変えたい場合はここを編集してください:

```ahk
global IME_DEBUG := false            ; デバッグモード(既定 OFF、Ctrl+Shift+F12 で切替)
global IME_LOG_TO_FILE := true       ; ファイル出力(既定 ON)
global IME_LOG_FILE := A_ScriptDir . "\ime_debug.log"
global IME_LOG_FILE_OLD := A_ScriptDir . "\ime_debug_old.log"
global IME_LOG_MAX_SIZE := 10485760  ; ログローテーション閾値(10MB)
global IME_RETRY_COUNT := 2          ; リトライ回数
global IME_RETRY_DELAY := 50         ; リトライ間隔(ミリ秒)
```

# CHANGELOG - alt-ime-rev

## [v1.0.0] - 2026-04-13 — 初回公開

alt-ime-rev の最初の公開リリース。yuki0ueda が自分用として長期間プライベートで
使い込んできた AutoHotkey v2 製の日本語 IME 制御スクリプトを、一般公開のため整備したもの。

### 🎯 機能

#### 基本操作
- **左右 Alt キー空打ちで IME ON/OFF**
  - 左 Alt 空打ち → IME OFF（英数）
  - 右 Alt 空打ち → IME ON（日本語）
  - Alt を押しながら他キーを叩いた場合は通常の Alt として動作
- **Win + CapsLock** を無効化

#### エラーハンドリング・堅牢性
- 全 `DllCall` の戻り値チェック、try-catch による例外処理
- 自動リトライロジック（既定 2 回、50ms 間隔）で一時的エラーを吸収
- ウィンドウハンドル検証 (`IsValidHwnd()`) による無効 hwnd の早期検出
- 競合状態（race condition）対策

#### デバッグ機能
- **Ctrl+Shift+F12** で実行中にデバッグモードを切り替え
- `IME_Log()` による詳細ログ（INFO / WARN / ERROR / SUCCESS の 4 レベル）
- 状態変化を "Before → After" 形式で記録
- ツールチップで現在のモード・ログファイルパスを 3 秒表示

#### ファイルログ
- `ime_debug.log` に自動保存（UTF-8、OutputDebug と並行出力）
- **自動ローテーション**: 10MB 超で `ime_debug_old.log` にリネーム
- `IME_LOG_TO_FILE` で ON/OFF 切替可能
- DebugView が起動していなくてもログが残るため長期運用に対応

#### プラットフォーム
- **配布バイナリは x64 単一** — AutoHotkey v2 本家配布に ARM64 ネイティブ base ファイルが存在しないため
- **Windows 11 on ARM 対応** — Microsoft Prism エミュレーション経由で x64 .exe がそのまま動作(ホットキー処理で API 呼び出しが軽量なため、Prism のオーバーヘッドは実用上問題なし)
- **コードは x86 / x64 / ARM64 いずれでもネイティブ動作可能**(`.ahk` を AHK v2 で直接実行する場合)
- `DllCall` 型指定を全面的に ARM64 ポインタ幅対応
- ポインタサイズ計算の修正（`!A_PtrSize` 条件削除、`ptrSize` 変数統一）

#### 特殊環境対応
- **New Outlook (olk.exe)** — Alt キーの挙動が特殊な New Outlook 向け専用ハンドリング
- **Razer Synapse 共存** — `A_MaxHotkeysPerInterval := 350` でキーカスタマイズツールとのバッティング回避

### 📄 ライセンス
MIT License（`src/IME.ahk` は k-ayaki 氏が v2 ポート公開時 2023-07-17 に NYSL 宣言。NYSL A-3 / A-4 に基づき本フォークは MIT へ relicense。詳細は [LICENSE](./LICENSE) NOTICE セクション参照）

### 🙏 謝辞
- **IME.ahk (v1, 2008)**: eamat — "089.zip" via `lukewarm.s101.xrea.com/up`, GitHub: [@eamat-dot](https://github.com/eamat-dot)
- **IME.ahk AutoHotkey v2 port (2023-07-17, NYSL 宣言)**: [Ken'ichiro Ayaki (k-ayaki)](https://github.com/k-ayaki/IMEv2.ahk)
- **Original alt-ime script**: [karakaram](https://github.com/karakaram/alt-ime-ahk)
- **Intermediate fork (starting point)**: nekocodeX — 旧 `nekocodeX/alt-ime-ahk-mod`（現在は非公開）
- **Current maintainer**: [yuki0ueda](https://github.com/yuki0ueda/alt-ime-rev)

---

## 内部開発履歴 (Archived internal history)

> 以下は v1.0.0 として公開する前、yuki0ueda がプライベートで開発していた
> 内部バージョンの記録です。これら内部バージョンは一度も公開リリースされておらず、
> 全機能は v1.0.0 に統合されています。参考・経緯の透明化のために保存しています。

## [v5.2] - 2025-10-23

### 🎯 主な改善目標
**ファイルログ機能の追加** - 長期テスト・運用時のログ保存

### ✨ 新機能

#### ファイルログ出力
- **自動ファイル保存**
  - `ime_debug.log` にログを自動保存（スクリプトと同じフォルダ）
  - OutputDebugとファイルへの並行出力
  - UTF-8エンコーディング

- **ログローテーション**
  - ファイルサイズが10MBを超えたら自動的にローテーション
  - 古いログは `ime_debug_old.log` にリネーム
  - ディスク容量を節約

- **設定オプション**
  ```ahk
  global IME_LOG_TO_FILE := true      ; ファイルログON/OFF
  global IME_LOG_FILE := "ime_debug.log"
  global IME_LOG_MAX_SIZE := 10485760  ; 10MB
  ```

#### デバッグモード強化
- `Ctrl+Shift+F12` でデバッグモードON時にログファイル情報を表示
- ツールチップに「Log file: パス」を表示（3秒間）
- デバッグモードON時にシステム情報をログに記録

### 🔧 改善点

#### 長期運用対応
- **DebugViewなしでもログが残る**
  - DebugViewを起動していなくてもファイルに記録
  - PCを再起動してもログが保存される
  - 問題発生時の後追い調査が可能

- **パフォーマンス最適化**
  - ログローテーションチェックは100回に1回のみ
  - ファイル書き込みエラーが発生しても動作継続
  - エラー時はOutputDebugにフォールバック

#### エラーハンドリング
- ファイル書き込み失敗時も動作継続
- ログローテーション失敗時も動作継続
- より堅牢なエラー処理

### 📊 ログファイルの場所

```
スクリプトのフォルダ/
├── alt-ime-ahk-mod-yuv5.2.ahk
├── IMEv5.2.ahk
├── ime_debug.log           ← 現在のログ（最大10MB）
└── ime_debug_old.log       ← 古いログ（前回分）
```

### 📝 使用方法

#### 基本的な使用（v5.1と同じ）
1. `alt-ime-ahk-mod-yuv5.2.ahk` を実行
2. `Ctrl+Shift+F12` でデバッグモードON
3. AltキーでIME操作
4. **自動的に `ime_debug.log` にログが保存される**

#### ログファイルの確認
```ahk
; スクリプトと同じフォルダにある ime_debug.log を開く
; メモ帳、VSCode、サクラエディタなどで閲覧可能
```

#### ファイルログを無効化（OutputDebugのみ）
```ahk
; IMEv5.2.ahk の冒頭で設定変更
global IME_LOG_TO_FILE := false  ; ファイルログOFF
```

### 🆚 v5.1との違い

| 項目 | v5.1 | v5.2 |
|------|-----|------|
| ログ出力先 | OutputDebugのみ | OutputDebug + ファイル |
| DebugView必要性 | 必須 | 不要（あれば便利） |
| ログ保存 | 手動設定が必要 | 自動保存 |
| 長期テスト適性 | △ | ◎ |
| ログローテーション | なし | 自動（10MB） |

### 🎯 v5.2の利点

✅ **長期テストに最適**
- 数日〜数週間のテストでもログが確実に残る
- 問題が起きた時に後から確認できる

✅ **運用が簡単**
- DebugViewを起動しなくても自動記録
- ファイルサイズも自動管理

✅ **デバッグが楽**
- ファイルで見れるので検索・分析が容易
- 他の人と共有しやすい

### 🔄 互換性

- **完全な後方互換性あり**
- v5.1のスクリプトは`IMEv5.1.ahk`を`IMEv5.2.ahk`に置き換えるだけで動作
- 関数シグネチャは全く変更なし
- ログフォーマットも同じ

---

## [v5.1] - 2025-10-23

### 🎯 主な改善目標
**ログの可読性向上** - IME操作の成功/失敗を明確に判定できるように

### ✨ 新機能

#### 状態変化の可視化
- **IME_SET: 設定前後の状態をログ出力**
  ```
  [INFO] IME_SET called: ON (1) for: A
  [SUCCESS] IME_SET: OFF → ON [SUCCESS] ✓
  ```
- **成功/失敗の明確な判定**
  - `[SUCCESS] ✓` - 期待通りに状態が変化
  - `[INFO] ✓` - すでに目的の状態だった
  - `[WARN]` - 状態変化が失敗
  - `[ERROR]` - 処理自体が失敗

#### IME_SetConvMode / IME_SetSentenceMode の改善
- 設定前後の値を比較してログ出力
- 例: `IME_SetConvMode: 25 → 1 [SUCCESS] ✓`

#### ログレベルの追加
- `SUCCESS` レベルを追加（緑のチェックマーク付き）
- 成功時のログが一目でわかる

### 🔧 改善点

#### デバッグの使いやすさ向上
- **ログから動作状況が一目瞭然**
  - 「どの状態からどの状態に変わったか」が明確
  - 「成功したのか、すでに設定済みだったのか」が区別可能
- **IME_GETのログを削減**
  - 頻繁に呼ばれるため、デバッグログを最小限に

#### パフォーマンスの微調整
- IME_SET後に10msの待機を追加（IME処理完了を待つ）
- 状態確認のタイミングを最適化

### 📊 ログ出力例（v5.1）

#### 成功時
```
[2025-10-23 13:57:24] [INFO] IME_SET called: ON (1) for: A
[2025-10-23 13:57:24] [INFO] GetGUIThreadInfo succeeded, hwndFocus: 1772284
[2025-10-23 13:57:24] [INFO] IME window handle: 331122
[2025-10-23 13:57:24] [INFO] SendMessage returned: 0
[2025-10-23 13:57:24] [SUCCESS] IME_SET: OFF → ON [SUCCESS] ✓
```

#### すでに設定済みの場合
```
[2025-10-23 13:57:30] [INFO] IME_SET called: ON (1) for: A
[2025-10-23 13:57:30] [INFO] IME_SET: ON → ON [ALREADY SET] ✓
```

#### 失敗時
```
[2025-10-23 13:57:35] [INFO] IME_SET called: ON (1) for: A
[2025-10-23 13:57:35] [WARN] IME_SET: OFF → OFF [FAILED] Expected: ON
[2025-10-23 13:57:35] [WARN] Retry 1/2
```

### 🆚 v5との違い

| 項目 | v5 | v5.1 |
|------|-----|------|
| IME_SETのログ | `IME_SET result: 0` | `OFF → ON [SUCCESS] ✓` |
| 成功/失敗判定 | 不明確 | 明確に判定 |
| 状態変化の記録 | なし | Before → After 形式 |
| ログの可読性 | △ | ◎ |

### 🔄 互換性

- **完全な後方互換性あり**
- v5のスクリプトは`IMEv5.ahk`を`IMEv5.1.ahk`に置き換えるだけで動作
- 関数シグネチャは全く変更なし

---

## [v5] - 2025-10-22

### 🎯 主な改善目標
ARM64環境での**動作安定性の大幅な向上**を目的とした改善版

### ✨ 新機能

#### デバッグ・診断機能
- **グローバルデバッグフラグ** (`IME_DEBUG`)
  - デフォルトは`false`（本番環境）
  - `Ctrl+Shift+F12`で実行中に切り替え可能
- **詳細ログ出力** (`IME_Log()`)
  - OutputDebugによるログ出力
  - ログレベル: INFO / WARN / ERROR
  - タイムスタンプ付き
- **エラー詳細情報**
  - `A_LastError`による詳細なエラーコード取得
  - DllCall失敗時の原因特定が容易に

#### リトライ機能
- **自動リトライロジック**
  - `IME_RETRY_COUNT`: デフォルト2回
  - `IME_RETRY_DELAY`: リトライ間隔50ms
  - 一時的なウィンドウ状態変化に対応

#### バリデーション機能
- **ウィンドウハンドル検証** (`IsValidHwnd()`)
  - NULLチェック
  - `IsWindow()`による実在確認
  - 無効なhwndの早期検出

### 🔧 改善点

#### エラーハンドリング
- **すべてのDllCallに戻り値チェックを追加**
  - SendMessage、GetGUIThreadInfo、ImmGetContext など
  - 失敗時の適切な処理とログ出力
- **try-catchブロック**
  - すべての主要関数を例外処理で保護
  - 予期しないエラーからの回復

#### コードの最適化
- **共通関数化による重複排除**
  - `GetTargetWindow()`: ウィンドウハンドル取得の共通化
  - `GetIMEWindow()`: IMEウィンドウハンドル取得の共通化
  - 8つの関数で重複していたコードを2つの共通関数に集約
- **コードの可読性向上**
  - より詳細なコメント
  - 明確な変数名
  - 処理フローの明示化

#### 堅牢性の向上
- **競合状態（Race Condition）への対策**
  - hwnd取得とIME操作の間の状態変化に対応
  - リトライによる一時的なエラーの吸収
- **戻り値の改善**
  - IME_GET: `1/0/-1` (ON/OFF/エラー)
  - IME_SET: `true/false` (成功/失敗)
  - エラー状態を明確に区別可能

### 📋 変更されたファイル

#### IMEv5.ahk
すべてのIME制御関数を改善:
- `IME_GET()` - 状態取得にエラーハンドリング追加
- `IME_SET()` - 状態設定にエラーハンドリング追加
- `IME_GetConvMode()` - 入力モード取得の改善
- `IME_SetConvMode()` - 入力モード設定の改善
- `IME_GetSentenceMode()` - 変換モード取得の改善
- `IME_SetSentenceMode()` - 変換モード設定の改善
- `IME_GetConverting()` - 変換中判定の改善
- `Get_Keyboard_Layout()` - キーボード配列取得の改善

新規追加関数:
- `IME_Log()` - ログ出力
- `IsValidHwnd()` - hwnd検証
- `GetTargetWindow()` - ターゲットウィンドウ取得（共通）
- `GetIMEWindow()` - IMEウィンドウ取得（共通）

#### alt-ime-ahk-mod-yuv5.ahk
- IMEv5.ahkをインクルード
- デバッグモード切り替えホットキー追加 (`Ctrl+Shift+F12`)
- コメントの改善

### 🐛 修正された問題

#### v4で発生していた問題
1. **動作が不安定**
   - → エラーハンドリングとリトライロジックで改善
   - → ウィンドウ状態の変化に強くなった

2. **エラーの原因が不明**
   - → デバッグログで詳細な診断が可能に
   - → A_LastErrorでエラーコード取得

3. **一時的なエラーで動作停止**
   - → リトライロジックで一時的なエラーを吸収
   - → より安定した動作

### 🔄 互換性

#### 後方互換性
- **関数シグネチャは変更なし**
  - v4のスクリプトをv5で使用可能（IMEv4_fixed.ahk → IMEv5.ahkに置き換えるだけ）
- **戻り値の拡張**
  - 既存の動作は維持
  - エラー時の戻り値を追加（`-1`や`false`）

#### プラットフォーム
- **完全サポート**: x86, x64, ARM64
- **テスト済み**: Windows 11 ARM64

### 📊 パフォーマンス

- **通常動作**: v4とほぼ同等
- **エラー発生時**: リトライにより最大150ms（50ms × 3回）の遅延
- **デバッグモードOFF**: オーバーヘッドは最小限

### 🚀 使用方法

#### 基本的な使用
```ahk
#Include IMEv5.ahk

; IMEをON
IME_SET(1)

; IMEをOFF
IME_SET(0)

; IME状態取得
status := IME_GET()  ; 1:ON, 0:OFF, -1:エラー
```

#### デバッグモード
```ahk
; スクリプト起動時にデバッグモードを有効化
global IME_DEBUG := true

; または実行中に Ctrl+Shift+F12 で切り替え
```

#### カスタマイズ
```ahk
; リトライ回数を変更（デフォルト: 2）
global IME_RETRY_COUNT := 3

; リトライ間隔を変更（デフォルト: 50ms）
global IME_RETRY_DELAY := 100
```

### 📝 開発者向け情報

#### デバッグログの確認方法
1. **DebugView**を使用（推奨）
   - [Sysinternals DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview)をダウンロード
   - 管理者権限で実行
   - `IME_DEBUG := true`に設定してスクリプト実行

2. **OutputDebug**の出力を確認
   ```
   [2025-10-22 12:34:56] [INFO] IME_SET called: 1 for: A
   [2025-10-22 12:34:56] [INFO] GetTargetWindow succeeded
   [2025-10-22 12:34:56] [INFO] IME window handle: 12345678
   [2025-10-22 12:34:56] [INFO] IME_SET result: 1
   ```

#### 既知の制限
- New Outlook (`olk.exe`) では特別な処理が必要（既に実装済み）
- 一部のアプリケーションでIMEウィンドウが取得できない場合がある

### 🙏 謝辞
- Original Author: [karakaram](https://github.com/karakaram/alt-ime-ahk)
- Intermediate fork (starting point): nekocodeX — 旧 `nekocodeX/alt-ime-ahk-mod`（現在は非公開）
- v4 以降の改修（ARM64 対応、v5 系の安定性・エラーハンドリング・デバッグ・ログ機能）: [yuki0ueda](https://github.com/yuki0ueda/alt-ime-rev)

### 📄 ライセンス
NYSL <http://www.kmonos.net/nysl/>

---

## [v4] - 以前のバージョン

### v4での主な改善
- ポインタサイズの計算を修正（!A_PtrSize条件削除）
- 大文字小文字の統一（PtrSize→ptrSize）
- DllCallの型指定を全面的に修正（ARM64対応）
- 戻り値型を明示化

### v4での問題点
- エラーハンドリングがない
- デバッグ機能がない
- 動作が不安定になることがある
- エラーの原因特定が困難

→ **v5でこれらの問題をすべて解決**

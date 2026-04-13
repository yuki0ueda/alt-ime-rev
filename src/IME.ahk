#Requires AutoHotkey v2.0
;;; IME.ahk NYSL <http://www.kmonos.net/nysl/>
;;; AutoHotkey を流行らせるアップローダ <http://lukewarm.s101.xrea.com/up/>
;;;   の 089.zip [Shift&Space + IME.ahk] (2008/09/21 20:18)
;;; Index of /_pub/eamat/MyScript の IME20091203.zip (IME.ahk)
;;;   http://www6.atwiki.jp/eamat/pub/MyScript/
;;; IME20121110.zip (本家, A32/U32/U64 同梱)
;;;   http://www6.atwiki.jp/_pub/eamat/MyScript/Lib/IME20121110.zip

/*****************************************************************************
  IME 制御用 関数群 (IME.ahk)

    グローバル変数 : IME_DEBUG / IME_LOG_* / IME_RETRY_* (下記)
    各関数の依存性 : 同一ファイル内のヘルパー関数のみ
    AutoHotkey     : v 2.0
    Language       : Japanese
    Platform       : x86 / x64 / ARM64 (Windows NT 系)
    Authors        : v 1.1  eamat.             http://www6.atwiki.jp/eamat/   (GitHub: @eamat-dot)
                     v 2.0  Ken'ichiro Ayaki   https://github.com/k-ayaki/IMEv2.ahk
                     this   yuki0ueda          https://github.com/yuki0ueda/alt-ime-rev

  License: Ken'ichiro Ayaki (k-ayaki) が v2 ポート公開時 (2023-07-17) に
           NYSL <http://www.kmonos.net/nysl/> を明示宣言。
           NYSL A-3 / A-4 が改変・再ライセンスを許可しているため本フォークは MIT へ relicense。
           詳細は repo root の LICENSE および NOTICE を参照。

*****************************************************************************
  履歴 (upstream — 参考)
    2008.07.11  eamat  v1.0.47 以降の 関数ライブラリスクリプト対応用にファイル名を変更
    2008.12.10  eamat  コメント修正
    2009.07.03  eamat  IME_GetConverting() 追加
                       Last Found Window が有効にならない問題修正、他
    2009.12.03  eamat  IME 状態チェック GUIThreadInfo 利用版を取り込み
                       (IE や 秀丸 8β でも IME 状態が取れるように)
                       Google日本語入力β 向け調整: 入力/変換モードは取れないが
                       IME_GET/SET() と IME_GetConverting() は有効
    2012.11.10  eamat  x64 & Unicode 対応 (AHK_L U64、本家/A32/U32 との互換維持)
                       LongPtr 対策: ポインタサイズを A_PtrSize で見るようにした
                       WinTitle パラメータの機能を復活
                       (アクティブ窓は GetGUIThreadInfo、それ以外は Control ハンドル)
    2023.07.17  k-ayaki  AutoHotkey v2.0 ポート版として IMEv2.ahk を公開

  履歴 (this fork — 本リポでの追加改修)
    v4   yuki0ueda  ARM64 対応 (!A_PtrSize 条件削除、DllCall 型指定修正、戻り値型明示化)
    v5   yuki0ueda  エラーハンドリング強化、デバッグモード、自動リトライ、共通関数化
    v5.1 yuki0ueda  状態変化ログ (Before → After)、ログレベル拡張
    v5.2 yuki0ueda  ファイルログ出力、自動ローテーション (10MB)
    v1.0.0  公開初回リリース (alt-ime-rev) — 上記内部版 v4〜v5.2 を統合

  機能概要:
    - IME の ON/OFF 取得・設定、変換モード・文節モードの操作
    - OutputDebug とファイルの並行ログ出力、自動ローテーション (既定 10MB)
    - DllCall のエラーハンドリングとリトライ、ARM64 ポインタ幅対応

  設定は IME_DEBUG, IME_LOG_TO_FILE, IME_LOG_MAX_SIZE, IME_RETRY_COUNT,
  IME_RETRY_DELAY のグローバル変数で上書き可能。
*****************************************************************************
*/

;-----------------------------------------------------------
; グローバル設定
;-----------------------------------------------------------
global IME_DEBUG := false           ; デバッグモード（trueでログ出力）
global IME_LOG_TO_FILE := true      ; ファイルログ出力（trueでファイルにも保存）
global IME_LOG_FILE := A_ScriptDir . "\ime_debug.log"        ; ログファイルパス
global IME_LOG_FILE_OLD := A_ScriptDir . "\ime_debug_old.log" ; 古いログファイル
global IME_LOG_MAX_SIZE := 10485760  ; ログファイル最大サイズ (10MB)
global IME_RETRY_COUNT := 2         ; リトライ回数
global IME_RETRY_DELAY := 50        ; リトライ間隔（ミリ秒）

;-----------------------------------------------------------
; ログファイルのローテーション
;   ファイルサイズが上限を超えた場合、古いファイルにリネーム
;-----------------------------------------------------------
IME_RotateLogFile() {
    global IME_LOG_FILE, IME_LOG_FILE_OLD, IME_LOG_MAX_SIZE

    try {
        ; ログファイルが存在しない場合は何もしない
        if (!FileExist(IME_LOG_FILE)) {
            return
        }

        ; ファイルサイズ取得
        fileSize := 0
        Loop Files, IME_LOG_FILE {
            fileSize := A_LoopFileSize
        }

        ; サイズチェック
        if (fileSize > IME_LOG_MAX_SIZE) {
            ; 古いログファイルが存在する場合は削除
            ; （FileDelete は AHK v2 で失敗時に例外を投げるため、個別の try で保護してログ機能を止めない）
            if (FileExist(IME_LOG_FILE_OLD)) {
                try {
                    FileDelete(IME_LOG_FILE_OLD)
                } catch as err {
                    OutputDebug("[ERROR] Failed to delete old log file: " . err.Message)
                    return  ; 削除失敗時はローテーションを諦める（次回再試行）
                }
            }

            ; 現在のログファイルを古いファイルにリネーム
            FileMove(IME_LOG_FILE, IME_LOG_FILE_OLD, 1)

            ; ローテーション完了をOutputDebugに記録（ファイルには書かない）
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            OutputDebug("[" . timestamp . "] [INFO] Log file rotated: " . Round(fileSize/1048576, 2) . " MB")
        }
    } catch as err {
        ; エラーが発生してもログ機能は停止させない
        OutputDebug("[ERROR] Log rotation failed: " . err.Message)
    }
}

;-----------------------------------------------------------
; デバッグログ出力関数（ファイル出力対応版）
;   msg         ログメッセージ
;   level       ログレベル ("INFO", "WARN", "ERROR", "SUCCESS")
;-----------------------------------------------------------
IME_Log(msg, level := "INFO") {
    global IME_DEBUG, IME_LOG_TO_FILE, IME_LOG_FILE

    if (IME_DEBUG) {
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        logMsg := "[" . timestamp . "] [" . level . "] " . msg

        ; OutputDebugに出力（DebugView用）
        OutputDebug(logMsg)

        ; ファイルに出力
        if (IME_LOG_TO_FILE) {
            try {
                ; ログローテーションチェック（100回に1回だけチェック）
                static logCounter := 0
                logCounter++
                if (Mod(logCounter, 100) = 0) {
                    IME_RotateLogFile()
                }

                ; ファイルに追記
                FileAppend(logMsg . "`n", IME_LOG_FILE, "UTF-8")
            } catch as err {
                ; ファイル書き込みエラーが発生してもログ機能は停止させない
                ; OutputDebugには出力する
                OutputDebug("[ERROR] Failed to write log file: " . err.Message)
            }
        }
    }
}

;-----------------------------------------------------------
; ウィンドウハンドルの有効性チェック
;   hwnd        チェック対象のウィンドウハンドル
;   戻り値      true:有効 / false:無効
;-----------------------------------------------------------
IsValidHwnd(hwnd) {
    if (!hwnd || hwnd = 0) {
        IME_Log("Invalid hwnd: null or zero", "ERROR")
        return false
    }

    ; IsWindowで実際にウィンドウが存在するか確認
    try {
        result := DllCall("user32\IsWindow", "UPtr", hwnd, "Int")
        if (!result) {
            IME_Log("hwnd " . hwnd . " is not a valid window", "ERROR")
            return false
        }
        return true
    } catch as err {
        IME_Log("IsWindow failed: " . err.Message, "ERROR")
        return false
    }
}

;-----------------------------------------------------------
; ターゲットウィンドウハンドルの取得（共通関数）
;   WinTitle    対象Window（デフォルト "A" = アクティブウィンドウ）
;   戻り値      ウィンドウハンドル（失敗時は0）
;
; 機能:
;   1. WinExistでウィンドウの存在確認
;   2. WinActiveの場合、GetGUIThreadInfoでフォーカスウィンドウを取得
;   3. エラーハンドリングとバリデーション
;-----------------------------------------------------------
GetTargetWindow(WinTitle := "A") {
    try {
        ; ウィンドウの存在確認
        hwnd := WinExist(WinTitle)
        if (!hwnd) {
            IME_Log("Window not found: " . WinTitle, "WARN")
            return 0
        }

        ; アクティブウィンドウの場合、フォーカスされたコントロールを取得
        if (WinActive(WinTitle)) {
            ptrSize := A_PtrSize
            cbSize := 4 + 4 + (ptrSize * 6) + 16  ; GUITHREADINFO構造体サイズ
            stGTI := Buffer(cbSize, 0)
            NumPut("UInt", cbSize, stGTI, 0)

            ; GetGUIThreadInfoでスレッド情報取得
            result := DllCall("user32\GetGUIThreadInfo"
                , "UInt", 0              ; 現在のスレッド
                , "Ptr", stGTI.Ptr       ; 構造体ポインタ
                , "Int")                 ; 戻り値: BOOL

            if (result) {
                ; hwndFocusを取得（オフセット: cbSize[4] + flags[4] + hwndActive[ptrSize]）
                hwndFocus := NumGet(stGTI, 8 + ptrSize, "UPtr")
                if (hwndFocus && hwndFocus != 0) {
                    IME_Log("GetGUIThreadInfo succeeded, hwndFocus: " . hwndFocus, "INFO")
                    hwnd := hwndFocus
                } else {
                    IME_Log("GetGUIThreadInfo returned null hwndFocus, using original hwnd", "WARN")
                }
            } else {
                lastError := A_LastError
                IME_Log("GetGUIThreadInfo failed, error code: " . lastError, "WARN")
                ; フォールバック: 元のhwndを使用
            }
        }

        ; 最終的なhwnd検証
        if (!IsValidHwnd(hwnd)) {
            IME_Log("Final hwnd validation failed", "ERROR")
            return 0
        }

        return hwnd

    } catch as err {
        IME_Log("GetTargetWindow exception: " . err.Message, "ERROR")
        return 0
    }
}

;-----------------------------------------------------------
; IMEウィンドウハンドルの取得（共通関数）
;   hwnd        対象ウィンドウハンドル
;   戻り値      IMEウィンドウハンドル（失敗時は0）
;-----------------------------------------------------------
GetIMEWindow(hwnd) {
    if (!IsValidHwnd(hwnd)) {
        return 0
    }

    try {
        imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd"
            , "UPtr", hwnd      ; ウィンドウハンドル
            , "UPtr")           ; 戻り値: HWND (UPtr)

        if (!imeWnd || imeWnd = 0) {
            lastError := A_LastError
            IME_Log("ImmGetDefaultIMEWnd failed, error code: " . lastError, "ERROR")
            return 0
        }

        IME_Log("IME window handle: " . imeWnd, "INFO")
        return imeWnd

    } catch as err {
        IME_Log("GetIMEWindow exception: " . err.Message, "ERROR")
        return 0
    }
}

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF / -1:エラー
;-----------------------------------------------------------
IME_GET(WinTitle := "A") {
    ; ログ削減：GETは頻繁に呼ばれるのでログレベルをDEBUGに

    ; リトライロジック
    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                IME_Log("IME_GET: Failed to get target window", "ERROR")
                return -1
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                IME_Log("IME_GET: Failed to get IME window", "ERROR")
                return -1
            }

            ; WM_IME_CONTROL (0x0283), IMC_GETOPENSTATUS (0x0005)
            result := DllCall("user32\SendMessage"
                , "UPtr", imeWnd        ; IMEウィンドウハンドル
                , "UInt", 0x0283        ; WM_IME_CONTROL
                , "UPtr", 0x0005        ; IMC_GETOPENSTATUS
                , "UPtr", 0             ; lParam
                , "Ptr")                ; 戻り値: LRESULT

            status := result ? 1 : 0
            ; 詳細ログは必要時のみ
            ; IME_Log("IME_GET: Status=" . status, "INFO")
            return status

        } catch as err {
            IME_Log("IME_GET exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return -1
        }
    }

    return -1
}

;-----------------------------------------------------------
; IMEの状態をセット（状態変化ログ付き）
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          true:成功 / false:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle := "A") {
    targetState := SetSts ? "ON" : "OFF"
    IME_Log("IME_SET called: " . targetState . " (" . SetSts . ") for: " . WinTitle, "INFO")

    ; 【重要】設定前の状態を取得
    beforeState := IME_GET(WinTitle)
    beforeStr := (beforeState = 1) ? "ON" : (beforeState = 0) ? "OFF" : "UNKNOWN"

    ; リトライロジック
    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    IME_Log("Retry " . A_Index . "/" . IME_RETRY_COUNT, "WARN")
                    Sleep IME_RETRY_DELAY
                    continue
                }
                IME_Log("Failed to get target window after retries", "ERROR")
                return false
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                IME_Log("Failed to get IME window after retries", "ERROR")
                return false
            }

            ; WM_IME_CONTROL (0x0283), IMC_SETOPENSTATUS (0x0006)
            sendResult := DllCall("user32\SendMessage"
                , "UPtr", imeWnd        ; IMEウィンドウハンドル
                , "UInt", 0x0283        ; WM_IME_CONTROL
                , "UPtr", 0x0006        ; IMC_SETOPENSTATUS
                , "UPtr", SetSts        ; lParam: 0 or 1
                , "Ptr")                ; 戻り値: LRESULT

            IME_Log("SendMessage returned: " . sendResult, "INFO")

            ; 【重要】設定後の状態を取得して確認
            Sleep 10  ; IME処理を待つ（短い待機）
            afterState := IME_GET(WinTitle)
            afterStr := (afterState = 1) ? "ON" : (afterState = 0) ? "OFF" : "UNKNOWN"

            ; 状態変化をログに記録
            stateChange := beforeStr . " -> " . afterStr
            expectedMatch := (afterState = SetSts)

            if (expectedMatch) {
                IME_Log("IME_SET: " . stateChange . " [SUCCESS]", "SUCCESS")
                return true
            } else if (beforeState = afterState && beforeState = SetSts) {
                ; すでに目的の状態だった場合も成功
                IME_Log("IME_SET: " . stateChange . " [ALREADY SET]", "INFO")
                return true
            } else {
                IME_Log("IME_SET: " . stateChange . " [FAILED] Expected: " . targetState, "WARN")
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

        } catch as err {
            IME_Log("IME_SET exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return false
        }
    }

    return false
}

;-----------------------------------------------------------
; IME 入力モード取得
;   WinTitle="A"    対象Window
;   戻り値          入力モード / -1:エラー
;-----------------------------------------------------------
IME_GetConvMode(WinTitle := "A") {
    IME_Log("IME_GetConvMode called for: " . WinTitle, "INFO")

    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            ; WM_IME_CONTROL (0x0283), IMC_GETCONVERSIONMODE (0x0001)
            result := DllCall("user32\SendMessage"
                , "UPtr", imeWnd
                , "UInt", 0x0283
                , "UPtr", 0x0001
                , "UPtr", 0
                , "Ptr")

            IME_Log("Conversion mode: " . result, "INFO")
            return result

        } catch as err {
            IME_Log("IME_GetConvMode exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return -1
        }
    }

    return -1
}

;-----------------------------------------------------------
; IME 入力モードセット（状態変化ログ付き）
;   ConvMode        入力モード
;   WinTitle="A"    対象Window
;   戻り値          true:成功 / false:失敗
;-----------------------------------------------------------
IME_SetConvMode(ConvMode, WinTitle := "A") {
    IME_Log("IME_SetConvMode called: " . ConvMode . " for: " . WinTitle, "INFO")

    ; 設定前の状態を取得
    beforeMode := IME_GetConvMode(WinTitle)

    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

            ; WM_IME_CONTROL (0x0283), IMC_SETCONVERSIONMODE (0x0002)
            result := DllCall("user32\SendMessage"
                , "UPtr", imeWnd
                , "UInt", 0x0283
                , "UPtr", 0x0002
                , "UPtr", ConvMode
                , "Ptr")

            ; 設定後の状態を確認
            Sleep 10
            afterMode := IME_GetConvMode(WinTitle)

            if (afterMode = ConvMode) {
                IME_Log("IME_SetConvMode: " . beforeMode . " -> " . afterMode . " [SUCCESS]", "SUCCESS")
                return true
            } else {
                IME_Log("IME_SetConvMode: " . beforeMode . " -> " . afterMode . " [FAILED] Expected: " . ConvMode, "WARN")
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

        } catch as err {
            IME_Log("IME_SetConvMode exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return false
        }
    }

    return false
}

;-----------------------------------------------------------
; IME 変換モード取得
;   WinTitle="A"    対象Window
;   戻り値          変換モード / -1:エラー
;-----------------------------------------------------------
IME_GetSentenceMode(WinTitle := "A") {
    IME_Log("IME_GetSentenceMode called for: " . WinTitle, "INFO")

    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            ; WM_IME_CONTROL (0x0283), IMC_GETSENTENCEMODE (0x0003)
            result := DllCall("user32\SendMessage"
                , "UPtr", imeWnd
                , "UInt", 0x0283
                , "UPtr", 0x0003
                , "UPtr", 0
                , "Ptr")

            IME_Log("Sentence mode: " . result, "INFO")
            return result

        } catch as err {
            IME_Log("IME_GetSentenceMode exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return -1
        }
    }

    return -1
}

;-----------------------------------------------------------
; IME 変換モードセット（状態変化ログ付き）
;   SentenceMode    変換モード
;   WinTitle="A"    対象Window
;   戻り値          true:成功 / false:失敗
;-----------------------------------------------------------
IME_SetSentenceMode(SentenceMode, WinTitle := "A") {
    IME_Log("IME_SetSentenceMode called: " . SentenceMode . " for: " . WinTitle, "INFO")

    ; 設定前の状態を取得
    beforeMode := IME_GetSentenceMode(WinTitle)

    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

            imeWnd := GetIMEWindow(hwnd)
            if (!imeWnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

            ; WM_IME_CONTROL (0x0283), IMC_SETSENTENCEMODE (0x0004)
            result := DllCall("user32\SendMessage"
                , "UPtr", imeWnd
                , "UInt", 0x0283
                , "UPtr", 0x0004
                , "UPtr", SentenceMode
                , "Ptr")

            ; 設定後の状態を確認
            Sleep 10
            afterMode := IME_GetSentenceMode(WinTitle)

            if (afterMode = SentenceMode) {
                IME_Log("IME_SetSentenceMode: " . beforeMode . " -> " . afterMode . " [SUCCESS]", "SUCCESS")
                return true
            } else {
                IME_Log("IME_SetSentenceMode: " . beforeMode . " -> " . afterMode . " [FAILED] Expected: " . SentenceMode, "WARN")
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return false
            }

        } catch as err {
            IME_Log("IME_SetSentenceMode exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return false
        }
    }

    return false
}

;-----------------------------------------------------------
; IME 変換中かどうかを取得
;   WinTitle="A"    対象Window
;   戻り値          変換中の文字数 / 0:変換中でない / -1:エラー
;-----------------------------------------------------------
IME_GetConverting(WinTitle := "A") {
    IME_Log("IME_GetConverting called for: " . WinTitle, "INFO")

    Loop IME_RETRY_COUNT + 1 {
        try {
            hwnd := GetTargetWindow(WinTitle)
            if (!hwnd) {
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            ; ImmGetContextでIMEコンテキスト取得
            hIMC := DllCall("imm32\ImmGetContext"
                , "UPtr", hwnd
                , "UPtr")

            if (!hIMC) {
                IME_Log("ImmGetContext failed", "ERROR")
                if (A_Index <= IME_RETRY_COUNT) {
                    Sleep IME_RETRY_DELAY
                    continue
                }
                return -1
            }

            ret := 0

            ; ImmGetOpenStatusでIMEが開いているか確認
            openStatus := DllCall("imm32\ImmGetOpenStatus"
                , "UPtr", hIMC
                , "UInt")

            if (openStatus) {
                ; GCS_COMPSTR (0x8) で変換中の文字列の長さを取得
                ret := DllCall("imm32\ImmGetCompositionString"
                    , "UPtr", hIMC
                    , "UInt", 0x8
                    , "Ptr", 0
                    , "UInt", 0
                    , "UInt")
            }

            ; ImmReleaseContextでコンテキスト解放（戻り値 BOOL: 失敗時は WARN ログ）
            releaseResult := DllCall("imm32\ImmReleaseContext"
                , "UPtr", hwnd
                , "UPtr", hIMC
                , "Int")
            if (!releaseResult) {
                IME_Log("ImmReleaseContext failed", "WARN")
            }

            IME_Log("Converting status: " . ret . " chars", "INFO")
            return ret

        } catch as err {
            IME_Log("IME_GetConverting exception: " . err.Message, "ERROR")
            if (A_Index <= IME_RETRY_COUNT) {
                Sleep IME_RETRY_DELAY
                continue
            }
            return -1
        }
    }

    return -1
}

;-----------------------------------------------------------
; 使用中のキーボード配列の取得
;   WinTitle="A"    対象Window
;   戻り値          キーボード配列ID / 0:エラー
;-----------------------------------------------------------
Get_Keyboard_Layout(WinTitle := "A") {
    IME_Log("Get_Keyboard_Layout called for: " . WinTitle, "INFO")

    try {
        hwnd := GetTargetWindow(WinTitle)
        if (!hwnd) {
            IME_Log("Failed to get target window", "ERROR")
            return 0
        }

        ; GetWindowThreadProcessIdでスレッドID取得
        ThreadID := DllCall("user32\GetWindowThreadProcessId"
            , "UPtr", hwnd
            , "Ptr", 0
            , "UInt")

        if (!ThreadID) {
            lastError := A_LastError
            IME_Log("GetWindowThreadProcessId failed, error: " . lastError, "ERROR")
            return 0
        }

        ; GetKeyboardLayoutでキーボード配列取得
        InputLocaleID := DllCall("user32\GetKeyboardLayout"
            , "UInt", ThreadID
            , "UPtr")

        IME_Log("Keyboard layout: " . InputLocaleID, "INFO")
        return InputLocaleID

    } catch as err {
        IME_Log("Get_Keyboard_Layout exception: " . err.Message, "ERROR")
        return 0
    }
}

;-----------------------------------------------------------
; ヘルパー関数
;-----------------------------------------------------------

Get_languege_id(hKL) {
    return Format("0x{:X}", Mod(hKL, 0x10000))
}

Get_primary_language_identifier(local_identifier) {
    return Format("0x{:X}", Mod(local_identifier, 0x100))
}

Get_sublanguage_identifier(local_identifier) {
    return Format("0x{:X}", Floor(local_identifier / 0x100))
}

Get_languege_name() {
    locale_id := Get_languege_id(Get_Keyboard_Layout())
    return    (locale_id = "0x436") ? "af"
            : (locale_id = "0x804") ? "zh-cn"
            : (locale_id = "0xC04") ? "zh-hk"
            : (locale_id = "0x1004") ? "zh-sg"
            : (locale_id = "0x404") ? "zh-tw"
            : (locale_id = "0x411") ? "ja"
            : (locale_id = "-0xF3FC") ? "zh-yue"
            : "unknown"
}

Get_ime_file() {
    try {
        SubKey := Get_reg_Keyboard_Layouts()
        ime_file_name := RegRead("HKEY_LOCAL_MACHINE" . SubKey, "Ime File")
        return ime_file_name
    } catch {
        IME_Log("Get_ime_file failed", "ERROR")
        return ""
    }
}

Get_Layout_Text() {
    try {
        SubKey := Get_reg_Keyboard_Layouts()
        layout_text := RegRead("HKEY_LOCAL_MACHINE" . SubKey, "Layout Text")
        return layout_text
    } catch {
        IME_Log("Get_Layout_Text failed", "ERROR")
        return ""
    }
}

Get_reg_Keyboard_Layouts() {
    hKL := RegExReplace(Get_Keyboard_Layout(), "0x", "")
    return "\System\CurrentControlSet\Control\Keyboard Layouts\" . hKL
}

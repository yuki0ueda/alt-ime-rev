#Requires AutoHotkey v2.0

; alt-ime-rev  —  左右 Alt キーの空打ちで日本語 IME を ON/OFF する AutoHotkey v2 スクリプト
;
;   左 Alt    空打ち → IME OFF
;   右 Alt    空打ち → IME ON
;   Ctrl+Shift+F12   → デバッグモード切替
;
; Alt を押しながら他キーを叩いた場合は通常の Alt として動作する。
; 変更履歴は CHANGELOG.md、ライセンスとクレジットは LICENSE を参照。
; Repo: https://github.com/yuki0ueda/alt-ime-rev

#Include IME.ahk

; デバッグモード切り替えホットキー（開発・診断用）
; Ctrl+Shift+F12でデバッグモードのON/OFFを切り替え
^+F12:: {
    global IME_DEBUG
    IME_DEBUG := !IME_DEBUG
    status := IME_DEBUG ? "ON" : "OFF"

    ; ログファイル情報も表示
    global IME_LOG_TO_FILE, IME_LOG_FILE
    logInfo := ""
    if (IME_LOG_TO_FILE) {
        logInfo := "`nLog file: " . IME_LOG_FILE
    }

    ToolTip("Debug Mode: " . status . logInfo)
    SetTimer(() => ToolTip(), -3000)  ; 3秒後にツールチップを消去

    ; デバッグモードON時はログに記録
    if (IME_DEBUG) {
        IME_Log("=== Debug mode activated ===", "INFO")
        IME_Log("Log file: " . IME_LOG_FILE, "INFO")
        IME_Log("Platform: " . A_OSVersion . " (" . (A_PtrSize = 8 ? "64-bit" : "32-bit") . ")", "INFO")
    }

    Return
}

; Razer Synapseなど、キーカスタマイズ系のツールを併用しているときのエラー対策
A_MaxHotkeysPerInterval := 350

; 既存のインスタンスが存在する場合、終了して新たにインスタンスを開始
#SingleInstance Force

; 主要キーを "何もしない" パススルーホットキーとして一括登録する。
;
; 下の `LAlt up::` / `RAlt up::` は `A_PriorHotkey == "*~LAlt"` /
; `"*~RAlt"` で「直前に発火したホットキーが Alt 空打ちだったか」を比較して
; IME を切り替える。A_PriorHotkey は AHK に登録済みのホットキーの発火履歴
; しか持たないため、通常キー (a-z, 0-9, 記号, Fキー, ナビゲーション系) を
; 全て "空打ち以外のキー" として登録しておかないと、Alt を一度も挟まない
; 通常入力のあとに左右 Alt 単独を押しても `A_PriorHotkey` が古い Alt 名の
; まま残り、誤って IME が切り替わる。消すと Alt 空打ち検出が壊れる。
passthroughKeys := [
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z",
    "1","2","3","4","5","6","7","8","9","0",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "``","~","!","@","#","$","%","^","&","*","(",")",
    "-","_","=","+","[","{","]","}","\","|",
    ";","'",'"',",","<",".",">","/","?",
    "Esc","Tab","Space",
    "Left","Right","Up","Down","Enter",
    "PrintScreen","Delete","Home","End","PgUp","PgDn"
]
noopHotkey := (*) => 0
for k in passthroughKeys
    HotKey("*~" . k, noopHotkey)

; 上部メニューがアクティブになるのを抑制 / Xbox Game Bar 起動用仮想キーコードとのバッティング回避 (vk07 -> vkFF)
*~LAlt::Send ("{Blind}{vkFF}")
*~RAlt::Send ("{Blind}{vkFF}")

; 左 Alt 空打ちで IME を OFF
LAlt up::
{
    if (A_PriorHotkey == "*~LAlt") {
        IME_SET(0)
    }
    Return
}

; 右 Alt 空打ちで IME を ON
RAlt up::
{
    if (A_PriorHotkey == "*~RAlt") {
        IME_SET(1)
    }
    Return
}

; Win + CapsLock を無視
#CapsLock::Return

; New Outlook対策
; New Outlook では Alt キーの動作が特殊なため、完全にブロックして対応
#HotIf WinActive("ahk_exe olk.exe") || WinActive("ahk_class Olk Host")

*LAlt::
{
    KeyWait "LAlt"
    if (A_PriorKey == "LAlt") {
        IME_SET(0)
    }
    Return
}

*RAlt::
{
    KeyWait "RAlt"
    if (A_PriorKey == "RAlt") {
        IME_SET(1)
    }
    Return
}

#HotIf

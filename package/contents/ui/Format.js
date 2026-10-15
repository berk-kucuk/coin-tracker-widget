/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

.pragma library

// Currency signs that go in front of the number; anything else gets its
// code after it ("0.0021 BTC" style).
var SIGNS = {
    usd: "$", eur: "€", gbp: "£", jpy: "¥", cny: "¥", try: "₺", inr: "₹",
    krw: "₩", rub: "₽", cad: "C$", aud: "A$", brl: "R$", chf: "CHF ",
    btc: "₿", eth: "Ξ"
}

function sign(currency) {
    return SIGNS[currency] !== undefined ? SIGNS[currency] : ""
}

function group(intText) {
    return intText.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

// Plain number with sensible precision for its size: 83,468 · 142.87 ·
// 0.1842 · 0.00020742.
function number(v) {
    if (v === null || v === undefined || isNaN(v)) return "—"
    var a = Math.abs(v)
    var s
    if (a >= 1000) s = group(a.toFixed(0))
    else if (a >= 1) s = a.toFixed(2)
    else if (a === 0) s = "0"
    else s = a.toFixed(Math.min(12, 3 - Math.floor(Math.log(a) / Math.LN10)))
    return (v < 0 ? "-" : "") + s
}

// 1.68T · 32.5B · 84.1K
function big(v) {
    if (v === null || v === undefined || isNaN(v)) return "—"
    var a = Math.abs(v)
    var units = [[1e12, "T"], [1e9, "B"], [1e6, "M"], [1e3, "K"]]
    for (var i = 0; i < units.length; i++) {
        if (a >= units[i][0]) {
            var n = a / units[i][0]
            return (v < 0 ? "-" : "") + n.toFixed(n >= 100 ? 0 : n >= 10 ? 1 : 2) + units[i][1]
        }
    }
    return number(v)
}

function money(v, currency, compact) {
    var n = compact && Math.abs(v) >= 10000 ? big(v) : number(v)
    var s = sign(currency)
    if (s) return s + n
    return n + " " + String(currency).toUpperCase()
}

// "+1.24%" / "-0.42%"
function change(v) {
    if (v === null || v === undefined || isNaN(v)) return "—"
    var a = Math.abs(v)
    return (v >= 0 ? "+" : "-") + a.toFixed(a >= 100 ? 0 : a >= 10 ? 1 : 2) + "%"
}

// Compact duration like "2d 4h", "3h 12m", "45m", "<1m".
function duration(ms) {
    if (ms === null || ms === undefined || ms < 0) return ""
    var m = Math.floor(ms / 60000)
    if (m < 1) return "<1m"
    var d = Math.floor(m / 1440)
    var h = Math.floor((m % 1440) / 60)
    var mm = m % 60
    if (d > 0) return d + "d " + h + "h"
    if (h > 0) return h + "h " + mm + "m"
    return mm + "m"
}

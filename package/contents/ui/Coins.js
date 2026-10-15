/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

.pragma library

// Badge colours for well-known coins (CoinGecko ids). Dark brand colours
// are lifted so the badge reads on dark panels too. Other coins get a
// stable colour from their id.
var COLORS = {
    "bitcoin": "#f7931a",
    "ethereum": "#627eea",
    "solana": "#9945ff",
    "binancecoin": "#f3ba2f",
    "ripple": "#3b82c4",
    "cardano": "#3468d1",
    "dogecoin": "#c2a633",
    "polkadot": "#e6007a",
    "avalanche-2": "#e84142",
    "litecoin": "#a6a9aa",
    "chainlink": "#2a5ada",
    "tron": "#ff060a",
    "the-open-network": "#0098ea",
    "polygon-ecosystem-token": "#8247e5",
    "shiba-inu": "#ffa409",
    "tether": "#26a17b",
    "usd-coin": "#2775ca",
    "stellar": "#7d8bff",
    "cosmos": "#6f7390",
    "monero": "#ff6600",
    "bitcoin-cash": "#8dc351",
    "ethereum-classic": "#3ab83a",
    "uniswap": "#ff007a",
    "sui": "#4da2ff",
    "pepe": "#4c9540",
    "near": "#00c08b",
    "aptos": "#00bfa5",
    "arbitrum": "#28a0f0",
    "optimism": "#ff0420",
    "hedera-hashgraph": "#8259ef",
    "kaspa": "#70c7ba",
    "hyperliquid": "#97fce4"
}

// 13x13 round badge for the pixel theme; the symbol's first letter is cut
// out of the middle (columns 5-7, rows 4-8).
var DISC = [
    "0000111110000",
    "0011111111100",
    "0111111111110",
    "0111111111110",
    "1111111111111",
    "1111111111111",
    "1111111111111",
    "1111111111111",
    "1111111111111",
    "0111111111110",
    "0111111111110",
    "0011111111100",
    "0000111110000"
]

function hex2(n) {
    var s = Math.round(Math.max(0, Math.min(255, n))).toString(16)
    return s.length < 2 ? "0" + s : s
}

function hsl(h, s, l) {
    var a = s * Math.min(l, 1 - l)
    function f(n) {
        var k = (n + h / 30) % 12
        return 255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)))
    }
    return "#" + hex2(f(0)) + hex2(f(8)) + hex2(f(4))
}

function color(id) {
    if (COLORS[id]) return COLORS[id]
    var h = 0
    var s = String(id)
    for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360
    return hsl(h, 0.6, 0.55)
}

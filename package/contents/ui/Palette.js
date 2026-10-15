/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

.pragma library

// Pixel theme: Sweetie 16 inspired.
var GREEN = "#38b764"
var RED = "#e43b44"
var ORANGE = "#ef7d57"
var INK = "#1a1c2c"

// Modern theme: GitHub-like up / down colours.
var UP = "#3fb950"
var DOWN = "#f85149"

function forChange(v, theme) {
    if (v === null || v === undefined || isNaN(v)) return ""
    if (theme === 1) return v >= 0 ? UP : DOWN
    return v >= 0 ? GREEN : RED
}

/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Price line. Pixel theme: one block per `unit` screen pixels, gaps between
// columns filled so the line stays connected. Modern theme: an antialiased
// line with a fading fill underneath.
Canvas {
    id: spark

    property var points: []
    property color color: Kirigami.Theme.textColor
    property int unit: 2
    property bool fill: true
    property bool dimmed: false
    readonly property bool pixel: Plasmoid.configuration.theme === 0

    opacity: dimmed ? 0.5 : 1
    renderStrategy: Canvas.Cooperative
    antialiasing: !pixel

    onPointsChanged: requestPaint()
    onColorChanged: requestPaint()
    onUnitChanged: requestPaint()
    onPixelChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onAvailableChanged: requestPaint()

    function rgba(a) {
        return Qt.rgba(color.r, color.g, color.b, a)
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const pts = points || []
        if (pts.length < 2 || width < 2 || height < 2) return
        let lo = Infinity, hi = -Infinity
        for (const v of pts) { lo = Math.min(lo, v); hi = Math.max(hi, v) }
        const span = hi - lo || 1
        const n = pts.length

        if (pixel) {
            const u = Math.max(1, unit)
            const cols = Math.floor(width / u)
            const rows = Math.floor(height / u)
            if (cols < 2 || rows < 2) return
            const rowOf = c => {
                const v = pts[Math.round(c / (cols - 1) * (n - 1))]
                return Math.round((hi - v) / span * (rows - 1))
            }
            const vspan = (c, a, b) => { if (a <= b) ctx.fillRect(c * u, a * u, u, (b - a + 1) * u) }
            let prev = rowOf(0)
            for (let c = 0; c < cols; c++) {
                const r = rowOf(c)
                if (fill) {
                    ctx.fillStyle = rgba(0.18)
                    vspan(c, r + 1, rows - 1)
                }
                ctx.fillStyle = color
                vspan(c, r, r)
                // bridge jumps: half in the previous column, half in this one
                const mid = (prev + r) / 2
                if (r > prev + 1) {
                    vspan(c - 1, prev + 1, Math.floor(mid))
                    vspan(c, Math.floor(mid) + 1, r - 1)
                } else if (r < prev - 1) {
                    vspan(c - 1, Math.ceil(mid), prev - 1)
                    vspan(c, r + 1, Math.ceil(mid) - 1)
                }
                prev = r
            }
            return
        }

        const lw = Math.max(1.25, unit * 0.75)
        const pad = lw / 2
        const x = i => i / (n - 1) * width
        const y = v => pad + (hi - v) / span * (height - pad * 2)
        ctx.beginPath()
        ctx.moveTo(0, y(pts[0]))
        for (let i = 1; i < n; i++) ctx.lineTo(x(i), y(pts[i]))
        if (fill) {
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.closePath()
            const g = ctx.createLinearGradient(0, 0, 0, height)
            g.addColorStop(0, rgba(0.28))
            g.addColorStop(1, rgba(0))
            ctx.fillStyle = g
            ctx.fill()
            ctx.beginPath()
            ctx.moveTo(0, y(pts[0]))
            for (let i = 1; i < n; i++) ctx.lineTo(x(i), y(pts[i]))
        }
        ctx.lineWidth = lw
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        ctx.strokeStyle = color
        ctx.stroke()
    }
}

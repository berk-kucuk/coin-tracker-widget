/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

import "PixelFont.js" as PF

// Text drawn with the built-in 3x5 bitmap font, `unit` screen pixels per
// font pixel, so it stays crisp at any size.
Canvas {
    id: canvas

    property string text: ""
    property int unit: 2
    property color color: Kirigami.Theme.textColor

    readonly property string glyphs: PF.normalize(text)

    implicitWidth: PF.width(text) * unit
    implicitHeight: PF.H * unit
    width: implicitWidth
    height: implicitHeight

    renderStrategy: Canvas.Cooperative
    antialiasing: false

    onGlyphsChanged: requestPaint()
    onUnitChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    // paints requested while hidden are dropped
    onVisibleChanged: if (visible) requestPaint()
    onAvailableChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = canvas.color
        let x = 0
        for (let i = 0; i < glyphs.length; i++) {
            const rows = PF.glyph(glyphs[i])
            for (let r = 0; r < PF.H; r++) {
                for (let c = 0; c < PF.W; c++) {
                    if (rows[r][c] === "1")
                        ctx.fillRect((x + c) * unit, r * unit, unit, unit)
                }
            }
            x += PF.W + 1
        }
    }
}

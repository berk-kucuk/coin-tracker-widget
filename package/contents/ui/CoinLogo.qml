/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "Coins.js" as Coins
import "PixelFont.js" as PF
import "Palette.js" as Palette

// Coin mark: a 13x13 pixel disc with the symbol's first letter in the pixel
// theme; the coin's own logo (cached by the collector) otherwise, falling
// back to a coloured disc with the letter.
Item {
    id: logo

    property var coin: null
    property real size: 16
    readonly property bool pixel: Plasmoid.configuration.theme === 0

    readonly property color tint: coin ? Coins.color(coin.id) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
    readonly property string letter: coin && coin.symbol ? PF.normalize(coin.symbol)[0] : "?"
    readonly property int cell: Math.max(1, Math.round(size / 13))

    implicitWidth: pixel ? cell * 13 : size
    implicitHeight: implicitWidth
    width: implicitWidth
    height: implicitHeight

    Canvas {
        id: disc
        visible: logo.pixel
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        antialiasing: false

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const c = logo.cell
            const g = PF.glyph(logo.letter)
            ctx.fillStyle = logo.tint
            for (let r = 0; r < 13; r++) {
                for (let col = 0; col < 13; col++) {
                    const inLetter = r >= 4 && r <= 8 && col >= 5 && col <= 7 && g[r - 4][col - 5] === "1"
                    if (Coins.DISC[r][col] === "1" && !inLetter)
                        ctx.fillRect(col * c, r * c, c, c)
                }
            }
        }
    }

    Connections {
        target: logo
        function onTintChanged() { disc.requestPaint() }
        function onLetterChanged() { disc.requestPaint() }
        function onCellChanged() { disc.requestPaint() }
        function onPixelChanged() { if (logo.pixel) disc.requestPaint() }
    }

    Rectangle {
        visible: !logo.pixel && image.status !== Image.Ready
        anchors.fill: parent
        radius: width / 2
        color: logo.tint
        Text {
            anchors.centerIn: parent
            text: logo.coin && logo.coin.symbol ? logo.coin.symbol[0] : "?"
            color: Palette.INK
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: Math.max(6, Math.round(logo.size * 0.55))
            font.weight: Font.Bold
        }
    }

    Image {
        id: image
        visible: !logo.pixel && status === Image.Ready
        anchors.fill: parent
        source: !logo.pixel && logo.coin && logo.coin.image ? logo.coin.image : ""
        sourceSize.width: Math.ceil(logo.size * 2)
        sourceSize.height: Math.ceil(logo.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
    }
}

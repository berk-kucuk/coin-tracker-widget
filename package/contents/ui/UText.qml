/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Theme-aware text: bitmap font in the pixel theme, the system font otherwise.
Item {
    id: t

    property string text
    property int unit: 2              // pixel theme: screen px per font pixel
    property real fontSize: unit * 5.5 // other themes: font pixel size
    property color color: Kirigami.Theme.textColor
    property bool bold: false
    readonly property bool pixel: Plasmoid.configuration.theme === 0

    implicitWidth: pixel ? pixelText.implicitWidth : label.implicitWidth
    implicitHeight: pixel ? pixelText.implicitHeight : label.implicitHeight
    width: implicitWidth
    height: implicitHeight

    PixelText {
        id: pixelText
        visible: t.pixel
        text: t.pixel ? t.text : ""
        unit: t.unit
        color: t.color
    }

    Text {
        id: label
        visible: !t.pixel
        text: t.pixel ? "" : t.text
        color: t.color
        font.family: Kirigami.Theme.defaultFont.family
        font.pixelSize: Math.max(8, Math.round(t.fontSize))
        font.weight: t.bold ? Font.DemiBold : Font.Normal
        font.features: { "tnum": 1 }
    }
}

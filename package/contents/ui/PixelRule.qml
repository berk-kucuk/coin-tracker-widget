/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Dotted pixel divider.
Item {
    id: rule

    property int u: 2

    Layout.fillWidth: true
    implicitHeight: u

    Row {
        spacing: rule.u
        Repeater {
            model: Math.max(0, Math.floor((rule.width + rule.u) / (rule.u * 2)))
            Rectangle {
                width: rule.u
                height: rule.u
                antialiasing: false
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
            }
        }
    }
}

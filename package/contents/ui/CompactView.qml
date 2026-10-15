/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

import "Format.js" as Format
import "Palette.js" as Palette

MouseArea {
    id: compact

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var coins: root.panelCoins
    readonly property bool showIcon: Plasmoid.configuration.showIcon
    readonly property bool showSymbol: Plasmoid.configuration.showSymbol || !showIcon
    readonly property bool showChange: Plasmoid.configuration.showChange
    readonly property bool showSparkline: Plasmoid.configuration.showSparkline
    readonly property bool compactPrices: Plasmoid.configuration.compactPrices
    readonly property bool stale: !!(root.market && root.market.stale)

    // Font pixels needed for price over change, with a margin.
    readonly property int stackedHeight: 14

    // 0 = auto, 1 = stacked, 2 = side by side. Auto stacks only when the
    // panel is thick enough to keep the text readable (3px per font pixel).
    readonly property bool stacked: {
        if (vertical || !showChange) return false
        const mode = Plasmoid.configuration.panelLayout
        if (mode === 1) return true
        if (mode === 2) return false
        return Math.floor(height / stackedHeight) >= 3
    }

    // Base size unit in screen pixels (one font pixel in the pixel theme),
    // chosen so everything fits the panel thickness.
    readonly property int unit: {
        if (vertical)
            return Math.max(1, Math.floor(width / 26))
        return Math.max(1, Math.floor(height / (stacked ? stackedHeight : 9)))
    }
    // The modern theme stops growing past a comfortable panel text size.
    readonly property real fontSize: Math.min(unit * 5.2, 16)
    readonly property real logoSize: stacked ? Math.min(height - 4, unit * 11, root.theme === 0 ? 999 : 28)
                                             : Math.min(height - 2, unit * 8, root.theme === 0 ? 999 : 22)

    Layout.minimumWidth: vertical ? -1 : content.implicitWidth + unit * 2
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? content.implicitHeight + unit * 2 : -1
    Layout.preferredHeight: Layout.minimumHeight

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    hoverEnabled: true
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            root.refresh()
        else
            root.expanded = !root.expanded
    }

    Loader {
        id: content
        anchors.centerIn: parent
        sourceComponent: compact.vertical ? verticalLayout : horizontalLayout
    }

    component Price: UText {
        property var coin
        text: coin ? root.price(coin, compact.compactPrices || compact.vertical) : ""
        unit: compact.unit
        fontSize: compact.fontSize
        bold: root.theme !== 0
    }

    component Change: UText {
        property var coin
        readonly property var v: root.change(coin)
        text: Format.change(v)
        unit: compact.unit
        fontSize: compact.fontSize * (compact.stacked ? 0.85 : 1)
        color: Palette.forChange(v, root.theme) || Qt.rgba(0.5, 0.5, 0.5, 1)
    }

    Component {
        id: horizontalLayout
        Row {
            spacing: compact.unit * 5

            // Nothing loaded yet: a dim mark keeps the widget clickable.
            CoinLogo {
                visible: compact.coins.length === 0
                coin: null
                size: compact.logoSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: compact.coins
                Row {
                    id: cell
                    required property var modelData
                    spacing: compact.unit * 2
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: compact.stale ? 0.55 : 1

                    CoinLogo {
                        visible: compact.showIcon
                        coin: cell.modelData
                        size: compact.logoSize
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    UText {
                        visible: compact.showSymbol
                        anchors.verticalCenter: parent.verticalCenter
                        text: cell.modelData.symbol
                        unit: compact.unit
                        fontSize: compact.fontSize
                        opacity: 0.75
                    }

                    Grid {
                        anchors.verticalCenter: parent.verticalCenter
                        columns: compact.stacked ? 1 : 2
                        rowSpacing: compact.unit * 2
                        columnSpacing: compact.unit * 2
                        verticalItemAlignment: Grid.AlignVCenter

                        Price { coin: cell.modelData }
                        Change { visible: compact.showChange; coin: cell.modelData }
                    }

                    Sparkline {
                        visible: compact.showSparkline
                        anchors.verticalCenter: parent.verticalCenter
                        width: compact.unit * (compact.stacked ? 18 : 14)
                        height: compact.stacked ? compact.unit * 10 : compact.unit * 5
                        unit: root.theme === 0 ? compact.unit : Math.max(1, compact.unit * 0.6)
                        fill: compact.stacked
                        points: root.panelSpark(cell.modelData)
                        color: Palette.forChange(root.change(cell.modelData), root.theme) || "gray"
                    }
                }
            }
        }
    }

    Component {
        id: verticalLayout
        Column {
            spacing: compact.unit * 4

            CoinLogo {
                visible: compact.coins.length === 0
                coin: null
                size: Math.min(compact.width - 2, compact.unit * 9)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Repeater {
                model: compact.coins
                Column {
                    id: vcell
                    required property var modelData
                    spacing: compact.unit * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: compact.stale ? 0.55 : 1

                    CoinLogo {
                        visible: compact.showIcon
                        coin: vcell.modelData
                        size: Math.min(compact.width - 2, compact.unit * 9)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    UText {
                        visible: compact.showSymbol
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: vcell.modelData.symbol
                        unit: compact.unit
                        fontSize: compact.fontSize
                        opacity: 0.75
                    }
                    Price { coin: vcell.modelData; anchors.horizontalCenter: parent.horizontalCenter }
                    Change { visible: compact.showChange; coin: vcell.modelData; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }
    }
}

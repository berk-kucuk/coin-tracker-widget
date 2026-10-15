/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "Format.js" as Format
import "Palette.js" as Palette

Item {
    id: full

    readonly property bool pixel: root.theme === 0

    // Pixel theme: logical px per font pixel (Plasma scales these on HiDPI).
    readonly property int u: 2
    // Modern theme: font sizes derived from the system font.
    readonly property real fs: Math.round(fm.height * 0.75)

    readonly property color dim: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
    readonly property int gap: pixel ? u * 6 : Kirigami.Units.largeSpacing
    readonly property var m: root.market || ({})

    Layout.preferredWidth: pixel ? u * 150 : Kirigami.Units.gridUnit * 18
    Layout.minimumWidth: pixel ? u * 120 : Kirigami.Units.gridUnit * 15
    Layout.preferredHeight: Math.min(body.implicitHeight + gap * 2, Kirigami.Units.gridUnit * 36)
    Layout.minimumHeight: Math.min(body.implicitHeight + gap * 2, Kirigami.Units.gridUnit * 14)

    FontMetrics {
        id: fm
        font: Kirigami.Theme.defaultFont
    }

    function ago(ms) {
        if (!ms) return ""
        const d = root.now - ms
        return d < 60000 ? i18n("just now") : i18n("%1 ago", Format.duration(d))
    }

    function statusText() {
        if (m.error === "rate_limited") return i18n("CoinGecko rate limit, retrying soon")
        if (m.error === "offline") return i18n("Offline")
        if (m.error) return i18n("CoinGecko error (%1)", m.error)
        return ""
    }

    component Divider: Item {
        Layout.fillWidth: true
        implicitHeight: full.pixel ? full.u : 1
        PixelRule {
            visible: full.pixel
            anchors.fill: parent
            u: full.u
        }
        Rectangle {
            visible: !full.pixel
            anchors.fill: parent
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
        }
    }

    // Small, normal and large text in both renderings.
    component Small: UText { unit: full.u; fontSize: full.fs * 0.9; color: full.dim }
    component Normal: UText { unit: full.u; fontSize: full.fs }
    component Large: UText { unit: full.u + 1; fontSize: full.fs * 1.5; bold: true }

    // "24H +1.20%" pill
    component ChangeChip: Row {
        property string label
        property var value
        spacing: full.pixel ? full.u * 2 : Kirigami.Units.smallSpacing
        Small { text: parent.label }
        Small {
            text: Format.change(parent.value)
            color: Palette.forChange(parent.value, root.theme) || full.dim
        }
    }

    component Stat: Row {
        property string label
        property string value
        spacing: full.pixel ? full.u * 2 : Kirigami.Units.smallSpacing
        Small { text: parent.label }
        Small { text: parent.value; color: Kirigami.Theme.textColor }
    }

    QQC2.ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: full.gap
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            id: body
            // keep the right-aligned prices clear of the scroll bar
            width: scroll.availableWidth - (scroll.QQC2.ScrollBar.vertical.visible ? scroll.QQC2.ScrollBar.vertical.width : 0)
            spacing: full.gap

            // ── nothing to show ──────────────────────────────────
            Normal {
                visible: root.loading || root.coins.length === 0
                color: full.dim
                text: root.loading ? i18n("Loading…")
                      : full.m.error ? full.statusText()
                      : i18n("No coins selected")
            }

            Repeater {
                model: root.coins

                ColumnLayout {
                    id: section
                    required property var modelData
                    required property int index
                    readonly property var c: modelData
                    readonly property bool stale: !!full.m.stale
                    Layout.fillWidth: true
                    spacing: full.pixel ? full.u * 3 : Kirigami.Units.smallSpacing

                    Divider { visible: section.index > 0 }

                    // header: logo, name, rank · price, 24h change
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: full.pixel ? full.u * 3 : Kirigami.Units.smallSpacing * 2

                        CoinLogo { coin: section.c; size: full.pixel ? 26 : full.fs * 2.2 }

                        Column {
                            spacing: full.pixel ? full.u * 2 : 0
                            UText { text: section.c.name; unit: full.u + 1; fontSize: full.fs * 1.15; bold: true }
                            // "#" reads as "H" in the bitmap font
                            Small {
                                text: section.c.symbol + (!section.c.rank ? ""
                                      : full.pixel ? " · " + i18n("rank %1", section.c.rank) : " · #" + section.c.rank)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Column {
                            spacing: full.pixel ? full.u * 2 : 0
                            Large {
                                anchors.right: parent.right
                                text: root.price(section.c, false)
                                opacity: section.stale ? 0.5 : 1
                            }
                            Small {
                                anchors.right: parent.right
                                readonly property var v: section.c.change_24h
                                text: Format.change(v) + " · 24h"
                                color: Palette.forChange(v, root.theme) || full.dim
                            }
                        }
                    }

                    // 7-day chart; click to open the coin on CoinGecko
                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: full.pixel ? full.u * 22 : Kirigami.Units.gridUnit * 2.6
                        unit: full.pixel ? full.u : 2
                        points: section.c.spark || []
                        color: Palette.forChange(section.c.change_7d, root.theme) || Kirigami.Theme.textColor
                        dimmed: section.stale

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://www.coingecko.com/en/coins/" + encodeURIComponent(section.c.id))
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: full.pixel ? full.u * 6 : Kirigami.Units.largeSpacing
                        ChangeChip { label: "1H"; value: section.c.change_1h }
                        ChangeChip { label: "24H"; value: section.c.change_24h }
                        ChangeChip { label: "7D"; value: section.c.change_7d }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: full.pixel ? full.u * 6 : Kirigami.Units.largeSpacing
                        Stat {
                            visible: section.c.low_24h !== null && section.c.high_24h !== null
                            label: i18n("24h")
                            value: Format.number(section.c.low_24h) + " – " + Format.number(section.c.high_24h)
                        }
                        Stat { visible: !!section.c.market_cap; label: i18n("Cap"); value: Format.big(section.c.market_cap) }
                        Stat { visible: !!section.c.volume; label: i18n("Vol"); value: Format.big(section.c.volume) }
                        Stat {
                            visible: !!section.c.ath
                            label: i18n("ATH")
                            value: Format.number(section.c.ath) + (section.c.ath_change !== null ? " (" + Format.change(section.c.ath_change) + ")" : "")
                        }
                    }
                }
            }

            // ── footer: coins not found, source, freshness ───────
            Divider { visible: root.coins.length > 0 }

            Small {
                visible: (full.m.missing || []).length > 0
                Layout.fillWidth: true
                text: i18n("Not found: %1", (full.m.missing || []).join(", "))
                color: Palette.ORANGE
            }

            RowLayout {
                visible: !root.loading && root.coins.length > 0
                Layout.fillWidth: true
                Small { text: "CoinGecko · " + String(root.currency).toUpperCase() }
                Item { Layout.fillWidth: true }
                Small {
                    text: full.statusText() || full.ago(full.m.updated_at)
                    color: full.m.stale || full.m.error ? Palette.ORANGE : full.dim
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.refresh()
    }
}

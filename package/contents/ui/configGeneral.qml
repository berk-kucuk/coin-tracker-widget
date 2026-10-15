/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_theme: themeBox.currentIndex
    property string cfg_coins
    property string cfg_currency
    property alias cfg_refreshSeconds: refresh.value
    property alias cfg_changeWindow: windowBox.currentIndex
    property alias cfg_panelMaxCoins: maxCoins.value
    property alias cfg_panelLayout: layoutBox.currentIndex
    property alias cfg_showIcon: showIcon.checked
    property alias cfg_showSymbol: showSymbol.checked
    property alias cfg_showChange: showChange.checked
    property alias cfg_showSparkline: showSparkline.checked
    property alias cfg_compactPrices: compactPrices.checked

    readonly property var currencies: ["usd", "eur", "try", "gbp", "jpy", "cny", "krw", "inr", "rub",
                                       "cad", "aud", "chf", "brl", "btc", "eth"]
    readonly property var coinList: cfg_coins.split(",").filter(s => s)

    function setCoins(list) {
        cfg_coins = list.join(",")
    }

    function addCoin(text) {
        const list = coinList.slice()
        for (const raw of text.split(/[,\s]+/)) {
            const id = raw.trim().toLowerCase()
            if (id && list.indexOf(id) === -1) list.push(id)
        }
        setCoins(list)
    }

    function moveCoin(i, by) {
        const list = coinList.slice()
        const j = i + by
        if (j < 0 || j >= list.length) return
        const t = list[i]
        list[i] = list[j]
        list[j] = t
        setCoins(list)
    }

    function removeCoin(i) {
        const list = coinList.slice()
        list.splice(i, 1)
        setCoins(list)
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: themeBox
            Kirigami.FormData.label: i18n("Theme:")
            model: [i18n("Pixel"), i18n("Modern")]
        }

        Item { Kirigami.FormData.isSection: true }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Coins:")
            Layout.minimumWidth: Kirigami.Units.gridUnit * 16
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: page.coinList
                RowLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideRight
                    }
                    QQC2.ToolButton {
                        icon.name: "arrow-up"
                        enabled: index > 0
                        onClicked: page.moveCoin(index, -1)
                        QQC2.ToolTip.text: i18n("Move up")
                        QQC2.ToolTip.visible: hovered
                    }
                    QQC2.ToolButton {
                        icon.name: "arrow-down"
                        enabled: index < page.coinList.length - 1
                        onClicked: page.moveCoin(index, 1)
                        QQC2.ToolTip.text: i18n("Move down")
                        QQC2.ToolTip.visible: hovered
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        onClicked: page.removeCoin(index)
                        QQC2.ToolTip.text: i18n("Remove")
                        QQC2.ToolTip.visible: hovered
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.TextField {
                    id: newCoin
                    Layout.fillWidth: true
                    placeholderText: i18n("btc, sol or a CoinGecko id")
                    onAccepted: if (text.trim()) { page.addCoin(text); text = "" }
                }
                QQC2.Button {
                    icon.name: "list-add"
                    text: i18n("Add")
                    enabled: newCoin.text.trim() !== ""
                    onClicked: { page.addCoin(newCoin.text); newCoin.text = "" }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 20
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                text: i18n("Tickers are matched to CoinGecko coins. For a token that shares its ticker with others, use its id from the coin's CoinGecko page (e.g. \"avalanche-2\").")
            }
        }

        QQC2.ComboBox {
            id: currencyBox
            Kirigami.FormData.label: i18n("Currency:")
            model: page.currencies.map(c => c.toUpperCase())
            currentIndex: Math.max(0, page.currencies.indexOf(page.cfg_currency))
            onActivated: index => page.cfg_currency = page.currencies[index]
        }

        QQC2.ComboBox {
            id: windowBox
            Kirigami.FormData.label: i18n("Change over:")
            model: [i18n("1 hour"), i18n("24 hours"), i18n("7 days")]
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: maxCoins
            Kirigami.FormData.label: i18n("Coins in panel:")
            from: 1
            to: 10
        }

        QQC2.ComboBox {
            id: layoutBox
            Kirigami.FormData.label: i18n("Panel layout:")
            model: [
                i18n("Automatic (stacked on thick panels)"),
                i18n("Stacked"),
                i18n("Side by side")
            ]
        }

        QQC2.CheckBox {
            id: showIcon
            Kirigami.FormData.label: i18n("Panel:")
            text: i18n("Show coin icons")
        }

        QQC2.CheckBox {
            id: showSymbol
            text: i18n("Show ticker symbols")
        }

        QQC2.CheckBox {
            id: showChange
            text: i18n("Show price change")
        }

        QQC2.CheckBox {
            id: showSparkline
            text: i18n("Show mini chart")
        }

        QQC2.CheckBox {
            id: compactPrices
            text: i18n("Shorten large prices (83.5K)")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: refresh
            Kirigami.FormData.label: i18n("Refresh every:")
            from: 60
            to: 3600
            stepSize: 30
            textFromValue: (v) => i18np("%1 second", "%1 seconds", v)
            valueFromText: (t) => parseInt(t)
        }
    }
}

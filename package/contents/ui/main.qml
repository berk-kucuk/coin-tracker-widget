/*
    SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

import "Format.js" as Format

PlasmoidItem {
    id: root

    // Latest collector output (see contents/code/collector.py).
    property var market: null
    property double now: Date.now()

    readonly property bool loading: market === null
    // 0 = pixel, 1 = modern
    readonly property int theme: Plasmoid.configuration.theme
    readonly property string currency: market && market.currency ? market.currency : Plasmoid.configuration.currency
    readonly property var coins: market && market.coins ? market.coins : []
    readonly property var panelCoins: coins.slice(0, Math.max(1, Plasmoid.configuration.panelMaxCoins))

    // The change shown in the panel and tooltip: 1 hour, 24 hours or 7 days.
    readonly property int changeWindow: Plasmoid.configuration.changeWindow
    readonly property string changeKey: ["change_1h", "change_24h", "change_7d"][changeWindow] || "change_24h"
    readonly property string changeLabel: ["1h", "24h", "7d"][changeWindow] || "24h"

    readonly property string collectorPath: decodeURIComponent(Qt.resolvedUrl("../code/collector.py").toString().replace(/^file:\/\//, ""))
    readonly property string collectorCommand: "python3 " + quote(collectorPath)
                                               + " --coins " + quote(Plasmoid.configuration.coins)
                                               + " --currency " + quote(Plasmoid.configuration.currency)

    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function change(coin) {
        return coin ? coin[changeKey] : null
    }

    function price(coin, compact) {
        return Format.money(coin.price, currency, compact)
    }

    // Sparkline points for the panel: the last day, or the week for 7d.
    function panelSpark(coin) {
        const s = coin.spark || []
        return changeWindow === 2 ? s : s.slice(-25)
    }

    function refresh() {
        executable.connectSource(collectorCommand)
    }

    Plasmoid.icon: "coin-tracker"

    toolTipMainText: i18n("Coin Tracker")
    toolTipSubText: {
        if (loading) return i18n("Loading…")
        if (coins.length === 0)
            return market.error ? i18n("Can't reach CoinGecko") : i18n("No coins selected")
        return coins.map(c => c.symbol + "  " + price(c, false) + "  " + Format.change(change(c)) + " (" + changeLabel + ")").join("\n")
    }

    // Prices in panels, the full card when placed on the desktop.
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
                             ? compactRepresentation : fullRepresentation
    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            // a reply for coins/currency the user has since changed
            if (source !== root.collectorCommand) return
            const out = String(data["stdout"] || "").trim()
            if (!out) return
            try {
                root.market = JSON.parse(out)
            } catch (e) {
                console.warn("coin-tracker: bad collector output", e)
            }
        }
    }

    Timer {
        interval: Math.max(60, Plasmoid.configuration.refreshSeconds) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    // New coin list or currency: fetch right away.
    onCollectorCommandChanged: refresh()
    onExpandedChanged: if (root.expanded) root.refresh()

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        },
        PlasmaCore.Action {
            text: i18n("Open CoinGecko")
            icon.name: "internet-web-browser"
            onTriggered: Qt.openUrlExternally("https://www.coingecko.com/")
        }
    ]
}

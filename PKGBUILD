# SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
# SPDX-License-Identifier: GPL-3.0-or-later
# Maintainer: berkkucukk <berkkucukk@proton.me>

pkgname=plasma6-applets-coin-tracker
_appletid=com.github.berkkucukk.cointracker
pkgver=1.0.0
pkgrel=1
pkgdesc="KDE Plasma 6 widget showing live cryptocurrency prices and 7-day charts from CoinGecko"
arch=('any')
license=('GPL-3.0-or-later')
depends=('plasma-workspace' 'python' 'libplasma' 'kirigami' 'kcmutils' 'plasma5support')
source=()

# Built from the local checkout this PKGBUILD lives in.
package() {
    local src="$startdir/package"
    local dest="$pkgdir/usr/share/plasma/plasmoids/$_appletid"

    install -Dm644 "$src/metadata.json" "$dest/metadata.json"
    # Python bytecode is a by-product of running the collector from the
    # checkout, not part of the widget.
    find "$src/contents" -type f -not -path '*/__pycache__/*' -not -name '*.pyc' | while read -r f; do
        install -Dm644 "$f" "$dest/${f#"$src/"}"
    done
    chmod 755 "$dest/contents/code/collector.py"

    install -Dm644 "$startdir/icons/coin-tracker.svg" \
        "$pkgdir/usr/share/icons/hicolor/scalable/apps/coin-tracker.svg"
    install -Dm644 "$startdir/README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}

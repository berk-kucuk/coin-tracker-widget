# Coin Tracker

A KDE Plasma 6 widget that shows live cryptocurrency prices in the panel or on
the desktop: price, change over 1 hour / 24 hours / 7 days and a 7-day chart
for every coin you pick. It comes with two themes (Pixel, Modern) and fits
thin panels by putting price and change side by side.

Data comes from [CoinGecko](https://www.coingecko.com/)'s public API. No
account or API key is needed.

## Features

- **Any coin on CoinGecko:** add coins by ticker (`btc`, `sol`, `pepe`) or by CoinGecko id (`avalanche-2`); tickers are resolved once and remembered
- **Currencies:** USD, EUR, TRY, GBP, JPY, CNY, KRW, INR, RUB, CAD, AUD, CHF, BRL, or priced in BTC / ETH
- **Themes:** Pixel (built-in bitmap font, pixel badges and charts), Modern (system font, coin logos, smooth charts)
- **Panel:** icon, ticker, price, change and an optional mini chart per coin; stacked on thick panels, side by side on thin ones; vertical panels are supported too
- **Popup:** 7-day chart, 1h / 24h / 7d change, 24h range, market cap, volume, all-time high; click a chart to open the coin on CoinGecko
- **Settings:** coin list and order, currency, which change the panel shows, how many coins go in the panel, refresh interval

## Install

Arch / Maze Linux:

```bash
makepkg -si
```

Any distro:

```bash
kpackagetool6 -t Plasma/Applet -i package
```

Then right-click the panel → *Add Widgets…* → **Coin Tracker**. Requires
`python3` (standard library only).

Update or remove a `kpackagetool6` install:

```bash
kpackagetool6 -t Plasma/Applet -u package
```

```bash
kpackagetool6 -t Plasma/Applet -r com.github.berkkucukk.cointracker
```

## How it fetches

All coins are fetched in one call to `api.coingecko.com/api/v3/coins/markets`.
Responses are cached in `~/.cache/coin-tracker-plasmoid/` for at least a
minute, whatever the refresh interval, so several widgets or a quick
open/close of the popup don't add requests. When CoinGecko rate-limits (HTTP
429) the widget backs off for five minutes and keeps showing the last
reading. Readings older than 15 minutes are dimmed and the popup says why.

Coin logos for the Modern theme are downloaded once into the same cache
directory.

## Development

Demo data, for screenshots or working offline:

```bash
COIN_TRACKER_DEMO=1 python3 package/contents/code/collector.py
```

Try the collector against the live API:

```bash
python3 package/contents/code/collector.py --coins btc,eth,sol --currency try
```

## License

GPL-3.0-or-later

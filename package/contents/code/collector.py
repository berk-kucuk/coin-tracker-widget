#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 berkkucukk <berkkucukk@proton.me>
# SPDX-License-Identifier: GPL-3.0-or-later
"""Price collector for the Coin Tracker plasmoid.

    collector.py [--coins bitcoin,eth,sol] [--currency usd]

Prints one JSON object on stdout with the market data of the requested coins
from CoinGecko's public API (no account or key needed). Coins can be given
as CoinGecko ids ("bitcoin") or ticker symbols ("btc"); symbols are resolved
once through CoinGecko's search and remembered.

All requested coins are fetched in a single call, cached for at least a
minute, with backoff when CoinGecko rate-limits. When the network is down the
last good reading is shown and marked stale.

Only the Python standard library is used.
"""

import hashlib
import json
import math
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
XDG_CACHE = os.environ.get("XDG_CACHE_HOME") or os.path.join(HOME, ".cache")
CACHE_DIR = os.path.join(XDG_CACHE, "coin-tracker-plasmoid")
IMG_DIR = os.path.join(CACHE_DIR, "img")
RESOLVE_CACHE = os.path.join(CACHE_DIR, "resolve.json")

API = "https://api.coingecko.com/api/v3"
API_MIN_INTERVAL = 60           # seconds between calls for one coin list
API_BACKOFF = 300               # after 429 / server errors
STALE_AFTER = 15 * 60
RESOLVE_RETRY = 24 * 3600       # retry unknown symbols once a day
USER_AGENT = "coin-tracker-plasmoid/1.0"
MAX_COINS = 25

# Common tickers, so the usual coins never need a search call.
SYMBOLS = {
    "btc": "bitcoin", "eth": "ethereum", "sol": "solana", "bnb": "binancecoin",
    "xrp": "ripple", "ada": "cardano", "doge": "dogecoin", "dot": "polkadot",
    "avax": "avalanche-2", "ltc": "litecoin", "link": "chainlink", "trx": "tron",
    "ton": "the-open-network", "pol": "polygon-ecosystem-token", "matic": "polygon-ecosystem-token",
    "shib": "shiba-inu", "usdt": "tether", "usdc": "usd-coin", "xlm": "stellar",
    "atom": "cosmos", "near": "near", "sui": "sui", "pepe": "pepe", "xmr": "monero",
    "bch": "bitcoin-cash", "etc": "ethereum-classic", "uni": "uniswap", "apt": "aptos",
    "arb": "arbitrum", "op": "optimism", "fil": "filecoin", "icp": "internet-computer",
    "hbar": "hedera-hashgraph", "kas": "kaspa", "hype": "hyperliquid", "dai": "dai",
    "wbtc": "wrapped-bitcoin", "aave": "aave", "inj": "injective-protocol",
    "rndr": "render-token", "render": "render-token", "tao": "bittensor", "algo": "algorand",
    "vet": "vechain", "xtz": "tezos", "eos": "eos", "sand": "the-sandbox", "mana": "decentraland",
    "bonk": "bonk", "wif": "dogwifcoin", "trump": "official-trump", "ena": "ethena",
}


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------

def now_ms():
    return int(time.time() * 1000)


def read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def write_json(path, data):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp, path)
    except OSError:
        pass


def num(v):
    try:
        v = float(v)
    except (TypeError, ValueError):
        return None
    return None if v != v or math.isinf(v) else v


def sig(v, digits=6):
    """Round to significant digits: keeps the JSON small for sparklines."""
    if not v:
        return v
    return round(v, max(0, digits - 1 - int(math.floor(math.log10(abs(v))))))


def http_json(url, timeout=8):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def cached_get(key, url, min_interval=API_MIN_INTERVAL):
    """GET JSON with a per-request cache and backoff.

    Returns (payload, fetched_at_ms, error). The payload is the freshest
    successful response, possibly old; errors never raise.
    """
    path = os.path.join(CACHE_DIR, "api-%s.json" % key)
    cache = read_json(path) or {}
    t = now_ms()
    if t - cache.get("fetched_at", 0) >= min_interval * 1000 and t >= cache.get("retry_after", 0):
        try:
            payload = http_json(url)
            cache = {"fetched_at": t, "payload": payload}
        except urllib.error.HTTPError as e:
            cache["retry_after"] = t + (API_BACKOFF if e.code == 429 or e.code >= 500 else API_MIN_INTERVAL) * 1000
            cache["last_error"] = "rate_limited" if e.code == 429 else "http_%d" % e.code
        except (urllib.error.URLError, OSError, ValueError):
            cache["retry_after"] = t + API_MIN_INTERVAL * 1000
            cache["last_error"] = "offline"
        write_json(path, cache)
    # a successful call replaces the whole cache, so an error sticks until then
    return cache.get("payload"), cache.get("fetched_at"), cache.get("last_error")


# --------------------------------------------------------------------------
# coin ids
# --------------------------------------------------------------------------

def parse_terms(text):
    out = []
    for s in str(text or "").split(","):
        s = s.strip().lower()
        if s and s not in out:
            out.append(s)
    return out[:MAX_COINS]


def resolve(term, cache):
    hit = cache.get(term)
    if hit and hit.get("id"):
        return hit["id"]
    return SYMBOLS.get(term, term)


def search(term, cache):
    """Look a symbol or name up on CoinGecko. Returns the id or None."""
    hit = cache.get(term)
    if hit and now_ms() - hit.get("at", 0) < RESOLVE_RETRY * 1000:
        return hit.get("id")
    found = None
    try:
        res = http_json(API + "/search?query=" + urllib.parse.quote(term))
        coins = res.get("coins") or []
        # exact symbol first (most coins share symbols with tiny tokens, the
        # search ranks by market cap), then exact id/name, then the top hit
        for c in coins:
            if str(c.get("symbol", "")).lower() == term:
                found = c.get("id")
                break
        if not found:
            for c in coins:
                if term in (str(c.get("id", "")).lower(), str(c.get("name", "")).lower()):
                    found = c.get("id")
                    break
        if not found and coins:
            found = coins[0].get("id")
    except (urllib.error.URLError, OSError, ValueError):
        return None  # don't remember network failures
    cache[term] = {"id": found, "at": now_ms()}
    return found


# --------------------------------------------------------------------------
# market data
# --------------------------------------------------------------------------

def markets_url(ids, currency):
    q = urllib.parse.urlencode({
        "vs_currency": currency,
        "ids": ",".join(ids),
        "sparkline": "true",
        "price_change_percentage": "1h,24h,7d",
        "per_page": len(ids),
    })
    return API + "/coins/markets?" + q


def fetch_markets(ids, currency):
    key = hashlib.sha1((currency + ":" + ",".join(sorted(ids))).encode()).hexdigest()[:16]
    payload, fetched, error = cached_get("markets-" + key, markets_url(ids, currency))
    rows = payload if isinstance(payload, list) else []
    return {str(r.get("id")): r for r in rows if isinstance(r, dict)}, fetched, error


def cached_image(coin_id, url):
    """Download the coin's small logo once; returns a file:// URL or ""."""
    if not url:
        return ""
    path = os.path.join(IMG_DIR, coin_id.replace("/", "_") + ".png")
    if not os.path.exists(path):
        try:
            os.makedirs(IMG_DIR, exist_ok=True)
            req = urllib.request.Request(url.replace("/large/", "/small/"), headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = resp.read(512 * 1024)
            tmp = path + ".tmp"
            with open(tmp, "wb") as f:
                f.write(data)
            os.replace(tmp, path)
        except (urllib.error.URLError, OSError, ValueError):
            return ""
    return "file://" + urllib.parse.quote(path)


def coin_out(r):
    spark = ((r.get("sparkline_in_7d") or {}).get("price") or [])
    spark = [sig(v) for v in (num(x) for x in spark) if v is not None]
    return {
        "id": r.get("id"),
        "symbol": str(r.get("symbol") or "").upper(),
        "name": r.get("name") or r.get("id"),
        "rank": r.get("market_cap_rank"),
        "price": num(r.get("current_price")),
        "change_1h": num(r.get("price_change_percentage_1h_in_currency")),
        "change_24h": num(r.get("price_change_percentage_24h_in_currency", r.get("price_change_percentage_24h"))),
        "change_7d": num(r.get("price_change_percentage_7d_in_currency")),
        "high_24h": num(r.get("high_24h")),
        "low_24h": num(r.get("low_24h")),
        "market_cap": num(r.get("market_cap")),
        "volume": num(r.get("total_volume")),
        "ath": num(r.get("ath")),
        "ath_change": num(r.get("ath_change_percentage")),
        "image": cached_image(str(r.get("id")), r.get("image")),
        "spark": spark,
    }


def collect(terms, currency):
    rcache = read_json(RESOLVE_CACHE) or {}

    def ids_for():
        return list(dict.fromkeys(resolve(t, rcache) for t in terms))

    rows, fetched, error = fetch_markets(ids_for(), currency) if terms else ({}, None, None)

    # Terms CoinGecko didn't take as ids (symbols, names): search them once
    # and refetch with what was found.
    checked = bool(terms) and not error
    if checked:
        changed = False
        for t in terms:
            if resolve(t, rcache) not in rows:
                found = search(t, rcache)
                changed = changed or bool(found and found not in rows)
        write_json(RESOLVE_CACHE, rcache)
        if changed:
            rows, fetched, error = fetch_markets(ids_for(), currency)

    coins, missing = [], []
    for i in ids_for():
        if i in rows:
            coins.append(coin_out(rows[i]))
    if checked and not error:
        missing = [t for t in terms if resolve(t, rcache) not in rows]

    t = now_ms()
    return {
        "version": 1,
        "generated_at": t,
        "source": "coingecko",
        "currency": currency,
        "updated_at": fetched,
        "stale": bool(coins) and (not fetched or t - fetched > STALE_AFTER * 1000),
        "error": error,
        "coins": coins,
        "missing": missing,
    }


# --------------------------------------------------------------------------
# demo data (COIN_TRACKER_DEMO=1), for screenshots
# --------------------------------------------------------------------------

def demo_spark(start, end, wiggle, seed):
    out = []
    for i in range(168):
        f = i / 167
        v = start + (end - start) * f
        v += wiggle * (math.sin(i / 7.0 + seed) + 0.5 * math.sin(i / 2.3 + seed * 2) + 0.3 * math.sin(i * 1.7))
        out.append(sig(v))
    return out


def demo(currency):
    t = now_ms()

    def c(cid, sym, name, rank, price, h1, d1, w1, cap, vol, wiggle, seed):
        start = price / (1 + w1 / 100)
        return {"id": cid, "symbol": sym, "name": name, "rank": rank, "price": price,
                "change_1h": h1, "change_24h": d1, "change_7d": w1,
                "high_24h": price * 1.018, "low_24h": price * 0.962, "market_cap": cap, "volume": vol,
                "ath": price * 1.51, "ath_change": -33.8, "image": "",
                "spark": demo_spark(start, price, price * wiggle, seed)}

    return {"version": 1, "generated_at": t, "source": "coingecko", "currency": currency,
            "updated_at": t - 40000, "stale": False, "error": None, "missing": [], "coins": [
                c("bitcoin", "BTC", "Bitcoin", 1, 83468.0, 0.31, 1.20, -2.48, 1.6775e12, 3.25e10, 0.006, 1),
                c("ethereum", "ETH", "Ethereum", 2, 3127.42, -0.42, -1.84, 4.12, 3.77e11, 1.84e10, 0.011, 2),
                c("solana", "SOL", "Solana", 7, 142.87, 1.12, 5.37, 11.9, 7.4e10, 4.1e9, 0.02, 3),
                c("dogecoin", "DOGE", "Dogecoin", 9, 0.1842, -0.05, -3.21, -6.7, 2.7e10, 1.2e9, 0.018, 4),
            ]}


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def arg(name, default):
    if name in sys.argv:
        i = sys.argv.index(name)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


def main():
    terms = parse_terms(arg("--coins", "bitcoin,ethereum,solana"))
    currency = arg("--currency", "usd").strip().lower() or "usd"
    if os.environ.get("COIN_TRACKER_DEMO"):
        out = demo(currency)
    else:
        try:
            out = collect(terms, currency)
        except Exception as e:  # the widget must always get valid JSON
            out = {"version": 1, "generated_at": now_ms(), "currency": currency, "coins": [],
                   "missing": [], "stale": False, "updated_at": None, "error": str(e)}
    sys.stdout.write(json.dumps(out, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()

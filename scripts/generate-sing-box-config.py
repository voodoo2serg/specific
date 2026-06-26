#!/usr/bin/env python3
import argparse
import json
import os
import sys
from urllib.parse import urlparse, parse_qs

DEFAULT_RU_DIRECT_DOMAINS = [
    "gosuslugi.ru", "esia.gosuslugi.ru", "nalog.gov.ru", "nalog.ru", "mos.ru", "mosreg.ru",
    "sberbank.ru", "online.sberbank.ru", "tbank.ru", "alfabank.ru", "vtb.ru", "gazprombank.ru",
    "pochtabank.ru", "raiffeisen.ru", "ozon.ru", "wildberries.ru", "market.yandex.ru",
    "yandex.ru", "dzen.ru", "vk.com", "ok.ru", "mail.ru", "rambler.ru"
]


def read_domain_file(path):
    domains = []
    if not path:
        return []
    if not os.path.exists(path):
        raise FileNotFoundError(f"Domain file not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            item = line.strip().lower()
            if not item or item.startswith("#"):
                continue
            if "://" in item:
                item = urlparse(item).hostname or item
            item = item.strip("./")
            if item and item not in domains:
                domains.append(item)
    return domains


def parse_vless(link, tag):
    p = urlparse(link.strip())
    if p.scheme != "vless":
        raise ValueError("Only vless:// links are supported")
    uuid = p.username
    server = p.hostname
    port = p.port or 443
    q = {k: v[0] for k, v in parse_qs(p.query).items()}
    if not uuid or not server:
        raise ValueError("Invalid VLESS link: missing UUID or server")
    return {
        "type": "vless",
        "tag": tag,
        "server": server,
        "server_port": port,
        "uuid": uuid,
        "flow": q.get("flow", "xtls-rprx-vision"),
        "tls": {
            "enabled": True,
            "server_name": q.get("sni", server),
            "utls": {"enabled": True, "fingerprint": q.get("fp", "chrome")},
            "reality": {
                "enabled": True,
                "public_key": q.get("pbk", ""),
                "short_id": q.get("sid", "")
            }
        },
        "packet_encoding": "xudp"
    }


def make_base(ru_direct_domains):
    return {
        "log": {"level": "info", "timestamp": True},
        "dns": {
            "servers": [
                {"tag": "proxy-dns", "address": "https://1.1.1.1/dns-query", "detour": "foreign"},
                {"tag": "local-dns", "address": "local", "detour": "direct"}
            ],
            "rules": [
                {"domain_suffix": ru_direct_domains, "server": "local-dns"}
            ],
            "final": "proxy-dns",
            "strategy": "prefer_ipv4"
        },
        "inbounds": [
            {
                "type": "tun",
                "tag": "tun-in",
                "interface_name": "voodoo0",
                "address": ["172.19.0.1/30"],
                "auto_route": True,
                "strict_route": True,
                "sniff": True
            }
        ],
        "outbounds": [
            {"type": "direct", "tag": "direct"},
            {"type": "block", "tag": "block"}
        ],
        "route": {
            "auto_detect_interface": True,
            "rules": [
                {"ip_is_private": True, "outbound": "direct"},
                {"protocol": "dns", "outbound": "direct"}
            ],
            "final": "foreign"
        }
    }


def main():
    ap = argparse.ArgumentParser(description="Generate sing-box client config from VLESS REALITY links.")
    ap.add_argument("--mode", choices=["full-foreign", "ru-compatible"], required=True)
    ap.add_argument("--foreign-link", required=True, help="VLESS link for the foreign VPS")
    ap.add_argument("--ru-link", help="Optional VLESS link for RU VPS")
    ap.add_argument("--ru-direct-domains-file", default="rules/ru-direct-domains.txt", help="Plain-text domain list for direct routing in ru-compatible mode")
    ap.add_argument("--output", default="sing-box-config.json")
    ap.add_argument("--profile-name", default="Voodoo VPN")
    args = ap.parse_args()

    if args.mode == "ru-compatible" and args.ru_direct_domains_file:
        try:
            ru_direct_domains = read_domain_file(args.ru_direct_domains_file)
        except FileNotFoundError:
            ru_direct_domains = DEFAULT_RU_DIRECT_DOMAINS
    else:
        ru_direct_domains = DEFAULT_RU_DIRECT_DOMAINS

    if not ru_direct_domains:
        ru_direct_domains = DEFAULT_RU_DIRECT_DOMAINS

    cfg = make_base(ru_direct_domains)
    foreign = parse_vless(args.foreign_link, "foreign")
    cfg["outbounds"].insert(0, foreign)

    if args.ru_link:
        cfg["outbounds"].insert(1, parse_vless(args.ru_link, "ru-exit"))

    if args.mode == "full-foreign":
        cfg["route"]["rules"] = [
            {"ip_is_private": True, "outbound": "direct"},
            {"protocol": "dns", "outbound": "foreign"}
        ]
        cfg["route"]["final"] = "foreign"
        cfg["dns"]["final"] = "proxy-dns"
        cfg["dns"]["rules"] = []
    else:
        cfg["route"]["rules"] = [
            {"ip_is_private": True, "outbound": "direct"},
            {"domain_suffix": ru_direct_domains, "outbound": "direct"},
            {"domain_suffix": ["ru", "su", "рф", "xn--p1ai"], "outbound": "direct"},
            {"rule_set": ["geoip-ru", "geosite-ru"], "outbound": "direct"},
            {"protocol": "dns", "outbound": "direct"}
        ]
        cfg["route"]["rule_set"] = [
            {
                "tag": "geoip-ru",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs",
                "download_detour": "foreign"
            },
            {
                "tag": "geosite-ru",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-ru.srs",
                "download_detour": "foreign"
            }
        ]
        cfg["route"]["final"] = "foreign"

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Written: {args.output}")
    if args.mode == "ru-compatible":
        print(f"Direct domains loaded: {len(ru_direct_domains)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

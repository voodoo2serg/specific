#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-global}"

case "$REGION" in
  us|usa|US|USA)
    CANDIDATES=("www.microsoft.com" "www.cloudflare.com" "www.apple.com" "www.bing.com") ;;
  eu|europe|de|nl|EU|DE|NL)
    CANDIDATES=("www.microsoft.com" "www.cloudflare.com" "www.apple.com" "www.mozilla.org") ;;
  asia|sg|jp|ASIA|SG|JP)
    CANDIDATES=("www.microsoft.com" "www.cloudflare.com" "www.apple.com" "www.samsung.com") ;;
  ru|russia|RU)
    CANDIDATES=("www.yandex.ru" "mail.ru" "www.ozon.ru" "www.vk.com") ;;
  *)
    CANDIDATES=("www.microsoft.com" "www.cloudflare.com" "www.apple.com" "www.mozilla.org" "www.yandex.ru") ;;
esac

if [ "$#" -gt 1 ]; then
  shift
  CANDIDATES=("$@")
fi

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}
need openssl
need curl

printf '%-28s %-8s %-8s %-10s %-8s %s\n' "HOST" "TLS1.3" "H2" "REDIRECT" "HTTP" "SUGGESTED"
for host in "${CANDIDATES[@]}"; do
  tls="no"; h2="no"; redir="unknown"; code="-"; suggestion="avoid"
  out="$(echo | timeout 10 openssl s_client -connect "${host}:443" -servername "$host" -tls1_3 -alpn h2 2>/dev/null || true)"
  if printf '%s' "$out" | grep -q "Protocol  *: TLSv1.3"; then tls="yes"; fi
  if printf '%s' "$out" | grep -q "ALPN protocol: h2"; then h2="yes"; fi
  hdr="$(timeout 10 curl -k -I -L --max-redirs 0 -s -o /tmp/voodoo_headers.$$ -w '%{http_code} %{redirect_url}' "https://${host}/" 2>/dev/null || true)"
  code="$(printf '%s' "$hdr" | awk '{print $1}')"
  loc="$(printf '%s' "$hdr" | cut -d' ' -f2-)"
  rm -f /tmp/voodoo_headers.$$
  if [ -n "$loc" ]; then redir="yes"; else redir="no"; fi
  if [ "$tls" = "yes" ] && [ "$h2" = "yes" ] && [ "$redir" = "no" ]; then suggestion="good"; fi
  printf '%-28s %-8s %-8s %-10s %-8s %s\n' "$host" "$tls" "$h2" "$redir" "$code" "$suggestion"
done

echo
echo "Use a candidate marked 'good' as: REALITY_SNI=host and REALITY_DEST=host:443"
echo "Run this script on each VPS region; results depend on the VPS network path."

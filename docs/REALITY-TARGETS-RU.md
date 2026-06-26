# Проверка REALITY_DEST по регионам

REALITY_DEST нельзя выбирать только по бренду. Его нужно проверять с конкретного VPS, потому что важны сетевой путь, TLS-поведение и доступность из региона.

## Что проверяем

Хороший кандидат обычно имеет:

```text
TLS 1.3: да
ALPN h2: да
редирект с корня: желательно нет
стабильная доступность из региона VPS: да
```

## Скрипт проверки

На каждом VPS запустите:

```bash
sudo apt-get update && sudo apt-get install -y openssl curl
bash scripts/check-reality-targets.sh us
bash scripts/check-reality-targets.sh eu
bash scripts/check-reality-targets.sh asia
bash scripts/check-reality-targets.sh ru
```

Можно проверить свои домены:

```bash
bash scripts/check-reality-targets.sh custom www.microsoft.com www.cloudflare.com www.apple.com
```

Если строка помечена `good`, используйте:

```bash
REALITY_SNI="host"
REALITY_DEST="host:443"
```

## Базовые кандидаты

US:

```text
www.microsoft.com
www.cloudflare.com
www.apple.com
www.bing.com
```

EU:

```text
www.microsoft.com
www.cloudflare.com
www.apple.com
www.mozilla.org
```

Asia:

```text
www.microsoft.com
www.cloudflare.com
www.apple.com
www.samsung.com
```

RU:

```text
www.yandex.ru
mail.ru
www.ozon.ru
www.vk.com
```

## Важное ограничение

Скрипт не гарантирует неблокируемость. Он только помогает не выбрать явно плохой REALITY_DEST. Проверку надо повторять отдельно на каждом VPS и после смены провайдера.

# Домены-исключения для RU Compatible

Файл с доменами-исключениями находится здесь:

```bash
rules/ru-direct-domains.txt
```

Эти домены в профиле `RU Compatible` идут напрямую (`direct`), минуя зарубежный VPS. Это нужно для Госуслуг, банков, налоговой, маркетплейсов и других российских сервисов, которые часто ломаются при зарубежном VPN.

## Как добавить домен

Откройте файл:

```bash
nano rules/ru-direct-domains.txt
```

Добавьте домен отдельной строкой:

```text
example.ru
login.example.ru
```

Затем заново сгенерируйте sing-box-конфиг:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://...' \
  --ru-direct-domains-file rules/ru-direct-domains.txt \
  --output serg-ru-compatible.json
```

## Текущий базовый список

```text
gosuslugi.ru
esia.gosuslugi.ru
nalog.gov.ru
nalog.ru
mos.ru
mosreg.ru
sberbank.ru
online.sberbank.ru
tbank.ru
alfabank.ru
vtb.ru
gazprombank.ru
pochtabank.ru
raiffeisen.ru
ozon.ru
wildberries.ru
market.yandex.ru
yandex.ru
dzen.ru
vk.com
ok.ru
mail.ru
rambler.ru
```

## Важное замечание

Правила `domain_suffix` означают, что `sberbank.ru` покрывает и поддомены вроде `online.sberbank.ru`. Тем не менее некоторые критичные домены оставлены явно, чтобы список было проще читать и сопровождать.

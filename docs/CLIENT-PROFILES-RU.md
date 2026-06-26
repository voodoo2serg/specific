# Клиентские профили Android / iOS / Windows

В этой схеме пользователю нужно не 10 разных VPN, а 2-3 понятных профиля.

## Профиль 1: Family Global / RU Compatible

Назначение: повседневное использование.

Логика:

```text
Госуслуги, банки, .ru, .рф, локальная сеть -> direct
Остальной интернет -> зарубежный VPS
DNS для зарубежного -> через зарубежный VPS
```

Подходит для телефонов семьи: банк и Госуслуги не ломаются, зарубежные сайты идут через защищенный маршрут.

Генерация sing-box config:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://...' \
  --output serg-ru-compatible.json
```

Если есть российский VPS и вы хотите сохранить его как отдельный endpoint:

```bash
python3 scripts/generate-sing-box-config.py \
  --mode ru-compatible \
  --foreign-link 'vless://...' \
  --ru-link 'vless://...' \
  --output serg-ru-compatible-with-ru-node.json
```

По умолчанию российские госы и банки все равно идут direct, а не через RU VPS.

## Профиль 2: Full Foreign

Назначение: весь трафик идет через зарубежный VPS.

```bash
python3 scripts/generate-sing-box-config.py \
  --mode full-foreign \
  --foreign-link 'vless://...' \
  --output serg-full-foreign.json
```

## Профиль 3: Emergency

Назначение: запасной зарубежный сервер другого провайдера.

Создается так же, как Full Foreign, но с VLESS-ссылкой резервного VPS.

## Android

Рекомендуемые клиенты:

- NekoBox for Android
- v2rayNG для простого импорта VLESS-ссылок
- sing-box совместимый клиент, если нужен TUN и rule-set

Сценарий:

1. Для простого режима импортируйте VLESS QR/link.
2. Для RU Compatible импортируйте JSON, созданный `generate-sing-box-config.py`.
3. Дайте семье только два профиля: `Family Global` и `Emergency`.

## iOS

Рекомендуемые клиенты:

- Streisand
- V2Box
- Shadowrocket, если доступен

Сценарий:

1. Для простого Full Foreign импортируйте VLESS QR/link.
2. Для сложного split routing используйте клиент, который принимает sing-box config или поддерживает routing rules.
3. Если клиент не поддерживает полноценный sing-box JSON, используйте два ручных профиля: Full Foreign и Direct Off для банков/госов.

## Windows

Рекомендуемые клиенты:

- v2rayN
- NekoRay
- sing-box GUI, если вы используете JSON-конфиги

Сценарий:

1. Импортируйте VLESS-ссылки для EU/US/SG.
2. Для RU Compatible используйте sing-box config.
3. Включите TUN/system proxy в зависимости от клиента.

## macOS

Рекомендуемые клиенты:

- Streisand
- NekoRay
- sing-box GUI

Для стабильного семейного сценария лучше использовать один проверенный клиент на всех устройствах, где это возможно.

## Настраиваемые direct-исключения

Список российских доменов, которые должны идти напрямую, находится в:

```bash
rules/ru-direct-domains.txt
```

После изменения списка нужно заново сгенерировать клиентский sing-box JSON через `scripts/generate-sing-box-config.py`.

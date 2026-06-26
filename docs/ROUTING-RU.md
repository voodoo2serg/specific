# Маршрутизация: Full Foreign и RU Compatible

## Full Foreign

Весь трафик уходит через зарубежный VPS.

Используйте этот режим, когда нужен полностью зарубежный IP.

## RU Compatible

Повседневный режим:

```text
локальная сеть -> direct
российские госуслуги/банки -> direct
.ru/.su/.рф -> direct
остальное -> foreign VPS
```

Это решает бытовую проблему: VPN включён, но Госуслуги и банки продолжают работать без зарубежного IP.

## RU VPS

Российский VPS не должен быть основным приватным endpoint. Его можно использовать только для выбранных российских сервисов, если direct по какой-то причине неудобен. Но для банков и госуслуг direct чаще совместимее, чем датацентровый RU IP.

## Где живёт маршрутизация

Маршрутизация должна жить на клиенте, а не на сервере. Сервер просто даёт безопасный endpoint. Клиент решает, какой домен куда отправлять.

## Клиентские шаблоны

- `client/sing-box-full-foreign.template.json`
- `client/sing-box-ru-compatible.template.json`

Замените placeholders на значения из VLESS-ссылок:

```text
__FOREIGN_SERVER_HOST__
__FOREIGN_UUID__
__FOREIGN_REALITY_SNI__
__FOREIGN_REALITY_PUBLIC_KEY__
__FOREIGN_REALITY_SHORT_ID__
```

Для RU VPS аналогично:

```text
__RU_SERVER_HOST__
__RU_UUID__
__RU_REALITY_SNI__
__RU_REALITY_PUBLIC_KEY__
__RU_REALITY_SHORT_ID__
```

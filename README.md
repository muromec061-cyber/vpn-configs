# VPN Configs

Личная VPN инфраструктура.

## Структура
- `codespace/` — Chisel сервер для GitHub Codespaces
- `scripts/` — скрипты установки и управления
- `.devcontainer/devcontainer.json` — конфиг Codespace
- `.github/workflows/publish-sub.yml` — GitHub Actions подписка

## Как это работает
1. GitHub Codespace запускает Chisel сервер (бесплатно до 60ч/мес)
2. WSL на ПК подключается к Codespace через Chisel клиент (systemd сервис)
3. Через туннель доступны: подписка (порт 80) и VPN (WebSocket :8448)
4. Телефон подключается к публичному URL Codespace

## Для телефона
- **Подписка:** `https://vigilant-zebra-7vq4g4qg46gv3wp9q-8081.app.github.dev/sub`
- **VPN (WiFi):** Reality / WS через локальный IP 192.168.0.107
- **VPN (мобильный):** WS через Codespace (конфиг MyPC-Mobile-CS в подписке)

## Codespace
Создаётся автоматически из `.devcontainer/devcontainer.json`.
Chisel сервер стартует автоматически при создании.
Через 30 мин без действия Codespace засыпает.
Для продления: https://github.com/settings/codespaces (увеличить idle timeout до 120 мин).

## Быстрый старт после перезагрузки ПК
```bash
# 1. Перезапустить Codespace (если уснул)
gh codespace start -c vigilant-zebra-7vq4g4qg46gv3wp9q

# 2. Проверить Chisel сервер
gh codespace ssh -c vigilant-zebra-7vq4g4qg46gv3wp9q -- 'pgrep -x "chisel server" > /dev/null || (nohup chisel server --port 8080 --reverse --keepalive 25s > /tmp/chisel.log 2>&1 &)'

# 3. Chisel клиент запускается автоматически (systemd)
systemctl status chisel-client
```

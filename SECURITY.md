# Security notes

This repository generates private access credentials on your VPS. Treat all generated VLESS links, QR codes, UUIDs, and REALITY keys as secrets.

Recommended practices:

- Keep the GitHub repository private.
- Do not commit generated `node.env` files with real IPs/secrets.
- Use one UUID per person/device.
- Revoke a lost device by removing its client from `/usr/local/etc/xray/config.json` and `/etc/xray/voodoo/clients.json`, then restart Xray.
- Use SSH keys and disable SSH password login.
- Keep servers updated.
- Do not assume this setup is unblockable.

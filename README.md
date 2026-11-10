# Victim Lab (10.10.10.20)

Nginx + ModSecurity (OWASP CRS) in front of DVWA and Juice Shop, MySQL for DVWA,
logs shipped to Splunk by the Universal Forwarder.

## Layout
```
docker-compose.yml          main stack
docker-compose.bypass.yml   optional: expose apps directly (8081 DVWA, 8082 Juice), no WAF
.env.example                WAF mode, paranoia level, DB creds
nginx/templates/            vhosts + JSON access log format
splunk-uf/                  inputs.conf / outputs.conf for the forwarder
scripts/                    setup-host.sh, reset.sh, waf-mode.sh
config/                     logrotate
logs/                       bind-mounted: nginx/, modsecurity/, docker/
```

## Setup
1. Install the Splunk UF .deb (download while the VM still has internet).
2. `sudo ./scripts/setup-host.sh`
3. `cd /opt/victim-lab && docker compose up -d`
4. DVWA: browse to `http://dvwa.lab/setup.php` -> Create / Reset Database (admin / password).
5. On the attacker VM and host, add to `/etc/hosts`:
   `10.10.10.20  dvwa.lab juice.lab`

## Daily use
| Task | Command |
|---|---|
| Log-only WAF | `./scripts/waf-mode.sh DetectionOnly` |
| Blocking WAF | `./scripts/waf-mode.sh On` |
| Raise CRS strictness | edit `PARANOIA` in `.env`, then `docker compose up -d` |
| Attack without WAF | `docker compose -f docker-compose.yml -f docker-compose.bypass.yml up -d` |
| Clean slate | `./scripts/reset.sh` |

## Things to verify on first boot
- `docker compose logs nginx-waf` shows no config errors (the CRS image's templating
  can differ between versions; if the custom template conflicts, check `/etc/nginx/conf.d/`
  inside the container).
- `logs/nginx/access.log` fills with JSON lines; `logs/modsecurity/audit.log` fills when you
  send `curl "http://dvwa.lab/?id=1' OR 1=1--"`.
- `/opt/splunkforwarder/bin/splunk list forward-server` shows 10.10.10.50:9997 active.
- Indexes `web`, `waf`, `os`, `docker` already exist on Splunk before the forwarder starts.

## Notes
- DB network is `internal: true`: MySQL has no route out and no published port.
- Containers on the `web` network can still reach the internet. After pulling images,
  disable the victim's NAT NIC.
- Default creds are intentionally weak. Never expose this VM outside the lab network.

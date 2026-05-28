# Supabase Self-Hosting Stack for Dokploy

This repository contains a complete Supabase Docker Compose stack based on the official self-hosting compose file. It includes Studio, Kong, Auth, PostgREST, Realtime, Storage, imgproxy, Postgres Meta, Edge Functions, Logflare Analytics, Vector, Postgres, and Supavisor.

## Quick Path

1. Generate a real `.env` locally with `sh scripts/generate-supabase-env.sh`.
2. Update `SUPABASE_PUBLIC_URL`, `API_EXTERNAL_URL`, `SITE_URL`, and SMTP values.
3. In Dokploy, create a Compose app from this repository.
4. Paste the generated `.env` values into the Dokploy environment editor.
5. Attach your public domain to port `8000` through Dokploy/Traefik.
6. Deploy and verify Studio at `https://your-domain` and API routes with the generated `ANON_KEY`.

## Exposed Services

| Service | Port | Purpose |
|---|---:|---|
| Kong | `8000` | Public Supabase API gateway and Studio route |
| Kong HTTPS | `8443` | Optional direct HTTPS listener, usually unused behind Dokploy |
| Supavisor session pooler | `5432` | PostgreSQL session connections |
| Supavisor transaction pooler | `6543` | PostgreSQL transaction pool connections |

Do not expose internal services like `auth`, `rest`, `storage`, or `studio` directly. Kong routes them safely under one public origin.

## Dokploy Notes

Use the Compose resource type, not a single Dockerfile application. Supabase is a multi-service stack.

Set the external URLs to your Dokploy domain:

```env
SUPABASE_PUBLIC_URL=https://supabase.example.com
API_EXTERNAL_URL=https://supabase.example.com
SITE_URL=https://app.example.com
```

For production, keep secrets in Dokploy environment variables or a secrets manager. Never commit `.env`.

## Persistence

Database and Storage data use named Docker volumes:

| Volume | Purpose |
|---|---|
| `supabase-db-data` | Postgres data directory |
| `supabase-storage-data` | Supabase Storage file backend |
| `supabase-db-config` | Postgres custom encryption/config state |
| `supabase-deno-cache` | Edge Runtime dependency cache |

Configure Dokploy backups for these volumes before accepting production traffic.

## Local Verification

```sh
sh scripts/generate-supabase-env.sh
docker compose --env-file .env config
docker compose --env-file .env up -d
docker compose ps
```

Expected public paths through Kong:

```sh
curl -H "apikey: $ANON_KEY" https://your-domain/rest/v1/
curl -H "apikey: $ANON_KEY" https://your-domain/auth/v1/health
curl -H "Authorization: Bearer $ANON_KEY" https://your-domain/functions/v1/hello
```

## References

- Official compose: `https://github.com/supabase/supabase/blob/master/docker/docker-compose.yml`
- Official Docker guide: `https://supabase.com/docs/guides/self-hosting/docker`

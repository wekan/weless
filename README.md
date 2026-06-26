# WeKan — Haxe + HaxeUI full-stack Kanban

A Trello/WeKan-style Kanban board built as a **single Haxe codebase** that compiles to
both an HTML5 frontend (HaxeUI) and a portable, type-safe backend (tink_web) targeting
either **PHP** (traditional web hosting) or **JavaScript** (AWS Lambda / Cloudflare
Workers). See [`docs/design.md`](docs/design.md) for the original brief.

## Tech stack

| Layer    | Technology |
|----------|------------|
| Language | Haxe 5.0.0-preview.1 (via [lix](https://github.com/lix-pm/lix.client)) |
| Frontend | HaxeUI (`haxeui-core`, `haxeui-html5`) — XML layouts + macro-built components |
| Backend  | tink_web / tink_http — type-safe routing, dual PHP/JS targets |
| Database | PostgreSQL (PDO on PHP) — schema in [`src/db/schema.sql`](src/db/schema.sql) |

## Layout

```
src/
  shared/Models.hx        Board / Column / Card types — shared by client and server
  client/                 HaxeUI HTML5 app
    ClientMain.hx         entry point (Toolkit.init + mount)
    MainView.hx           board view + drag-and-drop controller
    ColumnView.hx         a list
    CardView.hx           a draggable card
    BoardStore.hx         client state (seeded; syncs to the API best-effort)
    RestClient.hx         calls the backend
    assets/*.xml          HaxeUI layouts
    assets/styles/        custom CSS
  server/                 tink_web backend
    ServerMain.hx         picks the container per target and runs the router
    Api.hx                @:get / @:post / @:put routes
    Db.hx                 storage interface
    MemoryDb.hx           in-memory store (default; runs anywhere)
    PostgresDb.hx         real PostgreSQL via PDO (#if php, -D wekan_postgres)
    php/PDO*.hx           minimal PDO externs
  db/schema.sql           PostgreSQL schema + indexes
```

## Build

Install the toolchain (Node 24, Haxe 5, lix) then restore the pinned libraries:

```bash
npx lix download          # restores haxe_libraries/*.hxml (HaxeUI + tink stack)
```

> The pinned versions are mutually compatible and known to build on Haxe
> 5.0.0-preview.1. Installing "latest" of each library instead pulls
> incompatible versions, so prefer `lix download`.

| Command | Output |
|---------|--------|
| `npx haxe build.hxml` | both: client → `deploy/www/html5/app.js`, PHP server → `deploy/www/api` |
| `npx haxe build.client.hxml` | HTML5 client only |
| `npx haxe build.server.php.hxml` | PHP backend only |
| `npx haxe build.server.js.hxml` | JS / serverless backend only |

`build.sh` / `build.bat` wrap these in a menu.

## Run

The easiest way is the `build.sh` / `build.bat` menu, which builds and launches the
whole app (client + backend) on one origin so the client's default `/api` base URL
works with no CORS setup:

| Menu | What it runs |
|------|--------------|
| `7` | HTML5 client + **PHP** backend → http://127.0.0.1:8080 |
| `8` | HTML5 client + **JS/Node** backend → http://127.0.0.1:8080 |

Equivalent commands:

```bash
# Client + PHP backend (one PHP process serves static files and /api)
npx haxe build.client.hxml && npx haxe build.server.php.hxml
php -S 127.0.0.1:8080 tools/dev-router-php.php

# Client + JS backend (a Node HTTP dev server serves static files and /api)
npx haxe build.client.hxml && npx haxe build.devserver.node.hxml
PORT=8080 WWW_DIR=deploy/www/html5 node deploy/local/devserver.js
```

Then open http://127.0.0.1:8080 and try the API:

```bash
curl http://127.0.0.1:8080/api/boards/1
curl -X POST http://127.0.0.1:8080/api/cards -H 'Content-Type: application/json' \
     -d '{"columnId":1,"title":"Hello"}'
curl -X PUT http://127.0.0.1:8080/api/cards/1/move -H 'Content-Type: application/json' \
     -d '{"columnId":2,"position":0}'
```

> The production serverless build (`build.server.js.hxml`) compiles to an AWS Lambda
> *handler*, not a server — so local runs use the Node dev server
> ([`build.devserver.node.hxml`](build.devserver.node.hxml) →
> [`src/server/DevServerMain.hx`](src/server/DevServerMain.hx)) instead.

To persist to PostgreSQL, create the schema and build with the PDO store:

```bash
psql "$DATABASE_URL" -f src/db/schema.sql
npx haxe build.server.php.hxml -D wekan_postgres
# configure via env: DATABASE_DSN, DATABASE_USER, DATABASE_PASSWORD
```

## API

| Method | Path | Body | Returns |
|--------|------|------|---------|
| GET  | `/boards/:id`     | —                            | board + columns + cards |
| POST | `/columns`        | `{ boardId, title }`         | created column |
| POST | `/cards`          | `{ columnId, title, description? }` | created card |
| PUT  | `/cards/:id/move` | `{ columnId, position }`     | moved card |

All requests/responses are JSON.

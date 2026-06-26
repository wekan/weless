-- PostgreSQL schema for the Haxe/HaxeUI Kanban app.
-- Mirrors the typedefs in src/shared/Models.hx.
--
-- Apply with:  psql "$DATABASE_URL" -f src/db/schema.sql
--
-- Designed for cloud-native Postgres (Neon / AWS Aurora Serverless).

BEGIN;

-- ---------------------------------------------------------------------------
-- Board: top-level container for columns.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS board (
    id    SERIAL PRIMARY KEY,
    title TEXT   NOT NULL CHECK (length(trim(title)) > 0)
);

-- ---------------------------------------------------------------------------
-- Column: belongs to a board, ordered by position.
-- ("column" is reserved-ish; the table is named board_column to stay clear of it.)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS board_column (
    id       SERIAL  PRIMARY KEY,
    board_id INTEGER NOT NULL REFERENCES board (id) ON DELETE CASCADE,
    title    TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    position INTEGER NOT NULL DEFAULT 0
);

-- Fast lookup of all columns of a board, already in display order.
CREATE INDEX IF NOT EXISTS idx_board_column_board_position
    ON board_column (board_id, position);

-- ---------------------------------------------------------------------------
-- Card: belongs to a column, ordered within it by position.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS card (
    id          SERIAL  PRIMARY KEY,
    column_id   INTEGER NOT NULL REFERENCES board_column (id) ON DELETE CASCADE,
    title       TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    description TEXT    NOT NULL DEFAULT '',
    position    INTEGER NOT NULL DEFAULT 0
);

-- Fast lookup of all cards in a column, already in display order.
CREATE INDEX IF NOT EXISTS idx_card_column_position
    ON card (column_id, position);

COMMIT;

-- ---------------------------------------------------------------------------
-- Optional seed data (handy for local development / first run).
-- ---------------------------------------------------------------------------
-- INSERT INTO board (title) VALUES ('My First Board');
-- INSERT INTO board_column (board_id, title, position) VALUES
--     (1, 'To Do', 0), (1, 'Doing', 1), (1, 'Done', 2);
-- INSERT INTO card (column_id, title, description, position) VALUES
--     (1, 'Set up Haxe toolchain', 'lix + haxe 5.0', 0),
--     (1, 'Draft the schema',      '',               1),
--     (2, 'Wire up tink_web',      '',               0);

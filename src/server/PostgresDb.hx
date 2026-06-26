package;

#if php
import php.PDO;
import php.PDOStatement;
import tink.core.Promise;
import tink.core.Error.ErrorCode;
import shared.Models;

using tink.CoreApi;

/**
	Real PostgreSQL `Db` implementation backed by PHP's native PDO.

	Compiled only for the PHP target (`#if php`). Enable it from `ServerMain`
	by building with `-D wekan_postgres` and pointing `DATABASE_URL` at your
	cloud Postgres (Neon / Aurora Serverless). Schema: `src/db/schema.sql`.

	PDO is synchronous, so each method resolves its `Promise` immediately; the
	async signature keeps the routing layer identical to the JS/serverless build.
**/
class PostgresDb implements Db {
	final pdo:PDO;

	/**
		@param dsn   PDO DSN, e.g. `pgsql:host=localhost;port=5432;dbname=wekan`
		@param user  database user
		@param pass  database password
	**/
	public function new(dsn:String, ?user:String, ?pass:String) {
		pdo = new PDO(dsn, user, pass);
		pdo.setAttribute(PDO.ATTR_ERRMODE, PDO.ERRMODE_EXCEPTION);
	}

	public function loadBoard(id:Int):Promise<BoardData> {
		final boardStmt = pdo.prepare("SELECT id, title FROM board WHERE id = ?");
		boardStmt.execute(php.Lib.toPhpArray([id]));
		final boardRow = boardStmt.fetch(PDO.FETCH_ASSOC);
		if (boardRow == null || untyped !boardRow) {
			return new Error(NotFound, 'No board with id $id');
		}

		final colStmt = pdo.prepare("SELECT id, board_id, title, position FROM board_column WHERE board_id = ? ORDER BY position");
		colStmt.execute(php.Lib.toPhpArray([id]));

		final cardStmt = pdo.prepare("SELECT id, column_id, title, description, position FROM card WHERE column_id = ? ORDER BY position");

		final columns:Array<ColumnData> = [];
		for (cRow in rows(colStmt)) {
			final col:Column = {
				id: int(cRow['id']),
				boardId: int(cRow['board_id']),
				title: cRow['title'],
				position: int(cRow['position'])
			};
			cardStmt.execute(php.Lib.toPhpArray([col.id]));
			final cards:Array<Card> = [
				for (cardRow in rows(cardStmt)) {
					id: int(cardRow['id']),
					columnId: int(cardRow['column_id']),
					title: cardRow['title'],
					description: cardRow['description'],
					position: int(cardRow['position'])
				}
			];
			columns.push({column: col, cards: cards});
		}

		return ({board: {id: int(boardRow['id']), title: boardRow['title']}, columns: columns} : BoardData);
	}

	public function createColumn(data:NewColumn):Promise<Column> {
		final stmt = pdo.prepare("INSERT INTO board_column (board_id, title, position)
			VALUES (?, ?, (SELECT COALESCE(MAX(position) + 1, 0) FROM board_column WHERE board_id = ?))
			RETURNING id, board_id, title, position");
		stmt.execute(php.Lib.toPhpArray([data.boardId, data.title, data.boardId]));
		final row = stmt.fetch(PDO.FETCH_ASSOC);
		return ({
			id: int(row['id']),
			boardId: int(row['board_id']),
			title: row['title'],
			position: int(row['position'])
		} : Column);
	}

	public function createCard(data:NewCard):Promise<Card> {
		final stmt = pdo.prepare("INSERT INTO card (column_id, title, description, position)
			VALUES (?, ?, ?, (SELECT COALESCE(MAX(position) + 1, 0) FROM card WHERE column_id = ?))
			RETURNING id, column_id, title, description, position");
		stmt.execute(php.Lib.toPhpArray([data.columnId, data.title, data.description != null ? data.description : "", data.columnId]));
		final row = stmt.fetch(PDO.FETCH_ASSOC);
		return rowToCard(row);
	}

	public function moveCard(cardId:Int, move:MoveCard):Promise<Card> {
		pdo.beginTransaction();
		// Make room at the target position, then drop the card into it.
		final shift = pdo.prepare("UPDATE card SET position = position + 1 WHERE column_id = ? AND position >= ? AND id <> ?");
		shift.execute(php.Lib.toPhpArray([move.columnId, move.position, cardId]));

		final stmt = pdo.prepare("UPDATE card SET column_id = ?, position = ? WHERE id = ?
			RETURNING id, column_id, title, description, position");
		stmt.execute(php.Lib.toPhpArray([move.columnId, move.position, cardId]));
		final row = stmt.fetch(PDO.FETCH_ASSOC);
		pdo.commit();

		if (row == null || untyped !row) {
			return new Error(NotFound, 'No card with id $cardId');
		}
		return rowToCard(row);
	}

	// --- helpers -------------------------------------------------------------

	static inline function int(s:String):Int {
		return Std.parseInt(s);
	}

	static function rowToCard(row:php.NativeAssocArray<String>):Card {
		return {
			id: int(row['id']),
			columnId: int(row['column_id']),
			title: row['title'],
			description: row['description'],
			position: int(row['position'])
		};
	}

	static function rows(stmt:PDOStatement):Array<php.NativeAssocArray<String>> {
		return cast php.Lib.toHaxeArray(cast stmt.fetchAll(PDO.FETCH_ASSOC));
	}
}
#end

package;

import tink.core.Promise;
import tink.core.Error.ErrorCode;
import shared.Models;

using tink.CoreApi;

/**
	In-memory `Db` implementation.

	Used by default so the server runs with no external dependencies (handy for
	local development and for the JS/serverless target, which has no bundled
	PostgreSQL driver here). State lives for the lifetime of the process — on PHP
	that is a single request, so this is for development only; use `PostgresDb`
	for anything persistent.
**/
class MemoryDb implements Db {
	final boards:Map<Int, Board> = new Map();
	final columns:Array<Column> = [];
	final cards:Array<Card> = [];

	var nextColumnId = 1;
	var nextCardId = 1;

	public function new() {
		seed();
	}

	public function loadBoard(id:Int):Promise<BoardData> {
		final board = boards.get(id);
		if (board == null) {
			return new Error(NotFound, 'No board with id $id');
		}

		final cols = columns.filter(c -> c.boardId == id);
		cols.sort((a, b) -> a.position - b.position);

		final view:BoardData = {
			board: board,
			columns: [
				for (col in cols) {
					final cs = cards.filter(c -> c.columnId == col.id);
					cs.sort((a, b) -> a.position - b.position);
					{column: col, cards: cs};
				}
			]
		};
		return view;
	}

	public function createColumn(data:NewColumn):Promise<Column> {
		if (!boards.exists(data.boardId)) {
			return new Error(NotFound, 'No board with id ${data.boardId}');
		}
		final position = columns.filter(c -> c.boardId == data.boardId).length;
		final col:Column = {
			id: nextColumnId++,
			boardId: data.boardId,
			title: data.title,
			position: position
		};
		columns.push(col);
		return col;
	}

	public function createCard(data:NewCard):Promise<Card> {
		if (!Lambda.exists(columns, c -> c.id == data.columnId)) {
			return new Error(NotFound, 'No column with id ${data.columnId}');
		}
		final position = cards.filter(c -> c.columnId == data.columnId).length;
		final card:Card = {
			id: nextCardId++,
			columnId: data.columnId,
			title: data.title,
			description: data.description != null ? data.description : "",
			position: position
		};
		cards.push(card);
		return card;
	}

	public function moveCard(cardId:Int, move:MoveCard):Promise<Card> {
		final card = Lambda.find(cards, c -> c.id == cardId);
		if (card == null) {
			return new Error(NotFound, 'No card with id $cardId');
		}
		if (!Lambda.exists(columns, c -> c.id == move.columnId)) {
			return new Error(NotFound, 'No column with id ${move.columnId}');
		}

		card.columnId = move.columnId;

		// Re-pack positions in the destination column, inserting at move.position.
		final dest = cards.filter(c -> c.columnId == move.columnId && c.id != cardId);
		dest.sort((a, b) -> a.position - b.position);
		var index = move.position;
		if (index < 0) index = 0;
		if (index > dest.length) index = dest.length;
		dest.insert(index, card);
		for (i in 0...dest.length) {
			dest[i].position = i;
		}
		return card;
	}

	function seed():Void {
		boards.set(1, {id: 1, title: "My First Board"});
		columns.push({id: nextColumnId++, boardId: 1, title: "To Do", position: 0});
		columns.push({id: nextColumnId++, boardId: 1, title: "Doing", position: 1});
		columns.push({id: nextColumnId++, boardId: 1, title: "Done", position: 2});
		cards.push({id: nextCardId++, columnId: 1, title: "Set up Haxe toolchain", description: "lix + haxe 5.0", position: 0});
		cards.push({id: nextCardId++, columnId: 1, title: "Draft the schema", description: "", position: 1});
		cards.push({id: nextCardId++, columnId: 2, title: "Wire up tink_web", description: "", position: 0});
		cards.push({id: nextCardId++, columnId: 3, title: "Pick the stack", description: "", position: 0});
	}
}

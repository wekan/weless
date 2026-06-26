package;

import shared.Models;

/**
	Client-side board state.

	This is the single source of truth the UI renders from. It is seeded with a
	small sample board so the app is usable standalone (no backend required), and
	exposes mutation methods that the UI calls on drag-and-drop / add actions.

	Each mutation also calls into `RestClient` to persist the change to the
	tink_web backend; those calls are fire-and-forget and the UI does not block
	on them, so the app stays responsive (and functional) whether or not a server
	is reachable.
**/
class BoardStore {
	public var board(default, null):Board;
	public var columns(default, null):Array<ColumnData>;

	final rest:RestClient;
	var nextColumnId:Int;
	var nextCardId:Int;

	public function new(?rest:RestClient) {
		this.rest = rest != null ? rest : new RestClient();
		seed();
	}

	/** Find the column view that owns a given column id. **/
	public function findColumn(columnId:Int):Null<ColumnData> {
		for (c in columns) {
			if (c.column.id == columnId) {
				return c;
			}
		}
		return null;
	}

	/** Add a new column to the board and return it. **/
	public function addColumn(title:String):ColumnData {
		final col:Column = {
			id: nextColumnId++,
			boardId: board.id,
			title: title,
			position: columns.length
		};
		final view:ColumnData = {column: col, cards: []};
		columns.push(view);
		rest.createColumn({boardId: board.id, title: title});
		return view;
	}

	/** Add a new card to a column and return it. **/
	public function addCard(columnId:Int, title:String):Null<Card> {
		final col = findColumn(columnId);
		if (col == null) {
			return null;
		}
		final card:Card = {
			id: nextCardId++,
			columnId: columnId,
			title: title,
			description: "",
			position: col.cards.length
		};
		col.cards.push(card);
		rest.createCard({columnId: columnId, title: title});
		return card;
	}

	/**
		Move `card` to `targetColumnId`, inserting it at `targetIndex`.
		Recomputes `position` for every affected card and persists the move.
	**/
	public function moveCard(card:Card, targetColumnId:Int, targetIndex:Int):Void {
		final from = findColumn(card.columnId);
		final to = findColumn(targetColumnId);
		if (from == null || to == null) {
			return;
		}

		from.cards.remove(card);

		if (targetIndex < 0) {
			targetIndex = 0;
		}
		if (targetIndex > to.cards.length) {
			targetIndex = to.cards.length;
		}
		to.cards.insert(targetIndex, card);

		card.columnId = targetColumnId;
		reindex(from);
		if (from != to) {
			reindex(to);
		}

		rest.moveCard(card.id, {columnId: targetColumnId, position: card.position});
	}

	function reindex(col:ColumnData):Void {
		for (i in 0...col.cards.length) {
			col.cards[i].position = i;
		}
	}

	function seed():Void {
		board = {id: 1, title: "My First Board"};
		columns = [
			{
				column: {id: 1, boardId: 1, title: "To Do", position: 0},
				cards: [
					mkCard(1, 1, "Set up Haxe toolchain", "lix + haxe 5.0", 0),
					mkCard(2, 1, "Draft the PostgreSQL schema", "", 1),
					mkCard(3, 1, "Sketch the HaxeUI layout", "", 2)
				]
			},
			{
				column: {id: 2, boardId: 1, title: "Doing", position: 1},
				cards: [mkCard(4, 2, "Wire up tink_web routing", "PHP + JS targets", 0)]
			},
			{
				column: {id: 3, boardId: 1, title: "Done", position: 2},
				cards: [mkCard(5, 3, "Pick the tech stack", "Haxe full-stack", 0)]
			}
		];
		nextColumnId = 4;
		nextCardId = 6;
	}

	static function mkCard(id:Int, columnId:Int, title:String, description:String, position:Int):Card {
		return {
			id: id,
			columnId: columnId,
			title: title,
			description: description,
			position: position
		};
	}
}

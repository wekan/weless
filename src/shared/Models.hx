package shared;

/**
	Shared domain models for the Kanban app.

	These typedefs are compiled into BOTH the HaxeUI/HTML5 client and the
	tink_web backend (PHP / Node.js), so they must stay free of any
	target-specific API. They mirror the PostgreSQL schema in `src/db/schema.sql`.
**/

/** A board is the top-level container for columns. **/
typedef Board = {
	var id:Int;
	var title:String;
}

/** A column (a.k.a. "list" / "swimlane") belongs to a board and is ordered by `position`. **/
typedef Column = {
	var id:Int;
	var boardId:Int;
	var title:String;
	var position:Int;
}

/** A card belongs to a column and is ordered within it by `position`. **/
typedef Card = {
	var id:Int;
	var columnId:Int;
	var title:String;
	var description:String;
	var position:Int;
}

/**
	A board together with its columns and their cards.
	This is the shape returned by `GET /api/boards/:id` and consumed by the client.
	(Named `*Data` rather than `*View` to avoid clashing with the HaxeUI view
	components of the same concept on the client.)
**/
typedef BoardData = {
	var board:Board;
	var columns:Array<ColumnData>;
}

typedef ColumnData = {
	var column:Column;
	var cards:Array<Card>;
}

/**
	Payload for `PUT /api/cards/:id/move` — repositioning a card via drag-and-drop.
	Updates the owning column and the position within it.
**/
typedef MoveCard = {
	var columnId:Int;
	var position:Int;
}

/** Payload for creating a card. **/
typedef NewCard = {
	var columnId:Int;
	var title:String;
	var ?description:String;
}

/** Payload for creating a column. **/
typedef NewColumn = {
	var boardId:Int;
	var title:String;
}

package;

import tink.core.Promise;
import shared.Models;

/**
	Type-safe REST API for the Kanban app, dispatched by tink_web.

	tink_web turns the `@:get` / `@:post` / `@:put` metadata into a router (see
	`ServerMain`). Path captures use `$name` and bind to the like-named argument;
	an argument named `body` is decoded from the JSON request body. Return values
	are serialised to JSON automatically (the default `produces`).
**/
class Api {
	final db:Db;

	public function new(db:Db) {
		this.db = db;
	}

	/** GET /boards/:id — full board with columns and cards. **/
	@:get('/boards/$id')
	public function getBoard(id:Int):Promise<BoardData> {
		return db.loadBoard(id);
	}

	/** POST /columns — create a list. Body: { boardId, title }. **/
	@:post('/columns')
	public function createColumn(body:NewColumn):Promise<Column> {
		return db.createColumn(body);
	}

	/** POST /cards — create a card. Body: { columnId, title, description? }. **/
	@:post('/cards')
	public function createCard(body:NewCard):Promise<Card> {
		return db.createCard(body);
	}

	/** PUT /cards/:id/move — reposition a card (drag-and-drop). Body: { columnId, position }. **/
	@:put('/cards/$id/move')
	public function moveCard(id:Int, body:MoveCard):Promise<Card> {
		return db.moveCard(id, body);
	}
}

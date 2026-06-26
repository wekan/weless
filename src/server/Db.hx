package;

import tink.core.Promise;
import shared.Models;

/**
	Storage facade for the API.

	Two implementations exist:
	  - `MemoryDb`  — in-memory, compiles & runs on every target (default; lets the
	                  server run with zero setup, and keeps the JS/serverless target
	                  buildable without a native driver).
	  - `PostgresDb` — real PostgreSQL via PHP PDO (`#if php`), per the design.

	All methods are async (`tink.core.Promise`) so a networked driver can be
	dropped in without changing the routing layer.
**/
interface Db {
	function loadBoard(id:Int):Promise<BoardData>;
	function createColumn(data:NewColumn):Promise<Column>;
	function createCard(data:NewCard):Promise<Card>;
	function moveCard(cardId:Int, move:MoveCard):Promise<Card>;
}

package;

import haxe.Json;
import haxe.Http;
import shared.Models;

/**
	Thin client for the tink_web backend (see `src/server/Api.hx`).

	Calls are best-effort: failures are swallowed so the UI keeps working against
	its local `BoardStore` even when no server is running. Point `baseUrl` at the
	deployed API (PHP webhost or AWS Lambda/Cloudflare Worker) to enable
	persistence.
**/
class RestClient {
	public var baseUrl:String;

	public function new(baseUrl:String = "/api") {
		this.baseUrl = baseUrl;
	}

	/** GET /api/boards/:id — load a full board with its columns and cards. **/
	public function loadBoard(id:Int, onResult:BoardData->Void, ?onError:String->Void):Void {
		final http = new Http('$baseUrl/boards/$id');
		http.onData = data -> {
			try {
				onResult(Json.parse(data));
			} catch (e:Dynamic) {
				if (onError != null) onError(Std.string(e));
			}
		};
		http.onError = err -> if (onError != null) onError(err);
		http.request(false);
	}

	/** POST /api/columns **/
	public function createColumn(payload:NewColumn):Void {
		post('$baseUrl/columns', payload);
	}

	/** POST /api/cards **/
	public function createCard(payload:NewCard):Void {
		post('$baseUrl/cards', payload);
	}

	/** PUT /api/cards/:id/move — reposition a card (drag-and-drop). **/
	public function moveCard(cardId:Int, payload:MoveCard):Void {
		send('PUT', '$baseUrl/cards/$cardId/move', payload);
	}

	function post(url:String, payload:Dynamic):Void {
		send("POST", url, payload);
	}

	// Best-effort write request. Uses XMLHttpRequest directly because the JS
	// `haxe.Http` does not expose arbitrary HTTP verbs (PUT). Errors are ignored
	// so the local UI stays usable when no server is reachable.
	function send(method:String, url:String, payload:Dynamic):Void {
		#if js
		try {
			final xhr = new js.html.XMLHttpRequest();
			xhr.open(method, url, true);
			xhr.setRequestHeader("Content-Type", "application/json");
			xhr.send(Json.stringify(payload));
		} catch (_:Dynamic) {}
		#end
	}
}

package;

#if nodejs
import tink.http.Request;
import tink.http.Response.OutgoingResponse;
import tink.http.containers.NodeContainer;
import tink.web.routing.Context;
import tink.web.routing.Router;

using tink.CoreApi;

/**
	Local development server for the JS/Node backend.

	The production JS target (`build.server.js.hxml`) compiles to an AWS Lambda
	handler, which is not a standalone HTTP server. This entry point instead runs
	a real Node HTTP server (tink_http `NodeContainer`) that:
	  - serves the compiled HaxeUI client for any non-`/api` path, and
	  - routes `/api/*` to the same tink_web `Api` used in production.

	Serving both from one origin means the client's default `/api` base URL works
	with no CORS setup. Configure with env vars `PORT` (default 8080) and
	`WWW_DIR` (default `deploy/www/html5`).
**/
class DevServerMain {
	static var www:String;

	public static function main() {
		final port = switch Sys.getEnv("PORT") {
			case null: 8080;
			case v: Std.parseInt(v);
		}
		www = switch Sys.getEnv("WWW_DIR") {
			case null: "deploy/www/html5";
			case v: v;
		}

		final router = new Router<Api>(new Api(new MemoryDb()));

		final handler = function(req:IncomingRequest):Future<OutgoingResponse> {
			final path = (req.header.url.path : String);
			if (path == "/api" || StringTools.startsWith(path, "/api/")) {
				return route(router, req, path);
			}
			return Future.sync(serveStatic(path));
		};

		new NodeContainer(port).run(handler).handle(function(result) switch result {
			case Running(_): Sys.println('Dev server on http://127.0.0.1:$port  (client + /api)');
			case Failed(e): Sys.println('Failed to start: ${e.message}');
			case Shutdown: Sys.println('Server shut down');
		});
	}

	/** Strip the `/api` prefix and dispatch to the tink_web router. **/
	static function route(router:Router<Api>, req:IncomingRequest, path:String):Future<OutgoingResponse> {
		var rest = path.substr(4);
		if (rest == "") {
			rest = "/";
		}
		final query = (req.header.url.query : String);
		final url = rest + (query == null || query == "" ? "" : '?$query');
		final header = new IncomingRequestHeader(req.header.method, url, req.header.protocol, [for (f in req.header) f]);
		final rerouted = new IncomingRequest(req.clientIp, header, req.body);
		return router.route(Context.ofRequest(rerouted)).recover(OutgoingResponse.reportError);
	}

	static function serveStatic(path:String):OutgoingResponse {
		var file = www + (path == "/" ? "/index.html" : path);
		if (!sys.FileSystem.exists(file) || sys.FileSystem.isDirectory(file)) {
			file = www + "/index.html"; // SPA fallback
		}
		final bytes = sys.io.File.getBytes(file);
		return OutgoingResponse.blob(200, bytes, contentType(file));
	}

	static function contentType(file:String):String {
		return switch haxe.io.Path.extension(file).toLowerCase() {
			case "html": "text/html; charset=utf-8";
			case "js": "application/javascript; charset=utf-8";
			case "css": "text/css; charset=utf-8";
			case "json": "application/json";
			case "png": "image/png";
			case "jpg" | "jpeg": "image/jpeg";
			case "svg": "image/svg+xml";
			case _: "application/octet-stream";
		}
	}
}
#end

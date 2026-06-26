package;

import tink.http.Container;
import tink.http.Handler;
import tink.http.Request;
import tink.http.Response.OutgoingResponse;
import tink.web.routing.Context;
import tink.web.routing.Router;

using tink.CoreApi;

/**
	Backend entry point.

	Builds a tink_web `Router` over `Api` and runs it inside the container that
	matches the compile target:
	  - PHP   (`-php`)        → `PhpContainer`            (traditional web hosting)
	  - Node  (`-js -D nodejs`) → `AwsLambdaNodeContainer` (AWS Lambda / serverless)
	  - other                 → `LocalContainer`          (fallback)

	The routing and business logic are identical across targets — only the
	container (and, optionally, the `Db` implementation) changes.
**/
class ServerMain {
	public static function main() {
		final db:Db = makeDb();
		final router = new Router<Api>(new Api(db));

		final handler:Handler = function(req:IncomingRequest):Future<OutgoingResponse> {
			return router.route(Context.ofRequest(req)).recover(OutgoingResponse.reportError);
		};

		// `run` returns a lazy Future — make it eager so the container actually
		// starts processing the request.
		container().run(handler).eager();
	}

	static function makeDb():Db {
		#if (php && wekan_postgres)
		// Build with `-D wekan_postgres` to persist to PostgreSQL via PDO.
		final dsn = Sys.getEnv("DATABASE_DSN");
		return new PostgresDb(dsn != null ? dsn : "pgsql:host=localhost;port=5432;dbname=wekan", Sys.getEnv("DATABASE_USER"), Sys.getEnv("DATABASE_PASSWORD"));
		#else
		return new MemoryDb();
		#end
	}

	static function container():Container {
		#if php
		return tink.http.containers.PhpContainer.inst;
		#elseif nodejs
		return new tink.http.containers.AwsLambdaNodeContainer('handler');
		#else
		return tink.http.containers.LocalContainer.inst;
		#end
	}
}

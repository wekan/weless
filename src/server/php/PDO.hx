package php;

#if php
/**
	Minimal extern for PHP's native PDO class.

	Haxe's standard library does not ship PDO externs, so we declare just the
	surface `PostgresDb` needs. `@:native("PDO")` binds to the global PHP class.
**/
@:native("PDO")
extern class PDO {
	function new(dsn:String, ?username:String, ?password:String, ?options:php.NativeArray);

	function prepare(statement:String, ?options:php.NativeArray):PDOStatement;
	function query(statement:String):PDOStatement;
	function exec(statement:String):Int;
	function lastInsertId(?name:String):String;
	function beginTransaction():Bool;
	function commit():Bool;
	function rollBack():Bool;
	function setAttribute(attribute:Int, value:Dynamic):Bool;

	static var FETCH_ASSOC:Int;
	static var ATTR_ERRMODE:Int;
	static var ERRMODE_EXCEPTION:Int;
}
#end

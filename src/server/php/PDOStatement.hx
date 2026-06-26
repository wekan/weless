package php;

#if php
/** Minimal extern for PHP's native PDOStatement. **/
@:native("PDOStatement")
extern class PDOStatement {
	function execute(?params:php.NativeArray):Bool;
	function fetch(?mode:Int):php.NativeAssocArray<String>;
	function fetchAll(?mode:Int):php.NativeIndexedArray<php.NativeAssocArray<String>>;
	function rowCount():Int;
}
#end

<?php
/**
 * Local dev router for the PHP backend.
 *
 * Run with:
 *   php -S 127.0.0.1:8080 haxe/tools/dev-router-php.php
 *   # (from the `haxe/` dir:)  php -S 127.0.0.1:8080 tools/dev-router-php.php
 *
 * Serves the compiled HaxeUI client for any non-/api path and dispatches
 * /api/* to the compiled tink_web backend — same origin, so the client's
 * default "/api" base URL works with no CORS setup.
 */

$root = __DIR__ . '/..';
$www  = $root . '/deploy/www/html5';
$api  = $root . '/deploy/www/api/index.php';

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($path === '/api' || strpos($path, '/api/') === 0) {
    // Strip the /api prefix so the router sees /boards, /cards, ...
    $rest = substr($path, 4);
    if ($rest === '' || $rest === false) {
        $rest = '/';
    }
    $query = parse_url($_SERVER['REQUEST_URI'], PHP_URL_QUERY);
    $_SERVER['REQUEST_URI'] = $rest . ($query !== null ? '?' . $query : '');
    require $api;
    return true;
}

// --- static file serving --------------------------------------------------
$file = realpath($www . ($path === '/' ? '/index.html' : $path));

// Guard against path traversal; fall back to index.html (SPA).
if ($file === false || strpos($file, realpath($www)) !== 0 || !is_file($file)) {
    $file = $www . '/index.html';
}

$types = [
    'html' => 'text/html; charset=utf-8',
    'js'   => 'application/javascript; charset=utf-8',
    'css'  => 'text/css; charset=utf-8',
    'json' => 'application/json',
    'png'  => 'image/png',
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'svg'  => 'image/svg+xml',
];
$ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
header('Content-Type: ' . ($types[$ext] ?? 'application/octet-stream'));
readfile($file);
return true;

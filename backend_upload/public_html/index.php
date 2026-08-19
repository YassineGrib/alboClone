<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// Locate later_api root (either next to public_html or one level up)
$baseDir = file_exists(__DIR__.'/../later_api/bootstrap/app.php') 
    ? __DIR__.'/../later_api' 
    : __DIR__.'/../../later_api';

// Determine if the application is in maintenance mode...
if (file_exists($maintenance = $baseDir.'/storage/framework/maintenance.php')) {
    require $maintenance;
}

// Register the Composer autoloader...
require $baseDir.'/vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once $baseDir.'/bootstrap/app.php';

$app->handleRequest(Request::capture());

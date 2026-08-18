<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CollectionController;
use App\Http\Controllers\Api\SaveController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login'])->name('login');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/saves', [SaveController::class, 'index']);
    Route::post('/saves', [SaveController::class, 'store']);
    Route::post('/saves/auto-organize', [SaveController::class, 'autoOrganize']);
    Route::patch('/saves/{id}', [SaveController::class, 'update']);
    Route::delete('/saves/{id}', [SaveController::class, 'destroy']);
    Route::get('/collections', [CollectionController::class, 'index']);
    Route::post('/collections', [CollectionController::class, 'store']);
    Route::patch('/collections/{id}', [CollectionController::class, 'update']);
    Route::delete('/collections/{id}', [CollectionController::class, 'destroy']);
});

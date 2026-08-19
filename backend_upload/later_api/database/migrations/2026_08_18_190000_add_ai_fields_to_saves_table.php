<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('saves', function (Blueprint $table) {
            $table->text('ai_summary')->nullable();
            $table->string('category')->nullable();
            $table->json('ai_tags')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('saves', function (Blueprint $table) {
            $table->dropColumn(['ai_summary', 'category', 'ai_tags']);
        });
    }
};

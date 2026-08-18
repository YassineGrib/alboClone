<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DevUserSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->firstOrCreate(
            ['email' => 'you@local.test'],
            [
                'name' => 'You',
                'password' => 'password',
            ],
        );
    }
}

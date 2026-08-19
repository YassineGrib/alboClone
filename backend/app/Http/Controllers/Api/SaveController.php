<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSaveRequest;
use App\Http\Requests\UpdateSaveRequest;
use App\Jobs\ParseSaveJob;
use App\Models\Save;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class SaveController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Save::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('deleted_at')
            ->orderByDesc('created_at');

        if ($request->filled('updated_since')) {
            $query->where('updated_at', '>=', $request->date('updated_since'));
        }

        if ($request->filled('q')) {
            $needle = $request->string('q')->toString();
            $query->where(function ($inner) use ($needle) {
                $inner->where('title', 'like', '%'.$needle.'%')
                    ->orWhere('url', 'like', '%'.$needle.'%');
            });
        }

        if ($request->boolean('unfiled')) {
            $query->whereNull('collection_id');
        } elseif ($request->filled('collection_id')) {
            $query->where('collection_id', $request->string('collection_id')->toString());
        }

        if ($request->filled('content_status')) {
            $status = $request->string('content_status')->toString();
            if (in_array($status, ['pending', 'ready', 'failed'], true)) {
                $query->where('content_status', $status);
            }
        }

        $limit = min(max(1, $request->integer('limit', 100)), 500);
        $query->limit($limit);

        return response()->json(
            $query->get()->map(fn (Save $save) => $this->payload($save))->values(),
        );
    }

    public function store(StoreSaveRequest $request): JsonResponse
    {
        $existing = Save::query()->find($request->string('id')->toString());

        if ($existing) {
            if ($existing->user_id !== $request->user()->id) {
                return response()->json(['message' => 'Conflict'], 409);
            }

            return response()->json($this->payload($existing));
        }

        $now = $request->date('created_at') ?? now();

        $save = Save::query()->create([
            'id' => $request->string('id')->toString(),
            'user_id' => $request->user()->id,
            'url' => $request->string('url')->toString(),
            'title' => $request->string('title')->toString(),
            'content_status' => 'pending',
            'collection_id' => $request->input('collection_id'),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $aiEnabled = $request->boolean('ai_enabled', true);
        try {
            ParseSaveJob::dispatchSync($save->id, $aiEnabled);
            $save->refresh();
        } catch (\Throwable) {
            // Keep pending/fallback
        }

        return response()->json($this->payload($save));
    }

    public function autoOrganize(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $unfiled = Save::query()
            ->where('user_id', $userId)
            ->whereNull('deleted_at')
            ->whereNull('collection_id')
            ->get();

        $count = 0;
        foreach ($unfiled as $save) {
            $cat = !empty($save->category) ? trim($save->category) : null;
            if ($cat && !in_array(strtolower($cat), ['link', 'other'], true)) {
                $collection = \App\Models\Collection::firstOrCreate(
                    ['user_id' => $userId, 'name' => ucfirst($cat)],
                    ['id' => (string) \Illuminate\Support\Str::uuid()]
                );
                $save->collection_id = $collection->id;
                $save->save();
                $count++;
            }
        }

        return response()->json([
            'message' => "Organized {$count} items into smart folders",
            'organized_count' => $count,
        ]);
    }

    public function update(UpdateSaveRequest $request, string $id): JsonResponse
    {
        $save = Save::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->whereNull('deleted_at')
            ->first();

        if (! $save) {
            return response()->json(['message' => 'Not found'], 404);
        }

        if ($request->has('priority')) {
            $save->priority = $request->integer('priority');
        }

        if ($request->has('collection_id')) {
            $save->collection_id = $request->input('collection_id');
        }

        $save->save();

        return response()->json($this->payload($save));
    }

    public function destroy(Request $request, string $id): Response
    {
        $row = Save::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $row) {
            return response()->noContent(404);
        }

        if ($row->deleted_at === null) {
            $row->deleted_at = now();
            $row->save();
        }

        return response()->noContent();
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Save $save): array
    {
        return [
            'id' => $save->id,
            'url' => $save->url,
            'title' => $save->title,
            'image_url' => $save->image_url,
            'ai_summary' => $save->ai_summary,
            'category' => $save->category,
            'priority' => (int) ($save->priority ?? 0),
            'ai_tags' => $save->ai_tags ?? [],
            'content_status' => $save->content_status,
            'collection_id' => $save->collection_id,
            'created_at' => $save->created_at?->toIso8601String(),
            'updated_at' => $save->updated_at?->toIso8601String(),
        ];
    }
}

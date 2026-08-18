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

        $save = Save::query()->create([
            'id' => $request->string('id')->toString(),
            'user_id' => $request->user()->id,
            'url' => $request->string('url')->toString(),
            'title' => $request->string('title')->toString(),
            'content_status' => 'pending',
            'collection_id' => $request->input('collection_id'),
            'created_at' => $request->date('created_at') ?? now(),
        ]);

        ParseSaveJob::dispatch($save->id)->afterResponse();

        return response()->json($this->payload($save));
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

        $save->collection_id = $request->input('collection_id');
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
            'content_status' => $save->content_status,
            'collection_id' => $save->collection_id,
            'created_at' => $save->created_at?->toIso8601String(),
            'updated_at' => $save->updated_at?->toIso8601String(),
        ];
    }
}

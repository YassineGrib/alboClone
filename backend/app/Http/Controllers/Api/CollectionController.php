<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCollectionRequest;
use App\Http\Requests\UpdateCollectionRequest;
use App\Models\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class CollectionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $rows = Collection::query()
            ->where('user_id', $request->user()->id)
            ->orderBy('name')
            ->get();

        return response()->json(
            $rows->map(fn (Collection $collection) => $this->payload($collection))->values(),
        );
    }

    public function store(StoreCollectionRequest $request): JsonResponse
    {
        $existing = Collection::query()->find($request->string('id')->toString());

        if ($existing) {
            if ($existing->user_id !== $request->user()->id) {
                return response()->json(['message' => 'Conflict'], 409);
            }

            return response()->json($this->payload($existing));
        }

        $collection = Collection::query()->create([
            'id' => $request->string('id')->toString(),
            'user_id' => $request->user()->id,
            'name' => $request->string('name')->toString(),
        ]);

        return response()->json($this->payload($collection));
    }

    public function update(UpdateCollectionRequest $request, string $id): JsonResponse
    {
        $collection = $this->owned($request, $id);

        if (! $collection) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $collection->name = $request->string('name')->toString();
        $collection->save();

        return response()->json($this->payload($collection));
    }

    public function destroy(Request $request, string $id): Response
    {
        $collection = $this->owned($request, $id);

        if (! $collection) {
            return response()->noContent(404);
        }

        $collection->saves()->update(['collection_id' => null]);
        $collection->delete();

        return response()->noContent();
    }

    private function owned(Request $request, string $id): ?Collection
    {
        return Collection::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Collection $collection): array
    {
        return [
            'id' => $collection->id,
            'name' => $collection->name,
            'created_at' => $collection->created_at?->toIso8601String(),
            'updated_at' => $collection->updated_at?->toIso8601String(),
        ];
    }
}

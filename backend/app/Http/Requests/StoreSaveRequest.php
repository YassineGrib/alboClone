<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSaveRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'id' => ['required', 'uuid'],
            'url' => ['required', 'url', 'max:2048'],
            'title' => ['required', 'string'],
            'created_at' => ['sometimes', 'date'],
            'collection_id' => [
                'nullable',
                'uuid',
                Rule::exists('collections', 'id')->where(
                    fn ($query) => $query->where('user_id', $this->user()?->id),
                ),
            ],
        ];
    }
}

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

    protected function prepareForValidation(): void
    {
        if ($this->input('collection_id') === 'global' || empty($this->input('collection_id'))) {
            $this->merge(['collection_id' => null]);
        }
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
            'priority' => ['sometimes', 'integer', 'min:0', 'max:2'],
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

<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSaveRequest extends FormRequest
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
            'priority' => ['sometimes', 'integer', 'min:0', 'max:2'],
            'collection_id' => [
                'sometimes',
                'nullable',
                'uuid',
                Rule::exists('collections', 'id')->where(
                    fn ($query) => $query->where('user_id', $this->user()?->id),
                ),
            ],
        ];
    }
}

<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFingerprintDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $tenant = app('tenant');

        return [
            'name' => ['required', 'string', 'max:255'],
            'brand' => ['required', 'string', Rule::in(['zkteco', 'fingerspot', 'solution', 'other'])],
            'serial_number' => [
                'required',
                'string',
                'max:255',
                Rule::unique('fingerprint_devices', 'serial_number')->where('company_id', $tenant->id),
            ],
            'office_location_id' => [
                'nullable',
                Rule::exists('office_locations', 'id')->where('company_id', $tenant->id),
            ],
            'ip_address' => ['nullable', 'ip'],
            'port' => ['nullable', 'integer', 'min:1', 'max:65535'],
            'is_active' => ['boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama mesin wajib diisi.',
            'brand.required' => 'Merek mesin wajib dipilih.',
            'serial_number.required' => 'Serial number wajib diisi.',
            'serial_number.unique' => 'Serial number sudah terdaftar.',
        ];
    }
}

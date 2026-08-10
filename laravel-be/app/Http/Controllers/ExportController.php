<?php

namespace App\Http\Controllers;

use App\Models\GeneratedExport;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExportController extends Controller
{
    /**
     * Download a previously generated (async) export file.
     */
    public function download(GeneratedExport $export): StreamedResponse
    {
        if ($export->company_id !== auth()->user()->company_id) {
            abort(404);
        }

        if (! $export->isReady() || $export->path === null) {
            abort(404, 'File export belum siap atau tidak ditemukan.');
        }

        $disk = Storage::disk($export->disk);

        if (! $disk->exists($export->path)) {
            abort(404, 'File export tidak ditemukan.');
        }

        return $disk->download($export->path, $export->filename);
    }
}

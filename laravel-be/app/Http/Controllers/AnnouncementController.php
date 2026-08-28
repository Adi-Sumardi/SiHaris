<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use App\Models\Department;
use App\Models\Employee;
use App\Models\Position;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AnnouncementController extends Controller
{
    public function index(): View
    {
        $tenant = app('tenant');

        $announcements = Announcement::with(['creator'])
            ->where('company_id', $tenant->id)
            ->orderByDesc('is_pinned')
            ->orderByDesc('created_at')
            ->paginate(15);

        return view('announcements.index', compact('announcements'));
    }

    public function create(): View
    {
        $tenant = app('tenant');

        $departments = Department::where('company_id', $tenant->id)->orderBy('name')->get();
        $positions = Position::where('company_id', $tenant->id)->orderBy('name')->get();
        $employees = Employee::with('user')
            ->where('company_id', $tenant->id)
            ->orderBy('employee_id')
            ->get();

        return view('announcements.create', compact('departments', 'positions', 'employees'));
    }

    public function store(Request $request): RedirectResponse
    {
        $tenant = app('tenant');

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'priority' => 'required|in:low,normal,high,urgent',
            'target_audience' => 'required|in:all,department,position,specific',
            'target_ids' => 'nullable|array',
            'target_ids.*' => 'integer',
            'is_pinned' => 'nullable|boolean',
            'expires_at' => 'nullable|date|after:today',
            'attachment' => 'nullable|file|max:10240|mimes:pdf,jpg,jpeg,png',
        ]);

        $attachment = $this->storeAttachment($request, $tenant->id);

        $announcement = Announcement::create([
            'company_id' => $tenant->id,
            'created_by' => auth()->id(),
            'title' => $validated['title'],
            'content' => $validated['content'],
            'priority' => $validated['priority'],
            'target_audience' => $validated['target_audience'],
            'target_ids' => $validated['target_ids'] ?? null,
            'is_pinned' => $validated['is_pinned'] ?? false,
            'expires_at' => $validated['expires_at'] ?? null,
            ...$attachment ?? [],
        ]);

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil dibuat.');
    }

    public function show(Announcement $announcement): View
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $announcement->load(['creator', 'readers']);

        return view('announcements.show', compact('announcement'));
    }

    public function edit(Announcement $announcement): View
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $departments = Department::where('company_id', $tenant->id)->orderBy('name')->get();
        $positions = Position::where('company_id', $tenant->id)->orderBy('name')->get();
        $employees = Employee::with('user')
            ->where('company_id', $tenant->id)
            ->orderBy('employee_id')
            ->get();

        return view('announcements.edit', compact('announcement', 'departments', 'positions', 'employees'));
    }

    public function update(Request $request, Announcement $announcement): RedirectResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'priority' => 'required|in:low,normal,high,urgent',
            'target_audience' => 'required|in:all,department,position,specific',
            'target_ids' => 'nullable|array',
            'target_ids.*' => 'integer',
            'is_pinned' => 'nullable|boolean',
            'expires_at' => 'nullable|date',
            'attachment' => 'nullable|file|max:10240|mimes:pdf,jpg,jpeg,png',
            'remove_attachment' => 'nullable|boolean',
        ]);

        $attachment = $this->storeAttachment($request, $tenant->id);

        if ($attachment || $request->boolean('remove_attachment')) {
            if ($announcement->attachment_path) {
                Storage::disk('local')->delete($announcement->attachment_path);
            }
        }

        if (! $attachment && $request->boolean('remove_attachment')) {
            $attachment = [
                'attachment_path' => null,
                'attachment_name' => null,
                'attachment_size' => null,
                'attachment_mime_type' => null,
            ];
        }

        $announcement->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'priority' => $validated['priority'],
            'target_audience' => $validated['target_audience'],
            'target_ids' => $validated['target_ids'] ?? null,
            'is_pinned' => $validated['is_pinned'] ?? false,
            'expires_at' => $validated['expires_at'] ?? null,
            ...$attachment ?? [],
        ]);

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil diperbarui.');
    }

    public function destroy(Announcement $announcement): RedirectResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $announcement->delete();

        return redirect()->route('announcements.index')
            ->with('success', 'Pengumuman berhasil dihapus.');
    }

    public function publish(Announcement $announcement): RedirectResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $announcement->publish();

        return redirect()->back()
            ->with('success', 'Pengumuman berhasil dipublikasikan.');
    }

    public function unpublish(Announcement $announcement): RedirectResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id) {
            abort(404);
        }

        $announcement->unpublish();

        return redirect()->back()
            ->with('success', 'Pengumuman berhasil di-unpublish.');
    }

    public function preview(Announcement $announcement): BinaryFileResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id || ! $announcement->attachment_path) {
            abort(404);
        }

        if (! Storage::disk('local')->exists($announcement->attachment_path)) {
            abort(404);
        }

        return response()->file(
            Storage::disk('local')->path($announcement->attachment_path),
            [
                'Content-Type' => $announcement->attachment_mime_type ?? 'application/octet-stream',
                'Content-Disposition' => 'inline; filename="'.$announcement->attachment_name.'"',
            ]
        );
    }

    public function download(Announcement $announcement): StreamedResponse
    {
        $tenant = app('tenant');

        if ($announcement->company_id !== $tenant->id || ! $announcement->attachment_path) {
            abort(404);
        }

        if (! Storage::disk('local')->exists($announcement->attachment_path)) {
            abort(404);
        }

        return Storage::disk('local')->download(
            $announcement->attachment_path,
            $announcement->attachment_name,
            ['Content-Type' => $announcement->attachment_mime_type ?? 'application/octet-stream']
        );
    }

    /**
     * Validate and store the uploaded attachment, if any.
     *
     * @return array{attachment_path: string, attachment_name: string, attachment_size: int, attachment_mime_type: string}|null
     */
    private function storeAttachment(Request $request, int $companyId): ?array
    {
        if (! $request->hasFile('attachment')) {
            return null;
        }

        $file = $request->file('attachment');
        $path = $file->store("announcements/{$companyId}", 'local');

        return [
            'attachment_path' => $path,
            'attachment_name' => $file->getClientOriginalName(),
            'attachment_size' => $file->getSize(),
            'attachment_mime_type' => $file->getMimeType(),
        ];
    }
}

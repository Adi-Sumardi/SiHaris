<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class AppDownloadController extends Controller
{
    /**
     * Read current app version from public/downloads/VERSION file.
     * To update the version shown at /download, simply update that file on the server.
     */
    private function getAppVersion(): string
    {
        $versionFile = public_path('downloads/VERSION');
        if (File::exists($versionFile)) {
            return trim(File::get($versionFile));
        }

        return '1.0.2';
    }

    /**
     * Display smart download page or trigger auto-download based on User-Agent.
     */
    public function index(Request $request)
    {
        $userAgent = $request->header('User-Agent', '');

        $isAndroid = (bool) preg_match('/Android/i', $userAgent);
        $isIos = (bool) preg_match('/(iPhone|iPad|iPod)/i', $userAgent);

        // Allow query override (e.g. ?os=android or ?os=ios)
        if ($request->query('os') === 'android') {
            $device = 'android';
        } elseif ($request->query('os') === 'ios') {
            $device = 'ios';
        } elseif ($isAndroid) {
            $device = 'android';
        } elseif ($isIos) {
            $device = 'ios';
        } else {
            $device = 'desktop';
        }

        $apkPath = public_path('downloads/siharis-latest.apk');
        $ipaPath = public_path('downloads/siharis-latest.ipa');

        $apkExists = File::exists($apkPath);
        $ipaExists = File::exists($ipaPath);

        $apkSize      = $apkExists ? $this->formatBytes(File::size($apkPath)) : '118 MB';
        $apkModifiedAt = $apkExists ? date('d M Y, H:i', File::lastModified($apkPath)) : now()->format('d M Y, H:i');
        $ipaSize      = $ipaExists ? $this->formatBytes(File::size($ipaPath)) : null;

        $version = $this->getAppVersion();

        // If direct download requested
        if ($request->has('direct')) {
            if ($device === 'android' && $apkExists) {
                return response()->download($apkPath, "SiHaris-v{$version}.apk", [
                    'Content-Type' => 'application/vnd.android.package-archive',
                ]);
            }
            if ($device === 'ios' && $ipaExists) {
                return response()->download($ipaPath, "SiHaris-v{$version}.ipa", [
                    'Content-Type' => 'application/octet-stream',
                ]);
            }
        }

        return view('pages.download', compact(
            'device', 'isAndroid', 'isIos',
            'apkExists', 'apkSize', 'apkModifiedAt',
            'ipaExists', 'ipaSize', 'version'
        ));
    }

    /**
     * Direct Android APK download.
     */
    public function downloadAndroid()
    {
        $apkPath = public_path('downloads/siharis-latest.apk');

        if (!File::exists($apkPath)) {
            return redirect()->route('app.download')->with('error', 'File APK belum tersedia di server.');
        }

        $version = $this->getAppVersion();

        return response()->download($apkPath, "SiHaris-v{$version}.apk", [
            'Content-Type' => 'application/vnd.android.package-archive',
        ]);
    }

    /**
     * Direct iOS package download.
     */
    public function downloadIos()
    {
        $ipaPath = public_path('downloads/siharis-latest.ipa');

        if (!File::exists($ipaPath)) {
            return redirect()->route('app.download', ['os' => 'ios'])
                ->with('info', 'Paket instalasi iOS saat ini dalam proses sertifikasi / TestFlight.');
        }

        $version = $this->getAppVersion();

        return response()->download($ipaPath, "SiHaris-v{$version}.ipa", [
            'Content-Type' => 'application/octet-stream',
        ]);
    }

    /**
     * Format bytes to human-readable string.
     */
    private function formatBytes(int $bytes, int $precision = 1): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow   = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow   = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);

        return round($bytes, $precision) . ' ' . $units[$pow];
    }
}

<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class AppDownloadController extends Controller
{
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

        $apkSize = $apkExists ? $this->formatBytes(File::size($apkPath)) : '118 MB';
        $apkModifiedAt = $apkExists ? date('d M Y, H:i', File::lastModified($apkPath)) : now()->format('d M Y, H:i');
        
        $ipaSize = $ipaExists ? $this->formatBytes(File::size($ipaPath)) : null;

        $version = '1.0.1+6';

        // If direct download requested
        if ($request->has('direct')) {
            if ($device === 'android' && $apkExists) {
                return response()->download($apkPath, 'SiHaris-v1.0.1.apk', [
                    'Content-Type' => 'application/vnd.android.package-archive',
                ]);
            }
            if ($device === 'ios' && $ipaExists) {
                return response()->download($ipaPath, 'SiHaris-v1.0.1.ipa', [
                    'Content-Type' => 'application/octet-stream',
                ]);
            }
        }

        return view('pages.download', compact(
            'device',
            'isAndroid',
            'isIos',
            'apkExists',
            'apkSize',
            'apkModifiedAt',
            'ipaExists',
            'ipaSize',
            'version'
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

        return response()->download($apkPath, 'SiHaris-v1.0.1.apk', [
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

        return response()->download($ipaPath, 'SiHaris-v1.0.1.ipa', [
            'Content-Type' => 'application/octet-stream',
        ]);
    }

    /**
     * Format bytes to human readable format.
     */
    private function formatBytes(int $bytes, int $precision = 1): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);

        return round($bytes, $precision) . ' ' . $units[$pow];
    }
}

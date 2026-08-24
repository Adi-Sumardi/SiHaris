<?php

namespace Tests\Feature;

use Tests\TestCase;

class AppDownloadTest extends TestCase
{
    /**
     * Test /download page renders successfully.
     */
    public function test_download_page_renders_successfully(): void
    {
        $response = $this->get('/download');
        $response->assertStatus(200);
        $response->assertSee('Download Aplikasi');
        $response->assertSee('SiHaris Mobile');
    }

    /**
     * Test /download page auto-detects Android user agent.
     */
    public function test_download_page_detects_android(): void
    {
        $response = $this->withHeaders([
            'User-Agent' => 'Mozilla/5.0 (Linux; U; Android 13; en-US; SM-G998B) AppleWebKit/537.36',
        ])->get('/download');

        $response->assertStatus(200);
        $response->assertSee('Perangkat Android Terdeteksi');
    }

    /**
     * Test /download page auto-detects iPhone iOS user agent.
     */
    public function test_download_page_detects_ios(): void
    {
        $response = $this->withHeaders([
            'User-Agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        ])->get('/download');

        $response->assertStatus(200);
        $response->assertSee('Perangkat iPhone / iPad Terdeteksi');
    }

    /**
     * Test /download/android initiates APK file download.
     */
    public function test_download_android_initiates_file_download(): void
    {
        $response = $this->get('/download/android');
        $response->assertStatus(200);
        $response->assertHeader('content-type', 'application/vnd.android.package-archive');
    }
}

#!/bin/bash
# ==================================================
# GajiPro - Flutter App Bundle Release Script
# ==================================================
# Build AAB untuk upload ke Google Play Store

# Hentikan script kalau ada error
set -e

echo "=========================================="
echo "  GajiPro - App Bundle Release Build"
echo "=========================================="

# --------------------------------------------------
# 1. Pre-check: Pastikan key.properties ada
# --------------------------------------------------
echo ""
echo "[1/5] Checking release configuration..."

if [ ! -f "android/key.properties" ]; then
    echo ""
    echo "ERROR: android/key.properties not found!"
    echo ""
    echo "Buat file android/key.properties dengan isi:"
    echo ""
    echo "  storePassword=YOUR_PASSWORD"
    echo "  keyPassword=YOUR_PASSWORD"
    echo "  keyAlias=upload"
    echo "  storeFile=/Users/fahiem/gajipro.jks"
    echo ""
    echo "Jika belum punya keystore, jalankan:"
    echo ""
    echo "  keytool -genkey -v -keystore ~/gajipro.jks \\"
    echo "    -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
    echo ""
    exit 1
fi

STORE_FILE=$(grep "storeFile" android/key.properties | cut -d'=' -f2)
if [ ! -f "$STORE_FILE" ]; then
    echo ""
    echo "ERROR: Keystore file not found at: $STORE_FILE"
    echo "Pastikan path storeFile di key.properties benar."
    echo ""
    exit 1
fi

echo "  key.properties  : OK"
echo "  keystore file   : OK"

# --------------------------------------------------
# 2. Clean build lama
# --------------------------------------------------
echo ""
echo "[2/5] Cleaning previous build..."
flutter clean

# --------------------------------------------------
# 3. Get dependencies
# --------------------------------------------------
echo ""
echo "[3/5] Getting dependencies..."
flutter pub get

# --------------------------------------------------
# 4. Run build_runner (generated files: freezed, json_serializable)
# --------------------------------------------------
echo ""
echo "[4/5] Running build_runner..."
dart run build_runner build --delete-conflicting-outputs || true

# --------------------------------------------------
# 5. Build App Bundle
# --------------------------------------------------
echo ""
echo "[5/5] Building App Bundle (release)..."
flutter build appbundle --release \
    --obfuscate \
    --split-debug-info=build/debug-info

echo ""
echo "=========================================="
echo "  BUILD SUCCESSFUL!"
echo "=========================================="
echo ""
echo "  AAB file:"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "  Debug symbols (simpan untuk crash reporting):"
echo "  build/debug-info/"
echo ""
echo "  Next steps:"
echo "  1. Buka Google Play Console"
echo "  2. Pilih app GajiPro"
echo "  3. Go to Production > Create new release"
echo "  4. Upload app-release.aab"
echo "  5. Submit for review"
echo ""

#!/bin/bash
#
# GajiPro (SiHaris) — Update/redeploy an already-provisioned server
# Run this from inside the Laravel app directory (e.g. /var/www/siharis/laravel-be)
# after deploy.sh has already set everything up once.
#
# Usage:
#   sudo ./update.sh
#   sudo BRANCH=main SKIP_BUILD=true ./update.sh   # skip npm build if only backend changed

set -euo pipefail

BRANCH="${BRANCH:-main}"
SKIP_BUILD="${SKIP_BUILD:-false}"
PHP_VERSION="${PHP_VERSION:-8.3}"
WORKER_PROGRAM="${WORKER_PROGRAM:-siharis-worker}"

c_info()  { echo -e "\033[1;34m==>\033[0m $1"; }
c_ok()    { echo -e "\033[1;32m✓\033[0m $1"; }
c_warn()  { echo -e "\033[1;33m!\033[0m $1"; }
c_fatal() { echo -e "\033[1;31m✗ $1\033[0m"; exit 1; }

[[ -f artisan ]] || c_fatal "Run this from the Laravel app root (where artisan lives)."

c_info "Putting the app into maintenance mode..."
php artisan down --retry=60 || true

trap 'php artisan up || true' EXIT

c_info "Pulling latest changes (branch: ${BRANCH})..."
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

c_info "Installing composer dependencies..."
composer install --no-dev --optimize-autoloader

if [[ "$SKIP_BUILD" != "true" ]]; then
    c_info "Building frontend assets..."
    npm ci
    npm run build
else
    c_warn "SKIP_BUILD=true — skipped npm build."
fi

c_info "Clearing caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan event:clear

c_info "Running migrations..."
php artisan migrate --force

if php artisan list 2>/dev/null | grep -q l5-swagger:generate; then
    c_info "Regenerating API docs..."
    php artisan l5-swagger:generate || c_warn "l5-swagger:generate failed, skipping."
fi

c_info "Setting permissions..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

c_info "Caching config/routes/views for production..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

c_info "Restarting PHP-FPM..."
systemctl reload "php${PHP_VERSION}-fpm" || systemctl restart "php${PHP_VERSION}-fpm"

if command -v supervisorctl >/dev/null; then
    c_info "Restarting queue workers..."
    supervisorctl restart "${WORKER_PROGRAM}:*" || c_warn "Could not restart '${WORKER_PROGRAM}' — check 'supervisorctl status'."
fi

c_info "Bringing the app back up..."
php artisan up
trap - EXIT

c_ok "Update finished."

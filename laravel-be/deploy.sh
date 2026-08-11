#!/bin/bash
#
# GajiPro (SiHaris) — First-time VPS bootstrap & deploy
# Target: Ubuntu 22.04/24.04 LTS
#
# What it does: installs Nginx, PHP 8.3, MySQL, Redis, Composer, Node,
# Supervisor and Certbot; clones the app; configures .env, the database,
# Nginx vhost, queue worker and the Laravel scheduler cron; then requests
# an SSL certificate.
#
# Usage:
#   sudo cp deploy.sh /root/deploy.sh   # or run straight from a clone
#   sudo DOMAIN=hris.example.com ADMIN_EMAIL=you@example.com ./deploy.sh
#
# Every setting below can also be overridden as an environment variable
# instead of editing the file, e.g. `sudo DOMAIN=foo.com ./deploy.sh`.

set -euo pipefail

# ============================================================
# Configuration — edit these or pass as environment variables
# ============================================================
DOMAIN="${DOMAIN:-your-domain.com}"                 # e.g. hris.example.com (no https://, no www)
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"     # for Let's Encrypt renewal notices
REPO_URL="${REPO_URL:-https://github.com/Adi-Sumardi/SiHaris.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-/var/www/siharis}"              # where the repo is cloned
PHP_VERSION="${PHP_VERSION:-8.3}"

DB_NAME="${DB_NAME:-gajipro}"
DB_USER="${DB_USER:-gajipro_user}"
DB_PASSWORD="${DB_PASSWORD:-}"                       # leave empty to auto-generate

SKIP_SSL="${SKIP_SSL:-false}"                        # set true to skip certbot (e.g. no DNS yet)

# ============================================================
LARAVEL_DIR="$APP_DIR/laravel-be"

c_info()  { echo -e "\033[1;34m==>\033[0m $1"; }
c_ok()    { echo -e "\033[1;32m✓\033[0m $1"; }
c_warn()  { echo -e "\033[1;33m!\033[0m $1"; }
c_fatal() { echo -e "\033[1;31m✗ $1\033[0m"; exit 1; }

[[ $EUID -eq 0 ]] || c_fatal "Run this script as root (sudo ./deploy.sh)."

if [[ "$DOMAIN" == "your-domain.com" ]]; then
    c_fatal "Set DOMAIN first, e.g.: sudo DOMAIN=hris.example.com ADMIN_EMAIL=you@example.com ./deploy.sh"
fi

if [[ -z "$DB_PASSWORD" ]]; then
    DB_PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
    c_warn "No DB_PASSWORD given — generated one automatically (shown again at the end)."
fi

# ------------------------------------------------------------
c_info "Updating apt and installing base packages..."
apt-get update -y
apt-get install -y software-properties-common curl git unzip zip ufw

# ------------------------------------------------------------
c_info "Installing MySQL..."
if ! command -v mysql >/dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
    systemctl enable --now mysql
    c_ok "MySQL installed."
else
    c_ok "MySQL already installed, skipping."
fi

# ------------------------------------------------------------
c_info "Installing Redis..."
if ! command -v redis-cli >/dev/null; then
    apt-get install -y redis-server
    systemctl enable --now redis-server
    c_ok "Redis installed."
else
    c_ok "Redis already installed, skipping."
fi

# ------------------------------------------------------------
c_info "Installing Nginx..."
apt-get install -y nginx
systemctl enable --now nginx

# ------------------------------------------------------------
c_info "Installing PHP $PHP_VERSION and extensions..."
if ! apt-cache policy | grep -q ondrej/php; then
    add-apt-repository -y ppa:ondrej/php
    apt-get update -y
fi
apt-get install -y \
    "php${PHP_VERSION}" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-fpm" \
    "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-redis" \
    "php${PHP_VERSION}-bcmath" "php${PHP_VERSION}-bz2" "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-mbstring" "php${PHP_VERSION}-intl" "php${PHP_VERSION}-xml" \
    "php${PHP_VERSION}-zip" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-common"
update-alternatives --set php "/usr/bin/php${PHP_VERSION}"
systemctl enable --now "php${PHP_VERSION}-fpm"

# ------------------------------------------------------------
c_info "Installing Composer..."
if ! command -v composer >/dev/null; then
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
fi
c_ok "Composer: $(composer --version)"

# ------------------------------------------------------------
c_info "Installing Node.js (for building frontend assets)..."
if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi
c_ok "Node: $(node --version)"

# ------------------------------------------------------------
c_info "Installing Supervisor (queue worker)..."
apt-get install -y supervisor
systemctl enable --now supervisor

# ------------------------------------------------------------
c_info "Configuring firewall (ufw)..."
ufw allow OpenSSH >/dev/null
ufw allow 'Nginx Full' >/dev/null
ufw --force enable >/dev/null
c_ok "Firewall enabled (OpenSSH + Nginx Full)."

# ------------------------------------------------------------
c_info "Creating database and user..."
mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
c_ok "Database '${DB_NAME}' and user '${DB_USER}' ready."

# ------------------------------------------------------------
c_info "Cloning repository..."
mkdir -p "$(dirname "$APP_DIR")"
if [[ -d "$APP_DIR/.git" ]]; then
    c_warn "Repo already exists at $APP_DIR — pulling instead of cloning."
    git -C "$APP_DIR" fetch origin
    git -C "$APP_DIR" checkout "$BRANCH"
    git -C "$APP_DIR" pull origin "$BRANCH"
else
    git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

# ------------------------------------------------------------
c_info "Configuring .env..."
cd "$LARAVEL_DIR"
if [[ ! -f .env ]]; then
    if [[ -f .env.production.example ]]; then
        cp .env.production.example .env
    else
        cp .env.example .env
    fi
fi
sed -i "s#^APP_URL=.*#APP_URL=https://${DOMAIN}#" .env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
sed -i "s/^APP_ENV=.*/APP_ENV=production/" .env
sed -i "s/^APP_DEBUG=.*/APP_DEBUG=false/" .env
c_ok ".env written. Review mail/SendaGo (WhatsApp+email recap) and other secrets manually before going live."

# ------------------------------------------------------------
c_info "Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

c_info "Building frontend assets..."
npm ci
npm run build

c_info "Generating app key..."
php artisan key:generate --force

c_info "Running migrations..."
php artisan migrate --force

c_info "Linking storage..."
php artisan storage:link || true

c_info "Setting permissions..."
chown -R www-data:www-data "$LARAVEL_DIR/storage" "$LARAVEL_DIR/bootstrap/cache"
chmod -R 775 "$LARAVEL_DIR/storage" "$LARAVEL_DIR/bootstrap/cache"

c_info "Caching config/routes/views for production..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# ------------------------------------------------------------
c_info "Configuring Nginx..."
cat > "/etc/nginx/sites-available/${DOMAIN}.conf" <<NGINX
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    root ${LARAVEL_DIR}/public;
    index index.php;

    location ~* /storage/.*\.php\$ { deny all; }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINX
ln -sf "/etc/nginx/sites-available/${DOMAIN}.conf" /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
c_ok "Nginx vhost for ${DOMAIN} enabled."

# ------------------------------------------------------------
c_info "Configuring Supervisor queue worker..."
cat > /etc/supervisor/conf.d/gajipro-worker.conf <<SUPERVISOR
[program:gajipro-worker]
process_name=%(program_name)s_%(process_num)02d
command=php ${LARAVEL_DIR}/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
directory=${LARAVEL_DIR}
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=${LARAVEL_DIR}/storage/logs/worker.log
stopwaitsecs=3600
SUPERVISOR
supervisorctl reread
supervisorctl update
supervisorctl restart gajipro-worker: || true
c_ok "Queue worker running under Supervisor (gajipro-worker)."

# ------------------------------------------------------------
c_info "Configuring Laravel scheduler cron (needed for attendance:send-recap, etc.)..."
cat > /etc/cron.d/gajipro-scheduler <<CRON
* * * * * www-data cd ${LARAVEL_DIR} && php artisan schedule:run >> /dev/null 2>&1
CRON
chmod 644 /etc/cron.d/gajipro-scheduler
c_ok "Scheduler cron installed."

# ------------------------------------------------------------
if [[ "$SKIP_SSL" != "true" ]]; then
    c_info "Requesting SSL certificate via Certbot..."
    if ! command -v certbot >/dev/null; then
        snap install core >/dev/null 2>&1 || true
        snap refresh core >/dev/null 2>&1 || true
        apt-get remove -y certbot >/dev/null 2>&1 || true
        snap install --classic certbot
        ln -sf /snap/bin/certbot /usr/bin/certbot
    fi
    ufw allow 'Nginx Full' >/dev/null
    certbot --nginx --non-interactive --agree-tos -m "$ADMIN_EMAIL" \
        -d "$DOMAIN" -d "www.${DOMAIN}" || c_warn "Certbot failed — check that DNS for ${DOMAIN} already points to this server, then rerun: certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
else
    c_warn "SKIP_SSL=true — skipped certificate request. Run certbot manually once DNS is ready."
fi

# ------------------------------------------------------------
echo
c_ok "Deploy finished."
echo "----------------------------------------------------------"
echo " App URL:       https://${DOMAIN}"
echo " App directory: ${LARAVEL_DIR}"
echo " Database:      ${DB_NAME}"
echo " DB user:       ${DB_USER}"
echo " DB password:   ${DB_PASSWORD}"
echo "----------------------------------------------------------"
c_warn "Save the DB password above somewhere safe — it is not printed again."
c_warn "Still to do manually: fill in MAIL_*, SENDAGO_*, SENDAGOMAIL_* and other"
c_warn "third-party credentials in ${LARAVEL_DIR}/.env, then run:"
echo "   cd ${LARAVEL_DIR} && php artisan config:cache"

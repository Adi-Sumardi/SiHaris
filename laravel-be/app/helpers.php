<?php

if (! function_exists('single_tenant_mode')) {
    /**
     * Determine if the application is running in single-tenant mode.
     */
    function single_tenant_mode(): bool
    {
        return (bool) config('tenant.single_mode', false);
    }
}

if (! function_exists('locked_company_id')) {
    /**
     * Get the locked company ID when in single-tenant mode.
     */
    function locked_company_id(): int
    {
        return (int) config('tenant.company_id', 1);
    }
}

if (! function_exists('brand_name')) {
    /**
     * Get the current brand name used across the UI.
     *
     * Falls back to the application name when no brand override is set.
     */
    function brand_name(): string
    {
        return (string) (config('tenant.brand.name') ?: config('app.name', 'SiHaris'));
    }
}

if (! function_exists('brand_asset')) {
    /**
     * Resolve a brand asset URL with an optional fallback.
     */
    function brand_asset(string $configKey, ?string $fallback = null): ?string
    {
        $path = config("tenant.brand.{$configKey}") ?: $fallback;

        return $path ? asset($path) : null;
    }
}

if (! function_exists('format_days')) {
    /**
     * Format a day-count value for display: whole numbers render with no
     * decimal places, fractional values (e.g. a half-day balance of 0.5)
     * keep one decimal place.
     */
    function format_days(float|int|string $value): string
    {
        $value = (float) $value;

        return $value == floor($value)
            ? number_format($value, 0)
            : number_format($value, 1);
    }
}

if (! function_exists('brand_color')) {
    /**
     * Return a brand color by key (e.g. primary, accent).
     */
    function brand_color(string $key, string $default = '#2563eb'): string
    {
        return (string) (config("tenant.brand.{$key}_color") ?: $default);
    }
}

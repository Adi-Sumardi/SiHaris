<?php

describe('format_days', function () {
    it('formats whole numbers without a decimal point', function () {
        expect(format_days(10))->toBe('10')
            ->and(format_days(10.0))->toBe('10')
            ->and(format_days('12.0'))->toBe('12')
            ->and(format_days(0))->toBe('0');
    });

    it('keeps one decimal place for fractional values', function () {
        expect(format_days(0.5))->toBe('0.5')
            ->and(format_days(10.5))->toBe('10.5')
            ->and(format_days('2.5'))->toBe('2.5');
    });

    it('rounds to one decimal place for values with more precision', function () {
        expect(format_days(1.25))->toBe('1.3');
    });
});

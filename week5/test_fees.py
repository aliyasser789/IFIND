"""Unit and regression tests for fee calculation."""

import pytest

from fees import calculate_fee


@pytest.mark.parametrize(
    "scholarship, late_payment, expected",
    [
        (False, False, 1000),
        (True, False, 800),
        (False, True, 1100),
        (True, True, 900),
    ],
)
def test_calculate_fee(scholarship, late_payment, expected):
    """Verify fee calculation for all boolean combinations."""
    assert calculate_fee(scholarship, late_payment) == expected


@pytest.mark.parametrize(
    "late_payment, expected",
    [
        (False, 800),
        (True, 900),
    ],
)
def test_correct_scholarship_discount(late_payment, expected):
    """Verify that scholarship students receive a 20% discount."""
    assert calculate_fee(True, late_payment) == expected

"""Unit tests for grade calculation."""

import pytest

from grades import calculate_grade


@pytest.mark.parametrize(
    "score, expected",
    [
        (95, "A"),
        (85, "B"),
        (75, "C"),
        (65, "D"),
        (45, "F"),
        (100, "A"),
        (0, "F"),
        (60, "D"),
        (59, "F"),
    ],
)
def test_calculate_grade(score, expected):
    """Verify correct letter grades for valid scores."""
    assert calculate_grade(score) == expected


@pytest.mark.parametrize("score", [-5, 105])
def test_invalid_grade(score):
    """Verify that invalid scores raise a ValueError."""
    with pytest.raises(ValueError):
        calculate_grade(score)

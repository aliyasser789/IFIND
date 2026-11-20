## 4. Fee Calculation Findings

### Static Analysis

- Ruff: All checks passed.
- Pylint: 5 issues detected.
- Pylint score: 2.86/10.

| Code | Issue | Occurrences |
|---|---|---|
| C0304 | Missing final newline | 1 |
| C0114 | Missing module docstring | 1 |
| C0116 | Missing function docstring | 1 |
| C0121 | Unnecessary boolean comparison | 2 |

### Code Smells

- Hardcoded fee, discount and penalty values.
- Unnecessary comparisons with True.
- Missing documentation.
- Magic numbers.

## 5. Hidden Bug

The scholarship discount is incorrectly calculated
as 10% instead of the intended 20%.

### Root Cause

The discount multiplier is 0.10 instead of 0.20.

### Test Evidence

| Scenario | Expected | Actual | Result |
|---|---|---|---|
| Scholarship without penalty | 800 | 900 | FAILED |
| Scholarship with penalty | 900 | 1000 | FAILED |

### Test Results Before Bug Fix

- Characterization tests: 4 passed.
- Regression tests: 2 failed.
- Execution time: 0.14 seconds.

### Proposed Solution

- Correct the scholarship discount to 20%.
- Replace magic numbers with named constants.
- Simplify boolean conditions.
- Add appropriate documentation.
- Update the outdated characterization expectations.
- Rerun all tests and static analysis tools.

# Week 5 - After Refactoring

## 1. Grading Code Refactoring

### grades.py
- Added module and function docstrings.
- Removed unnecessary elif statements.
- Simplified control flow.
- Fixed missing final newline.
- Preserved the original grading behavior.

### test_grades.py
- Replaced repetitive tests with pytest parametrization.
- Corrected import formatting.
- Added appropriate docstrings.
- Preserved all nine original test cases.

### Grading Results

| Metric | Before | After |
|---|---|---|
| Ruff issues | 1 | 0 |
| Pylint issues | 15 | 0 |
| Pylint score | 5.16/10 | 10.00/10 |
| Tests passed | 9/9 | 9/9 |

## 2. Fee Calculation Refactoring

### fees.py
- Replaced magic numbers with named constants.
- Simplified boolean conditions.
- Added module and function docstrings.
- Corrected the scholarship discount from 10% to 20%.
- Fixed missing final newline.

### test_fees.py
- Added characterization tests.
- Added regression tests to expose the discount bug.
- Updated outdated expected values after the bug fix.
- Fixed missing final newline.

### Fee Calculation Results

| Metric | Before | After |
|---|---|---|
| Ruff issues | 0 | 0 |
| Pylint issues | 5 | 0 |
| Pylint score | 2.86/10 | 10.00/10 |
| Tests passed | 4/6 | 6/6 |
| Regression tests passed | 0/2 | 2/2 |

Note: The initial fee analysis covered fees.py alone.
The final analysis covered fees.py and test_fees.py.

## 3. Bug Fix Verification

The example scholarship discount was incorrectly
calculated using 10% instead of the intended 20%.

| Scenario | Before | After |
|---|---|---|
| Standard student | 1000 | 1000 |
| Scholarship student | 900 | 800 |
| Late payment | 1100 | 1100 |
| Scholarship with late payment | 1000 | 900 |

Both regression tests now pass successfully.

## 4. Overall Results

| Metric | Final Result |
|---|---|
| Grading tests | 11/11 passed |
| Fee calculation tests | 6/6 passed |
| Total tests | 17/17 passed |
| Execution time | 0.07 seconds |
| Ruff issues | 0 |
| Pylint issues | 0 |
| Pylint score | 10.00/10 |

## 5. Conclusion

The refactoring improved readability, maintainability,
documentation and test organization.

The scholarship discount bug in the constructed example
was successfully identified and corrected.

All 15 tested cases passed after refactoring.

## 6. Pairing Reflection

We collaborated on improving the grading system and
covering missing test cases. My partner contributed
additional tests for invalid grade inputs. Testing
helped us identify incorrect behavior and verify
the refactored code. This exercise demonstrated
the importance of collaboration, code quality,
and automated testing.

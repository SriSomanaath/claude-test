---
name: Test Report
description: Structured test report output for component validation
keep-coding-instructions: true
---

# Test Report Output Format

Format all component test results using this structure:

## Report Header

```
============================================================
COMPONENT TEST REPORT
============================================================
Component: [ComponentName]
File: [file/path.tsx]
Date: [YYYY-MM-DD]
============================================================
```

## Score Section

```
OVERALL SCORE: [XX]/100  [PASS/FAIL]

┌─────────────────────┬───────┬────────┐
│ Category            │ Score │ Status │
├─────────────────────┼───────┼────────┤
│ Standards           │ XX/20 │ [P/F]  │
│ Optimization        │ XX/20 │ [P/F]  │
│ Browser Compat      │ XX/20 │ [P/F]  │
│ Accessibility       │ XX/20 │ [P/F]  │
│ Security            │ XX/10 │ [P/F]  │
│ Test Coverage       │ XX/10 │ [P/F]  │
└─────────────────────┴───────┴────────┘
```

## Issues Section

Use severity tags:
- `[CRITICAL]` - Must fix before deployment
- `[WARNING]` - Should fix, potential problems
- `[INFO]` - Suggestions for improvement

```
ISSUES FOUND: [X Critical, X Warning, X Info]
------------------------------------------------------------

[CRITICAL] Issue Title
  Location: file.tsx:XX
  Problem: Description of the issue
  Impact: What could go wrong

[WARNING] Issue Title
  Location: file.tsx:XX
  Problem: Description of the issue

[INFO] Issue Title
  Location: file.tsx:XX
  Suggestion: How to improve
```

## Fixes Section

```
RECOMMENDED FIXES
------------------------------------------------------------

Fix #1: [Issue Title]
┌─ Before ─────────────────────────────────────────────────┐
│ [code that has the problem]                              │
└──────────────────────────────────────────────────────────┘
┌─ After ──────────────────────────────────────────────────┐
│ [corrected code]                                         │
└──────────────────────────────────────────────────────────┘

Fix #2: [Issue Title]
...
```

## Browser Compatibility Matrix

```
BROWSER COMPATIBILITY
------------------------------------------------------------
┌──────────────┬────────┬─────────┬────────┬───────┬───────┐
│ Feature      │ Chrome │ Firefox │ Safari │ Edge  │ Mobile│
├──────────────┼────────┼─────────┼────────┼───────┼───────┤
│ CSS Grid     │   OK   │   OK    │   OK   │  OK   │  OK   │
│ Flexbox      │   OK   │   OK    │   OK   │  OK   │  OK   │
│ ES6 Features │   OK   │   OK    │   OK   │  OK   │  OK   │
│ [Feature]    │  [OK]  │  [OK]   │ [WARN] │ [OK]  │ [OK]  │
└──────────────┴────────┴─────────┴────────┴───────┴───────┘
```

## Summary Section

```
============================================================
SUMMARY
============================================================
Verdict: [PASS/FAIL]

[If PASS]
Component meets all critical standards. Ready for review.

[If FAIL]
Component has [X] critical issues that must be resolved:
1. [Critical issue summary]
2. [Critical issue summary]

Next Steps:
1. [Action item]
2. [Action item]
============================================================
```

## Rules

1. Always show the score table first
2. List CRITICAL issues before WARNING before INFO
3. Provide specific line numbers for all issues
4. Include before/after code for every fix
5. Be concise but complete
6. End with clear pass/fail verdict

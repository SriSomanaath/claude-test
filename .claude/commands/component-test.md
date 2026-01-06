Comprehensive component testing and validation.

Run a full analysis on the specified component covering:

## 1. Standards Compliance
- [ ] Follows project coding standards (CLAUDE.md)
- [ ] Proper TypeScript types (no `any`)
- [ ] Correct file naming convention
- [ ] Import order followed
- [ ] Proper component structure
- [ ] JSDoc/docstrings present

## 2. Optimization Check
- [ ] No unnecessary re-renders (memo, useMemo, useCallback)
- [ ] Efficient state management
- [ ] No memory leaks (cleanup in useEffect)
- [ ] Bundle size impact (heavy imports)
- [ ] Lazy loading where appropriate
- [ ] No redundant computations

## 3. Browser Compatibility
- [ ] CSS features supported (flexbox, grid, etc.)
- [ ] ES6+ features with proper polyfills
- [ ] Event handling cross-browser
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Touch vs mouse interactions
- [ ] Browser-specific CSS prefixes needed

## 4. Accessibility (a11y)
- [ ] Semantic HTML elements
- [ ] ARIA attributes where needed
- [ ] Keyboard navigation support
- [ ] Screen reader friendly
- [ ] Color contrast compliance
- [ ] Focus management

## 5. Security
- [ ] No XSS vulnerabilities (dangerouslySetInnerHTML)
- [ ] Input sanitization
- [ ] No sensitive data in client code
- [ ] Secure API calls

## 6. Test Coverage
- [ ] Unit tests exist
- [ ] Edge cases covered
- [ ] Error states tested
- [ ] Loading states tested
- [ ] User interactions tested

## Output Format
Use `/output-style test-report` for structured results.

Provide:
1. **Score**: Overall score out of 100
2. **Issues**: List of problems found (Critical/Warning/Info)
3. **Fixes**: Specific code fixes for each issue
4. **Summary**: Pass/Fail verdict with recommendations

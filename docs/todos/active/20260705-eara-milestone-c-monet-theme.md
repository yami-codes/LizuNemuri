# Milestone C — Global Monet theme

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: #11

---

## 1. Goal

App-wide accent from now-playing cover (Monet); remove static ColorVariant picker.

## 2. Scope

**In scope:**
- `DynamicHueController` + DI + `main.dart` wiring
- `AppColors.schemeFromPlayerPalette`
- Remove settings color-variant section
- `SidebarDecoration` no longer depends on `ColorVariant`
- Tests updated

**Out of scope:**
- (none listed)

## 3. Acceptance

- [ ] Theme primary updates when track/cover changes
- [ ] Idle fallback accent when nothing playing
- [ ] Color variant UI removed
- [ ] All tests pass

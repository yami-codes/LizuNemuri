# Milestone C — Global Monet theme

- **创建时间**：2026-07-05
- **状态**：active
- **关联 PR**：#11

## Goal
App-wide accent from now-playing cover (Monet); remove static ColorVariant picker.

## Scope
- `DynamicHueController` + DI + `main.dart` wiring
- `AppColors.schemeFromPlayerPalette`
- Remove settings color-variant section
- `SidebarDecoration` no longer depends on `ColorVariant`
- Tests updated

## Acceptance
- [ ] Theme primary updates when track/cover changes
- [ ] Idle fallback accent when nothing playing
- [ ] Color variant UI removed
- [ ] All tests pass

---
name: admin-visual-restyle
metadata:
  type: decision
---

# Admin Panel Visual Restyle

## Decision

Restyled the existing AcquireBase admin panels using the reference at `design_reference/stitch_acquirebase_material_3_admin_panel/acquirebase_admin/DESIGN.md` as a **style-only** guide.

## Scope

Only colors, typography, spacing, shapes, and layout patterns were changed. No new screens, features, buttons, or data fields from the reference were added. Specifically excluded:

- Reports / flagged-content screen
- Pricing / ARR / TTM / revenue / profit / financial verification
- "New Listing" quick-add
- Two-Factor Auth
- Language & Region setting
- Notification preference toggles
- New Settings screen sections

## Tokens applied

- Font: Inter via `google_fonts`
- Primary: `#065EFF` (Electric Blue)
- Secondary: `#425BA3` (Steel Blue)
- Tertiary: `#9B2D00` (Burnt Orange)
- Surface container hierarchy: lowest → highest for layered cards
- Buttons: 8 px rounded rectangle
- Cards: 16 px radius on `surfaceContainerLow`
- Search / filter chips: pill-shaped (`StadiumBorder`)
- Admin shell: `NavigationRail` on desktop, `NavigationBar` on mobile
- Admin Overview: large metric-card grid
- Admin Moderation / Users: data tables on desktop, cards on mobile
- Admin project review: blue moderation-status banner

## Files changed

- `lib/core/theme/app_theme.dart` — explicit `ColorScheme`, Inter text theme, component themes
- `lib/features/admin/admin_panel_screen.dart` — responsive rail/bottom navigation shell
- `lib/features/admin/admin_overview_tab.dart` — large metric-card grid
- `lib/features/admin/admin_moderation_tab.dart` — desktop data table + mobile cards
- `lib/features/admin/admin_users_tab.dart` — desktop data table + mobile cards
- `lib/features/admin/admin_user_detail_screen.dart`
- `lib/features/admin/admin_audit_log_tab.dart`
- `lib/features/projects/project_detail_screen.dart` — admin review status banner

## Rationale

A unified admin look makes the demo feel coherent and lets every admin screen inherit the same tokens without scattering hard-coded colors. Staying style-only avoids scope creep while the project is still on the Spark plan.

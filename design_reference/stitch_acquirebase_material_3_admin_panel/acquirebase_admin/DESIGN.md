---
name: AcquireBase Admin
colors:
  surface: '#fbf8ff'
  surface-dim: '#d9d9e6'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f2ff'
  surface-container: '#ededfb'
  surface-container-high: '#e7e7f5'
  surface-container-highest: '#e1e1ef'
  on-surface: '#191b25'
  on-surface-variant: '#424656'
  inverse-surface: '#2e303a'
  inverse-on-surface: '#f0effd'
  outline: '#737688'
  outline-variant: '#c3c5d9'
  surface-tint: '#0051e0'
  primary: '#0048c9'
  on-primary: '#ffffff'
  primary-container: '#035dfe'
  on-primary-container: '#eceeff'
  inverse-primary: '#b5c4ff'
  secondary: '#425ba3'
  on-secondary: '#ffffff'
  secondary-container: '#99b0ff'
  on-secondary-container: '#274188'
  tertiary: '#9b2d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c53b00'
  on-tertiary-container: '#ffeae5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b5c4ff'
  on-primary-fixed: '#00164d'
  on-primary-fixed-variant: '#003cac'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174c'
  on-secondary-fixed-variant: '#294289'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59e'
  on-tertiary-fixed: '#3a0b00'
  on-tertiary-fixed-variant: '#842500'
  background: '#fbf8ff'
  on-background: '#191b25'
  surface-variant: '#e1e1ef'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
  headline-md:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
  title-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter-desktop: 24px
  margin-desktop: 32px
  gutter-mobile: 16px
  margin-mobile: 16px
  rail-width: 80px
  drawer-width: 360px
---

## Brand & Style

The design system is rooted in the **Corporate / Modern** aesthetic, specifically following the Material 3 (Material You) specification. It is designed for an enterprise-grade SaaS marketplace, prioritizing clarity, data density, and functional hierarchy.

The brand personality is professional, reliable, and efficient. It avoids decorative flourishes like gradients or glassmorphism in favor of a tonal surface system where depth is communicated through color luminance and subtle elevation. The interface is "data-focused," ensuring that the complex information of a marketplace—listings, analytics, and user management—remains the primary focus for the administrator. The updated palette introduces a tech-forward Electric Blue to suggest precision, speed, and digital innovation within the acquisition space.

## Colors

The color system utilizes a **Tonal Palette** approach. The Primary Electric Blue (#065EFF) serves as the main brand anchor for high-emphasis actions and active states. The Secondary Steel Blue (#5C74BE) is reserved for structural elements, specifically navigation surfaces (Rails and Drawers) to provide a professional, high-contrast frame for content. The Tertiary Burnt Orange (#C53B00) provides a vibrant accent for complementary data points and distinct call-outs.

### Surface Tiers
- **Surface:** The base layer of the application, utilizing a clean neutral base.
- **Surface Container Low:** Used for card backgrounds and secondary data sections.
- **Surface Container High:** Used for navigation rails and top app bars to distinguish them from the content area.
- **Surface Variant:** Used for subtle dividers and inactive states.

### Status Colors
Semantic colors (Success, Warning, Error, Info) are used sparingly to highlight critical system states, data trends, and destructive actions.

## Typography

The design system uses **Inter** for all levels to ensure maximum legibility across dense data tables and complex dashboards. 

- **Headlines:** Reserved for page titles and high-level dashboard metrics.
- **Titles:** Used for card headers, section titles, and modal headers.
- **Body:** The workhorse for all content, listing descriptions, and user information.
- **Labels:** Utilized for form field labels, button text, and small metadata like table headers.

Letter spacing is increased for smaller labels to maintain readability in condensed admin views.

## Layout & Spacing

The design system uses a **Fluid Grid** model with specific breakpoints for desktop (1440px) and mobile (390px).

### Desktop Layout
- **Navigation Rail:** A fixed 80px vertical rail on the left.
- **Columns:** 12-column grid.
- **Gutter:** 24px.
- **Margins:** 32px surrounding the main content area.

### Mobile Layout
- **Navigation Bar:** Fixed bottom navigation or a modal navigation drawer.
- **Columns:** 4-column grid.
- **Gutter:** 16px.
- **Margins:** 16px.

Spacing follows a 4px baseline grid. Padding within components should always be a multiple of 4 (e.g., 8px, 16px, 24px).

## Elevation & Depth

This design system uses **Tonal Layers** rather than heavy shadows to create depth, consistent with Material 3. 

1.  **Level 0 (Flat):** The main background surface.
2.  **Level 1 (Tonal):** Cards and secondary containers. These use a subtle tint of the primary Electric Blue over the surface color.
3.  **Level 2 (Lifted):** Active states, dropdown menus, and hovered cards. Uses a soft, diffused 4px blur shadow.
4.  **Level 3 (Floating):** Modals, dialogs, and FABs (Floating Action Buttons). High contrast shadow with 8px-12px blur.

Borders are used primarily for inputs and table rows, utilizing a "Surface Variant" color to keep the UI clean.

## Shapes

The shape language is **Rounded (Level 2)** to balance professionalism with modern SaaS friendliness.

- **Buttons & Small Components:** 8px (0.5rem) corner radius.
- **Cards & Modals:** 16px (1rem) corner radius.
- **Search Bars & Navigation Pills:** Fully rounded (Pill-shaped) for distinct interactive clarity.
- **Data Tables:** Outer corners are rounded to 12px, while internal row borders remain sharp to maintain a grid-like feel.

## Components

### Buttons
- **Primary:** Filled with Primary Electric Blue (#065EFF), white text. 8px radius.
- **Secondary:** Tonal (Steel Blue background, Primary Electric Blue text).
- **Outlined:** Surface Variant border, Primary text. For lower emphasis.

### Cards
- Cards use **Surface Container Low** backgrounds. 
- No borders on standard cards; depth is defined by tonal contrast.
- Padded with 24px internal spacing for data-heavy views.

### Navigation Rail (Desktop)
- Fixed to the left. 
- Active icons are encased in a pill-shaped tonal container (Primary color at 12% opacity).
- Labels use `label-md` typography.

### Data Tables
- Header row uses a subtle neutral background (Surface Variant).
- Row height: 52px for standard, 44px for "dense" mode.
- Text uses `body-md`. Action icons (Edit, Delete) are grouped at the far right.

### Input Fields
- **Filled Style:** Following Material 3, with a bottom indicator line.
- Labels use `label-lg` and float when the field is active.
- Rounded corners applied only to the top (4px).

### Chips
- Used for project categories (e.g., "SaaS", "E-commerce").
- 8px radius or pill-shaped.
- Filter chips include a leading icon for "X" to clear.
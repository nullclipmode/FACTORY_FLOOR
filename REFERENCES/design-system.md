---
description: Extract design tokens from references, generate platform-specific theme files
---

# /design-system

**Location:** `~/.claude/commands/design-system.md`
**Purpose:** Extract design tokens from references, generate platform-specific theme files, approve via kitchen sink
**Allowed Tools:** Bash, Read, Write, Edit, Browser (Chrome)

---

## When to Use

- After SPEC.md exists but before /new-app
- When user has design references (screenshots, URLs, examples)
- **Only for projects with UI** â€” skip for API-only, CLI, Python backend

---

## Phase 0: Detect Project Type

### Step 1: Scan Project

Look for platform indicators:

| File | Indicates |
|------|-----------|
| `package.json` with `next` or `react` | Web (Next.js/React) |
| `tailwind.config.*` | Web with Tailwind |
| `pubspec.yaml` | Flutter |
| `Podfile` or `*.xcodeproj` | iOS Native |
| `build.gradle` with Android | Android Native |
| `pyproject.toml` or `requirements.txt` only | Python (no UI) |
| `Cargo.toml` only | Rust (likely no UI) |

### Step 2: Classify Project

| Classification | Condition | Action |
|----------------|-----------|--------|
| Web Only | package.json with next/react, no pubspec.yaml | Generate web tokens |
| Flutter Only | pubspec.yaml, no package.json | Generate Flutter theme |
| Web + Flutter | Both present | Generate both, shared canonical tokens |
| Native iOS | Xcode project, no Flutter | Generate iOS assets (limited support) |
| Native Android | Gradle, no Flutter | Generate Android resources (limited support) |
| No UI | Python/Rust/Go backend only | Exit with message |
| Unknown | Can't determine | Ask user |

### Step 3: Handle No UI

If project has no UI:

```
Design system not applicable.

This project appears to be:
- [Python backend / API / CLI tool / etc.]

Design systems apply to projects with user interfaces.
No action needed.
```

Exit command.

### Step 4: Confirm Detection

```
Detected project type: [Web / Flutter / Web + Flutter]

Platforms to generate:
- [x] Web (Tailwind + tokens.ts)
- [x] Flutter (ThemeData + ColorScheme)

Proceed with design extraction? (or specify different platforms)
```

Wait for confirmation.

---

## Phase 1: Locate References

### Check for Design References

Search these locations:

1. `/references/` folder â€” screenshots, images
2. SPEC.md â€” URLs, design direction section
3. User-provided URLs in conversation

**Supported reference types:**
- Screenshots (PNG, JPG, WebP)
- URLs to live sites
- Figma links (view via Chrome)
- Design system documentation URLs

**If no references found:**
```
No design references found.

To extract a design system, I need visual references:

1. Add screenshots to /references/ folder
2. Provide URLs to sites with the desired aesthetic
3. Share Figma/design file links

What references would you like to use?
```

Wait for user input.

---

## Phase 2: Extract Canonical Tokens

Extract to platform-agnostic format first. This becomes the source of truth.

### Colors

| Category | What to Extract |
|----------|-----------------|
| Primary | Main brand/action color + full scale (50-950) |
| Secondary | Supporting brand color + scale (if present) |
| Neutral | Gray scale for backgrounds, text, borders |
| Success | Green scale for positive states |
| Warning | Amber/yellow scale for caution states |
| Error | Red scale for error states |
| Info | Blue scale for informational states |

**Extraction method:**
- Use eyedropper in Chrome DevTools
- Note exact hex values
- Generate full scales from base colors

### Typography

| Property | What to Extract |
|----------|-----------------|
| Font families | Headings, body, mono |
| Size scale | xs through 5xl (or equivalent) |
| Weights | normal, medium, semibold, bold |
| Line heights | tight, normal, relaxed |
| Letter spacing | tight, normal, wide |

### Spacing

| Property | What to Extract |
|----------|-----------------|
| Base unit | Usually 4px or 8px |
| Scale | Multipliers of base unit |

### Shape

| Property | What to Extract |
|----------|-----------------|
| Border radius | none, sm, md, lg, xl, full |
| Shadows | sm, md, lg, xl elevation levels |

---

## Phase 3: Generate Canonical tokens.json

Create `/design/tokens.json` â€” the platform-agnostic source of truth:

```json
{
  "$schema": "https://design-tokens.org/schema.json",
  "meta": {
    "generatedFrom": ["reference1.png", "https://example.com"],
    "generatedAt": "2026-01-06T12:00:00Z",
    "status": "draft"
  },
  "colors": {
    "primary": {
      "50": "#eff6ff",
      "100": "#dbeafe",
      "200": "#bfdbfe",
      "300": "#93c5fd",
      "400": "#60a5fa",
      "500": "#3b82f6",
      "600": "#2563eb",
      "700": "#1d4ed8",
      "800": "#1e40af",
      "900": "#1e3a8a",
      "950": "#172554"
    },
    "neutral": { },
    "success": { },
    "warning": { },
    "error": { }
  },
  "typography": {
    "fontFamilies": {
      "sans": ["Inter", "system-ui", "sans-serif"],
      "mono": ["JetBrains Mono", "monospace"]
    },
    "fontSizes": {
      "xs": { "value": 12, "unit": "px", "lineHeight": 16 },
      "sm": { "value": 14, "unit": "px", "lineHeight": 20 },
      "base": { "value": 16, "unit": "px", "lineHeight": 24 },
      "lg": { "value": 18, "unit": "px", "lineHeight": 28 },
      "xl": { "value": 20, "unit": "px", "lineHeight": 28 },
      "2xl": { "value": 24, "unit": "px", "lineHeight": 32 },
      "3xl": { "value": 30, "unit": "px", "lineHeight": 36 },
      "4xl": { "value": 36, "unit": "px", "lineHeight": 40 },
      "5xl": { "value": 48, "unit": "px", "lineHeight": 48 }
    },
    "fontWeights": {
      "normal": 400,
      "medium": 500,
      "semibold": 600,
      "bold": 700
    }
  },
  "spacing": {
    "baseUnit": 4,
    "scale": {
      "0": 0,
      "1": 4,
      "2": 8,
      "3": 12,
      "4": 16,
      "5": 20,
      "6": 24,
      "8": 32,
      "10": 40,
      "12": 48,
      "16": 64,
      "20": 80,
      "24": 96
    }
  },
  "borderRadius": {
    "none": 0,
    "sm": 2,
    "md": 4,
    "lg": 8,
    "xl": 12,
    "2xl": 16,
    "full": 9999
  },
  "shadows": {
    "sm": "0 1px 2px 0 rgb(0 0 0 / 0.05)",
    "md": "0 4px 6px -1px rgb(0 0 0 / 0.1)",
    "lg": "0 10px 15px -3px rgb(0 0 0 / 0.1)",
    "xl": "0 20px 25px -5px rgb(0 0 0 / 0.1)"
  }
}
```

---

## Phase 4: Generate Platform-Specific Files

### If Web (Tailwind)

**File: `/design/tokens.ts`**

```typescript
// Design Tokens - Web
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

export const colors = {
  primary: {
    50: '#eff6ff',
    // ... full scale
    DEFAULT: '#3b82f6',
  },
  // ... other colors
} as const;

export const typography = {
  fontFamily: {
    sans: ['Inter', 'system-ui', 'sans-serif'],
    mono: ['JetBrains Mono', 'monospace'],
  },
  fontSize: {
    xs: ['0.75rem', { lineHeight: '1rem' }],
    // ... full scale
  },
} as const;

// ... spacing, borderRadius, shadows
```

**File: `/tailwind.config.js`**

```javascript
// Tailwind Configuration
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

import { colors, typography } from './design/tokens';

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{js,ts,jsx,tsx}', './app/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors,
      fontFamily: typography.fontFamily,
      fontSize: typography.fontSize,
    },
  },
  plugins: [],
};
```

### If Flutter

**File: `/lib/theme/colors.dart`**

```dart
// Design Tokens - Colors
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary100 = Color(0xFFDBEAFE);
  static const Color primary200 = Color(0xFFBFDBFE);
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary500 = Color(0xFF3B82F6);
  static const Color primary600 = Color(0xFF2563EB);
  static const Color primary700 = Color(0xFF1D4ED8);
  static const Color primary800 = Color(0xFF1E40AF);
  static const Color primary900 = Color(0xFF1E3A8A);
  static const Color primary950 = Color(0xFF172554);
  
  static const Color primary = primary500;

  // Neutral
  static const Color neutral50 = Color(0xFFFAFAFA);
  // ... full scale

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Material color swatches for ThemeData
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF3B82F6,
    <int, Color>{
      50: primary50,
      100: primary100,
      200: primary200,
      300: primary300,
      400: primary400,
      500: primary500,
      600: primary600,
      700: primary700,
      800: primary800,
      900: primary900,
    },
  );
}
```

**File: `/lib/theme/typography.dart`**

```dart
// Design Tokens - Typography
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static String get _fontFamily => GoogleFonts.inter().fontFamily!;
  static String get _monoFontFamily => GoogleFonts.jetBrainsMono().fontFamily!;

  static TextTheme get textTheme => TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 48,
      fontWeight: FontWeight.bold,
      height: 1.0,
    ),
    displayMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.bold,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 30,
      fontWeight: FontWeight.bold,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    headlineSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.55,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
  );

  // Mono text style for code
  static TextStyle get mono => TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}
```

**File: `/lib/theme/spacing.dart`**

```dart
// Design Tokens - Spacing
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

class AppSpacing {
  AppSpacing._();

  static const double baseUnit = 4.0;

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  static const double space20 = 80;
  static const double space24 = 96;

  // Common padding/margin presets
  static const double xs = space1;
  static const double sm = space2;
  static const double md = space4;
  static const double lg = space6;
  static const double xl = space8;
  static const double xxl = space12;
}

class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;
  static const double full = 9999;
}
```

**File: `/lib/theme/app_theme.dart`**

```dart
// App Theme
// Generated from: /design/tokens.json
// Status: DRAFT - Awaiting approval

import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.neutral600,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.neutral900,
      error: AppColors.error,
      onError: Colors.white,
    ),
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.neutral50,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.neutral900,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.neutral200),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary400,
      onPrimary: AppColors.primary950,
      primaryContainer: AppColors.primary900,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.neutral400,
      onSecondary: AppColors.neutral950,
      surface: AppColors.neutral900,
      onSurface: AppColors.neutral50,
      error: AppColors.error,
      onError: Colors.white,
    ),
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.neutral50,
      displayColor: AppColors.neutral50,
    ),
    scaffoldBackgroundColor: AppColors.neutral950,
  );
}
```

---

## Phase 5: Generate Kitchen Sink

### If Web

**File: `/app/design/page.tsx`**

Create a page showing all colors, typography, spacing, and component examples using the generated tokens.

### If Flutter

**File: `/lib/screens/design_preview.dart`**

Create a screen showing all colors, typography, spacing, and component examples using the generated theme.

**Add to routes for preview access.**

---

## Phase 6: Present for Approval

```
## Design System Preview

### Platform: [Web / Flutter / Both]

### Preview Locations:
- Web: http://localhost:3000/design
- Flutter: Run app, navigate to Design Preview screen

### Extracted From
- [List reference sources]

### Files Generated

**Canonical (source of truth):**
- /design/tokens.json

**Web:** (if applicable)
- /design/tokens.ts
- /tailwind.config.js
- /app/design/page.tsx

**Flutter:** (if applicable)
- /lib/theme/colors.dart
- /lib/theme/typography.dart
- /lib/theme/spacing.dart
- /lib/theme/app_theme.dart
- /lib/screens/design_preview.dart

### Review Checklist

- [ ] Colors match reference intent
- [ ] Typography feels right
- [ ] Component styles look correct
- [ ] [If Flutter] Light and dark themes work

### Options

1. **Approve** â€” Lock tokens, proceed to build
2. **Adjust [specific token]** â€” I'll update and regenerate
3. **Major changes** â€” Describe what's wrong
```

---

## Phase 7: Lock on Approval

### Create Status File

**File: `/design/DESIGN_SYSTEM_STATUS.md`**

```markdown
# Design System Status

**Status:** âœ“ Approved
**Approved:** [timestamp]
**Platform:** [Web / Flutter / Both]
**References:** [list]

## Locked Files

### Canonical
- /design/tokens.json

### Web (if applicable)
- /design/tokens.ts
- /tailwind.config.js

### Flutter (if applicable)
- /lib/theme/colors.dart
- /lib/theme/typography.dart
- /lib/theme/spacing.dart
- /lib/theme/app_theme.dart

---
*Do not modify locked files directly. Run `/design-system` to update.*
```

---

## Command Syntax

```
/design-system                    # Full flow: detect â†’ extract â†’ preview â†’ approve
/design-system --web              # Force web output only
/design-system --flutter          # Force Flutter output only
/design-system --regenerate       # Re-extract from same references
/design-system --unlock           # Remove approval, allow modifications
```

---

## Platform Support Matrix

| Platform | Status | Output Files |
|----------|--------|--------------|
| Web (Tailwind) | âœ“ Full | tokens.ts, tailwind.config.js |
| Flutter | âœ“ Full | colors.dart, typography.dart, spacing.dart, app_theme.dart |
| React Native | âš ï¸ Partial | tokens.json â†’ manual conversion guidance |
| iOS Native | âš ï¸ Partial | tokens.json â†’ Asset catalog guidance |
| Android Native | âš ï¸ Partial | tokens.json â†’ XML resource guidance |
| Python/API | âœ— N/A | No UI â€” command exits |

---

## Notes

### Why Canonical tokens.json?

Single source of truth enables:
- Consistency across platforms in multi-platform projects
- Diffable history of design changes
- Future automation (Figma sync, CI validation)
- Platform additions without re-extraction

### Font Loading

**Web:** Use `next/font` or add to `_document.tsx`

**Flutter:** Add to pubspec.yaml:
```yaml
dependencies:
  google_fonts: ^6.1.0
```

### Dark Mode

**Web:** Use Tailwind's `dark:` variant or CSS variables

**Flutter:** `AppTheme.dark` provided. Use `ThemeMode.system` in MaterialApp.

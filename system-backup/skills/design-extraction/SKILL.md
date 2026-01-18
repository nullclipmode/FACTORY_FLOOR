---
description: Extract design tokens from screenshot - colors, fonts, spacing
---

# Design Extraction

Extract exact design specifications from a screenshot or URL reference.

## Steps

1. Verify reference accessible
2. Extract primary color (exact hex, e.g., #3B82F6)
3. Extract secondary color (exact hex or "none")
4. Extract neutral palette: background, surface, border, text-primary, text-muted (5 hex values)
5. Extract semantic colors: success, warning, error (3 hex values or "derive from primary")
6. Identify heading font (exact name or closest Google Font)
7. Identify body font (exact name or closest Google Font)
8. Extract font sizes: h1, h2, h3, body, small (5 pixel values)
9. Extract font weights used (e.g., 400, 500, 600, 700)
10. Extract spacing scale: xs, sm, md, lg, xl (5 pixel values)
11. Extract border radius: sm, md, lg (3 pixel values)
12. Extract shadow values (CSS shadow string or "none")
13. Create /design/tokens.json with all values
14. Verify tokens against original reference

## Output

Create `design/tokens.json`:

```json
{
  "colors": {
    "primary": "#hex",
    "secondary": "#hex",
    "neutral": { "background": "#hex", "surface": "#hex", "border": "#hex", "text": "#hex", "textMuted": "#hex" },
    "semantic": { "success": "#hex", "warning": "#hex", "error": "#hex" }
  },
  "typography": {
    "fonts": { "heading": "Font Name", "body": "Font Name" },
    "sizes": { "h1": 48, "h2": 36, "h3": 24, "body": 16, "small": 14 },
    "weights": [400, 500, 600, 700]
  },
  "spacing": { "xs": 4, "sm": 8, "md": 16, "lg": 24, "xl": 32 },
  "borderRadius": { "sm": 4, "md": 8, "lg": 12 },
  "shadows": { "sm": "...", "md": "...", "lg": "..." }
}
```

## Rules

- Extract EXACT values, no approximations
- If value cannot be determined, note "UNCERTAIN" with best guess
- Cross-reference final tokens against source

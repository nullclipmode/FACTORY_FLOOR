---
description: Clone a design exactly from screenshot - extract colors, spacing, fonts, layout
allowed-tools: Read, Write, Edit, Bash
---

# Clone Design from Screenshot

The user has provided a screenshot of a design they want to replicate EXACTLY.

## Phase 1: Extract Design Specifications

Analyze the screenshot with extreme precision:

**Colors:**
- Extract EXACT hex values for every color visible
- Primary, secondary, accent colors
- Background colors (note any gradients)
- Text colors (headings, body, muted)
- Border and shadow colors with opacity

**Typography:**
- Identify fonts (or closest match from Google Fonts)
- Font sizes for each text level (h1, h2, h3, body, small)
- Font weights used
- Line heights and letter spacing

**Spacing:**
- Padding values (inner spacing)
- Margin values (outer spacing)
- Gap between elements
- Section spacing
- Container max-widths

**Layout:**
- Grid structure (columns, rows)
- Breakpoint assumptions
- Alignment patterns

**Components:**
- Button styles (size, border-radius, shadows)
- Card styles
- Input field styles
- Navigation patterns

## Phase 2: Create Design Tokens

Create design tokens file capturing everything:
- src/styles/design-tokens.ts
- src/styles/globals.css
- tailwind.config.js updates

## Phase 3: Build the Component

Replicate EXACTLY:
- Match pixel-perfect where possible
- Use extracted tokens
- Include responsive behavior
- Include hover/focus states

## Phase 4: Comparison

Report:
- Original vs implementation
- Any differences and why
- Clarifications needed

## Rules

1. EXACT replication - do not improve unless asked
2. Preserve quirks - if design has unusual spacing, keep it
3. Note uncertainties - if you cannot determine a value, say so
4. Ask about mobile behavior if not shown

# Screen Style Guide

**Version:** 1.10 (January 2026)

Design system for toll system documentation and visualization pages displayed on screen and print. Includes components for operational personas, customer journeys, service blueprints, and CX frameworks.

---

## Typography

### Font Families

| Role | Font | Fallback Stack |
|------|------|----------------|
| Primary (UI & Body) | Source Sans 3 | `'Source Sans 3', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif` |
| Accent (Callouts) | Source Serif 4 | `'Source Serif 4', Georgia, 'Times New Roman', serif` |
| Monospace (Code) | Source Code Pro | `'Source Code Pro', 'SF Mono', Consolas, 'Liberation Mono', monospace` |
| Icons | Material Symbols Rounded | — |

Load from Google Fonts:
```html
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;500;600;700&family=Source+Serif+4:ital,wght@0,400;0,600;1,400&family=Source+Code+Pro:wght@400;500&family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0&display=swap" rel="stylesheet">
```

### Font Weights

**Source Sans 3**
| Weight | Value | Usage |
|--------|-------|-------|
| Regular | 400 | Body text, paragraphs |
| Semibold | 600 | Headings, labels, emphasis |
| Bold | 700 | Display text, strong emphasis (use sparingly) |

**Source Serif 4**
| Weight | Value | Usage |
|--------|-------|-------|
| Regular | 400 | Pull quotes, callout body text |
| Semibold | 600 | Callout emphasis, attributions |
| Italic | 400i | Epigraphs, citations |

**Source Code Pro**
| Weight | Value | Usage |
|--------|-------|-------|
| Regular | 400 | All code samples |
| Medium | 500 | Syntax highlighting keywords (optional) |

### Type Scale — Screen

Based on a **1.250 (Major Third)** ratio with a **16px** base. This tighter scale provides better information density for documentation.

| Level | Size | rem | Line Height | Weight | Font |
|-------|------|-----|-------------|--------|------|
| Display | 39px | 2.441rem | 1.1 | 700 | Source Sans 3 |
| H1 (Page Title) | 31px | 1.953rem | 1.2 | 600 | Source Sans 3 |
| H2 (Section Title) | 25px | 1.563rem | 1.25 | 600 | Source Sans 3 |
| H3 (Subsection) | 20px | 1.25rem | 1.3 | 600 | Source Sans 3 |
| H4 (Card Title) | 16px | 1rem | 1.4 | 600 | Source Sans 3 |
| Body | 16px | 1rem | 1.6 | 400 | Source Sans 3 |
| Body Small | 13px | 0.8rem | 1.5 | 400 | Source Sans 3 |
| Caption / Label | 10px | 0.64rem | 1.4 | 600 | Source Sans 3 |
| Tag | 9px | 0.563rem | 1.3 | 600 | Source Sans 3 |
| Code Inline | 13px | 0.8rem | inherit | 400 | Source Code Pro |
| Code Block | 13px | 0.8rem | 1.5 | 400 | Source Code Pro |

### Type Scale — Print

| Level | Size | Line Height | Weight | Font |
|-------|------|-------------|--------|------|
| Display | 30pt | 1.1 | 700 | Source Sans 3 |
| H1 | 24pt | 1.2 | 600 | Source Sans 3 |
| H2 | 19pt | 1.25 | 600 | Source Sans 3 |
| H3 | 15pt | 1.3 | 600 | Source Sans 3 |
| H4 | 12pt | 1.4 | 600 | Source Sans 3 |
| Body | 11pt | 1.5 | 400 | Source Sans 3 |
| Body Small | 9pt | 1.45 | 400 | Source Sans 3 |
| Caption | 8pt | 1.4 | 400 | Source Sans 3 |
| Code Inline | 9pt | inherit | 400 | Source Code Pro |
| Code Block | 9pt | 1.45 | 400 | Source Code Pro |

### Source Serif 4 — Accent Usage

Use Source Serif 4 sparingly to create deliberate contrast:

| Element | Size (Screen) | Size (Print) | Weight | Style |
|---------|---------------|--------------|--------|-------|
| Pull quote | 20px | 15pt | 400 | Regular |
| Callout box body | 16px | 11pt | 400 | Regular |
| Introduction paragraph | 17px | 12pt | 400 | Regular |
| Epigraph | 16px | 11pt | 400 | Italic |
| Attribution | 13px | 9pt | 600 | Semibold |

**When to use Source Serif 4:**
- Opening paragraphs of major sections
- Executive summaries
- Highlighted quotations
- Formal notes or asides
- Document epigraphs

**When not to use Source Serif 4:**
- Regular body text
- Headings
- Navigation
- Tables
- Code-adjacent content

### Text Spacing

| Element | Margin Top | Margin Bottom |
|---------|------------|---------------|
| H1 | 48px | 24px |
| H2 | 40px | 16px |
| H3 | 32px | 12px |
| H4 | 24px | 8px |
| Paragraph | 0 | 16px |
| Code block | 24px | 24px |
| Pull quote | 32px | 32px |
| List | 0 | 16px |
| List item | 0 | 8px |

### Maximum Line Length

| Context | Max Width |
|---------|-----------|
| Body text (screen) | 70–75 characters (~680px) |
| Body text (print) | 65–70 characters |
| Code blocks | 80 characters |

---

## Icon System

### Material Symbols Rounded

> ⚠️ **MANDATORY**: All icons in this design system **must** use Material Symbols Rounded. **Never use emoji** (📄, 📐, ✓, ⚠️, etc.) in any HTML document. Emoji lack consistent rendering across platforms and appear unprofessional.

This design system uses **Material Symbols Rounded** for all iconography, replacing emoji-based icons for better consistency, accessibility, and professional appearance.

#### Icon CSS Class

```css
.material-symbols-rounded {
    font-family: 'Material Symbols Rounded';
    font-weight: normal;
    font-style: normal;
    font-size: 24px;
    line-height: 1;
    letter-spacing: normal;
    text-transform: none;
    display: inline-block;
    white-space: nowrap;
    word-wrap: normal;
    direction: ltr;
    font-feature-settings: 'liga';
    -webkit-font-smoothing: antialiased;
}
```

#### Icon Sizing

| Context | Size | Class Modifier |
|---------|------|----------------|
| Inline with text | 18px | `.icon-sm` |
| Default | 24px | (none) |
| Card headers | 28px | `.icon-md` |
| Large callouts | 32px | `.icon-lg` |
| Hero sections | 48px | `.icon-xl` |

```css
.icon-sm { font-size: 18px; }
.icon-md { font-size: 28px; }
.icon-lg { font-size: 32px; }
.icon-xl { font-size: 48px; }
```

#### Icon Usage

Use icons inline with the `.material-symbols-rounded` class:

```html
<span class="material-symbols-rounded">settings</span>
<span class="material-symbols-rounded icon-sm">check_circle</span>
```

#### Icon Reference

Common icons used throughout the CX framework:

| Category | Icon Name | Use Case |
|----------|-----------|----------|
| **Status** | `check_circle` | Success, complete, on-target |
| | `warning` | At-risk, caution |
| | `error` | Failed, breached |
| | `info` | Information, neutral |
| | `pending` | In progress, waiting |
| **Navigation** | `arrow_forward` | Flow direction, next step |
| | `arrow_back` | Previous step |
| | `chevron_right` | Expand, navigate |
| | `expand_more` | Dropdown, expand |
| **Content** | `description` | Document, report |
| | `folder` | Category, group |
| | `bookmark` | Saved, important |
| | `label` | Tag, category |
| **Actions** | `settings` | Configuration, admin |
| | `edit` | Modify, update |
| | `visibility` | View, visible |
| | `visibility_off` | Hidden, backstage |
| | `search` | Find, lookup |
| **Communication** | `mail` | Email, message |
| | `phone` | Call, contact |
| | `chat` | Conversation |
| | `support_agent` | Customer service |
| | `campaign` | Outreach, notification |
| **People** | `person` | Individual, user |
| | `group` | Team, audience |
| | `account_circle` | Account, persona |
| | `badge` | Role, identity |
| **Metrics** | `trending_up` | Positive trend |
| | `trending_down` | Negative trend |
| | `trending_flat` | Stable |
| | `analytics` | Data, insights |
| | `speed` | Performance |
| | `schedule` | Time, duration |
| **Finance** | `payments` | Transaction, payment |
| | `account_balance` | Balance, account |
| | `receipt_long` | Invoice, bill |
| | `credit_card` | Payment method |
| **Journey** | `route` | Journey, path |
| | `flag` | Milestone, goal |
| | `star` | Moment of truth |
| | `emoji_emotions` | Emotional state |
| | `sentiment_satisfied` | Positive emotion |
| | `sentiment_dissatisfied` | Negative emotion |
| | `sentiment_neutral` | Neutral emotion |
| **Blueprint** | `storefront` | Physical evidence |
| | `touch_app` | Customer action |
| | `support_agent` | Frontstage |
| | `engineering` | Backstage |
| | `dns` | Support systems |
| **Process** | `task_alt` | Task complete |
| | `rule` | Decision point |
| | `call_split` | Branch |
| | `loop` | Cycle, repeat |
| | `sync` | Integration |
| **Governance** | `gavel` | Policy, decision |
| | `verified` | Approved, certified |
| | `shield` | Security, compliance |
| | `assignment` | Assignment, responsibility |

---

## Color System

### Base Colors (Slate)

| Token | Hex | Use |
|-------|-----|-----|
| `slate-50` | #f8fafc | Page background, subtle backgrounds |
| `slate-100` | #f1f5f9 | Card backgrounds, neutral tags |
| `slate-200` | #e2e8f0 | Borders, dividers |
| `slate-300` | #cbd5e1 | Muted borders |
| `slate-400` | #94a3b8 | Muted text, arrows |
| `slate-500` | #64748b | Secondary text |
| `slate-600` | #475569 | Body text |
| `slate-700` | #334155 | Emphasized text |
| `slate-900` | #0f172a | Headings |

### Semantic Colors

Colors have meaning in the toll system context:

| Color | Meaning | Background | Text |
|-------|---------|------------|------|
| **Green** | Reliable revenue, low risk | #d1fae5 / #ecfdf5 | #065f46 / #166534 |
| **Blue** | Commercial, working relationship | #bfdbfe / #dbeafe | #1e40af |
| **Sky** | Transactional, one-time | #e0f2fe / #f0f9ff | #0369a1 |
| **Amber** | At-risk, could go either way | #fde68a / #fef3c7 | #92400e |
| **Purple** | Interoperability | #ddd6fe / #ede9fe | #5b21b6 |
| **Stone** | Institutional, government | #e7e5e4 / #fafaf9 | #57534e |
| **Rose** | Problem, recovery | #fbcfe8 / #fce7f3 | #9d174d |
| **Gray** | Internal, non-revenue | #e2e8f0 / #f1f5f9 | #475569 |

### Emotional States

| State | Background | Text | Icon |
|-------|------------|------|------|
| Positive | #dcfce7 | #166534 | `sentiment_satisfied` |
| Neutral | #f1f5f9 | #475569 | `sentiment_neutral` |
| Negative | #fee2e2 | #991b1b | `sentiment_dissatisfied` |
| Mixed | #fef3c7 | #92400e | `emoji_emotions` |

### CX-Specific Colors

Extended palette for customer experience documentation:

| Context | Meaning | Background | Text | Border |
|---------|---------|------------|------|--------|
| **KPI On-Target** | Meeting or exceeding goals | #dcfce7 | #166534 | #86efac |
| **KPI At-Risk** | Approaching threshold | #fef3c7 | #92400e | #fcd34d |
| **KPI Breached** | Below acceptable threshold | #fee2e2 | #991b1b | #fca5a5 |
| **Severity 1** | Critical/Immediate | #fee2e2 | #991b1b | #fca5a5 |
| **Severity 2** | High priority | #ffedd5 | #9a3412 | #fdba74 |
| **Severity 3** | Medium priority | #fef3c7 | #92400e | #fcd34d |
| **Severity 4** | Low priority | #dcfce7 | #065f46 | #86efac |
| **Blueprint Physical** | Customer evidence layer | #dbeafe | #1e40af | #93c5fd |
| **Blueprint Customer** | Customer actions layer | #fef3c7 | #92400e | #fcd34d |
| **Blueprint Frontstage** | Visible staff/system | #d1fae5 | #065f46 | #6ee7b7 |
| **Blueprint Backstage** | Invisible operations | #e0e7ff | #3730a3 | #a5b4fc |
| **Blueprint Support** | Infrastructure/systems | #fce7f3 | #9d174d | #f9a8d4 |
| **RACI Responsible** | Does the work | #fee2e2 | #991b1b | — |
| **RACI Accountable** | Owns outcome | #fef3c7 | #92400e | — |
| **RACI Consulted** | Provides input | #dbeafe | #1e40af | — |
| **RACI Informed** | Kept updated | #d1fae5 | #065f46 | — |

### Journey Archetype Colors

Each journey archetype has a consistent color identity:

| Archetype | Description | Primary | Background | Text |
|-----------|-------------|---------|------------|------|
| **1A Self-Service** | Low-touch, portal-driven | #10b981 | #d1fae5 | #065f46 |
| **1B Managed** | High-touch, account rep | #3b82f6 | #dbeafe | #1e40af |
| **2 Transactional** | Invoice-triggered | #0ea5e9 | #e0f2fe | #0369a1 |
| **3 Institutional** | Agreement-based | #8b5cf6 | #ede9fe | #5b21b6 |
| **4 Recovery** | Collections/enforcement | #f43f5e | #fce7f3 | #9d174d |

---

## Components

### Cards

Standard card with shadow:
```css
.card {
    background: white;
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 4px 12px rgba(0,0,0,0.04);
    overflow: hidden;
}
```

Section card (for documentation):
```css
.section {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
```

### Tags / Chips

**Account Tag** (semantic color based on persona type):
```css
.account-tag {
    font-size: 0.65rem;
    font-weight: 600;
    padding: 0.2rem 0.5rem;
    border-radius: 4px;
    font-family: 'Source Code Pro', monospace;
}
```

**Payment Tag** (neutral):
```css
.payment-tag {
    background: #f1f5f9;
    color: #475569;
    border: 1px solid #cbd5e1;
}
```

**Behavior Tag** (amber):
```css
.behavior-tag {
    background: #fef3c7;
    color: #92400e;
    border: 1px solid #fcd34d;
}
```

**Channel Tag** (sky):
```css
.channel-tag {
    background: #e0f2fe;
    color: #0369a1;
    border: 1px solid #bae6fd;
}
```

**Persona Chip** (rounded, for lists):
```css
.persona-chip {
    font-size: 0.65rem;
    font-weight: 500;
    padding: 0.2rem 0.6rem;
    border-radius: 12px;
}
```

### Labels

Uppercase section label:
```css
.label {
    font-size: 0.65rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #94a3b8;
    margin-bottom: 0.25rem;
}
```

Segment divider:
```css
.segment-label {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: #64748b;
    margin: 2rem 0 1rem 0;
    padding-bottom: 0.5rem;
    border-bottom: 2px solid #e2e8f0;
}
```

### Callouts

Moment of Truth (journey highlight):
```css
.moment-of-truth {
    background: #fffbeb;
    border-left: 3px solid #fcd34d;
    padding: 0.5rem 0.75rem;
    margin-top: 0.75rem;
    font-size: 0.7rem;
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
}

.moment-of-truth .material-symbols-rounded {
    font-size: 16px;
    color: #f59e0b;
}
```

Note block:
```css
.note {
    background: #f8fafc;
    border-left: 3px solid #cbd5e1;
    padding: 0.5rem 0.75rem;
    font-size: 0.75rem;
    color: #64748b;
    font-style: italic;
}
```

Pull quote (Source Serif 4):
```css
.pull-quote {
    font-family: 'Source Serif 4', Georgia, serif;
    font-size: 1.313rem;
    font-weight: 400;
    line-height: 1.5;
    color: #334155;
    border-left: 4px solid #3b82f6;
    padding: 1rem 1.5rem;
    margin: 2rem 0;
    background: #f8fafc;
}

.pull-quote .attribution {
    font-family: 'Source Serif 4', Georgia, serif;
    font-size: 0.875rem;
    font-weight: 600;
    color: #64748b;
    margin-top: 0.75rem;
}
```

Introduction paragraph (Source Serif 4):
```css
.intro-paragraph {
    font-family: 'Source Serif 4', Georgia, serif;
    font-size: 1.125rem;
    font-weight: 400;
    line-height: 1.6;
    color: #475569;
    margin-bottom: 1.5rem;
}
```

Epigraph (Source Serif 4):
```css
.epigraph {
    font-family: 'Source Serif 4', Georgia, serif;
    font-size: 1rem;
    font-style: italic;
    color: #64748b;
    text-align: center;
    padding: 1.5rem 2rem;
    margin-bottom: 2rem;
}

.epigraph .source {
    font-family: 'Source Serif 4', Georgia, serif;
    font-size: 0.875rem;
    font-weight: 600;
    font-style: normal;
    margin-top: 0.5rem;
    display: block;
}
```

Operational implications:
```css
.ops-implications {
    background: #f8fafc;
    border-left: 3px solid #cbd5e1;
    padding: 0.6rem 0.8rem;
    margin-top: auto;
}
```

### Emotional Indicators

```css
.emotion {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    padding: 0.2rem 0.5rem;
    border-radius: 4px;
    font-size: 0.65rem;
    font-weight: 500;
}

.emotion .material-symbols-rounded {
    font-size: 16px;
}

.emotion-positive { background: #dcfce7; color: #166534; }
.emotion-neutral { background: #f1f5f9; color: #475569; }
.emotion-negative { background: #fee2e2; color: #991b1b; }
.emotion-mixed { background: #fef3c7; color: #92400e; }
```

### Branch Indicators

For journey decision points:
```css
.branch {
    border: 1px dashed #cbd5e1;
    border-radius: 6px;
    padding: 0.5rem;
    margin-top: 0.5rem;
    background: white;
}
.branch-label {
    font-size: 0.55rem;
    font-weight: 600;
    color: #64748b;
    text-transform: uppercase;
}
```

---

## CX Component Library

Components specific to customer experience documentation.

### Page Headers

CX document header (pastel with dark text):
```css
.cx-header {
    padding: 1.5rem 2rem;
    border-radius: 12px;
    margin-bottom: 1.5rem;
    border: 1px solid transparent;
}

.cx-header h1 {
    font-size: 1.75rem;
    font-weight: 700;
    margin-bottom: 0.25rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.cx-header h1 .material-symbols-rounded {
    font-size: 32px;
}

.cx-header .subtitle {
    font-size: 0.875rem;
    opacity: 0.8;
}
```

Journey header colors (pastel backgrounds with dark text):
```css
.cx-header.journey-1a {
    background: #d1fae5;
    color: #065f46;
    border-color: #a7f3d0;
}
.cx-header.journey-1b {
    background: #dbeafe;
    color: #1e40af;
    border-color: #bfdbfe;
}
.cx-header.journey-2 {
    background: #cffafe;
    color: #0e7490;
    border-color: #a5f3fc;
}
.cx-header.journey-3 {
    background: #ede9fe;
    color: #5b21b6;
    border-color: #ddd6fe;
}
.cx-header.journey-4 {
    background: #ffe4e6;
    color: #9f1239;
    border-color: #fecdd3;
}
```

Journey color reference:

| Journey | Background | Text | Border |
|---------|------------|------|--------|
| 1A Self-Service | #d1fae5 | #065f46 | #a7f3d0 |
| 1B Managed | #dbeafe | #1e40af | #bfdbfe |
| 2 Transactional | #cffafe | #0e7490 | #a5f3fc |
| 3 Institutional | #ede9fe | #5b21b6 | #ddd6fe |
| 4 Recovery | #ffe4e6 | #9f1239 | #fecdd3 |

### Status Badges

Document status indicators:
```css
.status-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    padding: 0.2rem 0.6rem;
    border-radius: 4px;
    font-size: 0.65rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.03em;
    font-family: 'Source Code Pro', monospace;
}

.status-badge .material-symbols-rounded {
    font-size: 14px;
}

.status-draft { background: #fef3c7; color: #92400e; }
.status-review { background: #dbeafe; color: #1e40af; }
.status-approved { background: #d1fae5; color: #065f46; }
.status-deprecated { background: #e2e8f0; color: #64748b; }
```

### KPI Metrics

Metric card for dashboards:
```css
.metric-card {
    background: white;
    border-radius: 12px;
    padding: 1.25rem;
    text-align: center;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}

.metric-card .icon {
    margin-bottom: 0.5rem;
}

.metric-card .icon .material-symbols-rounded {
    font-size: 28px;
    color: #64748b;
}

.metric-card .value {
    font-size: 2rem;
    font-weight: 700;
    font-family: 'Source Code Pro', monospace;
    color: #0f172a;
}

.metric-card .label {
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #64748b;
    margin-top: 0.25rem;
}

.metric-card .trend {
    font-size: 0.7rem;
    margin-top: 0.5rem;
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
}

.metric-card .trend .material-symbols-rounded {
    font-size: 16px;
}

.metric-card .trend-up { color: #16a34a; }
.metric-card .trend-down { color: #dc2626; }
```

Dark metric card (for dashboards):
```css
.metric-card.dark {
    background: #1e293b;
    color: white;
}

.metric-card.dark .value { color: white; }
.metric-card.dark .label { color: #94a3b8; }
.metric-card.dark .icon .material-symbols-rounded { color: #94a3b8; }
```

KPI status indicator:
```css
.kpi-status {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    padding: 0.25rem 0.6rem;
    border-radius: 999px;
    font-size: 0.75rem;
    font-weight: 600;
}

.kpi-status .material-symbols-rounded {
    font-size: 16px;
}

.kpi-status.on-target { background: #dcfce7; color: #166534; }
.kpi-status.at-risk { background: #fef3c7; color: #92400e; }
.kpi-status.breached { background: #fee2e2; color: #991b1b; }
```

### Service Blueprint

Blueprint layer label with icon:
```css
.blueprint-layer-label {
    width: 140px;
    flex-shrink: 0;
    padding: 1rem;
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    text-align: center;
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.4rem;
}

.blueprint-layer-label .material-symbols-rounded {
    font-size: 20px;
}

.layer-physical { background: #dbeafe; color: #1e40af; }
.layer-customer { background: #fef3c7; color: #92400e; }
.layer-frontstage { background: #d1fae5; color: #065f46; }
.layer-backstage { background: #e0e7ff; color: #3730a3; }
.layer-support { background: #fce7f3; color: #9d174d; }
```

Blueprint cell:
```css
.blueprint-cell {
    padding: 0.75rem;
    border: 1px solid #e2e8f0;
    min-height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
    font-size: 0.8rem;
    color: #475569;
}
```

Line of visibility/interaction:
```css
.blueprint-line {
    padding: 0.4rem;
    text-align: center;
    font-weight: 700;
    font-size: 0.65rem;
    text-transform: uppercase;
    letter-spacing: 0.1em;
}

.line-interaction { background: #f59e0b; color: white; }
.line-visibility { background: #3b82f6; color: white; }
.line-internal { background: #64748b; color: white; }
```

Fail point indicator:
```css
.fail-point {
    position: relative;
}

.fail-point::after {
    content: 'warning';
    font-family: 'Material Symbols Rounded';
    position: absolute;
    top: 4px;
    right: 4px;
    font-size: 16px;
    color: #f59e0b;
}
```

### RACI Matrix

RACI badge:
```css
.raci-badge {
    display: inline-block;
    width: 24px;
    height: 24px;
    line-height: 24px;
    border-radius: 50%;
    font-weight: 700;
    font-size: 0.7rem;
    text-align: center;
    font-family: 'Source Code Pro', monospace;
}

.raci-r { background: #fee2e2; color: #991b1b; }
.raci-a { background: #fef3c7; color: #92400e; }
.raci-c { background: #dbeafe; color: #1e40af; }
.raci-i { background: #d1fae5; color: #065f46; }
```

### Severity Levels

Severity badge with icon:
```css
.severity-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    padding: 0.2rem 0.6rem;
    border-radius: 999px;
    font-size: 0.7rem;
    font-weight: 600;
}

.severity-badge .material-symbols-rounded {
    font-size: 14px;
}

.severity-1 { background: #fee2e2; color: #991b1b; }
.severity-2 { background: #ffedd5; color: #9a3412; }
.severity-3 { background: #fef3c7; color: #92400e; }
.severity-4 { background: #d1fae5; color: #065f46; }
```

### Process Steps

Numbered step indicator:
```css
.step-number {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: #3b82f6;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 0.875rem;
    font-family: 'Source Code Pro', monospace;
}
```

Step card with icon:
```css
.step-card {
    background: #f8fafc;
    border-radius: 8px;
    padding: 1.25rem;
    text-align: center;
}

.step-card .icon {
    width: 40px;
    height: 40px;
    background: #3b82f6;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 0.75rem;
}

.step-card .icon .material-symbols-rounded {
    font-size: 20px;
    color: white;
}

.step-card h4 {
    font-size: 0.95rem;
    font-weight: 600;
    color: #334155;
    margin-bottom: 0.5rem;
}

.step-card p {
    font-size: 0.8rem;
    color: #64748b;
}
```

Horizontal process flow:
```css
.process-flow {
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
}

.process-flow .step-card {
    flex: 1;
    position: relative;
}

.process-flow .step-card:not(:last-child)::after {
    content: 'arrow_forward';
    font-family: 'Material Symbols Rounded';
    position: absolute;
    right: -1.25rem;
    top: 50%;
    transform: translateY(-50%);
    color: #94a3b8;
    font-size: 20px;
}
```

### Recovery Playbooks

Playbook card:
```css
.playbook-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    overflow: hidden;
}

.playbook-header {
    background: #1e293b;
    color: white;
    padding: 1rem 1.25rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

.playbook-header .material-symbols-rounded {
    font-size: 24px;
    opacity: 0.8;
}

.playbook-header h4 {
    font-size: 1rem;
    font-weight: 600;
}

.playbook-header .id {
    font-size: 0.7rem;
    font-family: 'Source Code Pro', monospace;
    opacity: 0.7;
}

.playbook-body {
    padding: 1.25rem;
}

.playbook-section {
    margin-bottom: 1rem;
}

.playbook-section h5 {
    font-size: 0.65rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #64748b;
    margin-bottom: 0.4rem;
    display: flex;
    align-items: center;
    gap: 0.3rem;
}

.playbook-section h5 .material-symbols-rounded {
    font-size: 14px;
}
```

Script block (for recovery scripts):
```css
.script-block {
    background: #f0fdf4;
    border: 1px solid #86efac;
    border-radius: 6px;
    padding: 0.75rem;
    font-size: 0.8rem;
    font-style: italic;
    color: #166534;
}
```

Don't block (anti-pattern):
```css
.dont-block {
    background: #fef2f2;
    border: 1px solid #fca5a5;
    border-radius: 6px;
    padding: 0.75rem;
    font-size: 0.8rem;
    color: #991b1b;
    display: flex;
    align-items: flex-start;
    gap: 0.5rem;
}

.dont-block .material-symbols-rounded {
    font-size: 16px;
}
```

### Training & Certification

Level card with icon:
```css
.level-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 1.25rem;
    text-align: center;
    border-top: 4px solid #3b82f6;
}

.level-card .icon {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 0.75rem;
}

.level-card .icon .material-symbols-rounded {
    font-size: 24px;
}

.level-card.level-1 { border-top-color: #fbbf24; }
.level-card.level-1 .icon { background: #fef3c7; color: #92400e; }

.level-card.level-2 { border-top-color: #fb923c; }
.level-card.level-2 .icon { background: #ffedd5; color: #9a3412; }

.level-card.level-3 { border-top-color: #ef4444; }
.level-card.level-3 .icon { background: #fee2e2; color: #991b1b; }

.level-card.level-4 { border-top-color: #8b5cf6; }
.level-card.level-4 .icon { background: #ede9fe; color: #5b21b6; }

.level-card h4 {
    font-size: 0.95rem;
    font-weight: 600;
    color: #334155;
    margin-bottom: 0.25rem;
}

.level-card .target {
    font-size: 0.75rem;
    color: #64748b;
    margin-bottom: 0.75rem;
}
```

### VOC Components

Survey type card with icon:
```css
.survey-card {
    background: #f8fafc;
    border-radius: 12px;
    padding: 1.25rem;
    border-left: 4px solid #3b82f6;
}

.survey-card .header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.25rem;
}

.survey-card .header .material-symbols-rounded {
    font-size: 20px;
    color: #3b82f6;
}

.survey-card h4 {
    font-size: 0.95rem;
    font-weight: 600;
    color: #334155;
}

.survey-card .trigger {
    font-size: 0.75rem;
    color: #64748b;
    margin-bottom: 0.75rem;
}
```

Question card:
```css
.question-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    overflow: hidden;
}

.question-text {
    font-style: italic;
    color: #475569;
    padding: 1rem;
    background: #f8fafc;
    border-left: 3px solid #3b82f6;
    margin: 1rem;
    border-radius: 0 6px 6px 0;
}
```

Scale visual:
```css
.scale-visual {
    display: flex;
    justify-content: space-between;
    padding: 0.75rem;
    background: linear-gradient(to right, #fee2e2, #fef3c7, #dcfce7);
    border-radius: 8px;
    font-size: 0.7rem;
    font-weight: 600;
}
```

Alert card with icon:
```css
.alert-card {
    background: white;
    border-radius: 8px;
    padding: 1rem;
    border-left: 4px solid #ef4444;
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
}

.alert-card .material-symbols-rounded {
    font-size: 20px;
}

.alert-card.critical .material-symbols-rounded { color: #ef4444; }
.alert-card.high .material-symbols-rounded { color: #f59e0b; }
.alert-card.medium .material-symbols-rounded { color: #3b82f6; }
.alert-card.low .material-symbols-rounded { color: #10b981; }

.alert-card.high { border-left-color: #f59e0b; }
.alert-card.medium { border-left-color: #3b82f6; }
.alert-card.low { border-left-color: #10b981; }

.alert-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    padding: 0.2rem 0.5rem;
    border-radius: 4px;
    font-size: 0.6rem;
    font-weight: 600;
    text-transform: uppercase;
    font-family: 'Source Code Pro', monospace;
}

.alert-badge .material-symbols-rounded {
    font-size: 12px;
}

.alert-badge.critical { background: #fee2e2; color: #991b1b; }
.alert-badge.high { background: #fef3c7; color: #92400e; }
.alert-badge.medium { background: #dbeafe; color: #1e40af; }
```

### Governance Components

Role card with icon:
```css
.role-card {
    background: #f8fafc;
    border-radius: 12px;
    padding: 1.25rem;
    border-left: 4px solid #3b82f6;
}

.role-card .header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.25rem;
}

.role-card .header .material-symbols-rounded {
    font-size: 20px;
}

.role-card h4 {
    font-size: 1rem;
    font-weight: 600;
    color: #334155;
}

.role-card .reports-to {
    font-size: 0.75rem;
    color: #64748b;
    margin-bottom: 0.75rem;
}

.role-card.executive { border-left-color: #8b5cf6; }
.role-card.executive .header .material-symbols-rounded { color: #8b5cf6; }

.role-card.journey { border-left-color: #10b981; }
.role-card.journey .header .material-symbols-rounded { color: #10b981; }

.role-card.episode { border-left-color: #14b8a6; }
.role-card.episode .header .material-symbols-rounded { color: #14b8a6; }

.role-card.analyst { border-left-color: #f59e0b; }
.role-card.analyst .header .material-symbols-rounded { color: #f59e0b; }
```

Governance body card:
```css
.gov-body-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    overflow: hidden;
}

.gov-body-header {
    background: #1e293b;
    color: white;
    padding: 1rem 1.25rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

.gov-body-header .material-symbols-rounded {
    font-size: 24px;
    opacity: 0.8;
}

.gov-body-header h4 {
    font-size: 1rem;
    font-weight: 600;
    margin-bottom: 0.15rem;
}

.gov-body-header .frequency {
    font-size: 0.75rem;
    opacity: 0.8;
}

.gov-body-content {
    padding: 1.25rem;
}
```

Member badge:
```css
.member-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    background: #f1f5f9;
    padding: 0.2rem 0.6rem;
    border-radius: 999px;
    font-size: 0.75rem;
    color: #475569;
}

.member-badge .material-symbols-rounded {
    font-size: 14px;
}
```

### Checklists

Quality checklist with icons:
```css
.checklist {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 0.5rem;
}

.checklist-item {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    padding: 0.6rem;
    background: #f8fafc;
    border-radius: 6px;
    font-size: 0.85rem;
}

.checklist-item .material-symbols-rounded {
    font-size: 18px;
    color: #94a3b8;
}

.checklist-item.checked .material-symbols-rounded {
    color: #10b981;
}

.checklist-item input[type="checkbox"] {
    display: none;
}
```

### Glossary Components

Letter badge:
```css
.letter-badge {
    width: 40px;
    height: 40px;
    background: #3b82f6;
    color: white;
    font-size: 1.25rem;
    font-weight: 700;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
}
```

Term entry:
```css
.term-entry {
    padding: 0.75rem 0;
    border-bottom: 1px solid #f1f5f9;
}

.term-entry:last-child {
    border-bottom: none;
}

.term-name {
    font-size: 1rem;
    font-weight: 600;
    color: #334155;
    margin-bottom: 0.15rem;
}

.term-definition {
    font-size: 0.875rem;
    color: #64748b;
}
```

Term tag with icon:
```css
.term-tag {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    padding: 0.15rem 0.5rem;
    border-radius: 4px;
    font-size: 0.65rem;
    font-weight: 500;
}

.term-tag .material-symbols-rounded {
    font-size: 12px;
}

.tag-alias { background: #e0e7ff; color: #3730a3; }
.tag-related { background: #d1fae5; color: #065f46; }
.tag-journey { background: #dbeafe; color: #1e40af; }
.tag-metric { background: #fef3c7; color: #92400e; }
```

### Emotional Journey

Emotion intensity meter:
```css
.emotion-meter {
    display: flex;
    gap: 2px;
}

.emotion-meter .bar {
    width: 12px;
    height: 20px;
    background: #e2e8f0;
    border-radius: 2px;
}

.emotion-meter .bar.active.positive { background: #22c55e; }
.emotion-meter .bar.active.negative { background: #ef4444; }
.emotion-meter .bar.active.neutral { background: #94a3b8; }
```

Emotion phase card:
```css
.emotion-phase {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 1rem;
}

.emotion-phase .phase-header {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    margin-bottom: 0.5rem;
}

.emotion-phase .phase-header .material-symbols-rounded {
    font-size: 18px;
}

.emotion-phase .phase-name {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #64748b;
}
```

### Journey Scorecard

Journey score card:
```css
.journey-score-card {
    background: #f8fafc;
    border-radius: 12px;
    padding: 1.25rem;
    border-left: 4px solid #3b82f6;
}

.journey-score-card .header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
}

.journey-score-card .header .material-symbols-rounded {
    font-size: 20px;
    color: #3b82f6;
}

.journey-score-card h4 {
    font-size: 0.95rem;
    font-weight: 600;
    color: #334155;
}

.score-row {
    display: flex;
    justify-content: space-between;
    padding: 0.4rem 0;
    border-bottom: 1px solid #e2e8f0;
    font-size: 0.85rem;
}

.score-row:last-child {
    border-bottom: none;
}

.score-row .label { color: #64748b; }
.score-row .value { font-weight: 600; color: #334155; }
```

Status dot:
```css
.status-dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    margin-right: 0.4rem;
}

.status-dot.green { background: #22c55e; }
.status-dot.yellow { background: #f59e0b; }
.status-dot.red { background: #ef4444; }
```

---

## Layout Patterns

### Page Structure

```css
body {
    font-family: 'Source Sans 3', -apple-system, BlinkMacSystemFont, sans-serif;
    background: #f8fafc;
    color: #1e293b;
    line-height: 1.6;
    padding: 2rem;
    font-size: 16px;
}
```

### Grid Layouts

**Persona Grid** (auto-fit cards):
```css
.persona-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
    gap: 1.25rem;
}
```

**Layers Grid** (3-column):
```css
.layers-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.25rem;
    margin: 1.5rem 0;
}
```

**Tracks Grid** (2-column):
```css
.tracks-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1.5rem;
    margin: 1.5rem 0;
}
```

### Journey Stages

Horizontal flow with arrows:
```css
.journey-flow {
    display: flex;
    gap: 0;
    min-width: max-content;
}

.stage {
    flex: 1;
    min-width: 170px;
    position: relative;
}

.stage-header {
    padding: 0.6rem 1rem;
    font-weight: 600;
    font-size: 0.75rem;
    text-align: center;
    background: #e2e8f0;
    color: #475569;
}

.stage:not(:last-child) .stage-header::after {
    content: 'arrow_forward';
    font-family: 'Material Symbols Rounded';
    position: absolute;
    right: -0.75rem;
    top: 50%;
    transform: translateY(-50%);
    color: #94a3b8;
    font-size: 18px;
    z-index: 1;
}

.stage-content {
    border: 1px solid #e2e8f0;
    border-top: none;
    padding: 1rem;
    background: #fafbfc;
    min-height: 280px;
}
```

### Flow Diagrams

Domain row with label and content:
```css
.domain-row {
    display: flex;
    align-items: stretch;
    gap: 1rem;
}

.domain-label {
    width: 140px;
    flex-shrink: 0;
    padding: 1.25rem 1rem;
    border-radius: 10px;
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    gap: 0.4rem;
}

.domain-label .material-symbols-rounded {
    font-size: 20px;
}

.flow-content {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem 1.25rem;
    background: white;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    flex-wrap: wrap;
}
```

Flow box (step in a process):
```css
.flow-box {
    background: #f1f5f9;
    border-radius: 8px;
    padding: 0.65rem 1.25rem;
    font-size: 0.85rem;
    font-weight: 500;
    color: #334155;
    text-align: center;
    white-space: nowrap;
    border: 1px solid #e2e8f0;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
}

.flow-box .material-symbols-rounded {
    font-size: 16px;
}

.flow-box.to-build {
    border: 2px dashed #94a3b8;
    background: #f8fafc;
}

.flow-box.highlight {
    background: #fef3c7;
    border: 2px solid #f59e0b;
    font-weight: 600;
    color: #92400e;
}
```

---

## Responsive Design System

### Viewport Meta Tag

Required in all HTML documents:
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

### Breakpoint System

| Token | Width | Target Device | CSS Variable |
|-------|-------|---------------|--------------|
| `sm` | 640px | Mobile landscape | `--breakpoint-sm` |
| `md` | 768px | Tablets | `--breakpoint-md` |
| `lg` | 1024px | Small laptops | `--breakpoint-lg` |
| `xl` | 1280px | Desktops | `--breakpoint-xl` |
| `2xl` | 1536px | Large screens | `--breakpoint-2xl` |

```css
:root {
    --breakpoint-sm: 640px;
    --breakpoint-md: 768px;
    --breakpoint-lg: 1024px;
    --breakpoint-xl: 1280px;
    --breakpoint-2xl: 1536px;
}
```

**Mobile-first approach**: Write base styles for mobile, then add complexity at larger breakpoints using `min-width`.

### Container System

Two container variants optimized for different document types and print targets:

| Container | Max-Width | Use Case | Print Target |
|-----------|-----------|----------|--------------|
| `.container` | 1024px | Text documents, guides, templates | Letter portrait (66% scale) |
| `.container-wide` | 1200px | Journey maps, blueprints, diagrams | Letter landscape (76% scale) |

**Why two containers?**
- **1024px** produces ~80 characters per line (optimal 50-80 range per typography research)
- **1200px** provides room for complex visualizations while printing well on landscape
- Both scale well to US Letter paper (8.5" × 11") with readable text

```css
/* Standard container - text documents, Letter portrait */
.container {
    width: 100%;
    max-width: 1024px;
    margin: 0 auto;
    padding: 0 1rem;
}

@media (min-width: 640px) { .container { padding: 0 1.5rem; } }
@media (min-width: 1024px) { .container { padding: 0 2rem; } }

/* Wide container - visual artifacts, Letter landscape */
.container-wide {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
}

@media (min-width: 640px) { .container-wide { padding: 0 1.5rem; } }
@media (min-width: 1024px) { .container-wide { padding: 0 2rem; } }
```

**Print scaling reference (US Letter):**

| Container | Portrait (672px) | Landscape (912px) |
|-----------|------------------|-------------------|
| 1024px | 66% (11pt → ~7pt) | 89% (nearly 1:1) |
| 1200px | 56% (11pt → ~6pt) | 76% (11pt → ~8pt) |

**When to use each:**
- `.container`: Guides, templates, procedures, any text-heavy document
- `.container-wide`: Journey maps, service blueprints, flow diagrams, comparison tables

### Fluid Typography

Use `clamp()` for smooth scaling between breakpoints:

```css
:root {
    /* Fluid type scale */
    --font-display: clamp(1.75rem, 4vw + 1rem, 2.441rem);   /* 28px → 39px */
    --font-h1: clamp(1.5rem, 3vw + 0.75rem, 1.953rem);      /* 24px → 31px */
    --font-h2: clamp(1.25rem, 2vw + 0.5rem, 1.563rem);      /* 20px → 25px */
    --font-h3: clamp(1.1rem, 1.5vw + 0.5rem, 1.25rem);      /* 18px → 20px */
    --font-body: clamp(0.938rem, 1vw + 0.5rem, 1rem);       /* 15px → 16px */
    --font-small: clamp(0.75rem, 0.8vw + 0.4rem, 0.8rem);   /* 12px → 13px */
}

.display { font-size: var(--font-display); }
h1 { font-size: var(--font-h1); }
h2 { font-size: var(--font-h2); }
h3 { font-size: var(--font-h3); }
body { font-size: var(--font-body); }
.body-small { font-size: var(--font-small); }
```

### Grid Responsive Modifiers

```css
/* Base grids */
.grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.25rem; }
.grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }

/* Responsive collapse */
@media (max-width: 1024px) {
    .grid-4 { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 768px) {
    .grid-2, .grid-3, .grid-4 { grid-template-columns: 1fr; }
}

/* Auto-fit grids (responsive by default) */
.grid-auto {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.25rem;
}
```

### Component-Specific Responsive Rules

**Journey Stages** (horizontal → vertical):
```css
.journey-flow {
    display: flex;
    gap: 0;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
}

@media (max-width: 768px) {
    .journey-flow {
        flex-direction: column;
    }
    .stage { min-width: 100%; }
    .stage:not(:last-child) .stage-header::after { display: none; }
}
```

**Process Flow** (horizontal arrows → vertical):
```css
@media (max-width: 768px) {
    .process-flow {
        flex-direction: column;
        gap: 1rem;
    }
    .process-flow .step-card:not(:last-child)::after {
        content: 'arrow_downward';
        right: 50%;
        top: auto;
        bottom: -1.5rem;
        transform: translateX(50%);
    }
}
```

**Domain Rows** (side-by-side → stacked):
```css
@media (max-width: 768px) {
    .domain-row {
        flex-direction: column;
    }
    .domain-label {
        width: 100%;
        flex-direction: row;
        justify-content: center;
    }
}
```

**Metric Cards** (4 → 2 → 1):
```css
.metrics-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
}

@media (max-width: 1024px) {
    .metrics-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 640px) {
    .metrics-grid { grid-template-columns: 1fr; }
}
```

**Tables** (horizontal scroll wrapper):
```css
.table-wrapper {
    width: 100%;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
}

@media (max-width: 640px) {
    .table-wrapper table {
        min-width: 600px;
    }
}
```

### Spacing Scale Adjustments

```css
:root {
    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;
    --space-xl: 2rem;
    --space-2xl: 3rem;
}

@media (max-width: 768px) {
    :root {
        --space-lg: 1.25rem;
        --space-xl: 1.5rem;
        --space-2xl: 2rem;
    }
}
```

### Touch Target Sizing

Minimum 44×44px for interactive elements on touch devices:

```css
@media (hover: none) and (pointer: coarse) {
    button,
    a,
    .tag,
    .status-badge,
    .nav-link {
        min-height: 44px;
        min-width: 44px;
        padding: 0.75rem 1rem;
    }

    .checklist-item {
        padding: 0.875rem;
    }
}
```

### Visibility Utilities

```css
/* Hide on specific breakpoints */
@media (max-width: 640px) { .hidden-sm { display: none !important; } }
@media (max-width: 768px) { .hidden-md { display: none !important; } }
@media (max-width: 1024px) { .hidden-lg { display: none !important; } }

/* Show only on specific breakpoints */
.visible-sm-only { display: none; }
@media (max-width: 640px) { .visible-sm-only { display: block; } }

.visible-md-only { display: none; }
@media (min-width: 641px) and (max-width: 768px) { .visible-md-only { display: block; } }
```

### Hover vs Touch Detection

```css
/* Hover effects only for devices that support hover */
@media (hover: hover) and (pointer: fine) {
    .card:hover {
        box-shadow: 0 4px 12px rgba(0,0,0,0.12);
        transform: translateY(-2px);
    }

    .nav-link:hover {
        background: var(--primary);
        color: white;
    }
}

/* Touch-specific adjustments */
@media (hover: none) and (pointer: coarse) {
    .card {
        /* Remove hover-dependent styles */
        transition: none;
    }
}
```

---

## Accessibility

### Focus States

Visible focus indicators for keyboard navigation:

```css
/* Remove default outline, add custom */
:focus {
    outline: none;
}

:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}

/* High contrast focus for dark backgrounds */
.dark :focus-visible,
.playbook-header :focus-visible {
    outline-color: white;
}
```

### Reduced Motion

Respect user preferences for reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
    }
}
```

### Color Contrast Requirements

| Element | Minimum Ratio | WCAG Level |
|---------|---------------|------------|
| Body text | 4.5:1 | AA |
| Large text (≥18px bold, ≥24px) | 3:1 | AA |
| UI components & graphics | 3:1 | AA |
| Enhanced (AAA) | 7:1 | AAA |

All color combinations in this style guide meet WCAG AA standards.

### Screen Reader Support

```css
/* Visually hidden but accessible to screen readers */
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
}

/* Skip link for keyboard users */
.skip-link {
    position: absolute;
    top: -40px;
    left: 0;
    background: #1e293b;
    color: white;
    padding: 0.5rem 1rem;
    z-index: 100;
}

.skip-link:focus {
    top: 0;
}
```

### High Contrast Mode

Support for Windows High Contrast Mode:

```css
@media (forced-colors: active) {
    .card,
    .section,
    .blueprint-cell {
        border: 1px solid CanvasText;
    }

    .status-badge,
    .tag,
    .raci-badge {
        border: 1px solid CanvasText;
    }
}
```

### Semantic HTML Structure

All documents **must** include proper semantic landmarks:

### Enhanced Focus States (v1.10)

All interactive elements must have visible focus states:

```css
/* === Accessibility v1.10 === */
:focus { outline: none; }
:focus-visible {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}
```

This removes the default focus outline but adds a visible ring only when using keyboard navigation (`:focus-visible`).

### Screen Reader Only Class (v1.10)

For visually hidden but accessible content:

```css
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
}
```

Use for form labels that should be read by screen readers but not displayed visually.

### Reduced Motion Support (v1.10)

Respect user preferences for reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
    }
}
```

### High Contrast Mode Support (v1.10)

Ensure UI elements remain visible in forced-colors mode:

```css
@media (forced-colors: active) {
    .card, .section, .cx-header, .tag, .status-badge {
        border: 1px solid CanvasText;
    }
}
```

### Touch Target Sizing (v1.10)

Ensure interactive elements meet minimum touch target size on touch devices:

```css
@media (hover: none) and (pointer: coarse) {
    button, a, .tag, .status-badge {
        min-height: 44px;
        min-width: 44px;
    }
}
```

This follows WCAG 2.5.5 Target Size guidelines (44x44 CSS pixels minimum).

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document Title | PTC</title>
    <!-- fonts, styles -->
</head>
<body>
    <a href="#main-content" class="skip-link">Skip to main content</a>

    <header>
        <!-- Page header, navigation -->
    </header>

    <main id="main-content">
        <!-- Primary page content -->
    </main>

    <footer>
        <!-- Document metadata, version -->
    </footer>
</body>
</html>
```

**Required elements:**
- `<main>` element wrapping primary content
- Skip navigation link for keyboard users
- Proper heading hierarchy (h1 → h2 → h3, no skipping levels)

### Icon Accessibility

Icons require appropriate ARIA attributes based on their purpose:

**Decorative icons** (visual enhancement only):
```html
<span class="material-symbols-rounded" aria-hidden="true">settings</span>
```

**Meaningful icons** (convey information):
```html
<span class="material-symbols-rounded" aria-label="Configuration">settings</span>
```

**Icon with adjacent text** (icon is redundant):
```html
<span class="material-symbols-rounded" aria-hidden="true">check_circle</span> Approved
```

**Icon-only button**:
```html
<button aria-label="Close dialog">
    <span class="material-symbols-rounded" aria-hidden="true">close</span>
</button>
```

### Form Accessibility

All form inputs **must** have associated labels:

```html
<!-- Explicit label association (preferred) -->
<label for="search-input">Search terms</label>
<input type="text" id="search-input" name="search">

<!-- Implicit label (wrapping) -->
<label>
    Search terms
    <input type="text" name="search">
</label>

<!-- Visually hidden label for search boxes -->
<label for="search-input" class="sr-only">Search glossary terms</label>
<input type="text" id="search-input" placeholder="Search terms...">
```

**Never** use placeholder text as the only label—it disappears on input and fails accessibility.

### Table Accessibility

Tables **must** include proper scope attributes for screen readers:

```html
<table>
    <thead>
        <tr>
            <th scope="col">Name</th>
            <th scope="col">Status</th>
            <th scope="col">Date</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th scope="row">Daily Driver</th>
            <td>Active</td>
            <td>2026-01-15</td>
        </tr>
    </tbody>
</table>
```

- Use `scope="col"` for column headers
- Use `scope="row"` for row headers
- Complex tables may need `headers` attribute referencing header `id`s

---

## Security Standards

### Content Security Policy Compliance

All documents **must** be CSP-compliant. This means:

**Prohibited:**
- Inline event handlers (`onclick`, `onkeyup`, `onmouseover`, etc.)
- `javascript:` URLs
- `eval()` and similar dynamic code execution

**Instead of inline handlers:**
```html
<!-- ❌ BAD: Inline event handler (CSP violation) -->
<input type="text" onkeyup="filterTerms()">

<!-- ✓ GOOD: External event listener -->
<input type="text" id="searchInput">
<script>
document.getElementById('searchInput').addEventListener('input', filterTerms);
</script>
```

**Instead of javascript: URLs:**
```html
<!-- ❌ BAD -->
<a href="javascript:void(0)" onclick="doSomething()">Click</a>

<!-- ✓ GOOD -->
<button type="button" id="action-btn">Click</button>
<script>
document.getElementById('action-btn').addEventListener('click', doSomething);
</script>
```

### Script Organization

For documents with interactivity:

```html
<body>
    <!-- Content -->

    <script>
    // All JavaScript at end of body
    // Use 'DOMContentLoaded' if scripts are in <head>

    function filterTerms() {
        // implementation
    }

    // Attach event listeners
    document.getElementById('searchInput').addEventListener('input', filterTerms);
    document.getElementById('statusFilter').addEventListener('change', updateView);
    </script>
</body>
```

---

## CSS Standards

### Inline Styles

**Avoid inline styles.** Use CSS classes instead.

```html
<!-- ❌ BAD: Inline style -->
<span class="material-symbols-rounded" style="font-size:14px;vertical-align:middle;color:#48bb78;">check_circle</span>

<!-- ✓ GOOD: CSS class -->
<span class="material-symbols-rounded icon-sm icon-success">check_circle</span>
```

```css
/* Define reusable classes */
.icon-sm { font-size: 14px; vertical-align: middle; }
.icon-success { color: #48bb78; }
.icon-error { color: #f56565; }
```

**Exceptions** (inline styles acceptable):
- Truly one-off styling in prototypes
- Dynamic values set by JavaScript
- Print-specific overrides

### CSS Custom Properties

Use CSS variables for consistency and maintainability:

```css
:root {
    /* Colors */
    --color-success: #48bb78;
    --color-error: #f56565;
    --color-warning: #f59e0b;

    /* Spacing */
    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;

    /* Z-index scale */
    --z-base: 0;
    --z-dropdown: 100;
    --z-sticky: 200;
    --z-modal: 400;
}

/* Usage */
.success-indicator { color: var(--color-success); }
.card { padding: var(--space-md); }
```

### Magic Numbers

Document or eliminate magic numbers:

```css
/* ❌ BAD: Unexplained value */
.header { height: 73px; }

/* ✓ GOOD: Documented or calculated */
.header {
    /* 48px logo + 12px padding top + 13px padding bottom */
    height: calc(48px + 12px + 13px);
}

/* Or use a variable */
:root { --header-height: 73px; }
.header { height: var(--header-height); }
```

---

## Dark Mode (Optional)

CSS variables enable theme switching:

```css
:root {
    --bg-primary: #f8fafc;
    --bg-secondary: #ffffff;
    --text-primary: #1e293b;
    --text-secondary: #475569;
    --border: #e2e8f0;
}

@media (prefers-color-scheme: dark) {
    :root {
        --bg-primary: #0f172a;
        --bg-secondary: #1e293b;
        --text-primary: #f1f5f9;
        --text-secondary: #94a3b8;
        --border: #334155;
    }
}

/* Usage */
body { background: var(--bg-primary); color: var(--text-primary); }
.card { background: var(--bg-secondary); border-color: var(--border); }
```

---

## Print Styles

### Page Setup

Two page formats for different document types. Use Letter paper (US standard).

```css
@media print {
    /* Portrait - text documents using .container */
    @page {
        size: letter portrait;
        margin: 0.75in;
    }

    body {
        background: white;
        color: black;
        font-size: 11pt;
        line-height: 1.5;
        padding: 0;
    }

    .container {
        max-width: 100%;
        padding: 0;
    }
}

/* Landscape variant for visual artifacts using .container-wide */
@media print {
    .print-landscape {
        /* Add to <body> or wrapper for landscape documents */
    }
}

@page landscape {
    size: letter landscape;
    margin: 0.5in 0.75in;
}

.print-landscape {
    page: landscape;
}
```

**Print classes:**
- Default: Letter portrait (8.5" × 11"), 0.75" margins
- `.print-landscape`: Letter landscape (11" × 8.5"), 0.5" top/bottom, 0.75" sides

**Usage:**
```html
<!-- Portrait document (default) -->
<body>
    <div class="container">...</div>
</body>

<!-- Landscape document -->
<body class="print-landscape">
    <div class="container-wide">...</div>
</body>
```

### Page Break Control

```css
@media print {
    /* Prevent breaks inside */
    .card,
    .section,
    .metric-card,
    .role-card,
    .playbook-card,
    table,
    figure {
        break-inside: avoid;
    }

    /* Force break before major sections */
    .page-break-before {
        break-before: page;
    }

    /* Prevent orphans/widows */
    p, li {
        orphans: 3;
        widows: 3;
    }

    /* Keep headings with content */
    h1, h2, h3, h4 {
        break-after: avoid;
    }
}
```

### Print-Specific Visibility

```css
@media print {
    /* Hide interactive/navigation elements */
    .nav-links,
    .template-note,
    button,
    .skip-link {
        display: none !important;
    }

    /* Show URLs after links */
    a[href^="http"]::after {
        content: " (" attr(href) ")";
        font-size: 0.8em;
        color: #64748b;
    }

    /* Preserve background colors */
    .cx-header,
    .tag,
    .status-badge,
    .blueprint-layer-label {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
}
```

### Shadows and Effects

```css
@media print {
    .card,
    .section,
    .metric-card {
        box-shadow: none;
        border: 1px solid #e2e8f0;
    }
}
```

---

## Performance

### Font Loading

Ensure fonts don't block rendering:

```css
/* In Google Fonts link, display=swap is included */
/* If self-hosting: */
@font-face {
    font-family: 'Source Sans 3';
    src: url('...') format('woff2');
    font-display: swap;
}
```

### Flexible Media Defaults

```css
img, video, svg, picture {
    max-width: 100%;
    height: auto;
    display: block;
}
```

### Overflow Prevention

```css
html {
    overflow-x: hidden;
}

body {
    overflow-x: hidden;
    overflow-wrap: break-word;
    word-wrap: break-word;
}

pre, code {
    overflow-x: auto;
    white-space: pre-wrap;
    word-break: break-word;
}
```

### Scroll Behavior

```css
html {
    scroll-behavior: smooth;
}

@media (prefers-reduced-motion: reduce) {
    html {
        scroll-behavior: auto;
    }
}

/* Offset for sticky headers when using anchor links */
[id] {
    scroll-margin-top: 80px;
}
```

---

## Z-Index Scale

Consistent layering system to prevent z-index conflicts:

| Layer | Z-Index | Use Case |
|-------|---------|----------|
| Base | 0 | Default content |
| Raised | 10 | Cards with hover effect |
| Dropdown | 100 | Dropdown menus |
| Sticky | 200 | Sticky headers |
| Overlay | 300 | Modal backdrops |
| Modal | 400 | Modal dialogs |
| Popover | 500 | Tooltips, popovers |
| Toast | 600 | Toast notifications |
| Max | 9999 | Skip links, critical UI |

```css
:root {
    --z-base: 0;
    --z-raised: 10;
    --z-dropdown: 100;
    --z-sticky: 200;
    --z-overlay: 300;
    --z-modal: 400;
    --z-popover: 500;
    --z-toast: 600;
    --z-max: 9999;
}
```

---

## Safe Area Insets

For devices with notches (iPhone X+):

```css
body {
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
    padding-bottom: env(safe-area-inset-bottom);
}

/* Fixed bottom elements */
.fixed-bottom {
    padding-bottom: calc(1rem + env(safe-area-inset-bottom));
}
```

---

## Line Clamping

For truncating text in cards:

```css
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
}
```

---

## Migration from Emoji Icons

When updating existing documents from emoji to Material Icons, use this mapping:

| Emoji | Material Icon | Use Case |
|-------|---------------|----------|
| 😊 / 😃 | `sentiment_satisfied` | Positive emotion |
| 😐 | `sentiment_neutral` | Neutral emotion |
| 😟 / 😢 | `sentiment_dissatisfied` | Negative emotion |
| ⚙️ | `settings` | Configuration |
| 📊 | `analytics` | Metrics, data |
| 📋 | `assignment` | Tasks, checklist |
| 📝 | `edit_note` | Edit, notes |
| 📄 | `description` | Document |
| 📁 | `folder` | Category |
| 👤 | `person` | Individual |
| 👥 | `group` | Team |
| 💰 | `payments` | Payment, finance |
| 📧 | `mail` | Email |
| 📞 | `phone` | Call |
| 💬 | `chat` | Conversation |
| ⚠️ | `warning` | Caution, at-risk |
| ❌ | `error` | Failed, breached |
| ✓ / ✔️ | `check_circle` | Success, complete |
| ➡️ | `arrow_forward` | Next, flow |
| ⬆️ | `trending_up` | Positive trend |
| ⬇️ | `trending_down` | Negative trend |
| ⭐ | `star` | Moment of truth |
| 🎯 | `flag` | Goal, target |
| 🔄 | `sync` | Integration |
| 🔒 | `lock` | Security |
| 🏢 | `business` | Organization |
| 🛒 | `shopping_cart` | Cart, purchase |
| 🔔 | `notifications` | Alert |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.10 | Jan 2026 | Enhanced Accessibility: Added :focus-visible styles for keyboard navigation, .sr-only utility class for screen reader content, @media (prefers-reduced-motion) support, @media (forced-colors: active) for high contrast mode, and touch target sizing (44px minimum). |
| v1.9 | Jan 2026 | Added Semantic HTML Structure requirements (`<main>`, skip links, heading hierarchy). Added Icon Accessibility guidelines (aria-hidden vs aria-label). Added Form Accessibility (label associations). Added Table Accessibility (scope attributes). Added Security Standards section (CSP compliance, no inline event handlers). Added CSS Standards (prohibit inline styles, use CSS variables, document magic numbers). |
| v1.8 | Jan 2026 | Dual container system: `.container` (1024px) for text documents/Letter portrait, `.container-wide` (1200px) for visual artifacts/Letter landscape. Changed print target from A4 to US Letter. Added print scaling reference table. |
| v1.7 | Jan 2026 | Added comprehensive Responsive Design System (breakpoints, fluid typography, container system, component-specific rules), Accessibility (focus states, reduced motion, high contrast), Dark Mode support, enhanced Print Styles, Performance guidelines, Z-Index scale, and utility classes. |
| v1.6 | Jan 2026 | Changed type scale from Perfect Fourth (1.333) to Major Third (1.250) for tighter, more compact documentation layouts. |
| v1.5 | Jan 2026 | Updated journey header colors to pastel palette with dark text for improved readability and softer visual presentation. |
| v1.4 | Jan 2026 | Updated typography system: replaced Inter/Roboto Mono with Source Sans 3, Source Serif 4, and Source Code Pro. Added 1.333 type scale, print specifications, and accent font usage guidelines for callouts and pull quotes. |
| v1.3 | Jan 2026 | Added Material Symbols Rounded icon system, replacing emoji-based icons. Added Icon System section with sizing, reference table, and migration guide. |
| v1.2 | Jan 2026 | Added CX Component Library for customer experience documentation. |
| v1.1 | Jan 2026 | Renamed to Screen Style Guide; added print guide reference. |
| v1.0 | Jan 2026 | Initial style guide. |

---
name: verify-screens
description: Verify all app screens render correctly with real data, checking the full pipeline from data source to UI
disable-model-invocation: true
argument-hint: [optional-screen-path]
---

# Screen Verification Audit

Verify the app renders real content end-to-end. If a screen path is provided, audit that screen. Otherwise audit all main screens.

## For each screen, check:

### 1. Data Pipeline
- Read the screen widget file
- Trace which provider/notifier supplies the data
- Trace the provider back to the repository/service
- Trace the repository back to the API client or local storage
- Confirm data exists at the source

### 2. Content Rendering
- Does the screen display actual content from the data source?
- Are there any hardcoded placeholder strings ("Coming soon", "No data", "Lorem ipsum")?
- Are list builders connected to real data providers?
- If the screen has cards/tiles, do they show real titles, descriptions, counts?

### 3. State Coverage
- **Loading**: Is there a skeleton/shimmer that matches the final layout?
- **Empty**: Is there an inviting message with a clear action?
- **Error**: Is there a helpful message with a retry option?
- **Content**: Does real data render correctly?

### 4. Design System Compliance
- All colors from the design system (no hardcoded hex values)
- All text styles from the typography scale (no inline TextStyle)
- All spacing from the spacing system (no magic number EdgeInsets)
- All radii from the radius constants
- Text overflow protection (maxLines + ellipsis)
- Touch targets 48px minimum

### 5. Report Format
For each screen, report:
```
Screen: [file_path:line]
Status: PASS / FAIL
Issues:
  - [specific issue with file:line reference]
  - [specific issue with file:line reference]
```

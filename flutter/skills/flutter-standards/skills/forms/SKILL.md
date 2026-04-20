---
name: forms
description: Apply when building Flutter forms — visible labels above fields, correct keyboardType and autofillHints, validate on submit/blur not focus, specific error messages, preserved input on error, keyboard handling, state preservation across rotation. Auto-invoke when editing TextFormField or form screens.
---

# Forms Implementation Rules

Forms are where apps lose users. Every friction point — unclear label, wrong keyboard, lost input on rotation, ambiguous error — is an abandonment.

This guide covers form UX, validation strategy, keyboard handling, and submission logic. Implements craft-guide's "State Design" for error/empty states and flutter.md's touch-target rules — does not restate them.

---

## Field Anatomy

Every form field has these layers, in this order:

1. **Label** (visible, above the field) — always. Never placeholder-only.
2. **Optional/required marker** — "Required" text or asterisk, paired with `Semantics(label: 'Required')`
3. **Input** — `TextField` / `TextFormField` / custom widget
4. **Helper text** (below, optional) — hints, format examples, character counts
5. **Error text** (below, replaces helper when invalid) — specific, actionable

```
Email                                     [Required]
┌─────────────────────────────────────────┐
│ you@example.com                         │
└─────────────────────────────────────────┘
We'll send a verification link
```

---

## Labels

- **Above the field**, left-aligned (or start-aligned for RTL)
- Concise: "Email" not "Enter your email address"
- Sentence case: "Date of birth" not "DATE OF BIRTH" or "date of birth"
- Never rely on placeholder text alone — it disappears on focus and screen readers skip it
- Required fields: visible indicator (asterisk, "Required" text, or both)
- Optional fields: mark explicitly in long forms ("Optional") to reduce ambiguity

---

## Placeholders (Hint Text)

- Use to show **format example**, not the label
  - ✅ "you@example.com" (format example)
  - ❌ "Email" (label — should be above the field)
- Lower contrast than entered text but still ≥3:1 (see accessibility.md)
- Disappear on focus — expected behavior, but never the only label source
- Keep short — under 40 characters

---

## Keyboard Types

Match the keyboard to the expected input. This is both UX and accessibility.

| Field type | `keyboardType` | Additional |
|------------|----------------|------------|
| Email | `TextInputType.emailAddress` | `autofillHints: [AutofillHints.email]` |
| Phone | `TextInputType.phone` | `autofillHints: [AutofillHints.telephoneNumber]` |
| Number (integer) | `TextInputType.number` | `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` |
| Decimal | `TextInputType.numberWithOptions(decimal: true)` | |
| URL | `TextInputType.url` | |
| Multiline | `TextInputType.multiline` | `maxLines: null` |
| Password | `TextInputType.visiblePassword` | `obscureText: true`, `autofillHints: [AutofillHints.password]` |
| Name | `TextInputType.name` | `autofillHints: [AutofillHints.name]` or `.givenName`/`.familyName` |
| Street address | `TextInputType.streetAddress` | `autofillHints: [AutofillHints.streetAddressLine1]` |
| Search | `TextInputType.text` | `textInputAction: TextInputAction.search` |

Never use `TextInputType.text` as a default when a more specific type exists.

---

## Autofill

- **Always provide `autofillHints`** for known field types — password managers and system autofill depend on them
- Common hints: `email`, `password`, `newPassword`, `username`, `name`, `givenName`, `familyName`, `telephoneNumber`, `postalCode`, `streetAddressLine1`, `creditCardNumber`
- For sign-up forms, use `newPassword` on the password field (not `password`) so password managers suggest a generated password
- Wrap related fields in `AutofillGroup` so autofill can match multi-field patterns (address, payment)

---

## Text Input Action

- Set `textInputAction:` on every field — controls the keyboard's action button
- `TextInputAction.next` for intermediate fields in a multi-field form
- `TextInputAction.done` for the final field
- `TextInputAction.search` for search fields
- `TextInputAction.send` for chat/message inputs
- Wire `onFieldSubmitted` to advance focus (`FocusScope.of(context).nextFocus()`) or submit the form

---

## Focus Management

- First field of a form: `autofocus: true` — opens the keyboard immediately for faster first-use
- Multi-field forms: declare `FocusNode`s at the form level, pass to each field
- `FocusNode` lifecycle: create in `initState`, dispose in `dispose`
- On `onFieldSubmitted`: explicitly move focus to the next field's `FocusNode`
- Final field: `onFieldSubmitted` calls the submit handler
- Never autofocus when the user didn't intend to start typing (e.g., a search field on a content screen)

---

## Keyboard & Scroll Handling

- Wrap the form body in a `SingleChildScrollView` (or `ListView`) so keyboard-push never clips fields
- Set `resizeToAvoidBottomInset: true` on the `Scaffold` (default — don't disable)
- On focus, auto-scroll to the focused field using `Scrollable.ensureVisible(context)`
- Fixed bottom actions (submit buttons): use `MediaQuery.viewInsets.bottom` to lift above the keyboard
- Never: keyboard covering the input users are typing in

---

## Validation Strategy

### When to validate

- **On submit** — minimum. All validators run when the user tries to save.
- **On blur** (field loses focus) — good. Gives immediate feedback without harassing the user mid-typing.
- **On change** — only for specific cases:
  - Password strength meter (live feedback)
  - Confirmation fields (passwords match)
  - Format-as-you-type (phone numbers, dates)
- **Never on focus** — validating empty fields the moment the user enters them is hostile UX

### Validator structure

- Return `null` for valid, `String` error message for invalid
- Keep validators pure functions — no side effects, no network calls
- Compose validators: `[required, email, maxLength(100)].firstWhere((v) => v(value) != null, orElse: () => (_) => null)`
- Async validation (server checks): show a separate loading state, don't block submit until it completes
- Server validation errors: always display on the relevant field, not as a global banner

### Error messages

- **Specific**: "Email must contain @" not "Invalid email"
- **Actionable**: "Password must include a number" not "Password invalid"
- **Non-blaming**: "This doesn't look like an email address" not "You entered wrong email"
- **No jargon**: "Check the format" not "Does not match regex"
- Error text replaces helper text in the same position — don't stack them

---

## Submit Button

- Label the action: "Create account" / "Save changes" / "Sign in" — not "Submit" or "OK"
- Disabled state when form is invalid — but validation-on-submit should ALSO catch it (disabled buttons must be easy to understand; users blame themselves otherwise)
- Alternative: keep button enabled, run validators on tap, focus first invalid field
- During submission: show inline loading (spinner inside the button, or replace label with "Saving…") — don't disable the whole screen
- After success: navigate away OR show clear success state. Never leave the form looking idle.
- After error: specific error message, keep user input intact (never clear the form), focus the first field that needs correction

---

## Error Handling Pattern

Server-side or async error flow:

1. User submits
2. Button enters loading state (never full-screen spinner unless the form is trivial)
3. On server error:
   - Field-specific error → attach to that field
   - Form-level error (e.g., "Account already exists") → banner above the form
   - Network error → banner with retry
4. User input preserved. Every field keeps its value.
5. Focus moves to the first invalid field.
6. Error announcement via `SemanticsService.announce` for screen readers.

---

## Multi-Step Forms

- Show progress: step indicator (1 of 4) or progress bar
- Each step validates before advancing
- Back button preserves entered data — never clears fields on back navigation
- Save draft state if the form is long (>3 steps) — don't lose work on app kill
- Summary/review step before final submit — user confirms what's being saved

---

## Specialized Inputs

- **Date**: use a picker (`showDatePicker`, `CupertinoDatePicker`). Never a free-text date field.
- **Time**: picker, not text
- **Dropdowns**: < 7 options → segmented control or radio; ≥ 7 → bottom sheet with search
- **Checkboxes**: always pair with a tappable label (wrap in `InkWell`)
- **Switches**: for on/off settings, not for form submission
- **Sliders**: discrete values where they apply (quantity, rating); show current value as text alongside
- **Password**: show/hide toggle, strength indicator on sign-up, never on sign-in

---

## Accessibility (see accessibility.md for full rules)

- Every field has a matching visible + `Semantics` label
- Required fields announced to screen readers
- Errors announced when validation fails
- Focus moves to first invalid field on submit
- Field labels associated via `Semantics(label: ...)` — screen readers read label + value
- Touch targets on checkboxes/radios expand to include the label text (whole row tappable)

---

## State Preservation

- Use `PageStorageKey` or `AutomaticKeepAliveClientMixin` for forms inside tabs/pagers
- Persist draft state if the form is long (autosave to local storage on change, debounced)
- On app backgrounding mid-form: save state, restore on return
- After navigating away from a half-filled form: prompt to save or discard, never lose silently

---

## Destructive Form Actions

- "Delete account", "Remove all data" — always a two-step flow:
  1. Tap destructive action → confirmation dialog
  2. Dialog requires typing a confirmation word ("DELETE") or re-entering password
- Primary button in the dialog: safe action ("Cancel"). Destructive button: secondary position.
- Never put destructive actions next to safe ones without clear visual distinction (color + icon + spacing)

---

## DON'TS

- Don't use placeholder text as the label
- Don't validate on focus
- Don't clear field values on error
- Don't disable the whole form during submission — just the submit button
- Don't show "Invalid" or "Required" without saying what's wrong
- Don't use `TextInputType.text` when a specific type fits
- Don't skip autofill hints on known field types
- Don't autofocus fields users didn't ask to edit
- Don't let the keyboard cover the focused field
- Don't lose user input on rotation, backgrounding, or navigation

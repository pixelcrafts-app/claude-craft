---
name: scan
description: "Run all Flutter code scans: hardcoded values, duplicate code, accessibility patterns. Explicit command only."
disable-model-invocation: true
argument-hint: [optional-directory]
---

# flutter:scan

Sweep `$ARGUMENTS` (default: `lib/`) across three scan types. Report findings only — no rule restatement.

---

## 1. Hardcoded Values

Rules → `flutter-standards:engineering §No Hardcoded Values`

| Category | Grep |
|----------|------|
| Hex colors | `Color\(0x[0-9A-Fa-f]{8}\)\|Color\.fromARGB` |
| Magic EdgeInsets | `EdgeInsets\.(all\|symmetric\|only\|fromLTRB)\([0-9]` |
| Magic SizedBox | `SizedBox\((height\|width): [0-9]` |
| Magic BorderRadius | `BorderRadius\.(circular\|all)\([0-9]` |
| Inline TextStyle | `TextStyle\(` |
| Hardcoded Duration | `Duration\((milliseconds\|seconds): [0-9]` |
| FontWeight outside typography | `FontWeight\.w[0-9]+` |
| Repeated opacity literals | `withOpacity\(0\.` |

**Ignore:** `lib/**/theme/`, `**/colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `shadows.dart`, `gradients.dart`, `animations.dart`, `test/`, `*.g.dart`, `*.freezed.dart`, lines with `// design-system` or `// allow-literal`. Literals `0`, `1`, `-1`, `''`, `[]`, `true`, `false`, map keys.

**Verdict:** 0 → clean. 1–10 → fix inline. 11–50 → schedule pass. 50+ → flag at architecture level.

---

## 2. Duplicates

Rules → `flutter-standards:engineering §Reusability First`

| Type | Detection |
|------|-----------|
| Widget duplicates | `class \w+ extends (Stateless\|Stateful\|Consumer\|HookConsumer)Widget` — compare `build()` skeletons |
| Helper duplicates | `(formatDate\|formatTime\|formatCurrency\|isValidEmail\|validateEmail)`, `extension \w+ on (DateTime\|String)` — group by signature |
| Provider duplicates | `(Provider\|FutureProvider\|StateNotifierProvider\|StreamProvider)<` — flag same type from same source |
| Mapper duplicates | `class \w+Mapper`, `fromJson\(Map<String, dynamic>` — flag same output type |
| Inline card/button | `Container\(decoration: BoxDecoration\(` — flag 3+ occurrences with minor variation |
| Service/repo overlap | `class \w+(Service\|Repository)` — flag overlapping responsibilities |

**Ignore:** `test/`, `*.g.dart`, `*.freezed.dart`, abstract classes/interfaces, `deprecated_` prefixed files. Flag as candidates only — user decides.

**Verdict:** 0 → clean. 1–5 → fix opportunistically. 6–20 → schedule refactor sprint. 20+ → flag at architecture level.

---

## 3. Accessibility

Rules → `flutter-standards:accessibility`

| Pattern | Grep | Check |
|---------|------|-------|
| Missing Semantics | `IconButton\(\|GestureDetector\(\|InkWell\(\|Image\.(asset\|network\|file)\(` | ±10 lines for `Semantics(`, `tooltip:`, `semanticLabel:`, `excludeFromSemantics:` |
| Color-alone signals | `color: .*(Red\|Green\|Yellow\|Error\|Success\|Warning)`, `BoxDecoration\(.*color:` | Adjacent icon or text carrying same meaning |
| Touch targets <48dp | `IconButton\(.*padding:\s*EdgeInsets\.zero`, `iconSize:\s*(1[0-9]\|2[0-3])\b`, `GestureDetector\(.*child:\s*Icon`, `InkWell\(.*child:\s*Icon` | Surrounding `SizedBox` or `constraints` expanding to 48 |
| Placeholder-only fields | `TextField\(\|TextFormField\(` | Presence of `labelText:`, `Semantics(label:`, or visible `Text` above |
| Missing autofill hints | `keyboardType:\s*TextInputType\.(emailAddress\|phone\|streetAddress\|name)`, `obscureText:\s*true` | Presence of `autofillHints:` |
| Broken text scaling | `textScaler:\s*TextScaler\.noScaling`, `textScaleFactor:`, `maxLines:\s*1\b` | Fixed-height containers containing `Text` |
| Missing focus indicators | `focusColor:\s*Colors\.transparent`, `includeFocusSemantics:\s*false` | Custom visible focus state present |
| Unannounced state changes | `ScaffoldMessenger\.of\(context\)\.showSnackBar`, `showDialog\(` | `SemanticsService.announce` or focus shift nearby |
| RTL violations | `EdgeInsets\.only\(.*left:`, `EdgeInsets\.only\(.*right:`, `Alignment\.(centerLeft\|centerRight\|topLeft\|topRight\|bottomLeft\|bottomRight)`, `Positioned\(.*(left\|right):` | Replace with DirectionalEdgeInsets/AlignmentDirectional |
| Reduced motion | `AnimationController\|AnimatedContainer\|AnimatedOpacity\|AnimatedPositioned` | File references `disableAnimations` |

**Ignore:** `test/`, `integration_test/`, `*.g.dart`, `*.freezed.dart`, `lib/shared/design_system/`. Decorative images with `excludeFromSemantics: true` are not violations.

**Verdict:** 0 → rare; double-check scanner coverage. 1–5 → fix in next PR. 6–20 → dedicated accessibility sweep. 20+ → add `AppIconButton`, `AppTextField`, `AppStatusIndicator` to design system.

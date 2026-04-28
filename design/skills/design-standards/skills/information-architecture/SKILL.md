---
name: information-architecture
description: Apply when designing or reviewing web page structure, navigation, route hierarchy, or content placement. Auto-invoke when generating multi-page flows, navigation systems, or page layouts.
---

# Information Architecture

## Page Identity

Every page must have one answerable job expressible in five words or fewer. If it cannot be stated that concisely, the page must be split into focused pages or merged with an adjacent page.

No piece of data may appear on more than one route. Each datum has one canonical page; all other pages link to it.

Hub pages (listings, browse views, dashboards) show enough information about each item for the user to make a selection — not everything about each item. That is the detail page's job.

Detail pages show everything about one item. They do not repeat listing-level summaries.

A detail-page design must never be promoted directly to a top-level route. If an item warrants top-level placement, redesign it as a landing page before assigning it a top-level route.

## Navigation Structure

Primary navigation contains three to seven items. Fewer than three indicates under-specified structure; more than seven indicates the information architecture is wrong, not the navigation.

Each primary nav item must serve a distinct user intent. Two items that serve the same intent must be merged into one.

Search is scoped to the content section it searches and lives inside that section. It is not a standalone primary nav item or a standalone route.

Settings belongs inside the profile or account section. It is not a primary nav item.

Breadcrumbs are required on every page that is three or more levels deep in the hierarchy.

The active nav item must be visually distinct from all other nav items on every page. The user must be able to determine their current location without reading the page heading.

## Route Hierarchy

Flat hierarchies are preferred over deep ones. More than three levels of nesting produces navigation failure. If a path requires a fourth level, restructure the hierarchy before adding the route.

Route parameters carry identity — the permanent identity of a resource (`/article/:id`). Query parameters carry transient state — filter, sort, and pagination values.

Every route must function on cold start. Landing directly on any URL must produce a fully operational page without requiring prior navigation through the application.

Auth-gated routes redirect to the login page. The return URL is preserved in the redirect so the user lands on the originally requested page after authentication.

## Content Placement

Actions belong adjacent to their objects. An edit control appears on the item it edits. A delete control appears on the item it deletes. A separate edit page is only acceptable when the editing interaction itself requires a dedicated context.

Progressive disclosure is enforced across the listing-to-detail boundary. Summaries appear on listing pages; full detail appears on detail pages. The same content does not appear at both levels.

Above the fold contains the primary action and primary content for the page. Navigation chrome does not occupy above-the-fold real estate.

Each page contains one primary call to action. Secondary actions are visually subordinate to the primary action — lower contrast, smaller size, or reduced visual weight.

## Density Identity

Each page type has a fixed density profile. Density types must not be mixed on the same page.

Dashboard and hub pages are spacious and scannable. Section gaps are 24–32px.

Data tables are compact. Row padding is 8–12px. Information density is maximized.

Article and reading pages are single-column. Line length is 60–75 characters. Line-height is 1.6.

Forms are single-column. Field gaps are 16px. Labels appear above their fields on every form, without exception.

Marketing and landing pages lead with a hero, use generous whitespace, and minimize navigation chrome.

## IA Audit Checklist

Run this checklist before shipping any multi-page flow.

- Can each page's job be stated in five words or fewer?
- Does any piece of content appear on more than one page?
- Are there more than seven primary nav items?
- Do any two nav items serve the same user intent?
- Does every route handle cold start correctly and independently?
- Does every auth-gated route preserve the return URL on redirect?

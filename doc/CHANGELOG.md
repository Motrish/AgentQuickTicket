# Changelog

## 1.0.18

- Run OTOBO's `AJAXUpdate` for `ServiceID` after a no-submit profile postback. This applies the same service-dependent dynamic-field ACL refresh as selecting a service manually.

## 1.0.17

- Preserve `Action=AgentTicketPhone` in the native profile refresh URL and POST body so action-scoped ACLs remain active when dynamic fields change.

## 1.0.16

- Add configurable separator lines before selected profiles.
- Add a direct separator toggle to the administration overview.
- Render separators locally in the AgentTicketPhone widget only between visible profiles.

## 1.0.15

- Fix the profile list cursor handling so all profiles are displayed when group mappings are loaded.

## 1.0.14

- Remove orphaned rows from `agent_quick_ticket_profile_grp` during schema repair.
- Prevent failed profile creation from leaving an incomplete profile row.
- Ensure the profile-group table exists before profile creation and updates.

## 1.0.13

- Add an idempotent database schema repair during install, upgrade and reinstall so incomplete earlier installations create `agent_quick_ticket_profile_grp` automatically.

## 1.0.12

- Rename all profile database constraints and indexes to comply with OTOBO's 30-character identifier limit.

## 1.0.11

- Rename the profile-group table and database identifiers to comply with OTOBO's 30-character identifier limit.

## 1.0.10

- Include the OTOBO challenge token in the administration save form and log failed profile saves.

## 1.0.9

- Redraw visible OTOBO Modernize fields after applying a profile so selections such as next ticket state are immediately visible.

## 1.0.8

- Rewrite the user documentation with installation, configuration, placeholders, troubleshooting, security and operational guidance.

## 1.0.7

- Merge the German plugin translations into OTOBO's existing language catalog.
- Prevent unrelated standard OTOBO labels from falling back to English after installation.

## 1.0.6

- Restrict the German language extension to AgentQuickTicket-specific strings so it cannot override OTOBO core translations.
- Add German translations for the remaining admin, SysConfig, AJAX and server-side validation messages.
- Translate runtime warnings and errors using the active OTOBO language.

## 1.0.5

- Keep article-text profiles on the current AgentTicketPhone form so CKEditor does not restore the screen default during the prefill refresh.
- Synchronize both the live textarea value and its source text for late CKEditor initialization.

## 1.0.4

- Preserve profile values during AgentTicketPhone prefill refresh without creating a ticket.
- Synchronize the configured article text with OTOBO's CKEditor instance.
- Return a useful JSON error and log the exception if profile resolution fails.

## 1.0.3

- Initialize frontend JavaScript through OTOBO's `APP_MODULE` lifecycle so `Core.Config` is available before the admin dynamic-field editor and AgentTicketPhone widget start.

## 1.0.2

- Rebuilt the distributable using OTOBO's canonical PackageBuild element and attribute order.

## 1.0.1

- Corrected OTOBO package metadata and lifecycle declarations for UI installation.
- Added repository metadata for `Motrish/AgentQuickTicket`.

## 1.0.0

- Initial AgentTicketPhone quick-ticket widget.
- Admin profile CRUD and group/customer restrictions.
- Server-side validation, placeholder resolution and apply warnings.
- OTOBO package metadata, database schema, demo seed and maintenance helper.

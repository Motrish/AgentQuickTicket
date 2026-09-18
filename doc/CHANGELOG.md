# Changelog

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

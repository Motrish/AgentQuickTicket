# AgentQuickTicket

AgentQuickTicket adds configurable “Schnellticket”-Profile to OTOBO's `AgentTicketPhone` screen.

The widget appears below the customer information area after a customer user is selected. A profile is resolved and validated server-side, then applied to the existing phone-ticket form. The normal OTOBO form submission remains responsible for ticket creation; the plugin never creates a ticket directly.

Included:

- Admin CRUD at `Action=AdminAgentQuickTicket`.
- Per-profile group and customer-user restrictions.
- `Keep`, `Set` and `Clear` modes for queue, type, service, SLA, priority, status, owner, responsible, subject, body and time units.
- Supported dynamic-field configuration with server-side type/reference validation.
- Safe placeholders such as `%CustomerUserID%`, `%CustomerFullname%`, `%AgentLogin%` and `%CurrentDate%`.
- Confirmation and overwrite warnings before applying a profile.
- Optional demo profile `PasswordReset` using TypeID `5`, ServiceID `61`, PriorityID `1` and subject `Passwort reset %CustomerUserID%`.

See [INSTALL.md](INSTALL.md) and [ADMIN.md](ADMIN.md) for setup and operation.

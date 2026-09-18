# AgentQuickTicket

OTOBO extension for configurable quick-ticket profiles in `AgentTicketPhone`.

The plugin adds an agent-only quick-ticket widget below the customer information area. Profiles prefill the regular phone-ticket form; the ticket is created only when the agent submits that form.

## Installation

1. Download the latest `AgentQuickTicket-*.opm` release.
2. Install it through OTOBO's package manager.
3. Rebuild the configuration and refresh the agent session.
4. Configure profiles at `Action=AdminAgentQuickTicket`.

Supported target versions are OTOBO 11.0.x and 11.2.x. See [`doc/INSTALL.md`](doc/INSTALL.md) and [`doc/ADMIN.md`](doc/ADMIN.md) for details.

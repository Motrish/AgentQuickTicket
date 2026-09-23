# Installation

## Build an OPM

From an OTOBO checkout or installation, build the package with the OTOBO package builder. `--module-directory` must point to this source directory so the file list can be read.

```bash
bin/otobo.Console.pl Dev::Package::Build \
  --module-directory=/path/to/AgentQuickTicket \
  /path/to/AgentQuickTicket/AgentQuickTicket.sopm \
  /tmp
```

The result is `/tmp/AgentQuickTicket-1.0.19.opm`.

## Install

```bash
bin/otobo.Console.pl Admin::Package::Install /tmp/AgentQuickTicket-1.0.19.opm
bin/otobo.Console.pl Maint::Config::Rebuild
bin/otobo.Console.pl Maint::Cache::Delete
```

Restart or refresh the agent browser session after the package install. The admin menu entry is under `Ticket` as `Quick ticket profiles`.

The package creates the two tables `agent_quick_ticket_profile` and `agent_quick_ticket_profile_grp`. On upgrades, the package also runs an idempotent schema repair, removes orphaned group mappings and then seeds the demo profile. Installation seeds the idempotent demo profile `PasswordReset`; it can also be created or checked later with:

```bash
scripts/AgentQuickTicketMigrate.pl --check
scripts/AgentQuickTicketMigrate.pl --seed-demo
```

The demo expects the OTOBO objects from the concept: CustomerUserID `11443146`, ServiceID `61`, TypeID `5` and PriorityID `1`. The selected service must be available for the customer user in the target installation.

## Compatibility

The package declares OTOBO framework compatibility for 11.0.x and 11.2.x. The source was syntax-checked against OTOBO 11.0 and 11.2 APIs. A live browser/database test still needs to be run on the target instance.

There is intentionally no `CustomerFrontend` registration. The package definition removes the two plugin tables during uninstall; export or document the profiles before removing the package.

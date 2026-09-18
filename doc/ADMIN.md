# Administration

Open `Action=AdminAgentQuickTicket` and create a profile.

## Access

Select one or more agent groups. An agent can use the profile when they belong to one of those groups and have `create` permission for the effective queue. If no group is selected, enable `Allow all eligible agents`; otherwise the profile is rejected by server-side authorization.

Customer scope can be `All` or a list of customer logins/customer IDs. The scope is checked server-side on every profile lookup and apply request.

## Field modes

- `Keep`: preserve the current AgentTicketPhone value.
- `Set`: apply the configured value.
- `Clear`: send an empty value to the form.

The queue field is translated back to OTOBO's `Dest` format (`QueueID||QueueName`). The profile is applied to the regular form, so attachments and other current form data remain available and the agent can review the result before submitting.

## Placeholders

The following placeholders are accepted in text values:

`%CustomerUserID%`, `%CustomerID%`, `%CustomerFirstname%`, `%CustomerLastname%`, `%CustomerFullname%`, `%CustomerEmail%`, `%AgentLogin%`, `%AgentFirstname%`, `%AgentLastname%`, `%CurrentDate%`, `%CurrentDateTime%`.

Unknown placeholders cause validation failure. Values are resolved on the server and are not evaluated as HTML or code.

## Dynamic fields

Use the dynamic-field editor to select a valid Ticket or Article field. Supported types are `Text`, `TextArea`, `Checkbox`, `Dropdown`, `Multiselect`, `Date` and `DateTime`. The final JSON is validated again on save and on apply.

## Demo profile

`PasswordReset` is seeded with:

- TypeID `5`
- ServiceID `61`
- PriorityID `1`
- Subject `Passwort reset %CustomerUserID%`

Use the built-in **Test profile** block with a customer login before enabling the profile for production agents.

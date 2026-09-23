# AgentQuickTicket

AgentQuickTicket ist ein OTOBO-Plugin für konfigurierbare Schnellticket-Profile in `AgentTicketPhone`.

Ein Profil kann mehrere Ticketfelder, den Betreff, den Artikeltext und dynamische Felder vorausfüllen. Das Ticket wird dabei nicht sofort erstellt. Der Agent prüft das ausgefüllte Formular und erstellt das Ticket anschließend über den normalen OTOBO-Button.

## Funktionsumfang

- Agent-only-Widget unterhalb der Kundeninformationen in `AgentTicketPhone`
- Profile mit frei konfigurierbarem Namen, Label, Beschreibung, Icon, Farbe und Sortierung
- Konfigurierbare Trennlinien zwischen ausgewählten Profilen
- Vorausfüllen von Queue, Typ, Service, SLA, Priorität, Status, Besitzer, Verantwortlichem, Betreff, Artikeltext und Zeiteinheiten
- Unterstützung für dynamische Ticket- und Artikelfelder
- Platzhalter für Kundenbenutzer, Agenten und Datum/Uhrzeit
- Einschränkung auf Agentengruppen
- Einschränkung auf bestimmte Kundenbenutzer oder Kunden-IDs
- Prüfung von OTOBO-Berechtigungen, ACLs, Queues, Services, SLAs und dynamischen Feldern
- Warnungen bei überschriebenen Formularwerten
- Testfunktion für Profile in der Administrationsseite
- Demo-Profil `PasswordReset`
- Deutsche Übersetzungen ohne Überschreiben der OTOBO-Kernübersetzungen

Das Plugin registriert keine Customer-Frontend-Funktionen. Kunden können die Schnelltickets nicht selbst starten. Die Bedienung erfolgt ausschließlich durch Agents im Agenten-Interface.

## Voraussetzungen

- OTOBO 11.0.x oder 11.2.x
- aktiviertes Agenten-Interface
- aktivierte Aktion `AgentTicketPhone`
- Berechtigungen zum Installieren von OTOBO-Paketen
- Für ein Profil: Agentenberechtigung `create` für die wirksame Queue

Die Plugin-Metadaten lauten:

| Eigenschaft | Wert |
|---|---|
| Name | AgentQuickTicket |
| Vendor | Michael Nehmer \| Motrish |
| Repository | https://github.com/Motrish/AgentQuickTicket |
| Lizenz | GNU General Public License v3 |

## Installation über die OTOBO-Oberfläche

1. Die Datei `AgentQuickTicket-*.opm` herunterladen.
2. In OTOBO den Package Manager öffnen.
3. Das OPM-Paket hochladen und installieren beziehungsweise aktualisieren.
4. Die OTOBO-Konfiguration neu aufbauen.
5. Den OTOBO-Cache löschen.
6. Ab- und wieder anmelden oder den Browser mit `Strg+F5` aktualisieren.

Nach der Installation befindet sich die Administrationsseite unter:

```text
Action=AdminAgentQuickTicket
```

Je nach OTOBO-Navigation ist sie unter `Ticket` → `Quick ticket profiles` erreichbar.

## Installation über die Kommandozeile

```bash
bin/otobo.Console.pl Admin::Package::Install /path/to/AgentQuickTicket-1.0.18.opm
bin/otobo.Console.pl Maint::Config::Rebuild
bin/otobo.Console.pl Maint::Cache::Delete
```

Danach die Agentensitzung neu laden.

## Update

Ein Update erfolgt über den Package Manager mit der neuen OPM-Datei. Das Plugin unterstützt direkte Paketupdates.

Die Profildaten liegen in den Plugin-Tabellen und bleiben bei einem normalen Update erhalten. Vor einem Update sollte trotzdem ein Datenbank- beziehungsweise OTOBO-Backup vorhanden sein.

Nach jedem Update sollten ausgeführt werden:

```bash
bin/otobo.Console.pl Maint::Config::Rebuild
bin/otobo.Console.pl Maint::Cache::Delete
```

## Erstes Profil erstellen

1. `Action=AdminAgentQuickTicket` öffnen.
2. **Schnellticket-Profil hinzufügen** auswählen.
3. Die Grunddaten eintragen.
4. Mindestens eine Berechtigung für Agenten konfigurieren.
5. Die zu setzenden Ticketfelder auswählen.
6. Optional Kundenbereich, Bestätigung und Warnverhalten konfigurieren.
7. Das Profil speichern.
8. Mit **Test profile** und einem Kundenbenutzer testen.
9. Das Profil aktivieren und anschließend in `AgentTicketPhone` prüfen.

## Profil-Grunddaten

| Feld | Bedeutung |
|---|---|
| Interner Name | Stabiler technischer Bezeichner für Administration und Migrationen. Erlaubt sind Buchstaben, Zahlen, Punkt, Bindestrich und Unterstrich. Der Name muss mit einem Buchstaben beginnen. |
| Label | Sichtbarer Name des Buttons im AgentTicketPhone-Widget. |
| Beschreibung | Zusatzinformation und Tooltip des Buttons. |
| Icon | Lokale Font-Awesome-Klasse, zum Beispiel `fa-key` oder `fa-bolt`. |
| Farbe | Semantische Farbe wie `Primary`, `Success`, `Warning`, `Danger`, `Info`, `Neutral` oder ein Hexwert wie `#336699`. |
| Sortierung | Reihenfolge der Buttons im Widget. Kleinere Werte werden zuerst angezeigt. |
| Trennlinie | Mit **Trennlinie vor diesem Profil anzeigen** wird vor diesem Profil eine Linie dargestellt. Sie erscheint nur zwischen sichtbaren Profilen, nie vor dem ersten. |
| Gültigkeit | Nur gültige Profile werden Agents angeboten. |

Die Icons werden nicht aus dem Internet geladen. Das Plugin verwendet ausschließlich Font-Awesome-Klassen; die zugehörigen CSS- und Font-Dateien kommen aus der lokalen OTOBO-Installation.

## Agentenzugriff

Ein Profil kann über Agentengruppen eingeschränkt werden.

- Werden Gruppen ausgewählt, dürfen nur Agents aus diesen Gruppen das Profil verwenden.
- Werden keine Gruppen ausgewählt, muss **Alle berechtigten Agents erlauben** aktiviert werden.
- Zusätzlich muss der Agent für die wirksame Queue eine OTOBO-`create`-Berechtigung besitzen.
- Die Prüfung erfolgt serverseitig bei jedem Laden und Anwenden eines Profils.

Das Profil kann daher nicht allein durch Manipulation des Browsers verwendet werden.

## Kundenbereich

Ein Profil kann für alle Kundenbenutzer oder nur für eine Liste von Kunden-Logins beziehungsweise Kunden-IDs freigegeben werden.

- **Alle Kundenbenutzer**: Das Profil wird für jeden Kundenbenutzer angeboten, sofern der Agentenzugriff erfüllt ist.
- **Nur aufgelistete Kunden-Logins oder Kunden-IDs**: Nur die angegebenen Werte dürfen das Profil verwenden.

Der Kundenbereich wird serverseitig bei jeder Anfrage geprüft.

## Ticketfelder und Modi

Für jedes unterstützte Feld kann einer dieser Modi ausgewählt werden:

- `Keep`: aktuellen Wert im AgentTicketPhone-Formular beibehalten
- `Set`: konfigurierten Wert setzen
- `Clear`: vorhandenen Wert leeren

Unterstützte Standardfelder:

- Queue
- Typ
- Service
- SLA
- Priorität
- Status beziehungsweise nächster Ticketstatus
- Besitzer
- Verantwortlicher
- Betreffvorlage
- Artikeltextvorlage
- Zeiteinheiten

Bei `Queue` wird das interne OTOBO-Format `QueueID||QueueName` automatisch gesetzt. Das Profil arbeitet auf dem bestehenden Ticketformular. Bereits vorhandene Anhänge und andere Formularwerte bleiben erhalten.

Nach dem Anwenden werden die sichtbaren OTOBO-Modernize-Auswahlfelder neu gezeichnet. Dadurch zeigen beispielsweise Queue, Service, Priorität und nächster Status unmittelbar den übernommenen Wert und nicht nur den intern gesetzten Formularwert.

## Artikeltext und CKEditor

Der Artikeltext wird im OTOBO-Rich-Text-Editor gesetzt. Das Plugin synchronisiert dabei:

1. die CKEditor-Instanz,
2. das verbundene Textarea-Feld `RichText`,
3. den Wert, der beim normalen Erstellen des Tickets übertragen wird.

Ein Profil mit Artikeltext erstellt noch kein Ticket. Nach dem Anwenden kann der Agent den Text prüfen und anschließend den normalen Erstellen-Button verwenden.

## Platzhalter

Platzhalter können in Betreff, Artikeltext und unterstützten dynamischen Feldwerten verwendet werden.

| Platzhalter | Aufgelöster Wert |
|---|---|
| `%CustomerUserID%` | Login des Kundenbenutzers |
| `%CustomerID%` | Kunden-ID beziehungsweise Kundenorganisation |
| `%CustomerFirstname%` | Vorname des Kunden |
| `%CustomerLastname%` | Nachname des Kunden |
| `%CustomerFullname%` | Vollständiger Name des Kunden |
| `%CustomerEmail%` | E-Mail-Adresse des Kunden |
| `%AgentLogin%` | Login des aktuell angemeldeten Agents |
| `%AgentFirstname%` | Vorname des Agents |
| `%AgentLastname%` | Nachname des Agents |
| `%CurrentDate%` | Aktuelles Datum im Format `YYYY-MM-DD` |
| `%CurrentDateTime%` | Aktuelles Datum und Uhrzeit im Format `YYYY-MM-DD HH:MM:SS` |

Beispiel:

```text
Hallo %CustomerFirstname%,

Ihr Anliegen wurde am %CurrentDate% von %AgentFirstname% %AgentLastname% aufgenommen.

Kundenbenutzer: %CustomerUserID%
Kundennummer: %CustomerID%
E-Mail: %CustomerEmail%
```

`%CustomerUserID%` entspricht dem Kunden-Login, nicht zwingend einer numerischen Datenbank-ID. Unbekannte Platzhalter werden bei der serverseitigen Validierung abgelehnt.

## Dynamische Felder

Über **Dynamisches Feld hinzufügen** können gültige Ticket- oder Artikeldynamikfelder ausgewählt werden.

Unterstützte Feldtypen:

- `Text`
- `TextArea`
- `Checkbox`
- `Dropdown`
- `Multiselect`
- `Date`
- `DateTime`

Voraussetzungen:

- Das dynamische Feld muss in OTOBO existieren.
- Das Feld muss in `AgentTicketPhone` aktiviert sein.
- Der Objekt-Typ muss zu `Ticket` oder `Article` passen.
- Dropdown- und Mehrfachauswahlwerte müssen gültig sein.
- Datumswerte müssen im Format `YYYY-MM-DD` vorliegen.
- Datum-Zeit-Werte müssen im Format `YYYY-MM-DD HH:MM` oder `YYYY-MM-DD HH:MM:SS` vorliegen.

Die Konfiguration wird beim Speichern und erneut beim Anwenden des Profils validiert.

## Anwenden eines Profils

Beim Klick auf einen Schnellticket-Button führt das Plugin folgende Prüfungen durch:

1. Ist ein Kundenbenutzer ausgewählt?
2. Existiert das Profil und ist es gültig?
3. Darf der Agent das Profil verwenden?
4. Existieren Queue, Typ, Service, SLA, Status und Benutzerreferenzen?
5. Ist der Service dem Kundenbenutzer zugeordnet?
6. Erlauben aktuelle OTOBO-ACLs die Werte?
7. Würden bestehende Formularwerte überschrieben?

Je nach Profileinstellung wird bei Warnungen entweder abgebrochen oder das Profil mit Warnung angewendet.

Das Profil wird erst nach Bestätigung durch den Agenten auf das Formular angewendet. Die Ticketerstellung erfolgt ausschließlich über den normalen OTOBO-Workflow.

## Demo-Profil

Bei der Installation wird idempotent das Profil `PasswordReset` angelegt, sofern es noch nicht existiert.

Die Demo-Konfiguration verwendet:

| Feld | Wert |
|---|---:|
| CustomerUserID | `11443146` |
| ServiceID | `61` |
| TypeID | `5` |
| PriorityID | `1` |
| Betreff | `Passwort reset %CustomerUserID%` |

Die referenzierten OTOBO-Objekte müssen in der Zielinstallation vorhanden und gültig sein.

Das Profil kann mit dem Wartungsskript geprüft oder erneut angelegt werden:

```bash
scripts/AgentQuickTicketMigrate.pl --check
scripts/AgentQuickTicketMigrate.pl --seed-demo
```

## Fehlerdiagnose

### OTOBO-Log

Das Plugin protokolliert Backend-Ausnahmen mit dem Präfix:

```text
AgentQuickTicket ResolveProfile failed:
```

Der tatsächliche Logpfad hängt von OTOBOs `LogModule` ab. Prüfen:

```bash
grep -E "LogModule|LogModule::LogFile" /opt/otobo/Kernel/Config.pm
```

Bei Datei-Logging beispielsweise:

```bash
tail -f /tmp/otobo.log | grep --line-buffered AgentQuickTicket
```

Bei Syslog beispielsweise:

```bash
journalctl -f | grep AgentQuickTicket
```

### Browser-Entwicklertools

Wenn ein Body nicht übernommen wird:

1. `F12` öffnen.
2. Zum Tab **Network** wechseln.
3. Nur `Fetch/XHR` anzeigen.
4. Ein Schnellticket anklicken.
5. Den Request mit `Action=AgentQuickTicket` und `Subaction=ResolveProfile` öffnen.
6. In der Response prüfen, ob ein Feld `Body` vorhanden ist.

Danach in der Browser-Konsole ausführen:

```javascript
({
    editorKeys: Object.keys(window.CKEditorInstances || {}),
    editorExists: !!window.CKEditorInstances?.RichText,
    textareaValue: document.querySelector('#RichText')?.value,
    editorValue: window.CKEditorInstances?.RichText?.getData?.()
})
```

Interpretation:

- Kein `Body` in der Response: Body ist nicht im Profil gespeichert oder der Modus steht auf `Keep`.
- `Body` vorhanden, aber `editorExists` ist `false`: CKEditor war beim Setzen noch nicht initialisiert.
- `textareaValue` enthält Text, `editorValue` ist leer: CKEditor hat den Wert nicht übernommen oder später überschrieben.
- `editorValue` enthält Text, das erstellte Ticket ist leer: Problem bei der Synchronisierung während des normalen Submit-Vorgangs.

### Häufige Ursachen

- Das Profil wurde nach Änderung des Artikeltexts nicht gespeichert.
- Der Modus des Feldes `Article text template` steht auf `Keep` statt `Set`.
- Ein unbekannter Platzhalter wird verwendet.
- Der Browser verwendet noch alte JavaScript-Dateien aus dem Cache.
- Eine OTOBO-ACL blockiert den gesetzten Feldwert.
- Queue, Service, SLA, Status oder dynamisches Feld existieren nicht mehr oder sind ungültig.

Nach einem Plugin-Update immer ausführen:

```bash
bin/otobo.Console.pl Maint::Config::Rebuild
bin/otobo.Console.pl Maint::Cache::Delete
```

Anschließend Browser mit `Strg+F5` aktualisieren.

## Datenbank und Deinstallation

Das Plugin verwendet diese Tabellen:

- `agent_quick_ticket_profile`
- `agent_quick_ticket_profile_grp`

Vor einer Deinstallation sollten die Profile exportiert oder dokumentiert werden. Die Paketdeinstallation entfernt die Plugin-Tabellen gemäß OTOBO-Paketdefinition. Vorher ein Datenbankbackup erstellen.

Die Installation verändert keine OTOBO-Core-Dateien.

## Datenschutz und externe Verbindungen

Das Plugin verarbeitet die für das Ticket benötigten Kunden- und Agentendaten innerhalb von OTOBO. Es gibt keine externe API-Verbindung und keinen externen Icon- oder CDN-Abruf.

Die Font-Awesome-Icons werden aus den lokalen OTOBO-Assets geladen. Platzhalter werden serverseitig aufgelöst. Werte werden nicht als Perl-Code, JavaScript oder HTML-Code ausgeführt.

## Bekannte Einschränkungen

- Telefonnummer, Mobilnummer, Abteilung und weitere beliebige Kundenbenutzerfelder sind derzeit keine eigenen Platzhalter.
- Es wird nur `AgentTicketPhone` unterstützt.
- Die Ticketerstellung wird nicht automatisch durch den Button ausgelöst.
- Unterstützte dynamische Feldtypen sind auf die in dieser README genannten Typen beschränkt.
- Eine Live-Installation mit der lokalen Datenbank und den lokalen ACLs muss auf dem Zielsystem getestet werden.

## Entwicklung und Paketbau

Das Paket wird über `AgentQuickTicket.sopm` beschrieben. Ein OPM-Paket kann aus dem Quellverzeichnis gebaut werden:

```bash
bin/otobo.Console.pl Dev::Package::Build \
  --module-directory=/path/to/AgentQuickTicket \
  /path/to/AgentQuickTicket/AgentQuickTicket.sopm \
  /tmp
```

Vor der Veröffentlichung sollten mindestens diese Prüfungen ausgeführt werden:

```bash
prove -v scripts/test/AgentQuickTicketStatic.t
node --check var/httpd/htdocs/js/Core.Agent.AgentQuickTicket.js
node --check var/httpd/htdocs/js/Core.Agent.Admin.AgentQuickTicket.js
```

## Support und Repository

- Repository: https://github.com/Motrish/AgentQuickTicket
- Vendor: Michael Nehmer | Motrish
- Lizenz: GNU GPLv3
- Changelog: [`doc/CHANGELOG.md`](doc/CHANGELOG.md)
- Administrationsdetails: [`doc/ADMIN.md`](doc/ADMIN.md)
- Installationsdetails: [`doc/INSTALL.md`](doc/INSTALL.md)

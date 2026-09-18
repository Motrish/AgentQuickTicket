# --
# AgentQuickTicket German translations.
#
# Keep this file limited to plugin-specific strings. OTOBO loads de_*.pm
# after Kernel/Language/de.pm, so generic keys would overwrite translations
# globally for the complete agent interface.
# --

package Kernel::Language::de_AgentQuickTicket;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my %Translation = (
        'Quick tickets' => 'Schnelltickets',
        'Quick ticket profiles' => 'Schnellticket-Profile',
        'Add quick ticket profile' => 'Schnellticket-Profil hinzufügen',
        'Edit quick ticket profile' => 'Schnellticket-Profil bearbeiten',
        'About quick tickets' => 'Über Schnelltickets',
        'Profiles are applied to the regular AgentTicketPhone form. No ticket is created until the agent submits that form.' => 'Profile werden auf das normale AgentTicketPhone-Formular angewendet. Ein Ticket wird erst beim Absenden dieses Formulars erstellt.',
        'Please select a customer user first.' => 'Bitte zuerst einen Kundenbenutzer auswählen.',
        'Loading quick tickets...' => 'Schnelltickets werden geladen ...',
        'No quick tickets are available for this customer user.' => 'Für diesen Kundenbenutzer sind keine Schnelltickets verfügbar.',
        'Quick tickets could not be loaded.' => 'Schnelltickets konnten nicht geladen werden.',
        'The quick ticket profile could not be applied.' => 'Das Schnellticket-Profil konnte nicht angewendet werden.',
        'The AgentTicketPhone form was not found.' => 'Das AgentTicketPhone-Formular wurde nicht gefunden.',
        'The AgentTicketPhone form is missing its refresh fields.' => 'Dem AgentTicketPhone-Formular fehlen die Refresh-Felder.',
        'Fields to apply' => 'Anzuwendende Felder',
        'Existing values to overwrite' => 'Zu überschreibende Werte',
        'Warnings' => 'Warnungen',
        'Defaults' => 'Vorgaben',
        'Allowed agents' => 'Berechtigte Agenten',
        'Validation' => 'Validierung',
        'group(s)' => 'Gruppe(n)',
        'All eligible agents' => 'Alle berechtigten Agenten',
        'Toggle validity' => 'Gültigkeit umschalten',
        'Delete this quick ticket profile?' => 'Dieses Schnellticket-Profil löschen?',
        'No quick ticket profiles are configured.' => 'Es sind keine Schnellticket-Profile konfiguriert.',
        'Placeholder syntax' => 'Platzhalter-Syntax',
        'and the other documented placeholders can be used in text values.' => 'und die übrigen dokumentierten Platzhalter können in Textwerten verwendet werden.',
        'Basic data' => 'Grunddaten',
        'Stable identifier used for administration and migrations.' => 'Stabiler Bezeichner für Administration und Migrationen.',
        'Font Awesome class, for example fa-key.' => 'Font-Awesome-Klasse, zum Beispiel fa-key.',
        'Button color' => 'Tastenfarbe',
        'Use Primary, Success, Warning, Danger, Info, Neutral or a six-digit hex color.' => 'Primary, Success, Warning, Danger, Info, Neutral oder eine sechsstellige Hex-Farbe verwenden.',
        'Sort order' => 'Sortierung',
        'Agent access' => 'Agentenzugriff',
        'Allowed groups' => 'Erlaubte Gruppen',
        'Leave empty only when all eligible agents are explicitly allowed below.' => 'Nur leer lassen, wenn unten ausdrücklich alle berechtigten Agenten zugelassen werden.',
        'Allow all eligible agents when no group is selected' => 'Alle berechtigten Agenten erlauben, wenn keine Gruppe ausgewählt ist',
        'Keep preserves the current form value, Set writes the configured value, and Clear removes it. IDs are validated server-side.' => 'Keep übernimmt den aktuellen Formularwert, Set schreibt den konfigurierten Wert und Clear entfernt ihn. IDs werden serverseitig geprüft.',
        'Field' => 'Feld',
        'Mode' => 'Modus',
        'Internal name' => 'Interner Name',
        'Icon' => 'Symbol',
        'Subject template' => 'Betreffvorlage',
        'Article text template' => 'Artikeltextvorlage',
        'Keep' => 'Beibehalten',
        'Dynamic field' => 'Dynamisches Feld',
        'Only valid Ticket or Article dynamic fields with supported types are accepted. Values can contain placeholders.' => 'Es werden nur gültige dynamische Ticket- oder Artikelfelder mit unterstützten Typen akzeptiert. Werte können Platzhalter enthalten.',
        'Customer scope' => 'Kundenbereich',
        'Scope' => 'Bereich',
        'All customer users' => 'Alle Kundenbenutzer',
        'Only listed customer logins or customer IDs' => 'Nur aufgelistete Kunden-Logins oder Kunden-IDs',
        'Customer logins / IDs' => 'Kunden-Logins / IDs',
        'Apply behavior' => 'Anwendungsverhalten',
        'Invalid values' => 'Ungültige Werte',
        'Abort application' => 'Anwendung abbrechen',
        'Apply with warning' => 'Mit Warnung anwenden',
        'Confirmation' => 'Bestätigung',
        'Ask for confirmation before applying' => 'Vor der Anwendung bestätigen',
        'Warn when existing values would be overwritten' => 'Warnen, wenn vorhandene Werte überschrieben werden',
        'Test profile' => 'Profil testen',
        'Customer user login' => 'Kundenbenutzer-Login',
        'Resolve profile' => 'Profil auflösen',
        'Profile can be applied.' => 'Das Profil kann angewendet werden.',
        'Changed fields:' => 'Geänderte Felder:',
        'The configuration contains errors:' => 'Die Konfiguration enthält Fehler:',

        # SysConfig descriptions.
        'Frontend module registration for AgentQuickTicket administration.' => 'Frontend-Modulregistrierung für die AgentQuickTicket-Administration.',
        'Configure quick ticket profiles.' => 'Schnellticket-Profile konfigurieren.',
        'Loader registration for AgentQuickTicket administration.' => 'Loader-Registrierung für die AgentQuickTicket-Administration.',
        'Admin area navigation for AgentQuickTicket.' => 'Navigation im Adminbereich für AgentQuickTicket.',
        'Create and manage quick ticket profiles.' => 'Schnellticket-Profile erstellen und verwalten.',
        'AJAX frontend module for AgentQuickTicket.' => 'AJAX-Frontend-Modul für AgentQuickTicket.',
        'AJAX endpoint for quick ticket profiles.' => 'AJAX-Endpunkt für Schnellticket-Profile.',
        'Quick ticket endpoint' => 'Schnellticket-Endpunkt',
        'Loader registration for the AgentTicketPhone quick ticket widget.' => 'Loader-Registrierung für das AgentTicketPhone-Schnellticket-Widget.',
        'Injects the AgentQuickTicket widget into AgentTicketPhone.' => 'Fügt das AgentQuickTicket-Widget in AgentTicketPhone ein.',

        # Server-side validation and AJAX messages.
        'Missing profile or customer user.' => 'Profil oder Kundenbenutzer fehlt.',
        'The selected quick ticket profile does not exist.' => 'Das ausgewählte Schnellticket-Profil existiert nicht.',
        "Customer user '%s' was not found." => "Kundenbenutzer '%s' wurde nicht gefunden.",
        'You are not allowed to use this quick ticket profile.' => 'Sie sind nicht berechtigt, dieses Schnellticket-Profil zu verwenden.',
        'Profile validation failed.' => 'Die Profilvalidierung ist fehlgeschlagen.',
        'The profile could not be applied completely.' => 'Das Profil konnte nicht vollständig angewendet werden.',
        'The quick ticket profile could not be applied. Please check the OTOBO log.' => 'Das Schnellticket-Profil konnte nicht angewendet werden. Bitte prüfen Sie das OTOBO-Log.',
        'Unknown AgentQuickTicket subaction.' => 'Unbekannte AgentQuickTicket-Subaktion.',
        'Quick ticket profile not found.' => 'Schnellticket-Profil nicht gefunden.',
        'The profile could not be saved.' => 'Das Profil konnte nicht gespeichert werden.',
        'The internal name is already in use.' => 'Der interne Name wird bereits verwendet.',
        'Use letters, numbers, dot, dash and underscore; start with a letter.' => 'Verwenden Sie Buchstaben, Zahlen, Punkt, Bindestrich und Unterstrich; beginnen Sie mit einem Buchstaben.',
        'A visible label is required.' => 'Eine sichtbare Bezeichnung ist erforderlich.',
        'The icon must be a Font Awesome class such as fa-key.' => 'Das Symbol muss eine Font-Awesome-Klasse wie fa-key sein.',
        'Use a semantic color or a six-digit hexadecimal color.' => 'Verwenden Sie eine semantische Farbe oder eine sechsstellige Hex-Farbe.',
        'Select at least one group or explicitly allow all eligible agents.' => 'Wählen Sie mindestens eine Gruppe aus oder erlauben Sie ausdrücklich alle berechtigten Agenten.',
        'Dynamic field configuration is not valid JSON.' => 'Die Konfiguration der dynamischen Felder ist kein gültiges JSON.',

        # Server-side validation and ACL warnings with runtime values.
        'Unknown placeholder(s): %s' => 'Unbekannte Platzhalter: %s',
        "Queue '%s' does not exist." => "Queue '%s' existiert nicht.",
        'Unknown placeholder(s) in dynamic field %s: %s' => 'Unbekannte Platzhalter im dynamischen Feld %s: %s',
        "Service '%s' is not assigned to customer user '%s'." => "Service '%s' ist dem Kundenbenutzer '%s' nicht zugewiesen.",
        "SLA '%s' is not assigned to service '%s'." => "SLA '%s' ist dem Service '%s' nicht zugewiesen.",
        "You do not have create permission for queue '%s'." => "Sie haben keine Erstellberechtigung für die Queue '%s'.",
        "Unknown ticket field '%s'." => "Unbekanntes Ticketfeld '%s'.",
        "Invalid mode '%s' for field '%s'." => "Ungültiger Modus '%s' für Feld '%s'.",
        "Value for '%s' must be numeric." => "Der Wert für '%s' muss numerisch sein.",
        "Invalid invalid-value behavior '%s'." => "Ungültiges Verhalten für ungültige Werte: '%s'.",
        "Invalid customer scope '%s'." => "Ungültiger Kundenbereich '%s'.",
        'Customer scope requires at least one customer login or customer ID.' => 'Der Kundenbereich benötigt mindestens einen Kunden-Login oder eine Kunden-ID.',
        "Invalid mode '%s' for dynamic field '%s'." => "Ungültiger Modus '%s' für dynamisches Feld '%s'.",
        "Dynamic field '%s' does not exist." => "Das dynamische Feld '%s' existiert nicht.",
        "Dynamic field '%s' is not enabled in AgentTicketPhone." => "Das dynamische Feld '%s' ist in AgentTicketPhone nicht aktiviert.",
        "Dynamic field '%s' has unsupported type '%s'." => "Das dynamische Feld '%s' hat den nicht unterstützten Typ '%s'.",
        "Dynamic field '%s' has an invalid object type." => "Das dynamische Feld '%s' hat einen ungültigen Objekttyp.",
        "Checkbox dynamic field '%s' requires 0 or 1." => "Das Checkbox-Dynamische-Feld '%s' benötigt 0 oder 1.",
        "Value for dynamic field '%s' is not a valid dropdown value." => "Der Wert für das dynamische Feld '%s' ist kein gültiger Dropdown-Wert.",
        "Value '%s' for dynamic field '%s' is not a valid multiselect value." => "Der Wert '%s' für das dynamische Feld '%s' ist kein gültiger Mehrfachauswahlwert.",
        "Date dynamic field '%s' requires YYYY-MM-DD." => "Das Datumsfeld '%s' benötigt YYYY-MM-DD.",
        "DateTime dynamic field '%s' requires YYYY-MM-DD HH:MM[:SS]." => "Das Datum-Zeit-Feld '%s' benötigt YYYY-MM-DD HH:MM[:SS].",
        "Referenced OTOBO object for '%s' with ID '%s' does not exist." => "Das referenzierte OTOBO-Objekt für '%s' mit der ID '%s' existiert nicht.",
        "Unknown placeholder '%s'." => "Unbekannter Platzhalter '%s'.",
        "Checkbox dynamic field '%s' requires 0 or 1 after placeholder resolution." => "Das Checkbox-Dynamische-Feld '%s' benötigt nach der Platzhalterauflösung 0 oder 1.",
        "Value '%s' for dynamic field '%s' is not valid after placeholder resolution." => "Der Wert '%s' für das dynamische Feld '%s' ist nach der Platzhalterauflösung ungültig.",
        "Date dynamic field '%s' requires YYYY-MM-DD after placeholder resolution." => "Das Datumsfeld '%s' benötigt nach der Platzhalterauflösung YYYY-MM-DD.",
        "DateTime dynamic field '%s' requires YYYY-MM-DD HH:MM[:SS] after placeholder resolution." => "Das Datum-Zeit-Feld '%s' benötigt nach der Platzhalterauflösung YYYY-MM-DD HH:MM[:SS].",
        "%s '%s' is not allowed by the current AgentTicketPhone ACL context." => "%s '%s' ist im aktuellen AgentTicketPhone-ACL-Kontext nicht erlaubt.",
        "Dynamic field '%s' is hidden by the current AgentTicketPhone ACL context." => "Das dynamische Feld '%s' ist im aktuellen AgentTicketPhone-ACL-Kontext ausgeblendet.",
        "Value '%s' for dynamic field '%s' is blocked by the current AgentTicketPhone ACL context." => "Der Wert '%s' für das dynamische Feld '%s' ist im aktuellen AgentTicketPhone-ACL-Kontext gesperrt.",
    );

    # Extension language files are executed after the base language file.
    # Merge the plugin strings into the existing catalog; replacing it would
    # make all unrelated OTOBO translations fall back to English.
    $Self->{Translation} = {
        %{ $Self->{Translation} || {} },
        %Translation,
    };
}

1;

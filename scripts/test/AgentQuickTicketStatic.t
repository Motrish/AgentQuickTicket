#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use Test::More;

my $Root = File::Spec->rel2abs( File::Spec->catdir( $Bin, '..', '..' ) );

my @Required = qw(
    AgentQuickTicket.sopm
    README.md
    doc/AgentQuickTicket/README.md
    doc/AgentQuickTicket/INSTALL.md
    doc/AgentQuickTicket/ADMIN.md
    doc/AgentQuickTicket/CHANGELOG.md
    Kernel/Config/Files/XML/AgentQuickTicket.xml
    Kernel/Language/de_AgentQuickTicket.pm
    Kernel/Language/en_AgentQuickTicket.pm
    Kernel/System/AgentQuickTicket.pm
    Kernel/Modules/AdminAgentQuickTicket.pm
    Kernel/Modules/AgentQuickTicket.pm
    Kernel/Output/HTML/FilterElementPost/AgentQuickTicket.pm
    Kernel/Output/HTML/Templates/Standard/AdminAgentQuickTicket.tt
    Kernel/Output/HTML/Templates/Standard/AdminAgentQuickTicketEdit.tt
    Kernel/Output/HTML/Templates/Standard/AgentQuickTicketWidget.tt
    var/httpd/htdocs/js/Core.Agent.AgentQuickTicket.js
    var/httpd/htdocs/js/Core.Agent.Admin.AgentQuickTicket.js
    var/httpd/htdocs/skins/Agent/default/css/AgentQuickTicket.css
);

for my $Relative (@Required) {
    my @Parts = split m{/}, $Relative;
    ok( -f File::Spec->catfile( $Root, @Parts ), "required file $Relative" );
}

my $SOPM = File::Spec->catfile( $Root, 'AgentQuickTicket.sopm' );
my $XMLModule = File::Spec->catfile( $Root, 'Kernel', 'Config', 'Files', 'XML', 'AgentQuickTicket.xml' );
my $AdminEditTemplate = File::Spec->catfile( $Root, 'Kernel', 'Output', 'HTML', 'Templates', 'Standard', 'AdminAgentQuickTicketEdit.tt' );

SKIP: {
    eval { require XML::LibXML; 1 } or skip 'XML::LibXML is not installed', 4;

    my $Parser = XML::LibXML->new();
    my $SOPMDoc = eval { $Parser->parse_file($SOPM) };
    ok( $SOPMDoc, 'SOPM is well-formed XML' );
    is( $SOPMDoc->findvalue('/otobo_package/Name'), 'AgentQuickTicket', 'package name is correct' );

    my $ModuleDoc = eval { $Parser->parse_file($XMLModule) };
    ok( $ModuleDoc, 'SysConfig XML is well-formed XML' );
    ok( !$ModuleDoc->findnodes('//*[contains(local-name(), "CustomerFrontend") or contains(@Name, "CustomerFrontend")]'), 'no CustomerFrontend registration' );
}

open my $Handle, '<', File::Spec->catfile( $Root, 'Kernel', 'System', 'AgentQuickTicket.pm' )
    or die "Cannot read core module: $!";
local $/;
my $Core = <$Handle>;
close $Handle;

like( $Core, qr/CustomerFullname/, 'customer placeholder is implemented' );
like( $Core, qr/QueueCreateAllowed/, 'queue create permission check is implemented' );
like( $Core, qr/ConfirmBeforeApply/, 'apply confirmation is implemented' );
like( $Core, qr/our \$VERSION = '1\.0\.19'/, 'core module version is 1.0.19' );
like( $Core, qr/Presentation\s*=>\s*\{\s*SeparatorBefore\s*=>\s*0/s, 'separator presentation has a backward-compatible default' );
like( $Core, qr/sub\s+SetSeparatorBefore\s*\{/, 'separator setting has a persistence method' );
like( $Core, qr/\$PublicProfile\{SeparatorBefore\}\s*=\s*\$Profile->\{Configuration\}\{Presentation\}\{SeparatorBefore\}/, 'public profiles expose separator state' );
like( $Core, qr/GroupTableName\}\s*=\s*'agent_quick_ticket_profile_grp'/, 'profile group table uses the OTOBO-compatible name' );
like( $Core, qr/sub\s+EnsureDatabaseSchema\s*\{/, 'database schema repair method is implemented' );
like( $Core, qr/CREATE TABLE IF NOT EXISTS/, 'database schema repair is idempotent' );
like( $Core, qr/profile_id NOT IN \(SELECT id FROM/, 'orphaned group mappings are removed during schema repair' );
like( $Core, qr/Do not leave a profile without its group mapping data/, 'failed profile creation is rolled back' );
like( $Core, qr/my \@ProfileRows;/, 'profile rows are buffered before nested group queries' );
like( $Core, qr/for my \$Row \(\@ProfileRows\)/, 'group mappings are loaded after the profile result set' );

open my $SOPMHandle, '<', $SOPM
    or die "Cannot read SOPM: $!";
local $/;
my $SOPMText = <$SOPMHandle>;
close $SOPMHandle;

like( $SOPMText, qr/Unique Name="aqt_profile_iname_uniq"/, 'profile name constraint uses the OTOBO-compatible name' );
like( $SOPMText, qr/Index Name="aqt_profile_grp_pid"/, 'profile group profile index uses the OTOBO-compatible name' );
like( $SOPMText, qr/Index Name="aqt_profile_grp_gid"/, 'profile group group index uses the OTOBO-compatible name' );

open my $AdminEditHandle, '<', $AdminEditTemplate
    or die "Cannot read admin edit template: $!";
local $/;
my $AdminEditTemplateText = <$AdminEditHandle>;
close $AdminEditHandle;

like( $AdminEditTemplateText, qr/name="ChallengeToken" value="\[% Env\("ChallengeToken"\)/, 'admin save form includes the OTOBO challenge token' );
like( $AdminEditTemplateText, qr/name="SeparatorBefore"/, 'admin edit form includes the separator setting' );

open my $AdminOverviewHandle, '<', File::Spec->catfile( $Root, 'Kernel', 'Output', 'HTML', 'Templates', 'Standard', 'AdminAgentQuickTicket.tt' )
    or die "Cannot read admin overview template: $!";
local $/;
my $AdminOverviewTemplate = <$AdminOverviewHandle>;
close $AdminOverviewHandle;
like( $AdminOverviewTemplate, qr/Subaction=ToggleSeparator/, 'admin overview provides a separator toggle' );

open my $GermanLanguageHandle, '<', File::Spec->catfile( $Root, 'Kernel', 'Language', 'de_AgentQuickTicket.pm' )
    or die "Cannot read German language extension: $!";
local $/;
my $GermanLanguage = <$GermanLanguageHandle>;
close $GermanLanguageHandle;

unlike( $GermanLanguage, qr/^\s*'Actions'\s*=>/m, 'German extension does not override global Actions' );
unlike( $GermanLanguage, qr/^\s*'Queue'\s*=>/m, 'German extension does not override global Queue' );
unlike( $GermanLanguage, qr/^\s*'Ticket fields'\s*=>/m, 'German extension does not override global Ticket fields' );
like( $GermanLanguage, qr/Unknown placeholder\(s\): %s/, 'runtime warning translation is present' );
like( $GermanLanguage, qr/\%\{ \$Self-\>\{Translation\} \|\| \{\} \}/, 'German extension merges into the existing catalog' );

require File::Spec->catfile( $Root, 'Kernel', 'Language', 'de_AgentQuickTicket.pm' );
my $LanguageData = {
    Translation => {
        Preferences => 'Einstellungen',
    },
};
Kernel::Language::de_AgentQuickTicket::Data($LanguageData);
is( $LanguageData->{Translation}{Preferences}, 'Einstellungen', 'existing core translations are preserved' );
is( $LanguageData->{Translation}{'Quick tickets'}, 'Schnelltickets', 'plugin translation is added' );

open my $AgentJSHandle, '<', File::Spec->catfile( $Root, 'var', 'httpd', 'htdocs', 'js', 'Core.Agent.AgentQuickTicket.js' )
    or die "Cannot read agent JavaScript: $!";
local $/;
my $AgentJS = <$AgentJSHandle>;
close $AgentJSHandle;

like( $AgentJS, qr/CKEditorInstances\.RichText\.setData/, 'article text is written to CKEditor' );
like( $AgentJS, qr/\$RichText\.text\(TextValue\)\.val\(TextValue\)/, 'article text is written to the RTE source element' );
like( $AgentJS, qr/hasOwnProperty\.call\(Prefill, 'Body'\)/, 'article-text profiles stay on the current form' );
like( $AgentJS, qr/name="ExpandCustomerName"/, 'prefill refresh targets the AgentTicketPhone no-submit field' );
like( $AgentJS, qr/\$ExpandCustomerName\.val\('4'\)/, 'prefill refresh uses the no-submit AgentTicketPhone path' );
like( $AgentJS, qr/HTMLFormElement\.prototype\.submit\.call/, 'prefill refresh uses native form submission' );
like( $AgentJS, qr/TargetURL\.searchParams\.set\('Action', 'AgentTicketPhone'\)/, 'native refresh URL preserves AgentTicketPhone action for ACL matching' );
like( $AgentJS, qr/\$Action\.val\('AgentTicketPhone'\)/, 'native refresh POST body preserves AgentTicketPhone action' );
like( $AgentJS, qr/TargetURL\.searchParams\.set\(ServiceRefreshParameter, '1'\)/, 'profile postback marks the missing service refresh' );
like( $AgentJS, qr/Core\.AJAX\.FormUpdate\(\$Form, 'AJAXUpdate', 'ServiceID'\)/, 'postback runs OTOBO service dependency refresh' );
like( $AgentJS, qr/trigger\('redraw\.InputField'\)/, 'visible Modernize fields are redrawn after profile application' );
like( $AgentJS, qr/trigger\('change'\)/, 'OTOBO change handlers are notified after profile application' );
like( $AgentJS, qr/BuildSeparator/, 'widget builds a local separator element' );
like( $AgentJS, qr/RenderedProfiles > 0 && Profile\.SeparatorBefore/, 'widget does not render a separator before the first visible profile' );

open my $CSSHandle, '<', File::Spec->catfile( $Root, 'var', 'httpd', 'htdocs', 'skins', 'Agent', 'default', 'css', 'AgentQuickTicket.css' )
    or die "Cannot read AgentQuickTicket CSS: $!";
local $/;
my $CSS = <$CSSHandle>;
close $CSSHandle;
like( $CSS, qr/\.AgentQuickTicketSeparator\s*\{/, 'widget separator has local CSS' );

open my $ControllerHandle, '<', File::Spec->catfile( $Root, 'Kernel', 'Modules', 'AgentQuickTicket.pm' )
    or die "Cannot read controller: $!";
local $/;
my $Controller = <$ControllerHandle>;
close $ControllerHandle;

like( $Controller, qr/ResolveProfile failed/, 'ResolveProfile exceptions are logged' );

open my $AdminControllerHandle, '<', File::Spec->catfile( $Root, 'Kernel', 'Modules', 'AdminAgentQuickTicket.pm' )
    or die "Cannot read admin controller: $!";
local $/;
my $AdminController = <$AdminControllerHandle>;
close $AdminControllerHandle;

like( $AdminController, qr/profile save failed/, 'profile save failures are logged' );
like( $AdminController, qr/Subaction eq 'ToggleSeparator'/, 'admin controller handles separator toggling' );

done_testing();

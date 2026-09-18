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
    doc/README.md
    doc/INSTALL.md
    doc/ADMIN.md
    doc/CHANGELOG.md
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
like( $AgentJS, qr/trigger\('redraw\.InputField'\)/, 'visible Modernize fields are redrawn after profile application' );
like( $AgentJS, qr/trigger\('change'\)/, 'OTOBO change handlers are notified after profile application' );

open my $ControllerHandle, '<', File::Spec->catfile( $Root, 'Kernel', 'Modules', 'AgentQuickTicket.pm' )
    or die "Cannot read controller: $!";
local $/;
my $Controller = <$ControllerHandle>;
close $ControllerHandle;

like( $Controller, qr/ResolveProfile failed/, 'ResolveProfile exceptions are logged' );

done_testing();

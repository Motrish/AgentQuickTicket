#!/usr/bin/env perl

# --
# AgentQuickTicket maintenance helper.
# --

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../";

use Kernel::System::ObjectManager;

my $Mode = shift(@ARGV) || '';

if ( $Mode ne '--seed-demo' && $Mode ne '--list' && $Mode ne '--check' ) {
    print "Usage: $0 --seed-demo | --list | --check\n";
    exit 2;
}

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $QuickTicketObject = $Kernel::OM->Get('Kernel::System::AgentQuickTicket');

if ( $Mode eq '--seed-demo' ) {
    my $ID = $QuickTicketObject->SeedDemoProfile( UserID => 1 );
    print $ID ? "Demo profile PasswordReset is available (ID $ID).\n" : "Demo profile could not be created.\n";
    exit $ID ? 0 : 1;
}

if ( $Mode eq '--list' ) {
    my $Profiles = $QuickTicketObject->ProfileList( Valid => 0, UseCache => 0 );
    for my $Profile ( @{$Profiles} ) {
        printf "%s\t%s\t%s\n",
            $Profile->{ID},
            $Profile->{InternalName},
            $Profile->{ValidID} == 1 ? 'valid' : 'invalid';
    }
    exit 0;
}

my $Profiles = eval { $QuickTicketObject->ProfileList( Valid => 0, UseCache => 0 ) };
if ( !$Profiles || ref $Profiles ne 'ARRAY' ) {
    print "AgentQuickTicket database tables are not ready.\n";
    exit 1;
}

print "AgentQuickTicket database tables are available. Profiles: " . scalar(@{$Profiles}) . "\n";
exit 0;

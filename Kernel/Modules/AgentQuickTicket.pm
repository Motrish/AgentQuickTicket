# --
# OTOBO AgentQuickTicket agent-side AJAX controller.
# --

package Kernel::Modules::AgentQuickTicket;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless $Self, $Type;
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $QuickTicketObject = $Kernel::OM->Get('Kernel::System::AgentQuickTicket');

    my $Subaction = $Self->{Subaction} || 'GetProfiles';
    my $CustomerUserID = $ParamObject->GetParam( Param => 'CustomerUserID' ) || '';
    my $CurrentQueueID = $ParamObject->GetParam( Param => 'CurrentQueueID' ) || '';
    my $CurrentDest    = $ParamObject->GetParam( Param => 'CurrentDest' ) || '';
    if ( !$CurrentQueueID && $CurrentDest =~ /\A(\d+)\|\|/ ) {
        $CurrentQueueID = $1;
    }
    my %CurrentFields = map {
        $_ => $ParamObject->GetParam( Param => $_ ) || ''
    } qw(ServiceID TypeID PriorityID NextStateID NewUserID NewResponsibleID);

    if ( $Subaction eq 'GetProfiles' ) {
        my $Profiles = $QuickTicketObject->AgentProfilesGet(
            UserID          => $Self->{UserID},
            CustomerUserID  => $CustomerUserID,
            CurrentQueueID  => $CurrentQueueID,
            CurrentServiceID => $CurrentFields{ServiceID},
        );

        return $LayoutObject->JSONReply(
            Data => {
                Success => 1,
                Profiles => $Profiles,
            },
        );
    }

    if ( $Subaction eq 'ResolveProfile' || $Subaction eq 'DryRun' ) {
        my $ProfileID = $ParamObject->GetParam( Param => 'ProfileID' ) || '';
        my $Result = eval {
            $QuickTicketObject->ResolveProfile(
                ProfileID       => $ProfileID,
                UserID           => $Self->{UserID},
                CustomerUserID   => $CustomerUserID,
                CurrentQueueID   => $CurrentQueueID,
                UserTimeZone     => $Self->{UserTimeZone},
                CurrentServiceID => $CurrentFields{ServiceID},
                CurrentTypeID    => $CurrentFields{TypeID},
                CurrentPriorityID => $CurrentFields{PriorityID},
                CurrentStateID   => $CurrentFields{NextStateID},
                CurrentOwnerID   => $CurrentFields{NewUserID},
                CurrentResponsibleID => $CurrentFields{NewResponsibleID},
            );
        };
        if ( !$Result || $@ ) {
            my $Exception = $@ || 'ResolveProfile returned no result.';
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "AgentQuickTicket ResolveProfile failed: $Exception",
            );
            return $LayoutObject->JSONReply(
                Data => {
                    Success => 0,
                    Error   => $LanguageObject->Translate(
                        'The quick ticket profile could not be applied. Please check the OTOBO log.'
                    ),
                },
            );
        }
        $Result->{DryRun} = 1 if $Subaction eq 'DryRun';
        return $LayoutObject->JSONReply( Data => $Result );
    }

    return $LayoutObject->JSONReply(
        Data => {
            Success => 0,
            Error   => $LanguageObject->Translate('Unknown AgentQuickTicket subaction.'),
        },
    );
}

1;

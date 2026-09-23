# --
# OTOBO AgentQuickTicket administration module.
# --

package Kernel::Modules::AdminAgentQuickTicket;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

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
    my $Subaction = $Self->{Subaction} || '';

    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenEntity',
        Value     => $Self->{RequestedURL},
    );

    if ( $Subaction eq 'Add' ) {
        my $Profile = {
            ID            => '',
            InternalName  => '',
            Label         => '',
            Description   => '',
            Icon          => 'fa-bolt',
            Color         => 'Primary',
            SortOrder     => 100,
            ValidID       => 1,
            AllowedGroupIDs => [],
            Configuration => $QuickTicketObject->ConfigurationDefaults(),
        };
        return $Self->_RenderEdit( Profile => $Profile, Action => 'Add' );
    }

    if ( $Subaction eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $Profile = $QuickTicketObject->ProfileGet( ID => $ID );
        return $LayoutObject->ErrorScreen(
            Message => $LanguageObject->Translate('Quick ticket profile not found.')
        ) if !$Profile;
        return $Self->_RenderEdit( Profile => $Profile, Action => 'Change' );
    }

    if ( $Subaction eq 'AddAction' || $Subaction eq 'ChangeAction' ) {
        $LayoutObject->ChallengeTokenCheck();
        my ( $Data, $Errors ) = $Self->_ReadForm();
        my $Action = $Subaction eq 'AddAction' ? 'Add' : 'Change';

        if ( !$Errors->{InternalName} && $QuickTicketObject->InternalNameExistsCheck(
            InternalName => $Data->{InternalName},
            ID           => $Data->{ID},
        ) ) {
            $Errors->{InternalName} = $LanguageObject->Translate('The internal name is already in use.');
        }
        if ( !$Errors->{InternalName} && $Data->{InternalName} !~ /\A[A-Za-z][A-Za-z0-9_.-]{0,190}\z/ ) {
            $Errors->{InternalName} = $LanguageObject->Translate(
                'Use letters, numbers, dot, dash and underscore; start with a letter.'
            );
        }
        $Errors->{Label} = $LanguageObject->Translate('A visible label is required.') if !$Data->{Label};
        $Errors->{Icon} = $LanguageObject->Translate('The icon must be a Font Awesome class such as fa-key.')
            if $Data->{Icon} !~ /\Afa-[A-Za-z0-9-]+\z/;
        $Errors->{Color} = $LanguageObject->Translate('Use a semantic color or a six-digit hexadecimal color.')
            if $Data->{Color} !~ /\A(?:Primary|Success|Warning|Danger|Info|Neutral|#[0-9A-Fa-f]{6})\z/;
        $Errors->{Groups} = $LanguageObject->Translate(
            'Select at least one group or explicitly allow all eligible agents.'
        )
            if !@{ $Data->{GroupIDs} } && !$Data->{Configuration}{AllowAllEligibleAgents};

        my @ConfigurationErrors = $QuickTicketObject->ValidateConfiguration(
            Configuration => $Data->{Configuration},
        );
        $Errors->{Configuration} = \@ConfigurationErrors if @ConfigurationErrors;

        if (!%{$Errors}) {
            my $Success;
            if ( $Action eq 'Add' ) {
                $Success = $QuickTicketObject->Create(
                    %{$Data},
                    UserID => $Self->{UserID},
                );
            }
            else {
                $Success = $QuickTicketObject->Update(
                    %{$Data},
                    UserID => $Self->{UserID},
                );
            }

            if ($Success) {
                return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
            }

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "AgentQuickTicket profile save failed: action=$Action internal_name=$Data->{InternalName}",
            );
            $Errors->{General} = $LanguageObject->Translate('The profile could not be saved.');
        }

        return $Self->_RenderEdit(
            Profile => {
                %{$Data},
                AllowedGroupIDs => $Data->{GroupIDs},
            },
            Action => $Action,
            Errors => $Errors,
        );
    }

    if ( $Subaction eq 'Copy' ) {
        $LayoutObject->ChallengeTokenCheck();
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $Profile = $QuickTicketObject->ProfileGet( ID => $ID );
        return $LayoutObject->ErrorScreen(
            Message => $LanguageObject->Translate('Quick ticket profile not found.')
        ) if !$Profile;
        my $InternalName = $Profile->{InternalName} . '_copy';
        my $Counter = 1;
        while ( $QuickTicketObject->InternalNameExistsCheck( InternalName => $InternalName ) ) {
            $Counter++;
            $InternalName = $Profile->{InternalName} . '_copy' . $Counter;
        }
        $QuickTicketObject->Create(
            InternalName  => $InternalName,
            Label         => $Profile->{Label} . ' (Kopie)',
            Description   => $Profile->{Description},
            Icon          => $Profile->{Icon},
            Color         => $Profile->{Color},
            SortOrder     => $Profile->{SortOrder} + 1,
            ValidID       => 1,
            Configuration => $Profile->{Configuration},
            GroupIDs      => $Profile->{AllowedGroupIDs},
            UserID        => $Self->{UserID},
        );
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    if ( $Subaction eq 'Delete' ) {
        $LayoutObject->ChallengeTokenCheck();
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        $QuickTicketObject->Delete( ID => $ID );
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    if ( $Subaction eq 'Toggle' ) {
        $LayoutObject->ChallengeTokenCheck();
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $Profile = $QuickTicketObject->ProfileGet( ID => $ID );
        if ($Profile) {
            $QuickTicketObject->SetValid(
                ID      => $ID,
                ValidID => $Profile->{ValidID} ? 2 : 1,
                UserID  => $Self->{UserID},
            );
        }
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    if ( $Subaction eq 'ToggleSeparator' ) {
        $LayoutObject->ChallengeTokenCheck();
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $Profile = $QuickTicketObject->ProfileGet( ID => $ID );
        if ($Profile) {
            $QuickTicketObject->SetSeparatorBefore(
                ID      => $ID,
                Enabled => !$Profile->{Configuration}{Presentation}{SeparatorBefore},
                UserID  => $Self->{UserID},
            );
        }
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    if ( $Subaction eq 'Test' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $Profile = $QuickTicketObject->ProfileGet( ID => $ID );
        return $LayoutObject->ErrorScreen(
            Message => $LanguageObject->Translate('Quick ticket profile not found.')
        ) if !$Profile;
        my $CustomerUserID = $ParamObject->GetParam( Param => 'TestCustomerUserID' ) || '';
        my $Result = $QuickTicketObject->ResolveProfile(
            ProfileID      => $ID,
            UserID         => $Self->{UserID},
            CustomerUserID => $CustomerUserID,
            CurrentQueueID => 0,
            UserTimeZone   => $Self->{UserTimeZone},
        );
        return $Self->_RenderEdit(
            Profile    => $Profile,
            Action     => 'Change',
            TestResult => $Result,
            TestCustomerUserID => $CustomerUserID,
        );
    }

    return $Self->_RenderOverview();
}

sub _RenderOverview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $QuickTicketObject = $Kernel::OM->Get('Kernel::System::AgentQuickTicket');
    my $Profiles = $QuickTicketObject->ProfileList( Valid => 0, UseCache => 0 );
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my @Rows;

    for my $Profile ( @{$Profiles} ) {
        my @Errors = $QuickTicketObject->ValidateConfiguration(
            Configuration => $Profile->{Configuration},
        );
        my $QueueID = $Profile->{Configuration}{Fields}{QueueID}{Value} || '';
        my $ServiceID = $Profile->{Configuration}{Fields}{ServiceID}{Value} || '';
        my $TypeID = $Profile->{Configuration}{Fields}{TypeID}{Value} || '';
        my $PriorityID = $Profile->{Configuration}{Fields}{PriorityID}{Value} || '';
        push @Rows, {
            %{$Profile},
            ValidName      => $ValidObject->ValidLookup( ValidID => $Profile->{ValidID} ),
            ValidationText => @Errors ? join( ' ', @Errors ) : '',
            IsValid        => @Errors ? 0 : 1,
            QueueID        => $QueueID,
            ServiceID      => $ServiceID,
            TypeID         => $TypeID,
            PriorityID     => $PriorityID,
            GroupCount     => scalar @{ $Profile->{AllowedGroupIDs} || [] },
            SeparatorBefore => $Profile->{Configuration}{Presentation}{SeparatorBefore} ? 1 : 0,
        };
    }

    my %Data = (
        Profiles => \@Rows,
    );
    my $Output = join '', $LayoutObject->Header(), $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminAgentQuickTicket',
        Data         => \%Data,
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _RenderEdit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Profile = $Param{Profile} || {};
    my $Configuration = $Profile->{Configuration}
        || $Kernel::OM->Get('Kernel::System::AgentQuickTicket')->ConfigurationDefaults();
    my $DynamicFieldDefinitions = $Self->_DynamicFieldDefinitions();
    my %Data = (
        %{$Profile},
        Action       => $Param{Action} || 'Add',
        Errors       => $Param{Errors} || {},
        Configuration => $Configuration,
        FieldRows    => $Self->_FieldRows( Configuration => $Configuration ),
        Queues       => $Self->_OptionRows( Type => 'Queue', Selected => $Configuration->{Fields}{QueueID}{Value} ),
        Types        => $Self->_OptionRows( Type => 'Type', Selected => $Configuration->{Fields}{TypeID}{Value} ),
        Services     => $Self->_OptionRows( Type => 'Service', Selected => $Configuration->{Fields}{ServiceID}{Value} ),
        SLAs         => $Self->_OptionRows( Type => 'SLA', Selected => $Configuration->{Fields}{SLAID}{Value} ),
        Priorities   => $Self->_OptionRows( Type => 'Priority', Selected => $Configuration->{Fields}{PriorityID}{Value} ),
        States       => $Self->_OptionRows( Type => 'State', Selected => $Configuration->{Fields}{NextStateID}{Value} ),
        Users        => $Self->_OptionRows( Type => 'User', Selected => '' ),
        Groups       => $Self->_GroupRows( Selected => $Profile->{AllowedGroupIDs} || [] ),
        DynamicFieldDefinitions => $DynamicFieldDefinitions,
        DynamicFieldRows => $Self->_DynamicFieldRows(
            Configuration => $Configuration,
            Definitions   => $DynamicFieldDefinitions,
        ),
        DynamicFieldsJSON => $Kernel::OM->Get('Kernel::Output::HTML::Layout')->JSONEncode(
            Data => $Configuration->{DynamicFields} || {},
        ),
        CustomerIDsText => join( "\n", @{ $Configuration->{CustomerScope}{CustomerIDs} || [] } ),
        TestResult => $Param{TestResult},
        TestCustomerUserID => $Param{TestCustomerUserID} || '',
        ConfirmBeforeApplyChecked => $Configuration->{ConfirmBeforeApply} ? 'checked' : '',
        WarnOnExistingChangesChecked => $Configuration->{WarnOnExistingChanges} ? 'checked' : '',
        AllowAllEligibleAgentsChecked => $Configuration->{AllowAllEligibleAgents} ? 'checked' : '',
        SeparatorBeforeChecked => $Configuration->{Presentation}{SeparatorBefore} ? 'checked' : '',
    );

    my $Output = join '', $LayoutObject->Header(), $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminAgentQuickTicketEdit',
        Data         => \%Data,
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _ReadForm {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my %Errors;
    my %Data;

    for my $Name (qw(ID InternalName Label Description Icon Color SortOrder ValidID)) {
        $Data{$Name} = $ParamObject->GetParam( Param => $Name ) // '';
    }
    $Data{SortOrder} = 100 if $Data{SortOrder} eq '';
    $Data{ValidID} = 1 if $Data{ValidID} eq '';

    my $Configuration = $Kernel::OM->Get('Kernel::System::AgentQuickTicket')->ConfigurationDefaults();
    for my $Field (qw(QueueID TypeID ServiceID SLAID PriorityID NextStateID NewUserID NewResponsibleID Subject Body TimeUnits)) {
        my $Mode  = $ParamObject->GetParam( Param => 'FieldMode_' . $Field ) || 'Keep';
        my $Value = $ParamObject->GetParam( Param => 'FieldValue_' . $Field );
        $Value = '' if !defined $Value;
        $Configuration->{Fields}{$Field} = {
            Mode  => $Mode,
            Value => $Value,
        };
    }

    my $DynamicFieldsJSON = $ParamObject->GetParam( Param => 'DynamicFieldsJSON' ) || '{}';
    my $DynamicFields = eval { $JSONObject->Decode( Data => $DynamicFieldsJSON ) };
    if ( ref $DynamicFields ne 'HASH' ) {
        $Errors{DynamicFields} = $LanguageObject->Translate('Dynamic field configuration is not valid JSON.');
        $DynamicFields = {};
    }
    $Configuration->{DynamicFields} = $DynamicFields;

    my $CustomerScopeMode = $ParamObject->GetParam( Param => 'CustomerScopeMode' ) || 'All';
    my $CustomerIDsText = $ParamObject->GetParam( Param => 'CustomerIDs' ) || '';
    my @CustomerIDs = grep { $_ ne '' } map { s/^\s+|\s+$//gr } split /[\r\n,;]+/, $CustomerIDsText;
    $Configuration->{CustomerScope} = {
        Mode        => $CustomerScopeMode,
        CustomerIDs => \@CustomerIDs,
    };
    $Configuration->{ConfirmBeforeApply} = $ParamObject->GetParam( Param => 'ConfirmBeforeApply' ) ? 1 : 0;
    $Configuration->{WarnOnExistingChanges} = $ParamObject->GetParam( Param => 'WarnOnExistingChanges' ) ? 1 : 0;
    $Configuration->{InvalidValueBehavior} = $ParamObject->GetParam( Param => 'InvalidValueBehavior' ) || 'Abort';
    $Configuration->{AllowAllEligibleAgents} = $ParamObject->GetParam( Param => 'AllowAllEligibleAgents' ) ? 1 : 0;
    $Configuration->{Presentation}{SeparatorBefore} = $ParamObject->GetParam( Param => 'SeparatorBefore' ) ? 1 : 0;
    $Data{Configuration} = $Configuration;

    my @GroupIDs = $ParamObject->GetArray( Param => 'AllowedGroupIDs' );
    if (!@GroupIDs) {
        my $GroupCSV = $ParamObject->GetParam( Param => 'AllowedGroupIDsCSV' ) || '';
        @GroupIDs = grep { /^\d+$/ } split /[\s,;]+/, $GroupCSV;
    }
    @GroupIDs = grep { /^\d+$/ } @GroupIDs;
    $Data{GroupIDs} = \@GroupIDs;

    return ( \%Data, \%Errors );
}

sub _FieldRows {
    my ( $Self, %Param ) = @_;
    my $Configuration = $Param{Configuration} || {};
    my @Fields = (
        [ QueueID          => 'Queue' ],
        [ TypeID           => 'Type' ],
        [ ServiceID        => 'Service' ],
        [ SLAID            => 'SLA' ],
        [ PriorityID       => 'Priority' ],
        [ NextStateID      => 'Status' ],
        [ NewUserID        => 'Owner' ],
        [ NewResponsibleID => 'Responsible' ],
        [ Subject          => 'Subject template' ],
        [ Body             => 'Article text template' ],
        [ TimeUnits        => 'Time units' ],
    );
    return [ map {
        my ( $Name, $Label ) = @{$_};
        {
            Name  => $Name,
            Label => $Label,
            Mode  => $Configuration->{Fields}{$Name}{Mode} || 'Keep',
            Value => $Configuration->{Fields}{$Name}{Value} // '',
        }
    } @Fields ];
}

sub _OptionRows {
    my ( $Self, %Param ) = @_;
    my $Type = $Param{Type} || '';
    my $Selected = $Param{Selected} // '';
    my %List;
    if ( $Type eq 'Queue' ) {
        %List = $Kernel::OM->Get('Kernel::System::Queue')->QueueList( Valid => 1 );
    }
    elsif ( $Type eq 'Type' ) {
        %List = $Kernel::OM->Get('Kernel::System::Type')->TypeList( Valid => 1 );
    }
    elsif ( $Type eq 'Service' ) {
        %List = $Kernel::OM->Get('Kernel::System::Service')->ServiceList( Valid => 1, UserID => 1 );
    }
    elsif ( $Type eq 'SLA' ) {
        %List = $Kernel::OM->Get('Kernel::System::SLA')->SLAList( Valid => 1, UserID => 1 );
    }
    elsif ( $Type eq 'Priority' ) {
        %List = $Kernel::OM->Get('Kernel::System::Priority')->PriorityList( Valid => 1, UserID => 1 );
    }
    elsif ( $Type eq 'State' ) {
        %List = $Kernel::OM->Get('Kernel::System::State')->StateList( Valid => 1, UserID => 1 );
    }
    elsif ( $Type eq 'User' ) {
        %List = $Kernel::OM->Get('Kernel::System::User')->UserList( Type => 'Long', Valid => 1 );
    }
    return [ map {
        {
            ID       => $_,
            Name     => $List{$_},
            Selected => ( defined $Selected && $Selected ne '' && $_ eq $Selected ) ? 1 : 0,
        }
    } sort { ( $List{$a} // '' ) cmp ( $List{$b} // '' ) } keys %List ];
}

sub _GroupRows {
    my ( $Self, %Param ) = @_;
    my %Groups = $Kernel::OM->Get('Kernel::System::AgentQuickTicket')->GroupList();
    my %Selected = map { $_ => 1 } @{ $Param{Selected} || [] };
    return [ map {
        {
            ID       => $_,
            Name     => $Groups{$_},
            Selected => $Selected{$_} ? 1 : 0,
        }
    } sort { ( $Groups{$a} // '' ) cmp ( $Groups{$b} // '' ) } keys %Groups ];
}

sub _DynamicFieldDefinitions {
    my ( $Self, %Param ) = @_;
    my $Fields = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => [ 'Ticket', 'Article' ],
    ) || [];
    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
    my $FrontendConfig = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::AgentTicketPhone') || {};
    my $EnabledFields = $FrontendConfig->{DynamicField} || {};
    my %SupportedType = map { $_ => 1 } qw(Text TextArea Checkbox Dropdown Multiselect Date DateTime);
    return [ map {
        my $FieldType = $_->{FieldType} || '';
        my $PossibleValues = {};
        if ( $FieldType eq 'Dropdown' || $FieldType eq 'Multiselect' ) {
            $PossibleValues = $BackendObject->PossibleValuesGet(
                DynamicFieldConfig => $_,
            ) || {};
            $PossibleValues = {} if ref $PossibleValues ne 'HASH';
        }
        {
            Name       => $_->{Name},
            Label      => $_->{Label} || $_->{Name},
            FieldType  => $FieldType,
            ObjectType => $_->{ObjectType} || 'Ticket',
            Enabled    => $EnabledFields->{ $_->{Name} } ? 1 : 0,
            Supported  => $SupportedType{$FieldType} ? 1 : 0,
            PossibleValuesJSON => $JSONObject->Encode( Data => $PossibleValues ),
        }
    } grep { IsHashRefWithData($_) } @{$Fields} ];
}

sub _DynamicFieldRows {
    my ( $Self, %Param ) = @_;
    my $DynamicFields = $Param{Configuration}{DynamicFields} || {};
    my %Definitions = map { $_->{Name} => $_ } @{ $Param{Definitions} || [] };
    return [ map {
        my $Value = $DynamicFields->{$_}{Value};
        $Value = join( ',', @{$Value} ) if ref $Value eq 'ARRAY';
        {
            Name       => $_,
            ObjectType => $DynamicFields->{$_}{ObjectType} || 'Ticket',
            Mode       => $DynamicFields->{$_}{Mode} || 'Keep',
            Value      => defined $Value ? $Value : '',
            FieldType  => $Definitions{$_}{FieldType} || '',
        }
    } sort keys %{$DynamicFields} ];
}

1;

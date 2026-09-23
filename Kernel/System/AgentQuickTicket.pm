# --
# OTOBO AgentQuickTicket - configurable quick ticket profiles.
# --
# Copyright (C) 2026 Michael Nehmer
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
# --

package Kernel::System::AgentQuickTicket;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Group',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::Service',
    'Kernel::System::SLA',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Type',
    'Kernel::System::User',
    'Kernel::System::Valid',
);

our $VERSION = '1.0.19';

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless $Self, $Type;

    $Self->{TableName} = 'agent_quick_ticket_profile';
    $Self->{GroupTableName} = 'agent_quick_ticket_profile_grp';
    $Self->{CacheType} = 'AgentQuickTicket';
    $Self->{CacheTTL}  = 60 * 60 * 24;

    return $Self;
}

sub _Translate {
    my ( $Self, $Text, @Arguments ) = @_;

    return $Kernel::OM->Get('Kernel::Language')->Translate( $Text, @Arguments );
}

sub ConfigurationDefaults {
    my ( $Self, %Param ) = @_;

    return {
        SchemaVersion        => 1,
        Fields               => {
            QueueID          => { Mode => 'Keep', Value => '' },
            TypeID           => { Mode => 'Keep', Value => '' },
            ServiceID        => { Mode => 'Keep', Value => '' },
            SLAID            => { Mode => 'Keep', Value => '' },
            PriorityID       => { Mode => 'Keep', Value => '' },
            NextStateID      => { Mode => 'Keep', Value => '' },
            NewUserID        => { Mode => 'Keep', Value => '' },
            NewResponsibleID => { Mode => 'Keep', Value => '' },
            Subject          => { Mode => 'Keep', Value => '' },
            Body             => { Mode => 'Keep', Value => '' },
            TimeUnits        => { Mode => 'Keep', Value => '' },
        },
        DynamicFields        => {},
        CustomerScope        => {
            Mode        => 'All',
            CustomerIDs => [],
        },
        Presentation         => {
            SeparatorBefore => 0,
        },
        AllowAllEligibleAgents => 1,
        ConfirmBeforeApply  => 1,
        WarnOnExistingChanges => 1,
        InvalidValueBehavior => 'Abort',
    };
}

sub ProfileList {
    my ( $Self, %Param ) = @_;

    my $Valid = exists $Param{Valid} ? $Param{Valid} : 1;
    my $UseCache = exists $Param{UseCache} ? $Param{UseCache} : 1;
    my $CacheKey = 'ProfileList::' . ( $Valid ? 'valid' : 'all' );

    if ($UseCache) {
        my $Cached = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => $Self->{CacheType},
            Key  => $CacheKey,
        );
        return $Cached if ref $Cached eq 'ARRAY';
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $SQL = 'SELECT id, internal_name, label, description, icon, color, '
        . 'sort_order, configuration, valid_id, create_time, create_by, '
        . 'change_time, change_by FROM ' . $Self->{TableName};
    my @Bind;
    if ($Valid) {
        $SQL .= ' WHERE valid_id = ?';
        push @Bind, \$Valid;
    }
    $SQL .= ' ORDER BY sort_order ASC, label ASC, id ASC';

    return [] if !$DBObject->Prepare( SQL => $SQL, Bind => \@Bind );

    # OTOBO's DB object uses one active result cursor. Read the complete
    # profile result set before querying group mappings; otherwise the nested
    # Prepare() in _ProfileGroupIDs() replaces the profile cursor and only the
    # first profile is returned.
    my @ProfileRows;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ProfileRows, [@Row];
    }

    my @Profiles;
    for my $Row (@ProfileRows) {
        my $Profile = $Self->_RowToProfile($Row);
        $Profile->{AllowedGroupIDs} = $Self->_ProfileGroupIDs( ID => $Profile->{ID} );
        push @Profiles, $Profile;
    }

    if ($UseCache) {
        $Kernel::OM->Get('Kernel::System::Cache')->Set(
            Type  => $Self->{CacheType},
            Key   => $CacheKey,
            TTL   => $Self->{CacheTTL},
            Value => \@Profiles,
        );
    }

    return \@Profiles;
}

sub ProfileGet {
    my ( $Self, %Param ) = @_;

    my $ID = $Param{ID} || 0;
    return if !$ID || $ID !~ /\A\d+\z/;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $SQL = 'SELECT id, internal_name, label, description, icon, color, '
        . 'sort_order, configuration, valid_id, create_time, create_by, '
        . 'change_time, change_by FROM ' . $Self->{TableName} . ' WHERE id = ?';
    return if !$DBObject->Prepare( SQL => $SQL, Bind => [ \$ID ], Limit => 1 );

    my $Profile;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Profile = $Self->_RowToProfile(\@Row);
    }
    return if !$Profile;

    $Profile->{AllowedGroupIDs} = $Self->_ProfileGroupIDs( ID => $ID );
    return $Profile;
}

sub Create {
    my ( $Self, %Param ) = @_;

    return if !$Self->EnsureDatabaseSchema();

    my $Configuration = $Self->ConfigurationNormalize(
        Configuration => $Param{Configuration},
    );
    my $JSON = $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => $Configuration );

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $InternalName = $Param{InternalName} // '';
    my $Label        = $Param{Label}        // '';
    my $Description  = $Param{Description}  // '';
    my $Icon         = $Param{Icon}         // 'fa-bolt';
    my $Color        = $Param{Color}        // 'Primary';
    my $SortOrder    = defined $Param{SortOrder} ? int( $Param{SortOrder} ) : 100;
    my $ValidID      = defined $Param{ValidID} ? int( $Param{ValidID} ) : 1;
    my $UserID       = $Param{UserID} || 1;

    return if !$DBObject->Do(
        SQL => 'INSERT INTO ' . $Self->{TableName}
            . ' (internal_name, label, description, icon, color, sort_order, '
            . 'configuration, valid_id, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$InternalName, \$Label, \$Description, \$Icon, \$Color,
            \$SortOrder, \$JSON, \$ValidID, \$UserID, \$UserID,
        ],
    );

    my $ID;
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM ' . $Self->{TableName} . ' WHERE internal_name = ?',
        Bind => [ \$InternalName ],
        Limit => 1,
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }
    return if !$ID;

    if ( !$Self->_SaveProfileGroups(
        ID       => $ID,
        GroupIDs => $Param{GroupIDs} || [],
    ) ) {
        # Do not leave a profile without its group mapping data when a save
        # fails after the profile row has already been inserted.
        $DBObject->Do(
            SQL  => 'DELETE FROM ' . $Self->{TableName} . ' WHERE id = ?',
            Bind => [ \$ID ],
        );
        return;
    }

    $Self->CacheClear();
    return $ID;
}

sub Update {
    my ( $Self, %Param ) = @_;

    return if !$Self->EnsureDatabaseSchema();

    my $ID = $Param{ID} || 0;
    return if !$ID || $ID !~ /\A\d+\z/;

    my $Configuration = $Self->ConfigurationNormalize(
        Configuration => $Param{Configuration},
    );
    my $JSON = $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => $Configuration );

    my $InternalName = $Param{InternalName} // '';
    my $Label        = $Param{Label}        // '';
    my $Description  = $Param{Description}  // '';
    my $Icon         = $Param{Icon}         // 'fa-bolt';
    my $Color        = $Param{Color}        // 'Primary';
    my $SortOrder    = defined $Param{SortOrder} ? int( $Param{SortOrder} ) : 100;
    my $ValidID      = defined $Param{ValidID} ? int( $Param{ValidID} ) : 1;
    my $UserID       = $Param{UserID} || 1;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Do(
        SQL => 'UPDATE ' . $Self->{TableName} . ' SET internal_name = ?, label = ?, '
            . 'description = ?, icon = ?, color = ?, sort_order = ?, configuration = ?, '
            . 'valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$InternalName, \$Label, \$Description, \$Icon, \$Color,
            \$SortOrder, \$JSON, \$ValidID, \$UserID, \$ID,
        ],
    );

    return if !$Self->_SaveProfileGroups(
        ID       => $ID,
        GroupIDs => $Param{GroupIDs} || [],
    );

    $Self->CacheClear();
    return 1;
}

sub Delete {
    my ( $Self, %Param ) = @_;

    my $ID = $Param{ID} || 0;
    return if !$ID || $ID !~ /\A\d+\z/;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ' . $Self->{GroupTableName} . ' WHERE profile_id = ?',
        Bind => [ \$ID ],
    );
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ' . $Self->{TableName} . ' WHERE id = ?',
        Bind => [ \$ID ],
    );

    $Self->CacheClear();
    return 1;
}

sub SetValid {
    my ( $Self, %Param ) = @_;

    my $ID      = $Param{ID} || 0;
    my $ValidID = defined $Param{ValidID} ? int( $Param{ValidID} ) : 1;
    my $UserID  = $Param{UserID} || 1;
    return if !$ID || $ID !~ /\A\d+\z/;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Do(
        SQL => 'UPDATE ' . $Self->{TableName}
            . ' SET valid_id = ?, change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [ \$ValidID, \$UserID, \$ID ],
    );
    $Self->CacheClear();
    return 1;
}

sub SetSeparatorBefore {
    my ( $Self, %Param ) = @_;

    my $ID = $Param{ID} || 0;
    return if !$ID || $ID !~ /\A\d+\z/;

    my $Profile = $Self->ProfileGet( ID => $ID );
    return if !$Profile;

    my $Configuration = $Profile->{Configuration} || $Self->ConfigurationDefaults();
    $Configuration->{Presentation} ||= {};
    $Configuration->{Presentation}{SeparatorBefore} = $Param{Enabled} ? 1 : 0;

    return $Self->Update(
        ID            => $Profile->{ID},
        InternalName  => $Profile->{InternalName},
        Label         => $Profile->{Label},
        Description   => $Profile->{Description},
        Icon          => $Profile->{Icon},
        Color         => $Profile->{Color},
        SortOrder     => $Profile->{SortOrder},
        ValidID       => $Profile->{ValidID},
        Configuration => $Configuration,
        GroupIDs      => $Profile->{AllowedGroupIDs} || [],
        UserID        => $Param{UserID} || 1,
    );
}

sub EnsureDatabaseSchema {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # DatabaseInstall is not re-applied by every OTOBO package upgrade. This
    # idempotent statement repairs installations where the package metadata
    # was upgraded but the profile-group table was not created.
    return if !$DBObject->Do(
        SQL => 'CREATE TABLE IF NOT EXISTS ' . $Self->{GroupTableName}
            . ' (profile_id INTEGER NOT NULL, group_id INTEGER NOT NULL, '
            . 'UNIQUE (profile_id, group_id))',
    );

    # A previously failed save could have inserted a group row after the
    # profile row was removed. Such rows can never be displayed or resolved.
    return if !$DBObject->Do(
        SQL => 'DELETE FROM ' . $Self->{GroupTableName}
            . ' WHERE profile_id NOT IN (SELECT id FROM ' . $Self->{TableName} . ')',
    );

    return 1;
}

sub CacheClear {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    $CacheObject->Delete( Type => $Self->{CacheType}, Key => 'ProfileList::valid' );
    $CacheObject->Delete( Type => $Self->{CacheType}, Key => 'ProfileList::all' );
    return 1;
}

sub GroupList {
    my ( $Self, %Param ) = @_;
    return $Kernel::OM->Get('Kernel::System::Group')->GroupList( Valid => 0 );
}

sub CustomerUserGet {
    my ( $Self, %Param ) = @_;
    my $Login = $Param{CustomerUserID} // '';
    return if $Login eq '';
    return $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $Login,
    );
}

sub AgentProfilesGet {
    my ( $Self, %Param ) = @_;

    my $UserID = $Param{UserID} || 0;
    my $CustomerUserID = $Param{CustomerUserID} // '';
    return [] if !$UserID || !$CustomerUserID;

    my %CustomerData = $Self->CustomerUserGet( CustomerUserID => $CustomerUserID );
    return [] if !%CustomerData;

    my $CurrentQueueID = $Param{CurrentQueueID} || 0;
    my $Profiles = $Self->ProfileList( Valid => 1 );
    my @Allowed;

    PROFILE:
    for my $Profile ( @{$Profiles} ) {
        next PROFILE if !$Self->ProfileAllowed(
            Profile         => $Profile,
            UserID          => $UserID,
            CustomerData    => \%CustomerData,
            CurrentQueueID  => $CurrentQueueID,
        );

        my @Errors = $Self->ValidateConfiguration(
            Configuration => $Profile->{Configuration},
            Runtime       => 1,
        );
        next PROFILE if @Errors;

        my %PublicProfile = %{$Profile};
        $PublicProfile{SeparatorBefore} = $Profile->{Configuration}{Presentation}{SeparatorBefore} ? 1 : 0;
        $PublicProfile{Configuration} = undef;
        $PublicProfile{ValidationErrors} = [];
        push @Allowed, \%PublicProfile;
    }

    return \@Allowed;
}

sub ProfileAllowed {
    my ( $Self, %Param ) = @_;

    my $Profile      = $Param{Profile} || {};
    my $UserID       = $Param{UserID} || 0;
    my $CustomerData = $Param{CustomerData} || {};
    my $CurrentQueueID = $Param{CurrentQueueID} || 0;
    return if !$UserID || !$Profile->{ID};

    my $Config = $Profile->{Configuration} || $Self->ConfigurationDefaults();
    my $Scope = $Config->{CustomerScope} || {};
    if ( ( $Scope->{Mode} || 'All' ) eq 'CustomerIDs' ) {
        my %Allowed = map { $_ => 1 } @{ $Scope->{CustomerIDs} || [] };
        my $CustomerID = $CustomerData->{UserCustomerID} // '';
        return if !$Allowed{ $CustomerData->{UserLogin} // '' }
            && !$Allowed{$CustomerID};
    }

    my @Groups = @{ $Profile->{AllowedGroupIDs} || [] };
    if (@Groups) {
        my %AgentGroups = $Self->_AgentGroupIDs( UserID => $UserID );
        my $GroupAllowed = grep { $AgentGroups{$_} } @Groups;
        return if !$GroupAllowed;
    }
    elsif ( !$Config->{AllowAllEligibleAgents} ) {
        return;
    }

    my $QueueID = $Self->_ConfiguredQueueID(
        Configuration => $Config,
        CurrentQueueID => $CurrentQueueID,
    );
    if ($QueueID) {
        return if !$Self->QueueCreateAllowed( UserID => $UserID, QueueID => $QueueID );
    }

    return 1;
}

sub QueueCreateAllowed {
    my ( $Self, %Param ) = @_;

    my $UserID  = $Param{UserID}  || 0;
    my $QueueID = $Param{QueueID} || 0;
    return if !$UserID || !$QueueID;

    my $GroupID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID(
        QueueID => $QueueID,
    );
    return if !$GroupID;

    my %Groups = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
        UserID => $UserID,
        Type   => 'create',
    );
    return $Groups{$GroupID} ? 1 : 0;
}

sub ResolveProfile {
    my ( $Self, %Param ) = @_;

    my $ProfileID      = $Param{ProfileID} || 0;
    my $UserID         = $Param{UserID} || 0;
    my $CustomerUserID = $Param{CustomerUserID} // '';
    return { Success => 0, Error => $Self->_Translate('Missing profile or customer user.') }
        if !$ProfileID || !$UserID || !$CustomerUserID;

    my $Profile = $Self->ProfileGet( ID => $ProfileID );
    return { Success => 0, Error => $Self->_Translate('The selected quick ticket profile does not exist.') }
        if !$Profile || !$Profile->{ValidID};

    my %CustomerData = $Self->CustomerUserGet( CustomerUserID => $CustomerUserID );
    return {
        Success => 0,
        Error   => $Self->_Translate( "Customer user '%s' was not found.", $CustomerUserID ),
    }
        if !%CustomerData;

    my $CurrentQueueID = $Param{CurrentQueueID} || 0;
    my $CurrentServiceID = $Param{CurrentServiceID} || 0;
    my $CurrentTypeID = $Param{CurrentTypeID} || 0;
    my $CurrentPriorityID = $Param{CurrentPriorityID} || 0;
    my $CurrentStateID = $Param{CurrentStateID} || 0;
    my $CurrentOwnerID = $Param{CurrentOwnerID} || 0;
    my $CurrentResponsibleID = $Param{CurrentResponsibleID} || 0;
    if ( !$Self->ProfileAllowed(
        Profile        => $Profile,
        UserID         => $UserID,
        CustomerData   => \%CustomerData,
        CurrentQueueID => $CurrentQueueID,
    ) ) {
        return { Success => 0, Error => $Self->_Translate('You are not allowed to use this quick ticket profile.') };
    }

    my @ConfigurationErrors = $Self->ValidateConfiguration(
        Configuration => $Profile->{Configuration},
        Runtime       => 1,
    );
    return {
        Success => 0,
        Error   => $Self->_Translate('Profile validation failed.'),
        Errors  => \@ConfigurationErrors,
    }
        if @ConfigurationErrors;

    my $Configuration = $Profile->{Configuration};
    my %AgentData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $UserID,
    );
    my $Context = $Self->_PlaceholderContext(
        CustomerData => \%CustomerData,
        AgentData    => \%AgentData,
        UserTimeZone => $Param{UserTimeZone},
    );

    my @Warnings;
    my $Prefill = {};
    my @ChangedFields;

    FIELD:
    for my $Field ( sort keys %{ $Configuration->{Fields} || {} } ) {
        my $Definition = $Configuration->{Fields}{$Field} || {};
        my $Mode = $Definition->{Mode} || 'Keep';
        next FIELD if $Mode eq 'Keep';

        my $Value = $Mode eq 'Clear' ? '' : $Definition->{Value};
        my ( $Resolved, $Unknown ) = $Self->_ResolveTemplateValue(
            Value   => $Value,
            Context => $Context,
        );
        if (@{$Unknown}) {
            push @Warnings, $Self->_Translate(
                'Unknown placeholder(s): %s',
                join( ', ', @{$Unknown} ),
            );
            next FIELD;
        }

        my $OutputField = $Field;
        if ( $Field eq 'QueueID' ) {
            if ($Mode eq 'Clear') {
                $Prefill->{Dest} = '';
                $Prefill->{QueueID} = '';
            }
            else {
                my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet( ID => $Resolved );
                if ( !%Queue ) {
                    push @Warnings, $Self->_Translate( "Queue '%s' does not exist.", $Resolved );
                    next FIELD;
                }
                $Prefill->{Dest} = $Resolved . '||' . $Queue{Name};
                $Prefill->{QueueID} = $Resolved;
            }
            $OutputField = 'Queue';
        }
        elsif ( $Field eq 'NextStateID' ) {
            $Prefill->{NextStateID} = $Resolved;
            $OutputField = 'Status';
        }
        else {
            $Prefill->{$Field} = $Resolved;
        }
        push @ChangedFields, $OutputField;
    }

    DYNAMICFIELD:
    for my $Name ( sort keys %{ $Configuration->{DynamicFields} || {} } ) {
        my $Definition = $Configuration->{DynamicFields}{$Name} || {};
        my $Mode = $Definition->{Mode} || 'Keep';
        next DYNAMICFIELD if $Mode eq 'Keep';
        my $Value = $Mode eq 'Clear' ? '' : $Definition->{Value};
        my ( $Resolved, $Unknown ) = $Self->_ResolveTemplateValue(
            Value   => $Value,
            Context => $Context,
        );
        if (@{$Unknown}) {
            push @Warnings, $Self->_Translate(
                'Unknown placeholder(s) in dynamic field %s: %s',
                $Name,
                join( ', ', @{$Unknown} ),
            );
            next DYNAMICFIELD;
        }
        my $FieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $Name,
        );
        my @RuntimeValueErrors = $Self->_ValidateResolvedDynamicValue(
            Name   => $Name,
            Config => $FieldConfig,
            Value  => $Resolved,
        );
        if (@RuntimeValueErrors) {
            push @Warnings, @RuntimeValueErrors;
            next DYNAMICFIELD;
        }
        $Prefill->{'DynamicField_' . $Name} = $Resolved;
        push @ChangedFields, 'Dynamic field ' . $Name;
    }

    my $ServiceID = $Prefill->{ServiceID} || $CurrentServiceID;
    if ( $ServiceID && !$Self->_ServiceAllowedForCustomer(
        ServiceID       => $ServiceID,
        CustomerUserID  => $CustomerUserID,
    ) ) {
        push @Warnings, $Self->_Translate(
            "Service '%s' is not assigned to customer user '%s'.",
            $ServiceID,
            $CustomerUserID,
        );
    }

    if ( $Prefill->{SLAID} && $ServiceID ) {
        my %SLAList = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
            ServiceID => $ServiceID,
            UserID    => 1,
        );
        push @Warnings, $Self->_Translate(
            "SLA '%s' is not assigned to service '%s'.",
            $Prefill->{SLAID},
            $ServiceID,
        )
            if !$SLAList{ $Prefill->{SLAID} };
    }

    my $ConfiguredQueueID = $Self->_ConfiguredQueueID(
        Configuration => $Configuration,
        CurrentQueueID => $CurrentQueueID,
    );
    if ($ConfiguredQueueID && !$Self->QueueCreateAllowed( UserID => $UserID, QueueID => $ConfiguredQueueID )) {
        push @Warnings, $Self->_Translate(
            "You do not have create permission for queue '%s'.",
            $ConfiguredQueueID,
        );
    }

    push @Warnings, $Self->_ValidateTicketACLs(
        Configuration  => $Configuration,
        Prefill        => $Prefill,
        CustomerUserID => $CustomerUserID,
        UserID         => $UserID,
        CurrentQueueID => $CurrentQueueID,
        CurrentServiceID => $CurrentServiceID,
        CurrentTypeID => $CurrentTypeID,
        CurrentPriorityID => $CurrentPriorityID,
        CurrentStateID => $CurrentStateID,
        CurrentOwnerID => $CurrentOwnerID,
        CurrentResponsibleID => $CurrentResponsibleID,
    );

    if (@Warnings && ( $Configuration->{InvalidValueBehavior} || 'Abort' ) eq 'Abort') {
        return {
            Success       => 0,
            Error         => $Self->_Translate('The profile could not be applied completely.'),
            Warnings      => \@Warnings,
            ChangedFields => \@ChangedFields,
        };
    }

    return {
        Success          => 1,
        Profile          => {
            ID                => $Profile->{ID},
            Label             => $Profile->{Label},
            ConfirmBeforeApply => $Configuration->{ConfirmBeforeApply} ? 1 : 0,
            WarnOnExistingChanges => $Configuration->{WarnOnExistingChanges} ? 1 : 0,
        },
        CustomerUserID => $CustomerUserID,
        Prefill       => $Prefill,
        Warnings      => \@Warnings,
        ChangedFields => \@ChangedFields,
    };
}

sub ValidateConfiguration {
    my ( $Self, %Param ) = @_;

    my $Configuration = $Self->ConfigurationNormalize(
        Configuration => $Param{Configuration},
    );
    my @Errors;
    my $Mode = $Param{Runtime} ? 'runtime' : 'save';

    my %AllowedModes = map { $_ => 1 } qw(Keep Set Clear);
    my %IDFields = map { $_ => 1 } qw(QueueID TypeID ServiceID SLAID PriorityID NextStateID NewUserID NewResponsibleID);
    my %FieldLabels = (
        QueueID          => 'Queue',
        TypeID           => 'Type',
        ServiceID        => 'Service',
        SLAID            => 'SLA',
        PriorityID       => 'Priority',
        NextStateID      => 'Status',
        NewUserID        => 'Owner',
        NewResponsibleID => 'Responsible',
        Subject          => 'Subject',
        Body             => 'Article text',
        TimeUnits        => 'Time units',
    );

    for my $Field ( keys %{ $Configuration->{Fields} || {} } ) {
        my $Definition = $Configuration->{Fields}{$Field} || {};
        my $FieldMode = $Definition->{Mode} || 'Keep';
        push @Errors, $Self->_Translate( "Unknown ticket field '%s'.", $Field )
            if !$FieldLabels{$Field};
        push @Errors, $Self->_Translate( "Invalid mode '%s' for field '%s'.", $FieldMode, $Field )
            if !$AllowedModes{$FieldMode};
        next if $FieldMode ne 'Set';

        if ( $IDFields{$Field} && defined $Definition->{Value} && $Definition->{Value} ne '' ) {
            push @Errors, $Self->_Translate(
                "Value for '%s' must be numeric.",
                $FieldLabels{$Field},
            )
                if $Definition->{Value} !~ /\A\d+\z/;
        }
        push @Errors, $Self->_ValidateObjectReference(
            Field => $Field,
            Value => $Definition->{Value},
        ) if $IDFields{$Field} && defined $Definition->{Value} && $Definition->{Value} ne '';
        push @Errors, $Self->_ValidatePlaceholders( Value => $Definition->{Value} );
    }

    my $InvalidValueBehavior = $Configuration->{InvalidValueBehavior} || 'Abort';
    push @Errors, $Self->_Translate(
        "Invalid invalid-value behavior '%s'.",
        $InvalidValueBehavior,
    )
        if $InvalidValueBehavior ne 'Abort' && $InvalidValueBehavior ne 'Warn';

    my $ScopeMode = $Configuration->{CustomerScope}{Mode} || 'All';
    push @Errors, $Self->_Translate( "Invalid customer scope '%s'.", $ScopeMode )
        if $ScopeMode ne 'All' && $ScopeMode ne 'CustomerIDs';
    if ( $ScopeMode eq 'CustomerIDs' ) {
        push @Errors, $Self->_Translate('Customer scope requires at least one customer login or customer ID.')
            if !@{ $Configuration->{CustomerScope}{CustomerIDs} || [] };
    }

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $AgentTicketPhoneConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketPhone') || {};
    my $AgentTicketPhoneDynamicFields = $AgentTicketPhoneConfig->{DynamicField} || {};
    my %SupportedType = map { $_ => 1 } qw(Text TextArea Checkbox Dropdown Multiselect Date DateTime);
    for my $Name ( sort keys %{ $Configuration->{DynamicFields} || {} } ) {
        my $Definition = $Configuration->{DynamicFields}{$Name} || {};
        my $FieldMode = $Definition->{Mode} || 'Keep';
        push @Errors, $Self->_Translate(
            "Invalid mode '%s' for dynamic field '%s'.",
            $FieldMode,
            $Name,
        )
            if !$AllowedModes{$FieldMode};
        my $FieldConfig = $DynamicFieldObject->DynamicFieldGet( Name => $Name );
        if ( !IsHashRefWithData($FieldConfig) ) {
            push @Errors, $Self->_Translate( "Dynamic field '%s' does not exist.", $Name );
            next;
        }
        if ( !$AgentTicketPhoneDynamicFields->{$Name} ) {
            push @Errors, $Self->_Translate(
                "Dynamic field '%s' is not enabled in AgentTicketPhone.",
                $Name,
            );
        }
        if ( !$SupportedType{ $FieldConfig->{FieldType} || '' } ) {
            push @Errors, $Self->_Translate(
                "Dynamic field '%s' has unsupported type '%s'.",
                $Name,
                $FieldConfig->{FieldType} || 'unknown',
            );
        }
        if ( $Definition->{ObjectType} && $Definition->{ObjectType} ne ($FieldConfig->{ObjectType} || '') ) {
            push @Errors, $Self->_Translate( "Dynamic field '%s' has an invalid object type.", $Name );
        }
        push @Errors, $Self->_ValidatePlaceholders( Value => $Definition->{Value} );
        next if $FieldMode ne 'Set';

        if ( $FieldConfig->{FieldType} eq 'Checkbox' && defined $Definition->{Value}
            && !ref $Definition->{Value}
            && $Definition->{Value} !~ /%[A-Za-z0-9_]+%/
            && $Definition->{Value} !~ /\A(?:0|1)\z/ )
        {
            push @Errors, $Self->_Translate( "Checkbox dynamic field '%s' requires 0 or 1.", $Name );
        }
        if ( $FieldConfig->{FieldType} eq 'Dropdown' || $FieldConfig->{FieldType} eq 'Multiselect' ) {
            my $Possible = $DynamicFieldBackendObject->PossibleValuesGet(
                DynamicFieldConfig => $FieldConfig,
            ) || {};
            $Possible = {} if ref $Possible ne 'HASH';
            if ( $FieldConfig->{FieldType} eq 'Dropdown' ) {
                push @Errors, $Self->_Translate(
                    "Value for dynamic field '%s' is not a valid dropdown value.",
                    $Name,
                )
                    if defined $Definition->{Value} && $Definition->{Value} ne ''
                    && !ref $Definition->{Value}
                    && $Definition->{Value} !~ /%[A-Za-z0-9_]+%/
                    && !exists $Possible->{ $Definition->{Value} };
            }
            else {
                my @Values = ref $Definition->{Value} eq 'ARRAY'
                    ? @{ $Definition->{Value} }
                    : split /\s*,\s*/, ( $Definition->{Value} // '' );
                for my $Value (@Values) {
                    next if !defined $Value || $Value eq '' || $Value =~ /%[A-Za-z0-9_]+%/;
                    push @Errors, $Self->_Translate(
                        "Value '%s' for dynamic field '%s' is not a valid multiselect value.",
                        $Value,
                        $Name,
                    )
                        if !exists $Possible->{$Value};
                }
            }
        }
        if ( $FieldConfig->{FieldType} eq 'Date' && defined $Definition->{Value}
            && !ref $Definition->{Value}
            && $Definition->{Value} ne ''
            && $Definition->{Value} !~ /%[A-Za-z0-9_]+%/
            && $Definition->{Value} !~ /\A\d{4}-\d{2}-\d{2}(?:\s\d{2}:\d{2}:\d{2})?\z/ )
        {
            push @Errors, $Self->_Translate( "Date dynamic field '%s' requires YYYY-MM-DD.", $Name );
        }
        if ( $FieldConfig->{FieldType} eq 'DateTime' && defined $Definition->{Value}
            && !ref $Definition->{Value}
            && $Definition->{Value} ne ''
            && $Definition->{Value} !~ /%[A-Za-z0-9_]+%/
            && $Definition->{Value} !~ /\A\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}(?::\d{2})?\z/ )
        {
            push @Errors, $Self->_Translate(
                "DateTime dynamic field '%s' requires YYYY-MM-DD HH:MM[:SS].",
                $Name,
            );
        }
    }

    my $ServiceField = $Configuration->{Fields}{ServiceID} || {};
    my $SLAField = $Configuration->{Fields}{SLAID} || {};
    if ( ( $ServiceField->{Mode} || 'Keep' ) eq 'Set'
        && ( $SLAField->{Mode} || 'Keep' ) eq 'Set'
        && $ServiceField->{Value} && $SLAField->{Value}
        && $ServiceField->{Value} =~ /\A\d+\z/
        && $SLAField->{Value} =~ /\A\d+\z/ )
    {
        my %SLAs = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
            ServiceID => $ServiceField->{Value},
            UserID    => 1,
        );
        push @Errors, $Self->_Translate(
            "SLA '%s' is not assigned to service '%s'.",
            $SLAField->{Value},
            $ServiceField->{Value},
        )
            if !$SLAs{ $SLAField->{Value} };
    }

    return @Errors;
}

sub ConfigurationNormalize {
    my ( $Self, %Param ) = @_;

    my $Defaults = $Self->ConfigurationDefaults();
    my $Configuration = $Param{Configuration};
    if ( !defined $Configuration ) {
        $Configuration = {};
    }
    elsif ( !ref $Configuration ) {
        my $Decoded = eval {
            $Kernel::OM->Get('Kernel::System::JSON')->Decode( Data => $Configuration )
        };
        $Configuration = ref $Decoded eq 'HASH' ? $Decoded : {};
    }
    $Configuration = { %{$Defaults}, %{$Configuration} } if ref $Configuration eq 'HASH';
    $Configuration = $Defaults if ref $Configuration ne 'HASH';

    $Configuration->{Fields} = {
        %{ $Defaults->{Fields} },
        %{ ref $Configuration->{Fields} eq 'HASH' ? $Configuration->{Fields} : {} },
    };
    $Configuration->{DynamicFields} = {}
        if ref $Configuration->{DynamicFields} ne 'HASH';
    $Configuration->{CustomerScope} = {
        %{ $Defaults->{CustomerScope} },
        %{ ref $Configuration->{CustomerScope} eq 'HASH' ? $Configuration->{CustomerScope} : {} },
    };
    $Configuration->{CustomerScope}{CustomerIDs} = []
        if ref $Configuration->{CustomerScope}{CustomerIDs} ne 'ARRAY';
    $Configuration->{Presentation} = {
        %{ $Defaults->{Presentation} },
        %{ ref $Configuration->{Presentation} eq 'HASH' ? $Configuration->{Presentation} : {} },
    };
    $Configuration->{Presentation}{SeparatorBefore} = $Configuration->{Presentation}{SeparatorBefore} ? 1 : 0;
    $Configuration->{ConfirmBeforeApply} = $Configuration->{ConfirmBeforeApply} ? 1 : 0;
    $Configuration->{WarnOnExistingChanges} = $Configuration->{WarnOnExistingChanges} ? 1 : 0;
    $Configuration->{AllowAllEligibleAgents} = $Configuration->{AllowAllEligibleAgents} ? 1 : 0;
    $Configuration->{SchemaVersion} ||= 1;

    return $Configuration;
}

sub SeedDemoProfile {
    my ( $Self, %Param ) = @_;

    my $Existing = $Self->ProfileGetByInternalName( InternalName => 'PasswordReset' );
    return $Existing->{ID} if $Existing;

    my $Configuration = $Self->ConfigurationDefaults();
    $Configuration->{Fields}{TypeID} = {
        Mode  => 'Set',
        Value => '5',
    };
    $Configuration->{Fields}{ServiceID} = {
        Mode  => 'Set',
        Value => '61',
    };
    $Configuration->{Fields}{PriorityID} = {
        Mode  => 'Set',
        Value => '1',
    };
    $Configuration->{Fields}{Subject} = {
        Mode  => 'Set',
        Value => 'Passwort reset %CustomerUserID%',
    };

    return $Self->Create(
        InternalName => 'PasswordReset',
        Label        => 'Passwort zurücksetzen',
        Description  => 'Demo-Profil für die schnelle Aufnahme eines Passwort-Reset-Tickets.',
        Icon         => 'fa-key',
        Color        => 'Warning',
        SortOrder    => 10,
        ValidID      => 1,
        Configuration => $Configuration,
        GroupIDs      => [],
        UserID       => $Param{UserID} || 1,
    );
}

sub ProfileGetByInternalName {
    my ( $Self, %Param ) = @_;
    my $InternalName = $Param{InternalName} // '';
    return if $InternalName eq '';

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL  => 'SELECT id, internal_name, label, description, icon, color, sort_order, '
            . 'configuration, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM ' . $Self->{TableName} . ' WHERE internal_name = ?',
        Bind => [ \$InternalName ],
        Limit => 1,
    );
    my $Profile;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Profile = $Self->_RowToProfile(\@Row);
    }
    if ($Profile) {
        $Profile->{AllowedGroupIDs} = $Self->_ProfileGroupIDs( ID => $Profile->{ID} );
    }
    return $Profile;
}

sub InternalNameExistsCheck {
    my ( $Self, %Param ) = @_;
    my $InternalName = $Param{InternalName} // '';
    my $ID = $Param{ID} || 0;
    return if $InternalName eq '';

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my $SQL = 'SELECT id FROM ' . $Self->{TableName} . ' WHERE internal_name = ?';
    my @Bind = ( \$InternalName );
    if ($ID) {
        $SQL .= ' AND id <> ?';
        push @Bind, \$ID;
    }
    return if !$DBObject->Prepare( SQL => $SQL, Bind => \@Bind, Limit => 1 );
    my $Found;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Found = $Row[0];
    }
    return $Found ? 1 : 0;
}

sub _RowToProfile {
    my ( $Self, $Row ) = @_;
    my $Configuration = $Self->ConfigurationNormalize(
        Configuration => $Row->[7],
    );
    return {
        ID            => $Row->[0],
        InternalName  => $Row->[1],
        Label         => $Row->[2],
        Description   => $Row->[3] || '',
        Icon          => $Row->[4] || 'fa-bolt',
        Color         => $Row->[5] || 'Primary',
        SortOrder     => $Row->[6] || 0,
        Configuration => $Configuration,
        ValidID       => $Row->[8],
        CreateTime    => $Row->[9],
        CreateBy      => $Row->[10],
        ChangeTime    => $Row->[11],
        ChangeBy      => $Row->[12],
    };
}

sub _ProfileGroupIDs {
    my ( $Self, %Param ) = @_;
    my $ID = $Param{ID} || 0;
    return [] if !$ID;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return [] if !$DBObject->Prepare(
        SQL  => 'SELECT group_id FROM ' . $Self->{GroupTableName} . ' WHERE profile_id = ? ORDER BY group_id',
        Bind => [ \$ID ],
    );
    my @GroupIDs;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @GroupIDs, $Row[0];
    }
    return \@GroupIDs;
}

sub _SaveProfileGroups {
    my ( $Self, %Param ) = @_;
    my $ID = $Param{ID} || 0;
    my $GroupIDs = $Param{GroupIDs} || [];
    return if !$ID || ref $GroupIDs ne 'ARRAY';

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM ' . $Self->{GroupTableName} . ' WHERE profile_id = ?',
        Bind => [ \$ID ],
    );
    for my $GroupID ( @{$GroupIDs} ) {
        next if !defined $GroupID || $GroupID !~ /\A\d+\z/;
        return if !$DBObject->Do(
            SQL => 'INSERT INTO ' . $Self->{GroupTableName} . ' (profile_id, group_id) VALUES (?, ?)',
            Bind => [ \$ID, \$GroupID ],
        );
    }
    return 1;
}

sub _AgentGroupIDs {
    my ( $Self, %Param ) = @_;
    my $UserID = $Param{UserID} || 0;
    my %Groups;
    for my $Type (qw(ro rw create note owner priority move_into)) {
        my %Current = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $UserID,
            Type   => $Type,
        );
        @Groups{ keys %Current } = values %Current;
    }
    return %Groups;
}

sub _ConfiguredQueueID {
    my ( $Self, %Param ) = @_;
    my $Configuration = $Param{Configuration} || {};
    my $CurrentQueueID = $Param{CurrentQueueID} || 0;
    my $Field = $Configuration->{Fields}{QueueID} || {};
    return $Field->{Value} if ( $Field->{Mode} || 'Keep' ) eq 'Set' && $Field->{Value};
    return $CurrentQueueID if ( $Field->{Mode} || 'Keep' ) eq 'Keep';
    return;
}

sub _ValidateObjectReference {
    my ( $Self, %Param ) = @_;
    my $Field = $Param{Field} // '';
    my $Value = $Param{Value} // '';
    return if $Value eq '';
    my $Exists = 1;

    if ( $Field eq 'QueueID' ) {
        my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet( ID => $Value );
        $Exists = %Queue ? 1 : 0;
    }
    elsif ( $Field eq 'TypeID' ) {
        my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeGet( ID => $Value );
        $Exists = %Type ? 1 : 0;
    }
    elsif ( $Field eq 'ServiceID' ) {
        my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
            ServiceID => $Value,
            UserID    => 1,
        );
        $Exists = %Service ? 1 : 0;
    }
    elsif ( $Field eq 'SLAID' ) {
        my %SLA = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
            SLAID  => $Value,
            UserID => 1,
        );
        $Exists = %SLA ? 1 : 0;
    }
    elsif ( $Field eq 'PriorityID' ) {
        my %Priority = $Kernel::OM->Get('Kernel::System::Priority')->PriorityGet(
            PriorityID => $Value,
            UserID     => 1,
        );
        $Exists = %Priority ? 1 : 0;
    }
    elsif ( $Field eq 'NextStateID' ) {
        my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet( ID => $Value );
        $Exists = %State ? 1 : 0;
    }
    elsif ( $Field eq 'NewUserID' || $Field eq 'NewResponsibleID' ) {
        my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData( UserID => $Value );
        $Exists = %User ? 1 : 0;
    }

    return if $Exists;
    return $Self->_Translate(
        "Referenced OTOBO object for '%s' with ID '%s' does not exist.",
        $Field,
        $Value,
    );
}

sub _ValidatePlaceholders {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    if ( ref $Value eq 'ARRAY' ) {
        my @Errors;
        for my $Item ( @{$Value} ) {
            push @Errors, $Self->_ValidatePlaceholders( Value => $Item );
        }
        return @Errors;
    }
    if ( ref $Value eq 'HASH' ) {
        my @Errors;
        for my $Item ( values %{$Value} ) {
            push @Errors, $Self->_ValidatePlaceholders( Value => $Item );
        }
        return @Errors;
    }
    return if ref $Value || !defined $Value;
    my %Allowed = map { $_ => 1 } qw(
        CustomerUserID CustomerID CustomerFirstname CustomerLastname CustomerFullname CustomerEmail
        AgentLogin AgentFirstname AgentLastname CurrentDate CurrentDateTime
    );
    my @Errors;
    while ( $Value =~ /%([A-Za-z0-9_]+)%/g ) {
        push @Errors, $Self->_Translate( "Unknown placeholder '%s'.", '%' . $1 . '%' )
            if !$Allowed{$1};
    }
    return @Errors;
}

sub _PlaceholderContext {
    my ( $Self, %Param ) = @_;
    my $Customer = $Param{CustomerData} || {};
    my $Agent    = $Param{AgentData} || {};
    my $TimeZone = $Param{UserTimeZone};
    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => { TimeZone => $TimeZone },
    );

    return {
        CustomerUserID    => $Customer->{UserLogin} || $Customer->{Login} || '',
        CustomerID        => $Customer->{UserCustomerID} || '',
        CustomerFirstname => $Customer->{UserFirstname} || '',
        CustomerLastname  => $Customer->{UserLastname} || '',
        CustomerFullname  => $Customer->{UserFullname}
            || join( ' ', grep { $_ } ( $Customer->{UserFirstname}, $Customer->{UserLastname} ) ),
        CustomerEmail     => $Customer->{UserEmail} || '',
        AgentLogin        => $Agent->{UserLogin} || '',
        AgentFirstname    => $Agent->{UserFirstname} || '',
        AgentLastname     => $Agent->{UserLastname} || '',
        CurrentDate       => $DateTimeObject->Format( Format => '%Y-%m-%d' ),
        CurrentDateTime   => $DateTimeObject->Format( Format => '%Y-%m-%d %H:%M:%S' ),
    };
}

sub _ResolveTemplateValue {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    my $Context = $Param{Context} || {};
    if ( ref $Value eq 'ARRAY' ) {
        my @Resolved;
        my @Unknown;
        for my $Item ( @{$Value} ) {
            my ( $Resolved, $Unknown ) = $Self->_ResolveTemplateValue(
                Value   => $Item,
                Context => $Context,
            );
            push @Resolved, $Resolved;
            push @Unknown, @{$Unknown};
        }
        my %Unknown = map { $_ => 1 } @Unknown;
        return ( \@Resolved, [ sort keys %Unknown ] );
    }
    return ( $Value, [] ) if ref $Value;
    $Value = '' if !defined $Value;
    my %Unknown;
    $Value =~ s{%([A-Za-z0-9_]+)%}{
        if ( exists $Context->{$1} ) {
            defined $Context->{$1} ? $Context->{$1} : '';
        }
        else {
            $Unknown{$1} = 1;
            '%' . $1 . '%';
        }
    }gex;
    return ( $Value, [ sort keys %Unknown ] );
}

sub _ServiceAllowedForCustomer {
    my ( $Self, %Param ) = @_;
    my $ServiceID = $Param{ServiceID} || 0;
    my $Login = $Param{CustomerUserID} // '';
    return 1 if !$ServiceID || !$Login;

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
    my %CustomerServices = $ServiceObject->CustomerUserServiceMemberList(
        Result            => 'HASH',
        CustomerUserLogin => $Login,
        UserID            => 1,
    );
    return 1 if $CustomerServices{$ServiceID};

    my %DefaultServices = $ServiceObject->CustomerUserServiceMemberList(
        Result            => 'HASH',
        CustomerUserLogin => '<DEFAULT>',
        UserID            => 1,
    );
    return $DefaultServices{$ServiceID} ? 1 : 0;
}

sub _ValidateResolvedDynamicValue {
    my ( $Self, %Param ) = @_;
    my $Name = $Param{Name} // '';
    my $Config = $Param{Config} || {};
    my $Value = $Param{Value};
    return if !IsHashRefWithData($Config) || !defined $Value;

    my $FieldType = $Config->{FieldType} || '';
    my @Errors;
    if ( $FieldType eq 'Checkbox' && !ref $Value && $Value ne '' && $Value !~ /\A(?:0|1)\z/ ) {
        push @Errors, $Self->_Translate(
            "Checkbox dynamic field '%s' requires 0 or 1 after placeholder resolution.",
            $Name,
        );
    }
    if ( $FieldType eq 'Dropdown' || $FieldType eq 'Multiselect' ) {
        my $Possible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->PossibleValuesGet(
            DynamicFieldConfig => $Config,
        ) || {};
        if ( ref $Possible eq 'HASH' ) {
            my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ( $FieldType eq 'Multiselect'
                ? split(/\s*,\s*/, ( $Value // '' ))
                : ( $Value // '' ) );
            for my $Item (@Values) {
                next if !defined $Item || $Item eq '';
                push @Errors, $Self->_Translate(
                    "Value '%s' for dynamic field '%s' is not valid after placeholder resolution.",
                    $Item,
                    $Name,
                )
                    if !exists $Possible->{$Item};
            }
        }
    }
    if ( $FieldType eq 'Date' && !ref $Value && $Value ne ''
        && $Value !~ /\A\d{4}-\d{2}-\d{2}(?:\s\d{2}:\d{2}:\d{2})?\z/ )
    {
        push @Errors, $Self->_Translate(
            "Date dynamic field '%s' requires YYYY-MM-DD after placeholder resolution.",
            $Name,
        );
    }
    if ( $FieldType eq 'DateTime' && !ref $Value && $Value ne ''
        && $Value !~ /\A\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}(?::\d{2})?\z/ )
    {
        push @Errors, $Self->_Translate(
            "DateTime dynamic field '%s' requires YYYY-MM-DD HH:MM[:SS] after placeholder resolution.",
            $Name,
        );
    }
    return @Errors;
}

sub _ValidateTicketACLs {
    my ( $Self, %Param ) = @_;

    my $Configuration  = $Param{Configuration} || {};
    my $Prefill        = $Param{Prefill} || {};
    my $CustomerUserID = $Param{CustomerUserID} // '';
    my $UserID         = $Param{UserID} || 0;
    my $CurrentQueueID = $Param{CurrentQueueID} || 0;
    my $CurrentServiceID = $Param{CurrentServiceID} || 0;
    my $CurrentTypeID = $Param{CurrentTypeID} || 0;
    my $CurrentPriorityID = $Param{CurrentPriorityID} || 0;
    my $CurrentStateID = $Param{CurrentStateID} || 0;
    my $CurrentOwnerID = $Param{CurrentOwnerID} || 0;
    my $CurrentResponsibleID = $Param{CurrentResponsibleID} || 0;
    return if !$UserID;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $EffectiveQueueID = $Prefill->{QueueID} || $CurrentQueueID || 1;
    my %Context = (
        Action         => 'AgentTicketPhone',
        CustomerUserID => $CustomerUserID,
        QueueID        => $EffectiveQueueID,
        UserID         => $UserID,
        ServiceID      => $CurrentServiceID,
        TypeID         => $CurrentTypeID,
        PriorityID     => $CurrentPriorityID,
        NextStateID    => $CurrentStateID,
        OwnerID        => $CurrentOwnerID,
        NewOwnerID     => $CurrentOwnerID,
        ResponsibleID  => $CurrentResponsibleID,
        NewResponsibleID => $CurrentResponsibleID,
    );

    for my $Field (qw(TypeID ServiceID SLAID PriorityID NextStateID NewUserID NewResponsibleID)) {
        $Context{$Field} = $Prefill->{$Field} if exists $Prefill->{$Field};
    }
    if ( exists $Prefill->{NewUserID} ) {
        $Context{OwnerID} = $Prefill->{NewUserID};
        $Context{NewOwnerID} = $Prefill->{NewUserID};
    }
    if ( exists $Prefill->{NewResponsibleID} ) {
        $Context{ResponsibleID} = $Prefill->{NewResponsibleID};
        $Context{NewResponsibleID} = $Prefill->{NewResponsibleID};
    }
    $Context{DynamicField} = {
        map { $_ => $Prefill->{$_} }
        grep { /^DynamicField_/ && exists $Prefill->{$_} }
        keys %{$Prefill}
    };

    my @Warnings;
    my $CheckListValue = sub {
        my ( $Label, $SubType, $List, $Value ) = @_;
        return if !defined $Value || $Value eq '';
        if ( !ref $List || !exists $List->{$Value} ) {
            push @Warnings, $Self->_Translate(
                "%s '%s' is not allowed by the current AgentTicketPhone ACL context.",
                $Self->_Translate($Label),
                $Value,
            );
        }
        return;
    };

    if ( $Prefill->{QueueID} ) {
        my %Queues = $TicketObject->TicketMoveList(
            Type           => 'create',
            UserID         => $UserID,
            CustomerUserID => $CustomerUserID,
            Action         => 'AgentTicketPhone',
        );
        $CheckListValue->( 'Queue', 'Queue', \%Queues, $Prefill->{QueueID} );
    }

    if ( $Prefill->{TypeID} ) {
        my %Types = $TicketObject->TicketTypeList(%Context);
        $CheckListValue->( 'Type', 'Type', \%Types, $Prefill->{TypeID} );
    }

    if ( $Prefill->{ServiceID} ) {
        my %Services = $TicketObject->TicketServiceList(%Context);
        $CheckListValue->( 'Service', 'Service', \%Services, $Prefill->{ServiceID} );
    }

    if ( $Prefill->{SLAID} && $Prefill->{ServiceID} ) {
        my %SLAs = $TicketObject->TicketSLAList(%Context);
        $CheckListValue->( 'SLA', 'SLA', \%SLAs, $Prefill->{SLAID} );
    }

    if ( $Prefill->{PriorityID} ) {
        my %Priorities = $TicketObject->TicketPriorityList(%Context);
        $CheckListValue->( 'Priority', 'Priority', \%Priorities, $Prefill->{PriorityID} );
    }

    if ( $Prefill->{NextStateID} ) {
        my %States = $TicketObject->TicketStateList(%Context);
        $CheckListValue->( 'Status', 'Status', \%States, $Prefill->{NextStateID} );
    }

    my %Users;
    if ( $Prefill->{NewUserID} || $Prefill->{NewResponsibleID} ) {
        %Users = $Kernel::OM->Get('Kernel::System::User')->UserList(
            Type  => 'Long',
            Valid => 1,
        );
    }
    if ( $Prefill->{NewUserID} ) {
        my %Allowed = %Users;
        my $ACL = $TicketObject->TicketAcl(
            %Context,
            ReturnType    => 'Ticket',
            ReturnSubType => 'Owner',
            Data          => \%Allowed,
            UserID        => $UserID,
        );
        %Allowed = $TicketObject->TicketAclData() if $ACL;
        $CheckListValue->( 'Owner', 'Owner', \%Allowed, $Prefill->{NewUserID} );
    }
    if ( $Prefill->{NewResponsibleID} ) {
        my %Allowed = %Users;
        my $ACL = $TicketObject->TicketAcl(
            %Context,
            ReturnType    => 'Ticket',
            ReturnSubType => 'Responsible',
            Data          => \%Allowed,
            UserID        => $UserID,
        );
        %Allowed = $TicketObject->TicketAclData() if $ACL;
        $CheckListValue->( 'Responsible', 'Responsible', \%Allowed, $Prefill->{NewResponsibleID} );
    }

    for my $Name ( sort keys %{ $Configuration->{DynamicFields} || {} } ) {
        my $Definition = $Configuration->{DynamicFields}{$Name} || {};
        next if ( $Definition->{Mode} || 'Keep' ) ne 'Set';
        my $FieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $Name,
        );
        next if !IsHashRefWithData($FieldConfig);

        my %Visibility = ( $Name => $Name );
        my $VisibilityACL = $TicketObject->TicketAcl(
            %Context,
            ReturnType    => 'Form',
            ReturnSubType => '-',
            Data          => \%Visibility,
            UserID        => $UserID,
        );
        if ($VisibilityACL) {
            my %AllowedVisibility = $TicketObject->TicketAclData();
            push @Warnings, $Self->_Translate(
                "Dynamic field '%s' is hidden by the current AgentTicketPhone ACL context.",
                $Name,
            )
                if !$AllowedVisibility{$Name};
        }

        next if !defined $Definition->{Value} || $Definition->{Value} eq '';
        my $Possible = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->PossibleValuesGet(
            DynamicFieldConfig => $FieldConfig,
        ) || {};
        next if ref $Possible ne 'HASH' || !%{$Possible};
        next if ( $FieldConfig->{FieldType} || '' ) ne 'Dropdown'
            && ( $FieldConfig->{FieldType} || '' ) ne 'Multiselect';

        my %PossibleForACL = map { $_ => $_ } keys %{$Possible};
        my $ValueACL = $TicketObject->TicketAcl(
            %Context,
            ReturnType    => 'Ticket',
            ReturnSubType => 'DynamicField_' . $Name,
            Data          => \%PossibleForACL,
            UserID        => $UserID,
        );
        if ($ValueACL) {
            my %AllowedValues = $TicketObject->TicketAclData();
            my $RuntimeValue = exists $Prefill->{'DynamicField_' . $Name}
                ? $Prefill->{'DynamicField_' . $Name}
                : $Definition->{Value};
            my @Values = ref $RuntimeValue eq 'ARRAY'
                ? @{$RuntimeValue}
                : ( $RuntimeValue );
            for my $Value (@Values) {
                push @Warnings, $Self->_Translate(
                    "Value '%s' for dynamic field '%s' is blocked by the current AgentTicketPhone ACL context.",
                    $Value,
                    $Name,
                )
                    if $Value ne '' && !$AllowedValues{$Value};
            }
        }
    }

    return @Warnings;
}

1;

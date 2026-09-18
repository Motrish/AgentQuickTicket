# --
# OTOBO AgentQuickTicket output filter.
# --

package Kernel::Output::HTML::FilterElementPost::AgentQuickTicket;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless $Self, $Type;
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if !$Param{Data} || ref $Param{Data} ne 'SCALAR';
    return 1 if ( $Param{TemplateFile} || '' ) ne 'AgentTicketPhone';

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Widget = $LayoutObject->Output(
        TemplateFile => 'AgentQuickTicketWidget',
        Data         => {},
    );
    return 1 if !$Widget;

    # The widget is rendered hidden and moved directly after #CustomerInfo by
    # JavaScript. This keeps it outside #CustomerInfo .Content, which OTOBO
    # replaces during a customer-user AJAX refresh.
    my $Search = '(<div class="ContentColumn">)';
    ${ $Param{Data} } =~ s{$Search}{$Widget$1}ms;

    return 1;
}

1;

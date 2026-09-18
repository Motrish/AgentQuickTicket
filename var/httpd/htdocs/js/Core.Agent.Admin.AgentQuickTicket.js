// --
// OTOBO AgentQuickTicket administration helpers.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

Core.Agent.AdminAgentQuickTicket = (function (TargetNS) {

    function DynamicRows() {
        return $('#AgentQuickTicketDynamicFields tbody[data-role="dynamic-rows"] .AgentQuickTicketDynamicFieldRow');
    }

    function SelectedDefinition($Row) {
        var $Option = $Row.find('.AgentQuickTicketDynamicFieldName option:selected');
        var PossibleValues = {};

        try {
            PossibleValues = JSON.parse($Option.attr('data-possible-values') || '{}');
        }
        catch (Error) {
            PossibleValues = {};
        }

        return {
            Name: $Option.val() || '',
            FieldType: $Option.attr('data-field-type') || '',
            PossibleValues: PossibleValues
        };
    }

    function ValueFromEditor($Row) {
        var Value = $Row.find('.AgentQuickTicketDynamicFieldValue').val();
        if ($.isArray(Value)) {
            return Value;
        }
        return typeof Value === 'undefined' || Value === null ? '' : Value;
    }

    function RefreshValueEditor($Row, PreserveValue) {
        var PreviousValue = PreserveValue ? ValueFromEditor($Row) : '';
        var Definition = SelectedDefinition($Row);
        var $OldEditor = $Row.find('.AgentQuickTicketDynamicFieldValue');
        var $Editor;

        $Row.find('.AgentQuickTicketDynamicFieldType').text(Definition.FieldType || '-');

        if (Definition.FieldType === 'Checkbox') {
            $Editor = $('<select class="AgentQuickTicketDynamicFieldValue W90pc"></select>')
                .append('<option value="">--</option>')
                .append('<option value="1">1</option>')
                .append('<option value="0">0</option>');
        }
        else if (Definition.FieldType === 'Dropdown' || Definition.FieldType === 'Multiselect') {
            $Editor = $('<select class="AgentQuickTicketDynamicFieldValue W90pc"></select>');
            if (Definition.FieldType === 'Multiselect') {
                $Editor.attr({ multiple: 'multiple', size: 4 });
            }
            $Editor.append('<option value="">--</option>');
            $.each(Definition.PossibleValues || {}, function (Key, Label) {
                $Editor.append($('<option></option>').attr('value', Key).text(Label));
            });
        }
        else if (Definition.FieldType === 'TextArea') {
            $Editor = $('<textarea class="AgentQuickTicketDynamicFieldValue W90pc" rows="3"></textarea>');
        }
        else if (Definition.FieldType === 'Date') {
            $Editor = $('<input type="date" class="AgentQuickTicketDynamicFieldValue W90pc"/>');
        }
        else if (Definition.FieldType === 'DateTime') {
            $Editor = $('<input type="datetime-local" class="AgentQuickTicketDynamicFieldValue W90pc"/>');
        }
        else {
            $Editor = $('<input type="text" class="AgentQuickTicketDynamicFieldValue W90pc"/>');
        }

        if ($.isArray(PreviousValue)) {
            $Editor.val(PreviousValue);
        }
        else if (Definition.FieldType === 'Multiselect' && PreviousValue) {
            $Editor.val(String(PreviousValue).split(','));
        }
        else if (Definition.FieldType === 'DateTime' && PreviousValue) {
            $Editor.val(String(PreviousValue).replace(' ', 'T'));
        }
        else {
            $Editor.val(PreviousValue);
        }

        if ($OldEditor.length) {
            $OldEditor.replaceWith($Editor);
        }
        else {
            $Row.find('td').eq(4).prepend($Editor);
        }
    }

    function SyncDynamicFields() {
        var Configuration = {};

        DynamicRows().each(function () {
            var $Row = $(this);
            var Name = $Row.find('.AgentQuickTicketDynamicFieldName').val() || '';
            if (!Name) {
                return;
            }
            var Definition = SelectedDefinition($Row);
            var Value = ValueFromEditor($Row);
            if (Definition.FieldType === 'DateTime' && typeof Value === 'string') {
                Value = Value.replace('T', ' ');
            }
            Configuration[Name] = {
                ObjectType: $Row.find('.AgentQuickTicketDynamicFieldObject').val() || 'Ticket',
                Mode: $Row.find('.AgentQuickTicketDynamicFieldMode').val() || 'Keep',
                Value: Value || ''
            };
        });

        $('#DynamicFieldsJSON').val(JSON.stringify(Configuration));
    }

    function AddDynamicFieldRow() {
        var $Template = $('#AgentQuickTicketDynamicFieldRowTemplate');
        if (!$Template.length) {
            return;
        }
        var $Row = $Template.clone().removeAttr('id').removeClass('Hidden');
        $Row.addClass('AgentQuickTicketDynamicFieldRow');
        $('#AgentQuickTicketDynamicFields tbody[data-role="dynamic-rows"]').append($Row);
        RefreshValueEditor($Row, false);
    }

    TargetNS.Init = function () {
        // The OTOBO action configuration is guaranteed to be available during
        // APP_MODULE. Do not use jQuery DOM-ready here: that can run before
        // Core.Config has received the server-side configuration.
        var $AddButton = $('#AgentQuickTicketAddDynamicField');
        if (!$AddButton.length) {
            return;
        }

        $AddButton.off('click.AgentQuickTicket').on('click.AgentQuickTicket', AddDynamicFieldRow);

        $(document).on('click', '.AgentQuickTicketRemoveDynamicField', function () {
            $(this).closest('tr').remove();
        });

        $(document).on('change', '.AgentQuickTicketDynamicFieldName', function () {
            RefreshValueEditor($(this).closest('tr'), true);
        });

        DynamicRows().each(function () {
            RefreshValueEditor($(this), true);
        });

        $('#AgentQuickTicketEdit').on('submit', function () {
            SyncDynamicFields();
        });

        $(document).on('click', '#AgentQuickTicketProfiles a[data-confirm]', function (Event) {
            if (!window.confirm($(this).attr('data-confirm'))) {
                Event.preventDefault();
            }
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    TargetNS.SyncDynamicFields = SyncDynamicFields;
    return TargetNS;
}(Core.Agent.AdminAgentQuickTicket || {}));

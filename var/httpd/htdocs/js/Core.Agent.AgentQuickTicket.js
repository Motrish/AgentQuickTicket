// --
// OTOBO AgentQuickTicket agent-side widget and prefill adapter.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

Core.Agent.AgentQuickTicket = (function (TargetNS) {

    var State = {
        $Widget: null,
        LastCustomerUserID: null,
        RefreshTimer: null,
        Request: null
    };

    function ShowMessage(Message, IsError) {
        var $Message = State.$Widget.find('[data-role="message"]');
        if (!Message) {
            $Message.text('').addClass('Hidden').removeClass('Error Success');
            return;
        }
        $Message
            .text(Message)
            .removeClass('Hidden Error Success')
            .addClass(IsError ? 'Error' : 'Success');
    }

    function ShowLoading(Visible) {
        State.$Widget.find('[data-role="loading"]').toggleClass('Hidden', !Visible);
    }

    function CurrentQueueID() {
        var Value = $('#Dest').val() || '';
        var Match = Value.match(/^(\d+)\|\|/);
        return Match ? Match[1] : '';
    }

    function CurrentCustomerUserID() {
        return $('#SelectedCustomerUser').val() || '';
    }

    function CurrentTicketFields() {
        return {
            CurrentServiceID: $('#ServiceID').val() || '',
            CurrentTypeID: $('#TypeID').val() || '',
            CurrentPriorityID: $('#PriorityID').val() || '',
            CurrentStateID: $('#NextStateID').val() || '',
            CurrentOwnerID: $('#NewUserID').val() || '',
            CurrentResponsibleID: $('#NewResponsibleID').val() || ''
        };
    }

    function ClearButtons() {
        State.$Widget.find('[data-role="buttons"]').empty();
    }

    function SetEmptyState(HasCustomer) {
        State.$Widget.find('[data-role="hint"]').toggleClass('Hidden', HasCustomer);
        if (!HasCustomer) {
            ClearButtons();
            ShowMessage('', false);
        }
    }

    function ColorClass(Color) {
        var Normalized = String(Color || 'Primary').replace(/[^A-Za-z0-9_-]/g, '');
        return 'AgentQuickTicketButton--' + Normalized;
    }

    function BuildButton(Profile) {
        var $Button = $('<button type="button" class="AgentQuickTicketButton"></button>');
        var $Icon = $('<i class="fa" aria-hidden="true"></i>');
        var Icon = String(Profile.Icon || 'fa-bolt');

        if (!/^fa-[A-Za-z0-9-]+$/.test(Icon)) {
            Icon = 'fa-bolt';
        }
        $Icon.addClass(Icon);
        $Button.append($Icon).append($('<span></span>').text(Profile.Label || Profile.InternalName || ''));
        $Button.addClass(ColorClass(Profile.Color));
        if (Profile.Description) {
            $Button.attr('title', Profile.Description);
        }
        if (/^#[0-9A-Fa-f]{6}$/.test(String(Profile.Color || ''))) {
            $Button.css('background-color', Profile.Color);
        }
        $Button.on('click', function () {
            ApplyProfile(Profile);
        });
        return $Button;
    }

    function RenderProfiles(Profiles) {
        ClearButtons();
        State.$Widget.find('[data-role="hint"]').addClass('Hidden');
        if (!Profiles || !Profiles.length) {
            ShowMessage(Core.Language.Translate('No quick tickets are available for this customer user.'), false);
            return;
        }
        ShowMessage('', false);
        Profiles.sort(function (A, B) {
            return (parseInt(A.SortOrder, 10) || 0) - (parseInt(B.SortOrder, 10) || 0);
        });
        Profiles.forEach(function (Profile) {
            State.$Widget.find('[data-role="buttons"]').append(BuildButton(Profile));
        });
    }

    function LoadProfiles() {
        var CustomerUserID = CurrentCustomerUserID();
        State.LastCustomerUserID = CustomerUserID;
        SetEmptyState(!!CustomerUserID);
        if (!CustomerUserID) {
            return;
        }

        ShowLoading(true);
        State.Request = Core.AJAX.FunctionCall(
            Core.Config.Get('Baselink'),
            $.extend({
                Action: 'AgentQuickTicket',
                Subaction: 'GetProfiles',
                CustomerUserID: CustomerUserID,
                CurrentQueueID: CurrentQueueID(),
                CurrentDest: $('#Dest').val() || ''
            }, CurrentTicketFields()),
            function (Response) {
                ShowLoading(false);
                if (!Response || !Response.Success) {
                    RenderProfiles([]);
                    ShowMessage((Response && Response.Error) || Core.Language.Translate('Quick tickets could not be loaded.'), true);
                    return;
                }
                RenderProfiles(Response.Profiles || []);
            }
        );
    }

    function FormElements(Name) {
        var Elements = document.getElementsByName(Name);
        return Elements && Elements.length ? $(Elements) : $();
    }

    function Pad2(Value) {
        return String(Value || '').length === 1 ? '0' + Value : String(Value || '');
    }

    function CurrentDynamicDateValue(Name) {
        var $Year = FormElements(Name + 'Year');
        var $Month = FormElements(Name + 'Month');
        var $Day = FormElements(Name + 'Day');
        if (!$Year.length || !$Month.length || !$Day.length) {
            return null;
        }

        var $Used = FormElements(Name + 'Used').filter(':checkbox').first();
        if ($Used.length && !$Used.prop('checked')) {
            return '';
        }

        var DateValue = String($Year.first().val() || '') + '-'
            + Pad2($Month.first().val()) + '-' + Pad2($Day.first().val());
        var $Hour = FormElements(Name + 'Hour');
        var $Minute = FormElements(Name + 'Minute');
        if ($Hour.length && $Minute.length) {
            DateValue += ' ' + Pad2($Hour.first().val()) + ':' + Pad2($Minute.first().val()) + ':00';
        }
        return DateValue;
    }

    function SetDynamicDateValue(Name, Value) {
        var $Year = FormElements(Name + 'Year');
        var $Month = FormElements(Name + 'Month');
        var $Day = FormElements(Name + 'Day');
        if (!$Year.length || !$Month.length || !$Day.length) {
            return false;
        }

        var TextValue = $.isArray(Value) ? (Value[0] || '') : String(Value || '');
        var Match = TextValue.match(/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::\d{2})?)?$/);
        var $Used = FormElements(Name + 'Used').filter(':checkbox').first();
        if (!Match) {
            if ($Used.length) {
                $Used.prop('checked', false);
            }
            $Year.val('');
            $Month.val('');
            $Day.val('');
            FormElements(Name + 'Hour').val('');
            FormElements(Name + 'Minute').val('');
            return !TextValue;
        }

        if ($Used.length) {
            $Used.prop('checked', true);
        }
        $Year.val(Match[1]);
        $Month.val(Match[2]);
        $Day.val(Match[3]);
        if (Match[4]) {
            FormElements(Name + 'Hour').val(Match[4]);
            FormElements(Name + 'Minute').val(Match[5]);
        }
        else {
            FormElements(Name + 'Hour').val('00');
            FormElements(Name + 'Minute').val('00');
        }
        return true;
    }

    function CurrentValue(Name) {
        if (Name === 'Body' && typeof CKEditorInstances !== 'undefined' && CKEditorInstances.RichText) {
            try {
                return CKEditorInstances.RichText.getData() || '';
            }
            catch (Error) {
                // Fall back to the linked textarea below.
            }
        }

        var $Elements = FormElements(Name);
        if (!$Elements.length) {
            var DynamicDateValue = CurrentDynamicDateValue(Name);
            return DynamicDateValue === null ? '' : DynamicDateValue;
        }
        var $Checkbox = $Elements.filter(':checkbox').first();
        if ($Checkbox.length) {
            return $Checkbox.prop('checked') ? ($Checkbox.val() || '1') : '';
        }
        if ($Elements.first().is('select[multiple]')) {
            return $Elements.first().val() || [];
        }
        return $Elements.first().val() || '';
    }

    function SetRichTextValue(Value) {
        var TextValue = Value === null || typeof Value === 'undefined' ? '' : String(Value);
        var $RichText = $('#RichText');

        // AgentTicketPhone displays Body through CKEditor. Updating only the
        // source textarea leaves the visible editor unchanged.
        if (typeof CKEditorInstances !== 'undefined' && CKEditorInstances.RichText) {
            try {
                CKEditorInstances.RichText.setData(TextValue);
            }
            catch (Error) {
                // The textarea is still updated below and is the POST source.
            }
        }

        if ($RichText.length) {
            // Keep both the live value and the source text in sync. OTOBO's
            // RichTextEditor reads innerText when an instance is initialized.
            $RichText.text(TextValue).val(TextValue).prop('disabled', false);
            return true;
        }
        return false;
    }

    function SetFormValue(Name, Value) {
        if (Name === 'Body') {
            return SetRichTextValue(Value);
        }

        if (/^DynamicField_/.test(Name) && SetDynamicDateValue(Name, Value)) {
            return true;
        }

        var $Elements = FormElements(Name);
        if (!$Elements.length) {
            return false;
        }
        var $Checkbox = $Elements.filter(':checkbox').first();
        if ($Checkbox.length) {
            var Checked = Value === 1 || Value === '1' || Value === true || Value === 'true';
            $Checkbox.prop('checked', Checked);
        }
        else if ($Elements.first().is('select[multiple]')) {
            $Elements.first().val($.isArray(Value) ? Value : [Value]);
        }
        else {
            $Elements.first().val(Value === null || typeof Value === 'undefined' ? '' : Value);
        }
        return true;
    }

    function ValueIsDifferent(Current, NewValue) {
        if ($.isArray(Current) || $.isArray(NewValue)) {
            var CurrentArray = $.isArray(Current) ? Current : [Current];
            var NewArray = $.isArray(NewValue) ? NewValue : [NewValue];
            return CurrentArray.join('\u0000') !== NewArray.join('\u0000');
        }
        return String(Current || '') !== String(NewValue || '');
    }

    function ExistingChanges(Prefill) {
        var Changed = [];
        Object.keys(Prefill || {}).forEach(function (Name) {
            if (Name === 'QueueID') {
                return;
            }
            var Current = CurrentValue(Name);
            if (ValueIsDifferent(Current, Prefill[Name]) && (String(Current || '') !== '')) {
                Changed.push(Name);
            }
        });
        return Changed;
    }

    function ResolveProfile(Profile, Callback) {
        var CustomerUserID = CurrentCustomerUserID();
        if (!CustomerUserID) {
            ShowMessage(Core.Language.Translate('Please select a customer user first.'), true);
            return;
        }
        ShowLoading(true);
        Core.AJAX.FunctionCall(
            Core.Config.Get('Baselink'),
            $.extend({
                Action: 'AgentQuickTicket',
                Subaction: 'ResolveProfile',
                ProfileID: Profile.ID,
                CustomerUserID: CustomerUserID,
                CurrentQueueID: CurrentQueueID(),
                CurrentDest: $('#Dest').val() || ''
            }, CurrentTicketFields()),
            function (Response) {
                ShowLoading(false);
                if (!Response || !Response.Success) {
                    var ErrorText = (Response && Response.Error) || Core.Language.Translate('The quick ticket profile could not be applied.');
                    if (Response && Response.Warnings && Response.Warnings.length) {
                        ErrorText += ' ' + Response.Warnings.join(' ');
                    }
                    ShowMessage(ErrorText, true);
                    return;
                }
                Callback(Response);
            }
        );
    }

    function ApplyProfile(Profile) {
        ResolveProfile(Profile, function (Response) {
            var Warnings = Response.Warnings || [];
            var Existing = Response.Profile && Response.Profile.WarnOnExistingChanges
                ? ExistingChanges(Response.Prefill || {})
                : [];
            var Summary = [];
            Summary.push((Response.Profile && Response.Profile.Label) || Profile.Label || 'Quick ticket');
            Summary.push(Core.Language.Translate('Customer user') + ': ' + (Response.CustomerUserID || ''));
            if (Response.ChangedFields && Response.ChangedFields.length) {
                Summary.push(Core.Language.Translate('Fields to apply') + ': ' + Response.ChangedFields.join(', '));
            }
            if (Existing.length) {
                Summary.push(Core.Language.Translate('Existing values to overwrite') + ': ' + Existing.join(', '));
            }
            if (Warnings.length) {
                Summary.push(Core.Language.Translate('Warnings') + ': ' + Warnings.join(' '));
            }

            if ((Response.Profile && Response.Profile.ConfirmBeforeApply) && !window.confirm(Summary.join('\n'))) {
                return;
            }
            if (Warnings.length && !(Response.Profile && Response.Profile.ConfirmBeforeApply)
                && !window.confirm(Summary.join('\n'))) {
                return;
            }
            SubmitPrefill(Response.Prefill || {});
        });
    }

    function SubmitPrefill(Prefill) {
        var Form = document.getElementById('NewPhoneTicket');
        if (!Form) {
            ShowMessage(Core.Language.Translate('The AgentTicketPhone form was not found.'), true);
            return;
        }

        var HasBodyPrefill = Object.prototype.hasOwnProperty.call(Prefill, 'Body');

        Object.keys(Prefill).forEach(function (Name) {
            SetFormValue(Name, Prefill[Name]);
        });

        // Body is rendered by CKEditor. Keep the current page in place after
        // applying an article-text profile; a full AgentTicketPhone refresh
        // rebuilds the editor from the regular screen defaults and discards
        // the just-applied article text. The normal Create action submits the
        // synchronized textarea afterwards.
        if (HasBodyPrefill) {
            return;
        }

        // AgentTicketPhone's StoreNew path renders the submitted values back
        // into the form when ExpandCustomerName=4. This is a deliberate
        // no-submit path: it prevents ticket creation while preserving Body,
        // Subject, dynamic fields and the upload cache.
        var $Form = $(Form);
        var $Subaction = $Form.find('[name="Subaction"]').first();
        var $ExpandCustomerName = $Form.find('[name="ExpandCustomerName"]').first();
        if (!$Subaction.length || !$ExpandCustomerName.length) {
            ShowMessage(Core.Language.Translate('The AgentTicketPhone form is missing its refresh fields.'), true);
            return;
        }

        var OldSubaction = $Subaction.val();
        var OldExpandCustomerName = $ExpandCustomerName.val();
        $Subaction.val('StoreNew');
        $ExpandCustomerName.val('4');
        try {
            // Bypass submit handlers and client-side ticket creation actions.
            HTMLFormElement.prototype.submit.call(Form);
        }
        finally {
            $Subaction.val(OldSubaction);
            $ExpandCustomerName.val(OldExpandCustomerName);
        }
    }

    TargetNS.Init = function () {
        var $Widget = $('#AgentQuickTicketWidget');
        if (!$Widget.length || !$Widget.data('agent-quick-ticket-widget')) {
            return;
        }
        State.$Widget = $Widget;
        $Widget.insertAfter('#CustomerInfo').removeClass('Hidden');
        Core.App.Subscribe('Event.Agent.CustomerSearch.GetCustomerInfo.Callback', LoadProfiles);
        $('#SelectedCustomerUser').on('change', LoadProfiles);
        $(document).on('click', '#RemoveCustomerTicket, .CustomerTicketRemove', function () {
            window.setTimeout(LoadProfiles, 50);
        });
        LoadProfiles();
        State.RefreshTimer = window.setInterval(function () {
            var Current = CurrentCustomerUserID();
            if (Current !== State.LastCustomerUserID) {
                LoadProfiles();
            }
        }, 500);
    };

    // Register with OTOBO's module lifecycle. jQuery DOM-ready can fire
    // before Core.Config has loaded the server-side action configuration.
    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.AgentQuickTicket || {}));

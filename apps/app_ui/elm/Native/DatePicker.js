/* global _elm_lang$virtual_dom$Native_VirtualDom */
/* global $ */
/* global F2 */
/* exported _clarity$self_service_app$Native_DatePicker */
'use strict';

var _clarity$self_service_app$Native_DatePicker = function () {
    var root = function (attributes, defaultDate) {
        var model = {
            defaultDate: defaultDate
        };

        return _elm_lang$virtual_dom$Native_VirtualDom.custom(
            attributes,
            model,
            widgetImplementation
        );
    };

    var render = function (model) {
        var input = document.createElement('input');
        input.className = 'form-control';

        $(input).datetimepicker({
            onSelect: function (selectedDateTime) {
                var chosenDate = $(input).datetimepicker('getDate');
                var elmEvent = new CustomEvent(
                    'datechange',
                    {
                        detail: chosenDate.getTime()
                    }
                );
                input.dispatchEvent(elmEvent);
            }
        });

        var dateTime = moment(model.defaultDate).format('MM/DD/YYYY HH:mm');

        $(input).val(dateTime);

        return input;
    };

    var applyPatch = function (domNode, data) {
        return domNode;
    };

    var diff = function (oldData, newData) {
        if (oldData === newData) {
            return null;
        } else {
            return {
                applyPatch: applyPatch,
                data: {}
            };
        }
    };

    var widgetImplementation = {
        render: render,
        diff: diff
    };

    return {
        root: F2(root)
    };
}();

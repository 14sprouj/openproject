/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.Filters = {
  load_available_values_for_filter:  function  (filter_name, callback_func) {
    var select;
    select = $('' + filter_name + '_arg_1_val');
    if (select !== null && select.readAttribute('data-loading') === "ajax" && select.childElements().length === 0) {
      Ajax.Updater({ success: select }, window.global_prefix + '/cost_reports/available_values', {
        parameters: { filter_name: filter_name },
        insertion: 'bottom',
        evalScripts: false,
        onCreate: function (a, b) {
          $('operators_' + filter_name).disable();
          $('' + filter_name + '_arg_1_val').disable();
        },
        onComplete: function (a, b) {
          $('operators_' + filter_name).enable();
          $('' + filter_name + '_arg_1_val').enable();
          callback_func();
        }
      });
      Reporting.Filters.multi_select(select, false);
    } else {
      callback_func();
    }
  },

  show_filter: function (field, slowly, callback_func) {
    if (callback_func === undefined) {
      callback_func = function () {};
    }
    if (slowly === undefined) {
      slowly = true;
    }
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
      Reporting.Filters.load_available_values_for_filter(field, callback_func);
      // the following command might be included into the callback_function (which is called after the ajax request) later
      $('rm_' + field).value = field;
      if (slowly) {
        Effect.Appear(field_el);
      } else {
        field_el.show();
      }
      Reporting.Filters.operator_changed(field, $("operators_" + field));
      Reporting.Filters.display_category(field_el);
    }
  },

  display_category: function (tr_field) {
    var label = $(tr_field.getAttribute("data-label"));
    if (label !== null) {
      label.show();
    }
  },

  operator_changed: function (field, select) {
    var option_tag, arity;
    if (select === null) {
      return;
    }
    option_tag = select.options[select.selectedIndex];
    arity = parseInt(option_tag.getAttribute("data-arity"), 10);
    Reporting.Filters.change_argument_visibility(field, arity);
  },

  change_argument_visibility: function (field, arg_nr) {
    var params, i;
    params = [$(field + '_arg_1'), $(field + '_arg_2')];

    for (i = 0; i < 2; i += 1) {
      if (params[i] !== null) {
        if (arg_nr >= (i + 1) || arg_nr <= (-1 - i)) {
          params[i].show();
        } else {
          params[i].hide();
        }
      }
    }
  },

  add_filter: function (select) {
    var field;
    field = select.value;
    Reporting.Filters.show_filter(field);
    select.selectedIndex = 0;
    Reporting.Filters.select_option_enabled(select, field, false);
  },

  select_option_enabled: function (box, value, state) {
    box.select("[value='" + value + "']").first().disabled = state;
  },

  multi_select: function (select, multi) {
    select.multiple = multi;
    if (multi) {
      select.size = 4;
      // deselect first option
      select.options[0].selected = false;
    } else {
      select.size = 1;
    }
  },

  toggle_multi_select: function (select) {
    Reporting.Filters.multi_select(select, !select.multiple);
  }
};

Reporting.onload(function () {
  $("add_filter_select").observe("change", function () {
    Reporting.Filters.add_filter(this);
  });
});

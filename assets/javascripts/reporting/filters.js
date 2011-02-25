/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element, Form */

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
    // select first option by default
    select.selectedIndex = 0;
  },

  show_filter: function (field, options) {
    if (options === undefined) {
      options = {};
    }
    if (options.callback_func === undefined) {
      options.callback_func = function () {};
    }
    if (options.slowly === undefined) {
      options.slowly = false;
    }
    if (options.show_filter === undefined) {
      options.show_filter = true;
    }
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
      // the following command might be included into the callback_function (which is called after the ajax request) later
      var display_functor;
      if (options.show_filter) {
        (options.slowly ? Effect.Appear : Element.show)(field_el);
        Reporting.Filters.load_available_values_for_filter(field, options.callback_func);
        $('rm_' + field).value = field; // set the value, so the serialized form will return this filter
      } else {
        (options.slowly ? Effect.Fade : Element.hide)(field_el);
        field_el.removeAttribute('data-selected');
        $('rm_' + field).value = ""; // reset the value, so the serialized form will not return this filter
      }
      Reporting.Filters.operator_changed(field, $("operators[" + field + "]"));
      Reporting.Filters.display_category($(field_el.getAttribute("data-label")));
    }
  },

  /* Display the given category if any of its filters are visible. Otherwise hide it */
  display_category: function (label) {
    if (label !== null) {
      var filters = $$('.filter');
      for (var i = 0; i < filters.length; i += 1) {
        if (filters[i].visible() && filters[i].getAttribute("data-label") === label) {
          Element.show(label);
          return;
        }
      }
      Element.hide(label);
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
    Reporting.Filters.show_filter(field, { slowly: true });
    select.selectedIndex = 0;
    Reporting.Filters.select_option_enabled(select, field, false);
  },

  select_option_enabled: function (box, value, state) {
    var option = box.select("[value='" + value + "']").first();
    if (option !== undefined) {
      option.disabled = !state;
    }
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
  },

  remove_filter: function (field) {
    Reporting.Filters.show_filter(field, { show_filter: false });
    var dependents = Reporting.Filters.get_dependents($(field + '_arg_1_val'));
    if (dependents.size() !== 0) {
      Reporting.Filters.remove_filter(dependents.first());
    }
    Reporting.Filters.select_option_enabled($("add_filter_select"), field, true);
  },

  visible_filters: function () {
    return $("filter_table").select("tr").select(function (tr) {
      return tr.visible() === true;
    }).collect(function (filter) {
      return filter.getAttribute("data-filter-name");
    });
  },

  clear: function () {
    Reporting.Filters.visible_filters().each(function (filter) {
      Reporting.Filters.remove_filter(filter);
    });
  },

  get_dependents: function (element) {
    if (element.hasAttribute("data-dependents")) {
      return element.getAttribute("data-dependents").replace(/'/g, '"').evalJSON();
    } else {
      return [];
    }
  },

  // Activate the first dependent of the changed filter, if it is not already active.
  // Afterwards, collect the visible filters from the dependents list and start
  // narrowing down their values.
  activate_dependents: function () {
    var dependents = Reporting.Filters.get_dependents(this);
    var active_filters = Reporting.Filters.visible_filters();
    if (!active_filters.include(dependents.first())) {
      Reporting.Filters.show_filter(dependents.first(), { slowly: true });
      active_filters.unshift(dependents.first());
    }
    var source = this.getAttribute("data-filter-name");
    setTimeout(function () { // Make sure the newly shown filters are in the DOM
      var active_dependents = dependents.select(function (d) {
        return active_filters.include(d);
      });
      Reporting.Filters.narrow_values([source], active_dependents);
    }, 1);
  },

  // Narrow down the available values for the [dependents] of [sources].
  // This will narrow down for each dependent separately, adding each finished
  // dependent to the sources array and removing it from the dependents array.
  narrow_values: function (sources, dependents) {
    if (sources.size() === 0 || dependents.size === 0) {
      return;
    }
    var params = "?narrow_values=1&dependent=" + dependents.first();
    sources.each(function (filter) {
      params = params + "&sources[]=" + filter;
    });
    var targetUrl = document.location.href + params;
    var updater = new Ajax.Request(targetUrl,
      {
        asynchronous: true,
        evalScripts: true,
        postBody: Form.serialize('query_form'),
        onSuccess: function (response) {
          if (response.responseJSON !== undefined) {
            var selectBox = $(dependents.first() + "_arg_1_val");
            var selected = selectBox.select("option").collect(function (sel) {
              if (sel.selected) {
                return sel.value;
              }
            }).compact();
            var newOptions = response.responseJSON.inject("", function (str, o) {
              var value = (o === null ? "" : o);
              return str + '<option value="' + value + '">' + value.escapeHTML() + '</option>';
            });
            selectBox.innerHTML = newOptions;
            selected.each(function (val) {
              var opt = selectBox.select("option[value='" + val + "']");
              if (opt.size() === 1) {
                opt.first().selected = true;
              }
            });
            sources.push(dependents.first()); // Add as last element
            dependents.splice(0, 1); // Delete first element
            Reporting.Filters.narrow_values(sources, dependents);
          }
        }
      }
    );
  }
};

Reporting.onload(function () {
  $("add_filter_select").observe("change", function () {
    Reporting.Filters.add_filter(this);
  });
  $$(".filter_rem").each(function (e) {
    e.observe("click", function () {
      var filter_name = this.up('tr').getAttribute("data-filter-name");
      Reporting.Filters.remove_filter(filter_name);
    });
  });
  $$(".filter_operator").each(function (e) {
    e.observe("change", function () {
      var filter_name = this.getAttribute("data-filter-name");
      Reporting.Filters.operator_changed(filter_name, this);
    });
  });
  $$(".filter_multi-select").each(function (e) {
    e.observe("click", function () {
      Reporting.Filters.toggle_multi_select($(this.getAttribute("data-filter-name") + '_arg_1_val'));
    });
  });
  $$(".filters-select").each(function (s) {
    var selected_size = Array.from(s.options).findAll(function (o) {
      return o.selected === true;
    }).size();
    s.multiple = (selected_size > 1);
  });
  $$('.filters-select[data-dependents]').each(function (dependency) {
    dependency.observe("change", Reporting.Filters.activate_dependents);
  });
});

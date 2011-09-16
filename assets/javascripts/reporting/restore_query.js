/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.RestoreQuery = {

  select_operator: function (field, operator) {
    var select, i;
    select = $("operators_" + field);
    if (select === null) {
      return; // there is no such operator select field
    }
    for (i = 0; i < select.options.length; i += 1) {
      if (select.options[i].value === operator) {
        select.selectedIndex = i;
        break;
      }
    }
    Reporting.Filters.operator_changed(field, select);
  },

  disable_select_option: function (select, field) {
    for (var i = 0; i < select.options.length; i += 1) {
      if (select.options[i].value === field) {
        select.options[i].disabled = true;
        break;
      }
    }
  },

  // This is called the first time the report loads.
  // Params:
  //   elements: Array of visible filter-select-boxes that have dependents
  // (and possibly are dependents themselfes)
  initialize_load_dependent_filters: function(elements) {
    var filters_to_load, dependent_filters;
    dependent_filters = elements.findAll(function (select) { return select.getValue() == '<<inactive>>' || select.select('option[selected]').size()==0 });
    filters_to_load   = elements.reject( function (select) { return select.getValue() == '<<inactive>>' });
    // Filters which are <<inactive>> are probably dependents themselfes, so remove and forget them for now.
    // This is OK as they get reloaded later
    dependent_filters.each(function(select) {
      Reporting.Filters.remove_filter(select.up('tr').readAttribute("data-filter-name"));
    });
    // For each dependent filter we reload its dependent chain
    filters_to_load.each(function(selectBox) {
        var sources, selected_values;
        Reporting.Filters.activate_dependents(selectBox, function() {
          sources = Reporting.Filters.get_dependents(selectBox).collect(function(field) {
            return $('tr_' + field).select('.filter_values select').first();
          });
          sources.each(function(source) {
            if (source.hasAttribute('data-initially-selected')) {
              selected_values = source.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
              Reporting.Filters.select_values(source, selected_values);
              Reporting.Filters.value_changed(source.up('tr').readAttribute("data-filter-name"));
            }
          });
          if (sources.reject( function (select) { return select.value == '<<inactive>>' }).size() == 0) {
            Reporting.Filters.activate_dependents(selectBox);
          }
          else {
            Reporting.RestoreQuery.initialize_load_dependent_filters(sources);
          }
        });
    });
  },

  restore_dependent_filters: function(selectBox) {
    Reporting.Filters.activate_dependents(selectBox, function() {
        var sources = Reporting.Filters.get_dependents(selectBox).collect(function(field) {
          return $('tr_' + field).select('.filter_values select').first();
        });
        sources.each(function(source) {
          if (source.hasAttribute('data-initially-selected')) {
            var selected_values = source.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
            Reporting.Filters.select_values(source, selected_values);
            Reporting.Filters.value_changed(source.up('tr').readAttribute("data-filter-name"));
          }
        });
        if (sources.reject( function (select) { return select.value == '<<inactive>>' }).size() == 0) {
          Reporting.Filters.activate_dependents(selectBox);
        } else {
          sources.each(function (select) {
            Reporting.RestoreQuery.restore_dependent_filters(select);
          });
        }
      });
  },

  restore_filters: function () {
    console.log("restore filters");
    var deps = $$('.filters-select.filter-value').each(function(select) {
      var tr = select.up('tr');
      if (tr.visible()) {
        var filter = tr.readAttribute('data-filter-name');
        var dependent = select.readAttribute('data-dependent');
        if (filter && dependent) {
          Reporting.Filters.remove_filter(filter, false);
        }
      }
    });
    /*var dependents = deps[0];
    var independents = deps[1].select(function(select) {
      return select.up("tr").visible();
    });
    var dependent_filters = deps[0].findAll(function (select) {
      return select.getValue() == '<<inactive>>' || select.select('option[selected]').size()==0
    });
    // Filters which are <<inactive>> are probably dependents themselfes, so remove and forget them for now.
    // This is OK as they get reloaded later
    dependent_filters.each(function(select) {
      Reporting.Filters.remove_filter(select.up('tr').readAttribute("data-filter-name"));
    });*/
    $$("tr[data-selected=true]").each(function (e) {
      if (e.down(".filter_values select").hasAttribute("data-dependent")) return;
      var filter_name = e.getAttribute("data-filter-name");
      console.log("restore: " + filter_name);
      Reporting.Filters.add_filter(filter_name);
      // Reporting.RestoreQuery.restore_dependent_filters(e.down(".filters-select.filter-value"));
      // FIXME: rm_xxx values for filters have to be set after re-displaying them
      /*var rm_box, filter_name;
      rm_box = e.select("input[id^=rm]").first();
      filter_name = e.getAttribute("data-filter-name");
      rm_box.value = filter_name;
      Reporting.Filters.select_option_enabled($("add_filter_select"), filter_name, false);
      // correctly display number of arguments of filters depending on their arity
      Reporting.Filters.operator_changed(filter_name, $("operators[" + filter_name + "]"));*/
    });

    if (true) return; // pull the break

    var semaphore = dependents.length;
    dependents.each(function(dep) {
      filter_name = dep.up("tr").getAttribute("data-filter-name");
      if (filter_name == "sector_id") {
        console.log("[id=" + dep.readAttribute("id") + ", data-filter-name=" + filter_name + "]");
      }
      Reporting.Filters.load_available_values_for_filter(filter_name, function () {
        semaphore -= 1;
        if (semaphore <= 0) {
          Reporting.RestoreQuery.initialize_load_dependent_filters(dependents);
        }
        console.log("loaded available values for " + filter_name);
      });
    });
    /*independents.each(function (e) {
      filter_name = e.up("tr").getAttribute("data-filter-name");
      Reporting.Filters.load_available_values_for_filter(filter_name, function () {});
    });*/
  },

  restore_group_bys: function () {
    Reporting.GroupBys.group_by_container_ids().each(function(id) {
      var container, selected_groups;
      container = $(id);
      if (container.hasAttribute('data-initially-selected')) {
        selected_groups = container.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
        selected_groups.each(function(group_and_label) {
          var group, label;
          group = group_and_label[0];
          label = group_and_label[1];
          Reporting.GroupBys.add_group_by(group, label, container);
        });
      }
    });
  }
};

Reporting.onload(function () {
  Reporting.RestoreQuery.restore_group_bys();
  Reporting.RestoreQuery.restore_filters();
});










/*global $, selectAllOptions, moveOptions */

function toggle_filter(field) {
    var to_toggle, label;
    label = $('label_' + field);
    to_toggle = label.up().siblings();
    if (label.visible()) {
        to_toggle.invoke('show');
    } else {
        to_toggle.invoke('hide');
    }
}

function make_select_accept_multiple_values(select) {
    select.multiple = true;
    select.size = 4;
}

function make_select_accept_single_value(select) {
    select.multiple = false;
    select.size = 1;
}

function toggle_multi_select(select) {
    if (select.multiple === true) {
        make_select_accept_single_value(select);
    } else {
        make_select_accept_multiple_values(select);
    }
}

function change_argument_visibility(field, arg_nr) {
    var params, i;
    params = [$(field + '_arg_1'), $(field + '_arg_2')];

    for (i = 0; i < 2; i += 1) {
        if (params[i] !== null) {
            if (arg_nr >= (i + 1) || arg_nr <= (-1 - i)) {
                params[i].show();
            }
            else {
                params[i].hide();
            }
        }
    }
}

function operator_changed(field, select) {
    var option_tag, arity;
    option_tag = select.options[select.selectedIndex];
    arity = parseInt(option_tag.getAttribute("data-arity"), 10);
    change_argument_visibility(field, arity);
}

function display_category(tr_field) {
    var label = $(tr_field.getAttribute("data-label"));
    if (label !== null) {
        label.show();
    }
}

function hide_category(tr_field) {
    var label = $(tr_field.getAttribute("data-label"));
    if (label !== null) {
        label.hide();
    }
}

function set_remove_button_visibility(field, value) {
    var remove = $('rm_' + field);
    if (remove !== null) {
        if (value === true) {
            remove.show();
        } else {
            remove.hide();
        }
    }
}

function show_filter_callback(field, callback_func) {
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
        load_available_values_for_filter(field, callback_func);
        // the following command might be included into the callback_function (which is called after the ajax request) later
        field_el.show();
        toggle_filter(field);
        $('rm_' + field).value = field;
        operator_changed(field, $("operators_" + field));
        display_category(field_el);
    }
}

function show_filter(field) {
    show_filter_callback(field, function () {});
}

function occupied_category(tr_field) {
    var i, data_label, filters;
    data_label = tr_field.getAttribute("data-label");
    filters = document.getElementsByClassName('filter');
    for (i = 0; i < filters.length; i += 1) {
        if (filters[i].visible() && filters[i].getAttribute("data-label") === data_label) {
            return true;
        }
    }
    return false; //not hit
}

function hide_filter(field) {
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
        $('rm_' + field).value = "";
        field_el.hide();
        toggle_filter(field);
        operator_changed(field, $("operators_" + field));
        if (!occupied_category(field_el)) {
            hide_category(field_el);
        }
    }
}

function disable_select_option(select, field) {
    for (var i = 0; i < select.options.length; i += 1) {
        if (select.options[i].value === field) {
            select.options[i].disabled = true;
            break;
        }
    }
}

function enable_select_option(select, field) {
    for (var i = 0; i < select.options.length; i += 1) {
        if (select.options[i].value === field) {
            select.options[i].disabled = false;
            break;
        }
    }
}

function add_filter(select) {
    var field;
    field = select.value;
    show_filter(field);
    select.selectedIndex = 0;
    disable_select_option(select, field);
}

function remove_filter(field) {
    hide_filter(field);
    enable_select_option($("add_filter_select"), field);
}

function show_group_by(group_by, source) {
    // find group_by option-tag in source select-box
    for (i = 0; i < source.options.length; i += 1) {
        if (source.options[i].value === group_by) {
            source.value = group_by;
            add_group_by(source);
            break;
        }
    }
}

function select_operator(field, operator) {
    var select, i;
    select = $("operators_" + field);
    for (i = 0; i < select.options.length; i += 1) {
        if (select.options[i].value === operator) {
            select.selectedIndex = i;
            break;
        }
    }
    operator_changed(field, select);
}

function restore_select_values(select, values) {
    var i, j;
    if (values.length > 1) {
        make_select_accept_multiple_values(select);
    } else {
        make_select_accept_single_value(select);
    }
    for (i = 0; i < values.length; i += 1) {
        for (j = 0; j < select.options.length; j += 1) {
            if (select.options[j].value === values[i].toString()) {
                try {
                    select.options[j].selected = true;
                    break;
                } catch(e) {
                    window.setTimeout('$("' + select.id + '").childElements()[' + j + '].selected = true;', 1);
                }
            }
        }
    }
}

function select_active_group_bys() {
    [$('group_by_columns'), $('group_by_rows')].each(function (sel) {
        sel.multiple = true;
        sort_group_bys(sel, sel.siblings());
    });
}

function sort_group_bys(select, group_bys) {
    for (var k = 0; k < group_bys.length; k++) {
        for (var i = 0; i < select.options.length; i++) {
            if (group_bys[k].getAttribute('data-backref') == select.options[i].value) {
                select.options[i].setAttribute('data-sort_by', k);
                select.options[i].selected = true;
            }
        }
    }
    moveOptionsToTopLevel(select);
    sortOptions(select.id);
}

function reset_group_by_selects() {
    [$('group_by_columns'), $('group_by_rows')].each(function(select) {
        select.multiple = false;
        putOptionsIntoOpgroups(select);
        select.options[0].selected = true;
    });
}

function find_arguments(field) {
    var args = [], arg_count = 0, arg = null;
    arg = $(field + '_arg_' + (arg_count + 1) + '_val');
    while (arg !== null) {
        args[args.length] = arg;
        arg_count = arg_count + 1;
        arg = $(field + '_arg_' + (arg_count + 1) + '_val');
    }
    return args;
}

function restore_values(field, values) {
    var op_select, op_arity, args, i;
    op_select = $("operators_" + field);
    op_arity = op_select.options[op_select.selectedIndex].getAttribute("data-arity");
    args = find_arguments(field);
    if (!Object.isArray(values)) {
        values = [values];
    }
    if (op_arity < 0 && !(args[0].type.empty()) && args[0].type.include('select')) {
        restore_select_values(args[0], values);
    } else {
        for (i = 0; i < values.length && i < args.length; i += 1) {
            args[i].setValue(values[i]);
        }
    }
}

function restore_filter(field, operator, values) {
    select_operator(field, operator);
    disable_select_option($("add_filter_select"), field);
    show_filter_callback(field, function () {
        if (typeof(values) !== "undefined") {
            restore_values(field, values);
        }
    });
}

function add_group_by(select) {
    field = select.value;
    group_by = init_group_by(field + "_" + select.id);
    group_by.setAttribute('data-backref', field);
    select.up().appendChild(group_by);
    label = init_label(group_by);
    label.innerHTML = sanitized_selected(select);
    select.value = "";
    group_by.appendChild(label);
    group_by.appendChild(init_arrow(group_by));
    if (!(first_in_row(group_by))) {
        update_arrow(group_by.previous());
    }
    disable_select_option($('group_by_columns'), field);
    disable_select_option($('group_by_rows'), field);
}

function remove_group_by(arrow) {
    group_by = arrow.up();
    enable_select_option($('group_by_columns'), group_by.getAttribute('data-backref'));
    enable_select_option($('group_by_rows'), group_by.getAttribute('data-backref'));
    previous = group_by.previous();
    group_by.remove();
    if (previous !== null) {
        update_arrow(previous);
    }
}

function init_arrow(group_by) {
    arrow = document.createElement('div');
    arrow.setAttribute('id', group_by.id + '_arrow');
    arrow.setAttribute('class', 'arrow in_row arrow_left');
    arrow.src = "/plugin_assets/redmine_reporting/images/arrow_left.png";
    init_arrow_hover_effects(arrow);
    return arrow;
}

function init_arrow_hover_effects(arrow) {
    Event.observe(arrow, 'mouseover', function() { arrow_start_removal_hover(arrow) });
    Event.observe(arrow, 'mouseout', function() { arrow_end_removal_hover(arrow) });
    Event.observe(arrow, 'click', function() { remove_group_by(arrow) });
}

function arrow_start_removal_hover(arrow) {
    group_by_start_hover(arrow.up());
    update_arrow(arrow.up());
    arrow.className = arrow.className + "_remove";
}

function arrow_end_removal_hover(arrow) {
    group_by_end_hover(arrow.up());
    arrow.className = arrow.className.replace(/\_remove/, "");
}

function update_arrow(group_by) {
    arrow = $(group_by.id + "_arrow");
    if (arrow == null) return;
    if (last_in_row(group_by)) {
        arrow.className = "arrow in_row arrow_left";
    } else {
        arrow.className = "arrow in_row arrow_both";
    }
}

function init_label(group_by) {
    group_by_label = document.createElement('label');
    group_by_label.setAttribute('for', group_by.id);
    group_by_label.setAttribute('class', 'in_row group_by_label');
    group_by_label.setAttribute('id', group_by.id + '_label');
    init_group_by_hover_effects(group_by_label);
    return group_by_label;
}

function sanitized_selected(select) {
    return select.descendants().select(function(e) { return e.value == select.value }).first().innerHTML.strip();
}

function init_group_by(field) {
    group_by = document.createElement('span');
    group_by.className = 'in_row drag_element group_by';
    group_by.id = field;
    return group_by;
}

function init_group_by_hover_effects(group_by_label) {
    Event.observe(group_by_label, 'mouseover', function() {
        group_by_start_hover(group_by_label.up());
    });
    Event.observe(group_by_label, 'mouseout', function() {
        group_by_end_hover(group_by_label.up());
    });
}

function group_by_start_hover(group_by) {
    arrow = $(group_by.id + '_arrow');
    group_by.className = group_by.className.replace(/group\_by/, 'group_by_hover');
    if (last_in_row(group_by)) {
        arrow.className = 'arrow in_row arrow_left_hover';
    } else {
        arrow.className = 'arrow in_row arrow_both_hover_left';
    }
    if (!(first_in_row(group_by))) {
        $(group_by.previous().id + '_arrow').className = 'arrow in_row arrow_both_hover_right';
    }
}

function group_by_end_hover(group_by) {
    arrow = $(group_by.id + '_arrow');
    group_by.className = group_by.className.replace(/\_hover/, '');
    if (arrow !== null) {
        if (last_in_row(group_by)) {
            arrow.className = 'arrow in_row arrow_left';
        } else {
            arrow.className = 'arrow in_row arrow_both';
        }
    }
    if (!(first_in_row(group_by))) {
        $(group_by.previous().id + '_arrow').className = 'arrow in_row arrow_both';
    }
}

function first_in_row(group_by) {
    return ((group_by.previous() == null) || (!group_by.previous().hasClassName('group_by')));
}

function last_in_row(group_by) {
    return ((group_by.next() == null) || (!group_by.next().hasClassName('group_by')));
}

function move_group_by(group_by, target) {
    group_by = $(group_by);
    target = $(target);
    if (group_by === null || target === null) {
        return;
    }
    target.insert({ bottom: group_by.remove() });
}

function show_group_by_row(group_by) {
    show_group_by(group_by, $('group_by_rows'));
}

function show_group_by_column(group_by) {
    show_group_by(group_by, $('group_by_columns'));
}

function disable_all_filters() {
    $('filter_table').down().childElements().each(function (e) {
        var field, possible_select;
        e.hide();
        if (e.readAttribute('class') === 'filter') {
            field = e.id.gsub('tr_', '');
            hide_filter(field);
            enable_select_option($('add_filter_select'), field);
            possible_select = $(field + '_arg_1_val');
            if (possible_select !== null && possible_select.type && possible_select.type.include('select')) {
                make_select_accept_single_value(possible_select);
            }
        }
    });
}

function disable_all_group_bys() {
    [$('group_columns'), $('group_rows')].each(function(origin) {
        children = origin.childElements();
        for (var i = 0; i < children.length; i++) {
            if (children[i].hasClassName('group_by')) {
                [$('group_by_columns'), $('group_by_rows')].each(function (sel) {
                    enable_select_option(sel, children[i].getAttribute('data-backref'));
                });
                children[i].remove();
            }
        }
    });
}

function serialize_filter_and_group_by() {
    var ret_str, rows, columns;
    ret_str = Form.serialize('query_form');
    rows = Sortable.serialize('group_rows');
    columns = Sortable.serialize('group_columns');
    if (rows !== null && rows !== "") {
        ret_str += "&" + rows;
    }
    if (columns !== null && columns !== "") {
        ret_str += "&" + columns;
    }
    return ret_str;
}

function init_group_bys() {
    var options = {
        tag: 'span',
        overlap: 'horizontal',
        constraint: 'horizontal',
        containment: ['group_columns', 'group_rows'],
        //only: "group_by",
        dropOnEmpty: true,
        format: /^(.*)$/,
        hoverclass: 'drag_container_accept'
    };
    Sortable.create('group_columns', options);
    Sortable.create('group_rows', options);
}

function load_available_values_for_filter(filter_name, callback_func) {
    var select;
    select = $('' + filter_name + '_arg_1_val');
    if (select.readAttribute('data-loading') === "ajax" && select.childElements().length === 0) {
        new Ajax.Updater({ success: select }, '/cost_reports/available_values', {
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
        make_select_accept_single_value(select);
    }
    else {
        callback_func();
    }
}

function defineElementGetter() {
    if (document.getElementsByClassName === undefined) {
        document.getElementsByClassName = function (className)
        {
            var hasClassName, allElements, results, element, elementClass, i;
            hasClassName = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
            allElements = document.getElementsByTagName("*");
            results = [];
            for (i = 0; (element = allElements[i]) !== null; i += 1) {
                elementClass = element.className;
                if (elementClass && elementClass.indexOf(className) !== -1 && hasClassName.test(elementClass)) {
                    results.push(element);
                }
            }
            return results;
        };
    }
}

defineElementGetter();

require_dependency 'xls_report/xls_views'

class CostReportTable < XlsViews
  def final_row(final_row, cells)
    row = [show_row final_row]
    row += cells
    row << show_result(final_row)
  end

  def row(row, subrows)
    unless row.fields.empty?
      # Here we get the border setting, vertically. The rowspan #{subrows.size} need be
      # converted to a proper Excel bordering
      subrows = subrows.inject([]) do |array, subrow|
        if subrow.flatten == subrow
          array << subrow
        else
          array += subrow.collect(&:flatten)
        end
      end
      subrows.each_with_index do |subrow, idx|
        if idx == 0
          subrow.insert(0, show_row(row))
          subrow << show_result(row)
        else
          subrow.unshift("")
          subrow << ""
        end
      end
    end
    subrows
  end

  def cell(result)
    show_result result
  end

  def headers(list, first, first_in_col, last_in_col)
    if first_in_col # Open a new header row
      @header = [""] * @query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
    end

    list.each do |column|
      @header << show_row(column)
      @header += [""] * (column.final_number(:column) - 1).abs
    end

    if last_in_col # Finish this header row
      @header += [""] * @query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
      @headers << @header
    end
  end

  def footers(list, first, first_in_col, last_in_col)
    if first_in_col # Open a new footer row
      @footer = [""] * @query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
    end

    list.each do |column|
      @footer << show_result(column)
      @footer += [""] * (column.final_number(:column) - 1).abs
    end

    if last_in_col # Finish this footer row
      if first
        @footer << show_result(@query)
        @footer += [""] * (@query.depth_of(:row) - 1).abs # TODO: add rowspan=query.depth_of(:column)
      else
        @footer += [""] * @query.depth_of(:row) # TODO: add rowspan=query.depth_of(:column)
      end
      @footers << @footer
    end
  end

  def body(*line)
    @rows += line.flatten
  end

  def generate(sb, query, cost_type, unit_id)
    @query = query
    walker = query.walker

    walker.for_final_row &method(:final_row)
    walker.for_row &method(:row)
    walker.for_empty_cell { "" }
    walker.for_cell &method(:cell)

    @headers = []
    @header  = []
    walker.headers &method(:headers)

    @footers = []
    @footer  = []
    walker.reverse_headers &method(:footers)

    @rows = []
    walker.body &method(:body)

    build_spreadsheet(sb, cost_type, unit_id)
  end

  def build_spreadsheet(sb, cost_type, unit_id)
    sb.add_headers [label(cost_type, unit_id)]
    row_length = @headers.first.length
    @headers.each {|head| sb.add_headers(head, sb.current_row) }
    @rows.in_groups_of(row_length).each {|body| sb.add_row(body) }
    @footers.each {|foot| sb.add_headers(foot, sb.current_row) }
    sb
  end

  def label(cost_type, unit_id)
    "#{l(:caption_cost_type)}: " + case unit_id
    when -1 then l(:field_hours)
    when 0  then "EUR"
    else cost_type.unit_plural
    end
  end
end
class CostQuery::Operator < Report::Operator
  include CostQuery::QueryUtils

  #############################################################################################
  # Wrapped so we can place this at the top of the file.
  def self.define_operators # :nodoc:
    super

    # Operators from Redmine
    new "c", :arity => 0 do
      def modify(query, field, *values)
        raise "wrong field" if field.to_s.split('.').last != "status_id"
        query.where "(#{IssueStatus.table_name}.is_closed = #{quoted_true})"
        query
      end
    end

    new "o", :arity => 0 do
      def modify(query, field, *values)
        raise "wrong field" if field.to_s.split('.').last != "status_id"
        query.where "(#{IssueStatus.table_name}.is_closed = #{quoted_false})"
        query
      end
    end

    new "=_child_projects", :validate => :integers, :label => :label_is_project_with_subprojects do
      def modify(query, field, *values)
        p_ids = []
        values.each do |value|
          p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
        end
        "=".to_operator.modify query, field, p_ids
      rescue ActiveRecord::RecordNotFound
        query
      end
    end

    new "!_child_projects", :validate => :integers, :label => :label_is_not_project_with_subprojects do
      def modify(query, field, *values)
        p_ids = []
        values.each do |value|
          p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
        end
        "!".to_operator.modify query, field, p_ids
      rescue ActiveRecord::RecordNotFound
        query
      end
    end

  end
  #############################################################################################

end
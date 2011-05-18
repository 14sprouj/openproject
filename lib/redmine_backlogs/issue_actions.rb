class RedmineBacklogs::IssueActions < ChiliProject::Nissue::View
  def initialize(issue)
    @issue = issue
  end

  def render(t)
    css_class = "watcher_link_#{@issue.id}"
    content_tag(:div, [
        t.watcher_link(@issue, User.current, :class => css_class, :replace => ".#{css_class}")
      ], :class => 'contextual')
  end
end

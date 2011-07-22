class RedmineBacklogs::IssueForm < RedmineBacklogs::IssueView; end
require_dependency 'redmine_backlogs/issue_form/custom_field_paragraph'
require_dependency 'redmine_backlogs/issue_form/description_paragraph'
require_dependency 'redmine_backlogs/issue_form/fields_paragraph'
require_dependency 'redmine_backlogs/issue_form/heading'
require_dependency 'redmine_backlogs/issue_form/notes_paragraph'

class RedmineBacklogs::IssueForm < RedmineBacklogs::IssueView
  attr_reader :form_id
  
  def initialize(issue)
    super(issue)
    @form_id = "form_#{ActiveSupport::SecureRandom.hex(10)}"
  end

  def render(t)
    s = super(t)
    content_tag(:form, [
      s,
      notes_paragraph.render(t)
    ], :id => form_id)
  end
  
  def heading
    @heading ||= RedmineBacklogs::IssueForm::Heading.new(@issue)
  end
  
  def notes_paragraph
    @notes_paragraph ||= RedmineBacklogs::IssueForm::NotesParagraph.new(@issue)
  end

  def fields_paragraph
    @fields_paragraph ||= RedmineBacklogs::IssueForm::FieldsParagraph.new(@issue)
  end
  
  def description_paragraph
    @description_paragraph ||= RedmineBacklogs::IssueForm::DescriptionParagraph.new(@issue)
  end
  
  def related_issues_paragraph
    @related_issues_paragraph ||= ChiliProject::Nissue::EmptyParagraph.new
  end
  
  def sub_issues_paragraph
    @sub_issues_paragraph ||= ChiliProject::Nissue::EmptyParagraph.new
  end
end

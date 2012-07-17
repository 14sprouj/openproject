Feature: Project Details Widget

  Background:
    Given there is 1 project with the following:
      | Name | Parent |
    And the project "Parent" has 1 subproject with the following:
      | Name    | Child  |
    And I am already logged in as "admin"

  @javascript
  Scenario: Adding a "Project Details" widget
    Given I am on the project "Parent" overview personalization page
    When I select "Calendar" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Calendar" widget should be in the hidden block

  Scenario: Includes links to all child projects
    Given the following widgets should be selected for the overview page of the "Parent" project:
      | top        | Projectdetails   |
    When I go to the overview page of the project called "Parent"
    And I follow "Child" within ".mypage-box .project_details"
    Then I should be on the overview page of the project called "Child"

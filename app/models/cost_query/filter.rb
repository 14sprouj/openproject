require "set"

module CostQuery::Filter
  def self.all
    @all ||= Set[
      CostQuery::Filter::ActivityId,
      CostQuery::Filter::AssignedToId,
      CostQuery::Filter::CategoryId,
      CostQuery::Filter::CostTypeId,
      CostQuery::Filter::CreatedOn,
      CostQuery::Filter::DueDate,
      CostQuery::Filter::FixedVersionId,
      CostQuery::Filter::IssueId,
      #CostQuery::Filter::OverridenCosts, #FIXME: include me to this list
      CostQuery::Filter::PriorityId,
      CostQuery::Filter::ProjectId,
      CostQuery::Filter::SpentOn,
      CostQuery::Filter::StartDate,
      CostQuery::Filter::StatusId,
      CostQuery::Filter::Subject,
      CostQuery::Filter::TrackerId,
      CostQuery::Filter::Tweek,
      CostQuery::Filter::UpdatedOn,
      CostQuery::Filter::UserId
      ]
  end

  def self.all_grouped
    CostQuery::Filter.all.group_by { |f| f.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def self.from_hash
    raise NotImplementedError
  end
end

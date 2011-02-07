class MeetingContentsController < ApplicationController
  unloadable
  
  menu_item :meetings
  
  helper :wiki
  
  before_filter :find_meeting, :find_content
  before_filter :authorize
  
  def show
    @content = @content.find_version(params[:version]) unless params[:version].blank?
    render 'meeting_contents/show'
  end
  
  def update
    @content.attributes = params[:"#{@content_type}"]
    @content.author = User.current
    if @content.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :back
    else
    end
  end
  
  def history
    @version_count = @content.versions.count
    @version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @content_versions = @content.versions.all :select => "id, author_id, comment, updated_at, version", :order => 'version DESC', :limit => @version_pages.items_per_page + 1, :offset =>  @version_pages.current.offset
    render 'meeting_contents/history', :layout => !request.xhr?
  end
  
  def diff
    @diff = @content.diff(params[:version_to], params[:version_from])
    render_404 unless @diff
    render 'meeting_contents/diff'
  end
  
  private
    
  def find_meeting
    @meeting = Meeting.find(params[:meeting_id], :include => [:project, :author, :participants, :agenda, :minutes])
    @project = @meeting.project
    @author = User.current
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
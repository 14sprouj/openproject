ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'projects' do |p|
    p.connect 'projects', :action => 'index'
    p.connect 'projects/new', :action => 'new'
  end

  map.with_options :controller => 'my_projects_overviews' do |my|
    my.connect 'projects/:id', :action => 'index'
    my.connect 'my_projects_overview/:id/page_layout', :action => 'page_layout'
    my.connect 'my_projects_overview/:id/page_layout/add_block', :action => 'add_block'
    my.connect 'my_projects_overview/:id/page_layout/remove_block', :action => 'remove_block'
    my.connect 'my_projects_overview/:id/page_layout/order_blocks', :action => 'order_blocks'
    my.connect 'my_projects_overview/:id/page_layout/update_custom_element', :action => 'update_custom_element'
  end
end

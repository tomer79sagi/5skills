# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def type_value(options_arr, type_key)
    # Always ensure the key is an Integer
    type_key = type_key.to_i
    
    if type_key
      value = options_arr.rassoc(type_key)
      value = value[0] if value
    end
    
    value = '' if !value
    
    value
  end
  
  # Style
  # 
  def sort(view_field, sort_by)
    html = ""
    @link_attributes_h = {:action => params[:action], 
      :controller => params[:controller], 
      :sb => sort_by, 
      :sd => @sort_dir}
      
    @link_attributes_h = @link_attributes_h.merge({:p => @pagination_info[:page_number].to_s}) if @pagination_info && @pagination_info[:page_number]
    
    html << "#{link_to view_field, @link_attributes_h}" +
      '<span style="font-size:15px;color:black;background-color:yellow;">'
    
    html << @sort_dir_icon if @sort_by == sort_by
    
    html
  end
  
  # Style
  # 
  def paginate(style = 1)
    @link_attributes_h = {:action => params[:action], :controller => params[:controller], :sd => params[:sd], :sb => params[:sb]}
    html = ""
    
    html << '<table style="width:100%;">'
    
    # Print the 'Displaying X to Y of Z' line
    if style == 1
    
      html << '<tr>' +   
        '<td style="width:100%;text-align:left;">' + 
          'Displaying ' + (@pagination_info[:starting_point].to_i + 1).to_s + ' to '
          
      if (@pagination_info[:results_count].to_i < @pagination_info[:results_per_page].to_i) || 
          (@pagination_info[:page_number].to_i == @pagination_info[:number_of_pages].to_i)
        html << @pagination_info[:results_count].to_s
      else
        html << (@pagination_info[:starting_point].to_i + @pagination_info[:results_per_page].to_i).to_s
      end
      
      html << ' of ' + @pagination_info[:results_count] + 
        '</td>' +
        '</tr>'
      
    end
    
    html << '<tr>' +
        '<td style="width:100%;text-align:right;">' + 
          '<table>' + 
            '<tr>' + 
              '<td style="padding:.3em;border:.5px solid black;min-height:8px;">' + 
                "#{link_to "<< First", @link_attributes_h.merge({:p => 1}), :class => "content_link"}" +
              '</td>' + 
              '<td style="padding:.3em;border:.5px solid black;min-height:8px;">' + 
                "#{link_to "< Previous", @link_attributes_h.merge({:p => @pagination_info[:previous_page]}), :class => "content_link"}" +  
              '</td>'
              
    @counter_start = 1
    @counter_end = @pagination_info[:number_of_pages].to_i
    @page_navigation_padding = 4
    
    @is_start_shifted = @is_end_shifted = false

    if (@pagination_info[:page_number].to_i - @page_navigation_padding - 1) > 0
      @counter_start = @pagination_info[:page_number].to_i - @page_navigation_padding - 1
      @is_start_shifted = true      
    end
    
    if (@pagination_info[:page_number].to_i + @page_navigation_padding) < @pagination_info[:number_of_pages].to_i
      @counter_end = @pagination_info[:page_number].to_i + @page_navigation_padding + 1
      @is_end_shifted = true
    end
    
    @counter_start.upto @counter_end do |p|
      html << '<td style="padding:.3em;border:.5px solid black;min-height:8px;">'
      
      if @is_start_shifted || (p == @counter_end && @is_end_shifted)
        if @is_start_shifted
          html << '...'
          @is_start_shifted = false
        elsif @is_end_shifted
          html << '...'
          @is_end_shifted = false
        end
      else
        if p == @pagination_info[:page_number].to_i
          html << '<b>' + p.to_s + '</b>'
        else
          html << "#{link_to p.to_s, @link_attributes_h.merge({:p => p.to_s}), :class => "content_link"}"
        end
      end
    
      html << '</td>'
    end
              
    html << '<td style="padding:.3em;border:.5px solid black;min-height:8px;">' + 
                  "#{link_to "Next >", @link_attributes_h.merge({:p => @pagination_info[:next_page]}), :class => "content_link"}" + 
                '</td>' + 
                '<td style="padding:.3em;border:.5px solid black;min-height:8px;">' + 
                  "#{link_to "Last >>", @link_attributes_h.merge({:p => @pagination_info[:number_of_pages]}), :class => "content_link"}" + 
                '</td>' +   
              '</tr>' + 
            '</table>' + 
          '</td>' + 
        '</tr>' + 
      '</table>'

    html
    
  end
  
end

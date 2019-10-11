module FsAdminHelper
  
  def create_field(entity_obj, obj_map, html_field_map)
    html_obj_map = {}
    returned_str = ""
    html_field_map[:css_class] = "adm_field" if html_field_map[:css_class].nil?
    
    if obj_map
      # id
      if obj_map[:obj_id]
        html_obj_map[:id] = entity_obj
        obj_map[:obj_id].each do |path_elm|
          html_obj_map[:id] = html_obj_map[:id][path_elm.to_sym]
          break if html_obj_map[:id].nil?
        end
      end
      
      # value
      if obj_map[:obj_value]
        html_obj_map[:value] = entity_obj
        obj_map[:obj_value].each do |path_elm|
          html_obj_map[:value] = html_obj_map[:value][path_elm.to_sym]
          break if html_obj_map[:value].nil?
        end
      end
    end
    
    is_blank = true if html_obj_map[:value].nil? || html_obj_map[:value].blank?
    
    returned_str += '<div class="' + html_field_map[:css_class].to_s if html_field_map[:css_class]
    returned_str += ' ' + html_field_map[:css_class].to_s + '_untitled' if is_blank && html_field_map[:css_class]
    returned_str += '"'
    returned_str += ' id="' + html_field_map[:field_html_id].to_s + '"' if html_field_map[:field_html_id]
    returned_str += ' orig_value="' + html_obj_map[:value].to_s + '"' if obj_map && html_obj_map[:value]
    returned_str += ' autocomplete="' + html_field_map[:autocomplete].to_s + '"' if html_field_map && html_field_map[:autocomplete] && html_field_map[:autocomplete] == true
    returned_str += ' blank_value="' + html_field_map[:blank_value].to_s + '"'
    
    if html_obj_map[:id]
      returned_str += ' entity_id="' + html_obj_map[:id].to_s + '"'
    else
      returned_str += ' entity_id="-1"'
    end

    if is_blank
      returned_str += ' blank="true">' + html_field_map[:blank_value].to_s + '</div>'
    else
      returned_str += '>' + html_obj_map[:value].to_s + '</div>'    
    end
    
    returned_str
  end
  
end

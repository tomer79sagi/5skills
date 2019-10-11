module FiveSkillsHelper
  
  # ----------
  #  HELPERS
  # ----------
  
  def format_time(time_as_string, format_type = FsBaseController::TIME_FORMAT_TYPES[:default])
    case format_type
      when FsBaseController::TIME_FORMAT_TYPES[:default]
        time_as_string = DateTime.parse(time_as_string).strftime('%d %b, %Y - %H:%M')
      when FsBaseController::TIME_FORMAT_TYPES[:time_ago]
        time_as_string = time_ago_in_words(time_as_string) + " ago"
    end
    
    time_as_string
  end
  
  
  
  def squeeze_c(s_text, length = 25)
    
    more_text = " ... "
    
    # Always ensure the key is an Integer
    if s_text.length > length
      i_part = (length - more_text.length) / 2
      s_text = s_text[0..i_part] + more_text + s_text[-i_part..-1]
    end
    
    s_text
    
  end
  
  def is_edit
    params[:page_view_mode] == FiveSkillsController::PAGE_VIEW_MODES[:edit]
  end
  
  def is_create
    params[:page_view_mode] == FiveSkillsController::PAGE_VIEW_MODES[:create]
  end
  
  def is_binders
    !params[:field_binders].nil?
  end
  
  def fs_image_tag(img_id, size = "32x32")
    return if img_id.nil?
      
    image_tag(show_file_url(:file_id => img_id), :size => size)
  end
  
  def is_job_seeker_selected
    @user_type_id && @user_type_id == Fs2User::USER_TYPES[:job_seeker]
  end
  
  def is_recruitment_agent_selected
    @user_type_id && @user_type_id == Fs2User::USER_TYPES[:recruitment_agent]
  end
  
  def is_hiring_manager_selected
    @user_type_id && @user_type_id == Fs2User::USER_TYPES[:hiring_manager]
  end
  
  # -------------------- MVP 1 --------------------
  def width_for_additional_skill(skill_name, limit_chars, px_per_char = 8)
    char_count = skill_name.length
    width_in_px = px_per_char * limit_chars
    
    if char_count < limit_chars # good
      width_in_px = char_count * px_per_char
    end
    
    width_in_px
  end 
end

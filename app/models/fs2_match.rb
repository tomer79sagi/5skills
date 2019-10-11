#
# @search_matrix [row][column]
# @result_matrix [row][column]
#

class Fs2Match

  # Arrays 
  attr_accessor :search_matrix, :result_matrix
  attr_accessor :matched_cells
  attr_accessor :pct
  attr_accessor :baseline
   
  def initialize(search_obj, result_obj, baseline)
    # Set the SEARCH cells
    @search_matrix = Array.new
    @result_matrix = Array.new
    
    # {[1] => {
    #  :skill_match => {:keyword_id => 3, :search_cell => [0, 1], :result_cell => [0, 1]}, 
    #  :years_experience => [0, 2], 
    #  :skill_details_matches => {:count => 3}}}
    @matched_cells = {}
    
    @pct = 0
    @baseline = baseline
    
    5.times do |i|
      
      @search_matrix[i] = Array.new
      @search_matrix[i][0] = search_obj[i][0]
      @search_matrix[i][1] = search_obj[i][1]
      @search_matrix[i][2] = search_obj[i][2] # 'details' is already an array
      
      @result_matrix[i] = Array.new
      @result_matrix[i][0] = result_obj[i][0]
      @result_matrix[i][1] = result_obj[i][1]
      @result_matrix[i][2] = result_obj[i][2] if result_obj[i][2] # 'details' is already an array
      
      # @result_matrix[i][2] = result_obj[i][2].values if result_obj[i][2] # 'details' is already an array
          
    end
  end
  
  
  # * Ignore duplicate skill names or details
    
  # SKILL NAME = Total of 10%
  # (R) if 1 of the 2 top skills names matches the other -> 75%
  
  # SKILL NAME EXTRA (up to twice, 1 for top 2, 1 for bottom 3) = Total of 10%
  # (R) if both skill names match  -> 5% on top of the core
  # (R) Ignore if 1-2 skill names ALSO match 3-5 skill names (someone trying to cheat)
  
  # If also 3-5 skills match 3-5 skills -> ?
  # (R) IF remaining 1-2 top skills match 3-5 skills -> ?
  
  # (R) If 1 of the 2 top skill names matches 3-5 skill names -> 50%
  # (R) If 3-5 skills names match 3-5 skill names -> 25%
  
  # SKILL YEARS EXPERIENCE TOTAL = Total of 25% (5 X 5)
  # If years experience not defined in both -> nothing
  # if years experience defined in 1 and not the other -> nothing
  # if years experience defined in 1 and the other with no match -> -5
  # if years experience defined in 1 and the other with match -> +5
  
  # SKILL DETAIL = Total of 25% (CORE, 5 X 5) + 25% (EXTRA, 5 X 5) = 50%
  # if skill details (of skills name match) matches skill details of same skill name (At least one) -> 5%
  # if skill details matches additional 1 (up to 2) skill detail -> 2.5%
  
  # JOB TYPE & LOCATION = Total of 20%
  # if job type matches -> 10%
  # if job location matches -> 10%
  def match
    
    # Identify matching cells, track them
    
    # Match skill names
    i = 0
    
    5.times do |search_row_i|
      5.times do |result_row_i|
        # Match skill name (column = 0)
        match_keyword(i, [search_row_i, 0], [result_row_i, 0])
        
        if match_id_exists?(i)
          
          # Match skill years experience
          match_integer(i, [search_row_i, 1], [result_row_i, 1])
          
          # Match skill details
          match_keyword_array(i, [search_row_i, 2], [result_row_i, 2])
        end
        
        i += 1
      end
    end
    
    # Match additional job-related stuff (job type, job location)
    
    
    # Calculate points
    calc_skill_names([[0, 1], [5, 6]], false, 50, 10)
    calc_skill_names([[2, 3, 4], [7, 8, 9], [10, 15, 20], [11, 16, 21]], (pct > 0), 40, 10) 
    calc_skill_names([[12, 13, 14], [17, 18, 19], [22, 23, 24]], (pct > 0), 30, 10)
    
    calc_additional_attributes({:years_experience_pct => 5, :skill_details_first_pct => 2.5, :skill_details_additional_pct => 1})
    
    # puts "---------- PCT: " + @pct.to_s
        
  end
  
  def calc_additional_attributes(attributes_hash)
    i = 0
    
    5.times do |match_group|
      
      is_years_experience_match = false
      is_skills_experience_match = false
    
      5.times do |match_cell|
        # Calculate years experience
        if !is_years_experience_match && @matched_cells[i] && @matched_cells[i][:years_experience]
          @pct += attributes_hash[:years_experience_pct]
          is_years_experience_match = true
        end
        
        # Calculate skill details
        if !is_skills_experience_match && @matched_cells[i] && @matched_cells[i][:skill_details_matches][:count]
          @pct += attributes_hash[:skill_details_first_pct] if @matched_cells[i][:skill_details_matches][:count] == 1
          @pct += (attributes_hash[:skill_details_additional_pct] * 
            (@matched_cells[i][:skill_details_matches][:count] - 1)) if 
            @matched_cells[i][:skill_details_matches][:count] > 1
          is_skills_experience_match = true
        end
        
        i += 1
      end
    end
  end
  
  # This check is 'OR' based
  def calc_skill_names(match_id_groups_array, prev_type_exists, primary_pct, secondary_pct)
    is_primary_found = false
    primary_pct = 5 if prev_type_exists
    
    match_id_groups_array.each do |match_id_group|
      
      match_id_group.each do |match_id|
        if @matched_cells.has_key?(match_id)
          if !is_primary_found
            @pct += primary_pct
            is_primary_found = true
          else
            @pct += secondary_pct
          end
          
          break
        end
      end
      
    end
  end
  
  # This check is 'OR' based
  def match_id_array_exists?(match_id_array)
    match_id_array.each do |match_id|
      return true if @matched_cells.has_key?(match_id)
    end
  end
  
  def match_integer(match_id, search_cell, result_cell, remove_matching_cells = true)
    return if @search_matrix[search_cell[0]][search_cell[1]].nil? || @result_matrix[result_cell[0]][result_cell[1]].nil?
    
    if (@baseline == 0 && (@result_matrix[result_cell[0]][result_cell[1]].to_i >= @search_matrix[search_cell[0]][search_cell[1]].to_i)) ||
        (@baseline == 1 && (@result_matrix[result_cell[0]][result_cell[1]].to_i <= @search_matrix[search_cell[0]][search_cell[1]].to_i))
        
      @matched_cells[match_id][:years_experience] = [@search_matrix[search_cell[0]][search_cell[1]].to_i, @result_matrix[result_cell[0]][result_cell[1]].to_i]
    
      # Set the matching cells to null (indicating that these cells cannot be used anymore)
      if remove_matching_cells
        @search_matrix[search_cell[0]][search_cell[1]] = -2
        @result_matrix[result_cell[0]][result_cell[1]] = -2
      end
      
    end
  end
  
  def match_keyword_array(match_id, search_cell, result_cell, remove_matching_cells = true)
    return if @search_matrix[search_cell[0]][search_cell[1]].nil? || @result_matrix[result_cell[0]][result_cell[1]].nil?
    
    @matched_cells[match_id][:skill_details_matches] = {:priorities_array => [], :count => 0}
    i = 1
  
    @search_matrix[search_cell[0]][search_cell[1]].each_index do |search_detail_index|
      @result_matrix[result_cell[0]][result_cell[1]].each_index do |result_detail_index|
        
        if @search_matrix[search_cell[0]][search_cell[1]][search_detail_index] == @result_matrix[result_cell[0]][result_cell[1]][result_detail_index] &&
            @search_matrix[search_cell[0]][search_cell[1]][search_detail_index] != -2
          # Add the 'priority' (keyword position in the skill details attribe)
          @matched_cells[match_id][:skill_details_matches][:priorities_array].push(i)
          @matched_cells[match_id][:skill_details_matches][:count] += 1
          
          # Set the matching cells to null (indicating that these cells cannot be used anymore)
          if remove_matching_cells
            @search_matrix[search_cell[0]][search_cell[1]][search_detail_index] = -2
            @result_matrix[result_cell[0]][result_cell[1]][result_detail_index] = -2
          end
        end
        
      end
      
      i += 1
    end
      
  end
  
  def match_keyword(match_id, search_cell, result_cell, remove_matching_cells = true)
    return if (@search_matrix[search_cell[0]][search_cell[1]].nil? || @result_matrix[result_cell[0]][result_cell[1]].nil?) ||
      ((@search_matrix[search_cell[0]][search_cell[1]] && @search_matrix[search_cell[0]][search_cell[1]] == -1) || 
      (@result_matrix[result_cell[0]][result_cell[1]] && @result_matrix[result_cell[0]][result_cell[1]] == -1))
  
    if @search_matrix[search_cell[0]][search_cell[1]] == @result_matrix[result_cell[0]][result_cell[1]] && @search_matrix[search_cell[0]][search_cell[1]] != -2 
      
      # Initialise attributes - After the 1st match is found, initialise the matches
      @matched_cells[match_id] = {:skill_match => nil, :years_experience => nil, :skill_details_matches => {:count => 0}}  
          
      @matched_cells[match_id][:skill_match] = 
        {:keyword_id => @search_matrix[search_cell[0]][search_cell[1]].to_i,
        :search_cell => search_cell,
        :result_cell => result_cell}
      
      # Set the matching cells to null (indicating that these cells cannot be used anymore)
      if remove_matching_cells
        @search_matrix[search_cell[0]][search_cell[1]] = -2
        @result_matrix[result_cell[0]][result_cell[1]] = -2
      end
      
    end      
  end
  
  def old_match_func
    # (R) if 1 of the 2 top skills names matches the other -> 75%
    match_range(1, [[0, 0], [1, 0]], [[0, 0], [1, 0]], 70)
    match_range(2, [[0, 0], [1, 0]], [[0, 0], [1, 0]], 10) if match_id_exists?(1)
    
    if match_exists_at_least_one?([1, 2])
      match_range(4, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
      match_range(5, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 10) if !match_id_exists?(4) # OR with previous statement
    end
    
    
    match_range(3, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 10)
    
    
    if match_id_exists?(1)
      
      # 2nd top 2 skills match
      
      
      # 1st top 2 skills -> bottom 3 skills
      match_range(3, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 10)
      
      # If only 1 top 2 skill names exist
      if !match_id_exists?(2)
        match_range(4, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
        match_range(5, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 10) if !match_id_exists?(4) # OR with previous statement
        
        # 2nd match of top 2 with bottom 3
        if match_id_exists?(4) || match_id_exists?(5)
          match_range(6, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
          match_range(7, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 10) if !match_id_exists?(4) # OR with previous statement
        end
        
        # 3rd match of top 2 with bottom 3 (All match)
        if match_id_exists?(6) || match_id_exists?(7)
          match_range(8, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
          match_range(9, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 10) if !match_id_exists?(4) # OR with previous statement
        end
      end
      
    else
      
      # 1st match of top 2 with bottom 3
      match_range(4, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 50)
      match_range(5, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 50) if !match_id_exists?(4) # OR with previous statement
      
      # 2nd match of top 2 with bottom 3
      if match_id_exists?(4) || match_id_exists?(5)
        match_range(6, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
        match_range(7, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 10) if !match_id_exists?(4) # OR with previous statement
      end
      
      # 3rd match of top 2 with bottom 3 (All match)
      if match_id_exists?(6) || match_id_exists?(7)
        match_range(8, [[0, 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 50)
        match_range(9, [[2, 0], [3, 0], [4, 0]], [[0, 0], [1, 0]], 50) if !match_id_exists?(4) # OR with previous statement
      end
      
    end
    
    # If bottom 3 skills match bottom 3 skills
    # TODO: Create 'matches_exists()' accepting an array of match_ids
    if !match_id_exists?(1) && !match_id_exists?(2) && !match_id_exists?(4) && !match_id_exists?(5)
      # 1st match of top 2 with bottom 3
      match_range(8, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50)
      match_range(9, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50) if !match_id_exists?(4) # OR with previous statement
      
      # 2nd match of top 2 with bottom 3
      if match_id_exists?(4) || match_id_exists?(5)
        match_range(8, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50)
        match_range(9, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50) if !match_id_exists?(4) # OR with previous statement
      end
      
      # 3rd match of top 2 with bottom 3 (All match)
      if match_id_exists?(6) || match_id_exists?(7)
        match_range(8, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50)
        match_range(9, [[2, 0], [3, 0], [4, 0]], [[2, 0], [3, 0], [4, 0]], 50) if !match_id_exists?(4) # OR with previous statement
      end
    end
    
    # Match skill details
    match_range(6, [[get_match_rows_by_match_id(), 0], [1, 0]], [[2, 0], [3, 0], [4, 0]], 10)
  end
  
  def get_match_rows_by_match_id(match_id)
    [matched_cells[match_id]]
  end
  
  def match_id_exists?(match_id)
    @matched_cells.has_key?(match_id)
  end
  
  def match_exists_or?(match_left_id, match_right_id)
    matched_cells.has_key?(match_left_id) || match_right_id
  end
  
  def match_exists_at_least_one?(match_ids = nil)
    return if match_ids
    response = false
    
    match_ids.each do |match_id|
      if match_exists?(match_id)
        response = true
        break
      end
    end
    
    response
  end
  
  def match_range(match_id, search_cell_range, result_cell_range, pct_points, remove_matching_cells = true)
    
    match_found = false
    
    search_cell_range.each do |search_cell|
      
      result_cell_range.each do |result_cell|
        
        puts " ---: SRC[" + search_cell[0].to_s + "][" + search_cell[1].to_s + "] " + 
          @search_matrix[search_cell[0]][search_cell[1]].to_s + 
          " ; TRG[" + result_cell[0].to_s + "][" + result_cell[1].to_s + "] " + 
          @result_matrix[result_cell[0]][result_cell[1]].to_s
        
        next if @search_matrix[search_cell[0]][search_cell[1]].nil? || @result_matrix[result_cell[0]][result_cell[1]].nil?
        
        # 1. Rows 0-4, column 1 -> Skill names
        # 2. Rows 0-4, column 2 -> Skill years experience
      
        if @search_matrix[search_cell[0]][search_cell[1]] == @result_matrix[result_cell[0]][result_cell[1]]
          match_found = true
          @pct += pct_points
          
          @matched_cells[match_id] = [search_cell, result_cell]
          
          # Set the matching cells to null (indicating that these cells cannot be used anymore)
          if remove_matching_cells
            @search_matrix[search_cell[0]][search_cell[1]] = nil
            @result_matrix[result_cell[0]][result_cell[1]] = nil
          end
          
          break
        end
        
        # 3. Rows 0.4, column 3 -> Skill details (array of keywords)
        
      end
      
      break if match_found
      
    end
    
  end
   
  def to_s
    @search_matrix.to_s
  end
  
end

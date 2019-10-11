class Fs2File < ActiveRecord::Base
  
  attr_accessor :fs2_file
  
  ANONYMOUS_SECRET_IDS = {:profile_photo => 105, :company_logo => 105}
  FILE_TYPES = {:cv => 1, :profile_photo => 2, :job_description => 3, :company_logo => 4, :agency_logo => 5, :logo => 6}
  IMAGE_JOB_SEEKER_PLACEHOLDER_SIZES = {:small => "32x32", :medium => "50x50", :large => "168x168"}
  
  PUBLIC_FOLDER = "public/uploads/"
    
  # Validates size of file
  validates_inclusion_of :size, :in => 0..200000,
    :message => 'File exceeds 200kb limit, please upload a smaller file!',
    :unless => :no_file_selected
    
  validates_inclusion_of :extension, 
    :in => %w(jpg jpeg gif png),
    :message => 'File is not an image, use .jpg, .jpeg, .gif or .png files',
    :if => :is_image
    
  def is_image
    [FILE_TYPES[:profile_photo],
      FILE_TYPES[:company_logo],
      FILE_TYPES[:agency_logo],
      FILE_TYPES[:logo]].
        include?(self.file_type)
  end
  
  def no_file_selected
    return self.fs2_file.nil?
  end
  
  def file_type_name
    FILE_TYPES.index(self.file_type)
  end
  
  def image_ratio_resize(s_orig_dimensions, s_desired_dimensions)
    af_orig_dimensions = s_orig_dimensions.split("x").collect {|element| element = element.to_f}
    af_desired_dimensions = s_desired_dimensions.split("x").collect {|element| element = element.to_f}
    ratio = af_orig_dimensions[1] / af_orig_dimensions[0];
    
    if af_orig_dimensions[0] >= af_desired_dimensions[0] && ratio <= 1
      af_orig_dimensions[0] = af_desired_dimensions[0].round;
      af_orig_dimensions[1] = (af_orig_dimensions[0] * ratio).round;
    elsif af_orig_dimensions[1] >= af_desired_dimensions[1]
      af_orig_dimensions[1] = af_desired_dimensions[1].round;
      af_orig_dimensions[0] = (af_orig_dimensions[1] / ratio).round;
    end
    
    af_orig_dimensions.join("x")
  end
  
  def resize_from_s(s_desired_dimensions)
    if self.file_type && is_image && 
        self.original_dimensions && !self.original_dimensions.blank?
      image_ratio_resize(self.original_dimensions, s_desired_dimensions)
    end
  end
  
  def resize_from_i(maxW, maxH)
    resize_from_s(maxW.to_s + "x" + maxH.to_s)
  end
  
  def valid?
    super
    
    if !self.fs2_file
      self.errors.add("fs2_file", "No file was selected!")
      return false
    elsif self.errors && self.errors.length() > 0
      @current_errors_h = Hash.new
      
      self.errors.each {|attr, msg| @current_errors_h[attr] = msg}
      self.errors.clear()
      
      @current_errors_h.each {|key, value| self.errors.add("fs2_file", value)}
      return false
    end
  
    return true
  end
  
  def initialize(file_o)
    super
    
    return if !file_o
    
    self.name = sanitize_filename(file_o['fs2_file'].original_filename)
    directory = PUBLIC_FOLDER
    
    # create the file path
    self.path = File.join(directory, self.name)
    self.mime_type = file_o['fs2_file'].content_type
    
    # write the file
    File.open(self.path, "wb") { |f| f.write(file_o['fs2_file'].read) }
    
    self.extension = File.extname( self.name ).sub( /^\./, '').downcase
    self.size = File.size( self.path )
  end
  
  def delete
    File.delete(PUBLIC_FOLDER + self.name) if self.name && File.exist?(PUBLIC_FOLDER + self.name)
  end
  
  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    
    # replace all none alphanumeric, underscore or perioids
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_') 
  end
  
end

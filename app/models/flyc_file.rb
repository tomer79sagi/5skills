class FlycFile < ActiveRecord::Base
  
  attr_accessor :flyc_file
    
  # Validates size of file
  validates_inclusion_of :size, :in => 0..200000,
    :message => 'File exceeds 200kb limit, please upload a smaller file!',
    :unless => :no_file_selected
  
  def no_file_selected
    return self.flyc_file.nil?
  end
  
  def valid?
    super
    
    if !self.flyc_file
      self.errors.add("flyc_file", "No file was selected!")
      return false
    elsif self.errors && self.errors.length() > 0
      @current_errors_h = Hash.new
      
      self.errors.each {|attr, msg| @current_errors_h[attr] = msg}
      self.errors.clear()
      
      @current_errors_h.each {|key, value| self.errors.add("flyc_file", value)}
      return false
    end
  
    return true
  end
  
  def initialize(file_o)
    super
    
    return if !file_o
    
    self.name = sanitize_filename(file_o['flyc_file'].original_filename)
    directory = "uploads/"
    
    # create the file path
    self.path = File.join(directory, self.name)
    self.mime_type = file_o['flyc_file'].content_type
    
    # write the file
    File.open(self.path, "wb") { |f| f.write(file_o['flyc_file'].read) }
    
    self.extension = File.extname( self.name ).sub( /^\./, '').downcase
    self.size = File.size( self.path )
    # self.uri = "http://localhost:3002/uploads/" + self.name
    self.uri = "http://localhost:3002/files/ASDASDQWEQA231241"
  end
  
  def delete
    File.delete("uploads/" + self.name) if self.name && File.exist?("public/uploads/" + self.name)
  end
  
  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    
    # replace all none alphanumeric, underscore or perioids
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_') 
  end
  
end

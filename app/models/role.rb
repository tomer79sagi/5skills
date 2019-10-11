class Role < ActiveRecord::Base
  # Agent / Company contact association to Agency / Company
  # I have a local foreign_key named 'organisation_id' to find the Organisation I belong to (Agency or Company)
  # (matched remotely to the Organisation's 'id')
  
  has_many :role_applications, :class_name => 'RoleApplication', :foreign_key => "role_id"
  
  belongs_to :agency, :class_name => 'Organisation', :foreign_key => "agency_id" 
  belongs_to :company, :class_name => 'Organisation', :foreign_key => "company_id"
  belongs_to :agent, :class_name => 'Person', :foreign_key => "agent_id"
  
  validates_format_of :type_id,
    :with => /^[1-9]+$/ix,
    :message => "cannot be empty!",  
    :allow_nil => true,
    :allow_blank => true
  
  validates_presence_of :title
  
  validates_format_of :external_link, 
    :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :message => "is not a valid address!",
    :allow_nil => true,
    :allow_blank => true
    
  validates_numericality_of :duration, :salary_min, :salary_max, :message => "must be a number!", :allow_nil => true, :only_integer => true
  
  validates_format_of :salary_frequency_id, 
    :with => /^[1-9]+$/ix,
    :message => "cannot be empty if salary was entered!",
    :if => Proc.new { |role| (!role.salary_min.blank? || !role.salary_max.blank?) }
    
  validates_format_of :duration_type_id, 
    :with => /^[1-9]+$/ix,
    :message => "cannot be empty if duration was entered!",
    :if => Proc.new { |role| (!role.duration.blank?) }
    
  validates_format_of :location_id, 
    :with => /^\d+$/ix,
    :message => "cannot be blank!",
    :allow_nil => true,
    :allow_blank => true
    
  validates_format_of :source_id, 
    :with => /^\d+$/ix,
    :message => "cannot be blank!",
    :allow_nil => true,
    :allow_blank => true
    
  validates_format_of :agency_id, :company_id, 
    :with => /[^-1]/ix,
    :message => "cannot be blank!",
    :allow_nil => true,
    :allow_blank => true
  
  def self.custom_types(user_id)
    @custom_types = CustomType.find_by_sql("select select_value, select_id " + 
      "from custom_types " + 
      "where type_id = " + 1.to_s + " and user_id = " + user_id)
      
    @custom_types.collect {|ct| [ct.select_value, ct.select_id]}
  end
  
  def self.types
      [['Permanent', 1],
      ['Contract', 2],
      ['Fixed Term', 3], 
      ['Part Time', 4], 
      ['Casual', 5]]
  end
  
  def self.sources(user_id = nil)
    @arr = [['Seek.co.nz', 1],
      ['Trademe.co.nz', 2],
      ['Dominion Post', 3], 
      ['Jobs.govt.nz', 4]]
      
    if user_id
      @custom_options_arr = custom_types(user_id.to_s)
      @arr.concat(@custom_options_arr) if @custom_options_arr && !@custom_options_arr.blank?
    end
    
    @arr
  end
  
  def self.salary_types
      [['An Hour', 1],
      ['A Day', 2],
      ['A Week', 3], 
      ['A Fortnight', 4],
      ['A Month', 5],
      ['A Year', 6]]
  end
  
  def self.durations
      [['Days', 1],
      ['Weeks', 2],
      ['Months', 3], 
      ['Years', 4]]
  end
  
  def self.locations
      [['Auckland', 1],
      ['Wellington', 2],
      ['Christchurch', 3], 
      ['North Island - Other', 4],
      
      ['Gisborne', 5],
      ['Hamilton', 6],
      ['Napier - Hastings', 7],
      ['New Plymouth', 8],
      ['Palmerston North', 9],
      ['Rotorua', 10],
      ['Taupo', 11],
      ['Tauranga', 12],
      ['Wanganui', 13],
      ['Whangarei', 14],
      
      ['South Island - Other', 15],
      ['Blenheim', 16],
      ['Dunedin', 17],
      ['Greymouth', 18],
      ['Invercargill', 19],
      ['Nelson', 20],
      ['Queenstown / Wanaka', 21],
      ['Timaru', 22]]
  end
  
  def self.application_statuses
      [['Created', 1],
      ['CV Sent', 2],
      ['Application Sent', 3], 
      ['Shortlisted', 4],
      ['Interview Scheduled', 5],
      ['Waiting Decision', 6],
      ['- Application Rejected', 7],
      ['Offer Made', 8],
      ['Accepted Offer', 9],
      ['- Rejected Offer', 10]]
  end
  
  
  
  def self.types_for_select
    @options = types
    
    [['-- Choose --',0],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3), 
      option(@options, 4), 
      option(@options, 5)]
  end
  
  def self.sources_for_select(user_id)
    @options = sources
    
    # 1. Create the core types
    @options_arr = [['-- N/A --',0],
      ['-- Other --', -2],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3), 
      option(@options, 4)]
    
    # 2. Add the custom types
    @custom_options_arr = custom_types(user_id.to_s)
    
    if @custom_options_arr && !@custom_options_arr.blank? 
      @options_arr.concat([['', -1]])
      @options_arr.concat(@custom_options_arr)
    end
    
    @options_arr
      
  end
  
  def self.salary_types_for_select
    @options = salary_types
    
    [['-- N/A --',0],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3),
      option(@options, 4),
      option(@options, 5),
      option(@options, 6)]
  end
  
  def self.durations_for_select
    @options = durations
    
    [['-- N/A --',0],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3),
      option(@options, 4)]
  end
  
  def self.locations_for_select
    @options = locations
    
    [['-- N/A --',0],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3),
      ['', -1],
      option(@options, 4),
      option(@options, 5, 1),
      option(@options, 6, 1),
      option(@options, 7, 1),
      option(@options, 8, 1),
      option(@options, 9, 1),
      option(@options, 10, 1),
      option(@options, 11, 1),
      option(@options, 12, 1),
      option(@options, 13, 1),
      option(@options, 14, 1),
      ['', -1],
      option(@options, 15),
      option(@options, 16, 1),
      option(@options, 17, 1),
      option(@options, 18, 1),
      option(@options, 19, 1),
      option(@options, 20, 1),
      option(@options, 21, 1),
      option(@options, 22, 1)]
  end
  
  def self.application_statuses_for_select
    @options = application_statuses
    
    [['-- Choose --',0],
      ['', -1],
      option(@options, 1),
      option(@options, 2),
      option(@options, 3),
      ['', -1],
      option(@options, 4),
      option(@options, 5),
      option(@options, 6),
      option(@options, 7),
      ['', -1],
      option(@options, 8),
      option(@options, 9),
      option(@options, 10)]
  end
  
  
  
  def self.option(options_arr, index, indent = 0)
    value = ['', options_arr[index - 1][1]]
    
    indent.times do
      value[0].concat('. ')
    end
    
    value[0].concat((index).to_s + '. ' + options_arr[index - 1][0])
    
    value
  end
  
  def self.type_value(options_arr, type_key)
    # Always ensure the key is an Integer
    type_key = type_key.to_i
    
    if type_key
      value = options_arr.rassoc(type_key)
      value = value[0] if value
    end
    
    value = '' if !value
    
    value
  end
  
end

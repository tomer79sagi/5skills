class AddLinkedinTablesAndColumns < ActiveRecord::Migration
  def self.up
    
    # 1. Add timestamp columns to the 'user connectors' table
    change_table :fs2_user_connectors do |t|
        t.timestamps
    end
    
    
    # ----- CVS
    
    create_table :fs2_cvs do |cv|
      cv.column :job_seeker_id, :int
      
      cv.timestamps
    end   
    
    
    # ----- CV EDUCATIONS
    
    create_table :fs2_cv_educations do |cv_education|
      cv_education.column :cv_id, :int
      cv_education.column :degree, :string
      cv_education.column :field, :string
      cv_education.column :anonymous_education_institute_id, :int
      
      cv_education.timestamps
    end
    
    
    # ----- EDUCATION INSTITUTES
    
    create_table :fs2_education_institutes do |education_institute|
      education_institute.column :linkedin_education_institute_name, :string
      education_institute.column :address_city, :string
      education_institute.column :address_country, :string
      
      education_institute.timestamps
    end
    
    
    # ----- CV POSITIONS
    
    create_table :fs2_cv_positions do |cv_position|
      cv_position.column :cv_id, :int
      cv_position.column :domain, :string # e.g. 'Marketing', 'Web', 'Mobile'
      cv_position.column :anonymous_company_id, :int
      cv_position.column :start_month, :int
      cv_position.column :start_year, :int
      cv_position.column :end_month, :int
      cv_position.column :end_year, :int
      cv_position.column :is_current, :boolean
      
      cv_position.timestamps
    end
    
    
    # ----- ANONOYMOUS COMPANIES
    
    create_table :fs2_anonymous_companies do |anonymous_company|
      anonymous_company.column :real_company_id, :int
      anonymous_company.column :linkedin_company_name, :string
      anonymous_company.column :linkedin_company_id, :int
      anonymous_company.column :type_id, :int # i.e. 'private', 'non-profit', 'enterprise', 'government'
      anonymous_company.column :size_id, :int # i.e. 'start-up', 'small', 'medium', 'large', 'very large'
      anonymous_company.column :market_id, :int # i.e. 'local', 'regional', 'state', 'national', 'multinational'
      anonymous_company.column :industry_id, :int
      
      anonymous_company.column :address_region, :string # 'San Fransisco area', 'Central Israel'
      anonymous_company.column :address_city, :string
      anonymous_company.column :address_country, :string
      
      anonymous_company.timestamps
    end
    
    
    # ----- INDUSTRIES
    
    create_table :fs2_industries do |industry|
      industry.column :name, :string
      
      industry.timestamps
    end
     
  end

  def self.down
    drop_table :fs2_cvs
    drop_table :fs2_cv_educations
    drop_table :fs2_education_institutes
    drop_table :fs2_cv_positions
    drop_table :fs2_anonymous_companies
    drop_table :fs2_industries
    
    remove_column :fs2_user_connectors, :created_at
    remove_column :fs2_user_connectors, :updated_at
  end
end

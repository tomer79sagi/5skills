class Fs2CvsToJobsTransaction < ActiveRecord::Base
  
  STATUS_TYPES = {:cv_requested => 1, :cv_sent => 2, :cv_request_rejected => 3, :cv_request_approved => 4}
  STATUS_TYPE_NAMES = {:cv_requested => "CV requested", :cv_sent => "CV sent", :cv_request_rejected => "CV request rejected", :cv_request_approved => "CV request approved"}
  
  belongs_to :fs2_jobs_seekers, :class_name => 'Fs2JobSeeker', :foreign_key => "job_seeker_id"
  belongs_to :fs2_jobs, :class_name => 'Fs2Job', :foreign_key => "job_id"
  
  def status_name
    STATUS_TYPE_NAMES[STATUS_TYPES.index(self.status_id)]
  end

  def self.get_status_name(s_id)
    STATUS_TYPE_NAMES[STATUS_TYPES.index(s_id.to_i).to_sym]
  end
end

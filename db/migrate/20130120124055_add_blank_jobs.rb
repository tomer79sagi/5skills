class AddBlankJobs < ActiveRecord::Migration
  def self.up
    100.times do |i|
      job = Fs2Job.new({:title => "{blank_" + i.to_s + "}"})
      job.save(false)
      
      fs_profile = Fs2SkillsProfile.new({:entity_id => job.id.to_s, :entity_type => 1, :profile_type => 1})
      fs_profile.save(false)
    end
  end

  def self.down
  end
end

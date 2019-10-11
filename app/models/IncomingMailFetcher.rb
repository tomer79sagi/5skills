class IncomingMailFetcher < ActionMailer::Base
  # email is a TMail::Mail
  def receive(email)
    # Using TMail
    emails = TMail::Mail.parse(email)
    
    puts "To Address: " + emails.to
    
    #email.attachments are TMail::Attachment
    #but they ignore a text/mail parts.
#    email.parts.each_with_index do |part, index|
#      filename = part_filename(part)
#      filename ||= "#{index}.#{ext(part)}"
#      filepath = "#{RAILS_ROOT}/tmp/#{filename}"
#      puts "WRITING: #{filepath}"
#      File.open(filepath,File::CREAT|File::TRUNC|File::WRONLY,0644) do |f|
##        puts(part.body)
#        f.write(part.body)
#      end
#    end

  end

  # part is a TMail::Mail
  def part_filename(part)
    # This is how TMail::Attachment gets a filename
    file_name = (part['content-location'] &&
      part['content-location'].body) ||
      part.sub_header("content-type", "name") ||
      part.sub_header("content-disposition", "filename")
  end

  CTYPE_TO_EXT = {
    'image/jpeg' => 'jpg',
    'image/gif'  => 'gif',
    'image/png'  => 'png',
    'image/tiff' => 'tif'
  }

  def ext( mail )
    CTYPE_TO_EXT[mail.content_type] || 'txt'
  end
end
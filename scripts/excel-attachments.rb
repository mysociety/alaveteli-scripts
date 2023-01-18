# Run using rails runner, EG:
# PUBLIC_BODY_URL_NAME=url_name bin/rails runner excel-attachments.rb
#

unless ENV['PUBLIC_BODY_URL_NAME']
  puts 'Requires PUBLIC_BODY_URL_NAME environment variable'
  exit 1
end

include Rails.application.routes.url_helpers
include LinkToHelper

default_url_options[:host] = AlaveteliConfiguration.domain

pb = PublicBody.find_by!(url_name: ENV['PUBLIC_BODY_URL_NAME'])
all_attachments = FoiAttachment.joins(
  incoming_message: { info_request: [:public_body] }
).where(public_bodies: { id: pb })
attachments_of_interest = all_attachments.where('filename ~* ?', '\.xlsx?$')

# From https://stackoverflow.com/a/59927668
BASE = 1000
ROUND = 3
EXP = {0 => '', 1 => 'k', 2 => 'M', 3 => 'G', 4 => 'T'}
def file_size_humanize(file_size)
  EXP.reverse_each do |exp, char|
    if (num = file_size.to_f / BASE**exp) >= 1
      rounded = num.round ROUND
      n = (rounded - rounded.to_i > 0) ? rounded : rounded.to_i
      return "#{n} #{char}B"
    end
  end
end

attachments_of_interest.each do |attachment|
  embargoed = attachment.incoming_message.info_request.embargo.present?
  print (embargoed ? 'EMBARGOED:' : 'PUBLIC:').ljust(11)
  size = attachment.file.blob.byte_size
  print file_size_humanize(size).rjust(10) + ' '
  puts foi_attachment_url(attachment)
end

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

attachments_of_interest.each do |attachment|
  embargoed = attachment.incoming_message.info_request.embargo.present?
  print embargoed ? 'EMBARGOED: ' : 'PUBLIC   : '
  puts foi_attachment_url(attachment)
end

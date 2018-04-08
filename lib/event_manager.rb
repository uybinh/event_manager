require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
                              address: zip,
                              levels: 'country',
                              roles: ['legislatorUpperBody', 'legislatorLowerBody'])
    legislators = legislators.officials
    legislator_names = legislators.map(&:name).join(', ')
  rescue
    legislator_names = "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def clean_phone_number(phone)
  phone.gsub!(/\.|\(|\)|\s|-/,"")
  if phone.length == 11 && phone[0] == "1"
    phone = phone[1..-1]
  elsif phone.length != 10
    phone = 'Bad number'
  end
  phone
end


def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def parse_date(date_string)
  DateTime.strptime(date_string, "%m/%d/%y %H:%M")
end

def create_array_from_dates(contents, type)
  dates_array = []
  contents.each { |row| dates_array << parse_date(row[:regdate]).send(type) }
  dates_array
end

def dates_frequency(contents, type)
  dates_array = create_array_from_dates(contents, type)
  dates_array.inject({}) do |frequency, ele|
    frequency[ele] ||= 0
    frequency[ele] += 1
    frequency
  end
end

def largest_hash_key(hash)
  hash.max_by { |k,v| v }
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter


# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   phone = clean_phone_number(row[:homephone])
#   reg_hour = parse_date(row[:regdate]).hour
#   puts "#{name} #{phone} #{reg_hour}"

#   # zipcode = clean_zipcode(row[:zipcode])

#   # legislators = legislators_by_zipcode(zipcode)

#   # form_letter = erb_template.result(binding)

#   # save_thank_you_letters(id, form_letter)
# end


frequency = dates_frequency(contents, :wday)
puts frequency

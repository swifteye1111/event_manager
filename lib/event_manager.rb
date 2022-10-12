require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_number)
  phone_number = number_form(phone_number)
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..10]
  else
    'Invalid phone number'
  end
end

def number_form(num)
  num.tr('^0-9', '')
end

def find_optimal_hour(hours)
  hours.max_by { |i| hours.count(i) }
end

def find_optimal_window(hours)
  opt_hour = find_optimal_hour(hours)
  opt_end = opt_hour == 23 ? 0 : opt_hour + 1
  "#{opt_hour}:00 - #{opt_end}:00"
end

def find_optimal_day(days)
  opt_day = days.max_by { |day| days.count(day) }
  Date::DAYNAMES[opt_day]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('../output') unless Dir.exist?('../output')
  filename = "../output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

#template_letter = File.read('../form_letter.erb')
#erb_template = ERB.new template_letter

hours = Array.new
days = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
  #puts clean_phone_numbers(row[:homephone])
  hours.push(Time.strptime(row[:regdate], '%m/%d/%Y %k:%M').hour)
  days.push(Date.strptime(row[:regdate], '%m/%d/%Y').wday)
end

puts "The optimal time is #{find_optimal_window(hours)}."
puts "The optimal day is #{find_optimal_day(days)}."

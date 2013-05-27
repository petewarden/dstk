#!/usr/bin/env ruby

require 'rubygems'

require 'json'

START_YEAR = 1880
END_YEAR = 2080
NUMBER_OF_YEARS = (END_YEAR - START_YEAR)
CURRENT_YEAR = Time.now.year

# What proportion of people born are still alive at each age
# Derived from http://www.cdc.gov/nchs/data/nvsr/nvsr61/nvsr61_03.pdf
SURVIVORS_BY_FIVE_YEARS = [
  1.0,     # 0
  0.99228, # 5
  0.99167, # 10
  0.99089, # 15
  0.98804, # 20
  0.98341, # 25
  0.97863, # 30
  0.97328, # 35
  0.96639, # 40
  0.95602, # 45
  0.93999, # 50
  0.91635, # 55
  0.88356, # 60
  0.83720, # 65
  0.77153, # 70
  0.68006, # 75
  0.55562, # 80
  0.39797, # 85
  0.22347, # 90
  0.08303, # 95
  0.01680, # 100
]
SURVIVORS_STEP = 5.0

def get_survivor_percentage_from_age(age)
  earlier_index = (age / SURVIVORS_STEP).floor
  later_index = (age / SURVIVORS_STEP).ceil
  lerp = (age / SURVIVORS_STEP) - earlier_index
  one_minus_lerp = (1.0 - lerp)
  if (earlier_index < 0) or (earlier_index >= SURVIVORS_BY_FIVE_YEARS.length)
    earlier_value = 0
  else
    earlier_value = SURVIVORS_BY_FIVE_YEARS[earlier_index]
  end
  if (later_index < 0) or (later_index >= SURVIVORS_BY_FIVE_YEARS.length)
    later_value = 0
  else
    later_value = SURVIVORS_BY_FIVE_YEARS[later_index]
  end
  survivor_percentage = (earlier_value * one_minus_lerp) + (later_value * lerp)
  survivor_percentage
end

def output_row(name, male_count, female_count, year_counts, year_percentages)

  count = (male_count + female_count)
  male_percentage = (male_count.to_f / count.to_f) * 100.0

  earliest_year = nil
  latest_year = nil
  running_total = 0
  year_counts.each_with_index do |value, offset_year|
    year = (START_YEAR + offset_year)
    new_running_total = running_total + value
    percentile_05 = (count * 0.05)
    if !earliest_year and
      running_total < percentile_05 and
      new_running_total >= percentile_05
      earliest_year = year
    end
    percentile_95 = (count * 0.95)
    if !latest_year and
      running_total < percentile_95 and
      new_running_total >= percentile_95
      latest_year = year
    end
    running_total = new_running_total
  end

  most_popular_year = nil
  most_popular_percentage = nil
  year_percentages.each_with_index do |percentage, offset_year|
    year = (START_YEAR + offset_year)
    if !most_popular_year or percentage > most_popular_percentage
      most_popular_year = year
      most_popular_percentage = percentage
    end
  end

  puts [
    name,
    count,
    male_percentage,
    most_popular_year,
    earliest_year,
    latest_year,
    '"' + year_percentages.join('_') + '"'
  ].join(',')
end

NAME_INPUT_FOLDER = ARGV[0]

year_totals = Array.new(NUMBER_OF_YEARS, 0)
name_rows = {}

Dir.glob(File.join(NAME_INPUT_FOLDER, 'yob*.txt')) do |filename|
  year = filename.gsub(/.*yob([0-9]+)\.txt/, '\1').to_i
  year_index = (year - START_YEAR)
  File.open(filename).each_line do |line|
    row = line.split(',')
    name = row[0].downcase
    gender = row[1]
    count = row[2].to_i
    year_totals[year_index] += count
    if !name_rows[name] then name_rows[name] = [] end
    name_rows[name] << [gender, count, year]
  end
end

name_rows.each do |name, rows|

  male_count = 0
  female_count = 0
  year_counts = Array.new(NUMBER_OF_YEARS, 0)
  year_percentages = Array.new(NUMBER_OF_YEARS, 0.0)
  rows.each do |row|
    gender = row[0]
    count = row[1]
    year = row[2]
    if gender == 'M'
      male_count += count
    else
      female_count += count
    end
    offset_year = (year - START_YEAR)
    year_counts[offset_year] += count
    year_total = year_totals[offset_year]
    percentage_of_year = (count / year_total.to_f)
    age = CURRENT_YEAR - year
    percentage_of_survivors = get_survivor_percentage_from_age(age)
    year_percentages[offset_year] += (percentage_of_year * percentage_of_survivors)
  end

  output_row(name, male_count, female_count, year_counts, year_percentages)
end


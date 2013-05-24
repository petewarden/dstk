#!/usr/bin/env ruby

require 'rubygems'

require 'json'

START_YEAR = 1880
END_YEAR = 2080
NUMBER_OF_YEARS = (END_YEAR - START_YEAR)

def output_row(name, male_count, female_count, year_counts)

  count = (male_count + female_count)
  male_to_female_ratio = (male_count.to_f / female_count.to_f)

  median_year = nil
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
    percentile_50 = (count * 0.5)
    if !median_year and
      running_total < percentile_50 and
      new_running_total >= percentile_50
      median_year = year
    end
    percentile_95 = (count * 0.95)
    if !latest_year and
      running_total < percentile_95 and
      new_running_total >= percentile_95
      latest_year = year
    end
    running_total = new_running_total
  end

  puts [
    name,
    count,
    male_to_female_ratio,
    median_year,
    earliest_year,
    latest_year,
  ].join(',')
end

previous_name = nil
previous_male_count = 0
previous_female_count = 0
previous_year_counts = Array.new(NUMBER_OF_YEARS, 0)

$stdin.each_line do |line|
  row = line.split(',')
  name = row[0]
  gender = row[1]
  count = row[2].to_i
  filename = row[3]
  year = filename.gsub(/yob([0-9]+)\.txt/, '\1').to_i

  if name != previous_name
    if previous_name
      output_row(previous_name, previous_male_count, previous_female_count, previous_year_counts)
    end
    previous_name = name
    previous_male_count = 0
    previous_female_count = 0
    previous_year_counts = Array.new(NUMBER_OF_YEARS, 0)
  end

  if gender == 'M'
    previous_male_count += count
  else
    previous_female_count += count
  end
  offset_year = (year - START_YEAR)
  previous_year_counts[offset_year] += count
end

output_row(previous_name, previous_male_count, previous_female_count, previous_year_counts)

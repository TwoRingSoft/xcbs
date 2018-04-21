# given the list of "BUILD_SETTING_NAME = value" strings in provided file, sort them by their value portion and output in form "value = BUILD_SETTING_NAME" 
#
# This is a utility to help identify the roots of build setting values to unexpand in other values, thus avoiding generating diffs on different developers' machines. This script is not meant for deployment to users' machines.

keysAndValues = Hash.new

File.open(ARGV[0]).readlines.each do |line|
  mapping = line.split(' = ')
  keysAndValues[mapping[0].strip] = mapping[1].strip
end

keysAndValues.sort_by { |key, value| value }.each { |key, value| puts "#{value} = #{key}" }

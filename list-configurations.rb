# Reading in the output of xcodebuild -list, print just the list of build configurations

started_build_configs = false

build_configs = Array.new

STDIN.read.split("\n").each do |line|
  if started_build_configs then
    if line.strip == '' then
      break
    else
      build_configs << line.strip
    end
  elsif line.strip == 'Build Configurations:' then
    started_build_configs = true
  end
end

build_configs.each do |config|
  puts config
end
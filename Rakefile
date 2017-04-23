require 'bundler/gem_tasks'

task :example do
  sh 'cd docs &&' \
     ' rdoc' \
     " -t 'RDoc::Generator::SolarFish Example'" \
     ' -a' \
     ' -f solarfish' \
     ' -o example_output' \
     ' --sf-htmlfile index.html' \
     ' --sf-jsonfile index.json'
end

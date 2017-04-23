require 'bundler/gem_tasks'

task :example do
  sh 'cd docs &&' \
     ' rdoc' \
     ' -a' \
     ' -f solarfish' \
     ' -o example_html' \
     " -t 'RDoc::Generator::SolarFish Example'"
end

require 'bundler/gem_tasks'

task :example do
  sh 'cd docs &&' \
     ' rdoc' \
     ' -a' \
     ' -f rsinglepage' \
     ' -o example_html' \
     " -t 'RDoc::Generator::RSinglePage Example'"
end

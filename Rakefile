require 'bundler/gem_tasks'

task :sass do
  sh "cd data/rdoc-generator-singlepage/themes/default &&" +
     " sass < styles.sass > styles.css"
end

task :example do
  sh "cd docs &&" +
     " rdoc" +
     " -f rsinglepage" +
     " -o example_html" +
     " -t 'RDoc::Generator::RSinglePage Example'"
end

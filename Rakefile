task :default => [:test]

desc "run tests"
task :test do
  sh "ruby-test -Ilib test/*.rb"
end

desc "convert README to site/readme.html"
task :readme do
  sh "malt README.rdoc > site/readme.html"
end

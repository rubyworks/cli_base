--- 
name: execute
company: RubyWorks
title: Executioner
contact: Trans <transfire@gmail.com>
requires: 
- group: 
  - build
  name: syckle
  version: 0+
- group: 
  - test
  name: qed
  version: 0+
resources: 
  code: http://github.com/rubyworks/executioner
  mail: http://groups.google.com/group/rubyworks-mailinglist
  home: http://rubyworks.github.com/executioner
pom_verison: 1.0.0
manifest: 
- .ruby
- lib/executioner/errors.rb
- lib/executioner/help.rb
- lib/executioner/version.rb
- lib/executioner/version.yml
- lib/executioner.rb
- qed/01_single_command.rdoc
- qed/02_multiple_commands.rdoc
- qed/03_optparse_example.rdoc
- qed/04_help_text.rdoc
- qed/applique/compare.rb
- qed/samples/help.txt
- test/test_executioner.rb
- HISTORY.rdoc
- LICENSE
- README.rdoc
- ROADMAP.rdoc
- VERSION
- EXAMPLE.rdoc
version: 0.4.0
copyright: Copyright (c) 2010 Thomas Sawyer
licenses: 
- Apache 2.0
description: Executioner is an OCM (Object Command Mapper) CLI framework for Ruby. A subclass of the Executioner base class can define a complete command line tool using nothing more than Ruby's own method definitions.
summary: Killer Commandlines
authors: 
- Thomas Sawyer
created: 2008-08-08

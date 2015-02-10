rally-test-results
==================

Experiment : Send junit test results to rally

These scripts are written with Rally REST Toolkit for Ruby. https://github.com/RallyTools/RallyRestToolkitForRuby Code in this repository is available on as-is basis and is not supported by Rally support.

___

Requirements

Ruby (2.x)

Windows : http://rubyinstaller.org/downloads/

Gems

gem install rally_api
gem install nokogiri
gem install markaby

___

To Run

Copy and configure the sample.json file.

Create an api-key go to https://rally1.rallydev.com/login

run with 
'''
ruby rally_test_results.rb <config.json> <build number>
'''



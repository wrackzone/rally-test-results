require 'rubygems'
require 'nokogiri'
require 'rally_api'
require 'markaby'
require 'json'
require 'time'
require 'logger'

# comments TA33
# comments TA33
# comments TA64

class RallyTestResults 

	def initialize configFile,build

		print "Reading config file #{configFile}\n"

		@img_pass = "data:image/gif;base64,R0lGODlhEAAQANUAAPX589bo0LLUpoi+d1iiP2SqTimJCrTWqTuTH/r8+SaFCNvr1iaHBmeiVPf79iyKDcHduHSyYHGmYK3RoUiaLX64a5jGiYu/etjq05GzhUyWM0ubMJvHjKrQnjaNGSeHB+Xx4eDu3EWZKi6KEPz+/E2dMySGBMzMzGZmmf///////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAACoALAAAAAAQABAAAAZ5QJVwSBQeKsWkMGAYKJMihBJFpaYiJkGKSkSlvqmJiQBGdVOn0+LBCKS355SDYhqA4UNvqmHyANIncBwdKl4HJll3cAWJISMmGmiAiyYGECUmHwGKeBeIiBJoW1VmKgkbiAgAZV+lQhgKJhmSW3hEFmR3XEogo1VEQQA7"

		@img_fail = "data:image/gif;base64,R0lGODlhEAAQANUAAPvq6vnh4eBhYc0yMf78/NIaGfrk5P75+dEXFvTJydMgH9tGRsyvr8zKys0JCPrn59UsK/K+vczFxfvt7dYyMdQmJe+sq8yTk8UKDtg4N/fY2OqUk88LCs0ODdk+PfXMzOJqasyJic1AP80aGeygn8kGBuNzc/ne3s1OTc0cG+JtbdMjItYvLttJSdIdHOV5ecwDA8yoqOV8fM0CAczMzP///2Zmmf///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAADcALAAAAAAQABAAAAaFwJtwSCwaj4DMYqiazQTGRQFAJJWetqzNBItkiQnFs1azzGRkG9H2GMxQMcegQauph7baATTjIAJkdms1NAwdMykMNHV3QnknLjNiBQlpawEjMwMSIjMOIYJDBiszf3otThuNNxVOF4t2Wo0QTi+BdpZCLE4edLB5jRROGA+3sUc3slpEQQA7"

		print "Connecting to rally\n"

		print "Running in ", Dir.pwd,"\n"

		# connect to rally.
		#Setting custom headers
		headers = RallyAPI::CustomHttpHeader.new()
		headers.name = "RallyTestResults"
		headers.vendor = "Rally"
		headers.version = "1.0"

		#or one line custom header
		headers = RallyAPI::CustomHttpHeader.new({:vendor => "Vendor", :name => "Custom Name", :version => "1.0"})

		file = File.read(configFile)
		config_hash = JSON.parse(file)

		config = {:base_url => !config_hash["base-url"] ? "https://rally1.rallydev.com/slm" : config_hash["base-url"]}
		if (!config_hash["api-key"] || config_hash["api-key"]==="")
			config[:username]   = config_hash["user"]
			config[:password]   = config_hash["password"]
		else
			config[:api_key]   = config_hash["api-key"] # "_y9sB5fixTWa1V36PTkOS8QOBpQngF0DNvndtpkw05w8"
		end
		config[:workspace] = config_hash["workspace"]
		config[:project]    = config_hash["project"]
		config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()

		@rally = RallyAPI::RallyRestJson.new(config)

		@project = find_project(config[:project])
		@workspace = find_workspace(config[:workspace])
		@build = build
		@resultsPath = config_hash["results-path"]

		print "Project:#{@project["Name"]}\n"

		@logger = Logger.new("rally-test-results.log")

	end

	def find_workspace(name)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "workspace"
		test_query.fetch = "Name,ObjectID"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 1000          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(Name = \"#{name}\")"

		results = @rally.find(test_query)

		return results.first
	end
	
	def find_user(name)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "user"
		test_query.fetch = "UserName,ObjectID"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 1000          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(UserName = \"#{name}\")"

		results = @rally.find(test_query)

		return results.first
	end

	def find_project(name)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "project"
		test_query.fetch = "Name,ObjectID"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 1000          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(Name = \"#{name}\")"

		results = @rally.find(test_query)

		return results.first
	end

	def find_test_set(name)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "testset"
		test_query.fetch = "FormattedID,Name,ObjectID,TestCases"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 10          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(Name = \"#{name}\")"
		test_query.project = @project

		results = @rally.find(test_query)

		return results.first

	end

	def find_test_case(name)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "testcase"
		test_query.fetch = "FormattedID,Name,ObjectID"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 10          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(Name = \"#{name}\")"
		test_query.project = @project

		results = @rally.find(test_query)

		return results.first

	end

	def find_test_case_id(tc_id)

		test_query = RallyAPI::RallyQuery.new()
		test_query.type = "testcase"
		test_query.fetch = "FormattedID,Name,ObjectID"
		test_query.page_size = 200       #optional - default is 200
		test_query.limit = 10          #optional - default is 99999
		test_query.project_scope_up = false
		test_query.project_scope_down = true
		test_query.order = "Name Asc"
		test_query.query_string = "(FormattedID = \"#{tc_id}\")"
		test_query.project = @project

		results = @rally.find(test_query)

		return results.first

	end

	def today8601

		t = Time.now

	end

	def extract_testcaseid_from_name(name)
		if (/.*(TC[0-9]{1,6}).*/ =~ name)
			$1
		else 
			nil
		end
	end

	def process_file rb_file

			xmldoc = Nokogiri::XML(File.open(rb_file))
		
			xp = "//testsuite"


			xmldoc.xpath(xp).each { |ts| 
				# TODO: timestamp="10 Feb 2015 19:21:53 GMT"
				timestamp = ts.at_xpath("@timestamp") ? ts.at_xpath("@timestamp").value : today8601
				# print "Timestamp: #{timestamp}\n"
				verdict = true
				
				tc_name =  ts.at_xpath("@name").value
				tc_id = extract_testcaseid_from_name(tc_name)

				if !tc_id
					@logger.error("No Rally Test Case ID found in : #{tc_name}")
					next 
				end

				# rally_tc = find_test_case(tc_name)
				rally_tc = find_test_case_id(tc_id)
				
				if (rally_tc)
					print "#{rally_tc["FormattedID"]}:#{rally_tc["Name"]}\n"
				else
					print "Not found:#{tc_name}\ncreating...\n"
					@logger.error("Test Case ID not found : #{tc_id}")
					next
					# rally_tc = @rally.create("testcase", {
					# 	"Workspace" => @workspace,
					# 	"Project" => @project,
					# 	"Name" => tc_name	
					# })
					# print "Created:#{rally_tc["FormattedID"]}\n"
				end

				mab = Markaby::Builder.new
  				mab.table do
  					tr do
  						td "Test Case"
  						td "Status"
  						td "Message"
  					end

					ts.xpath("testcase").each { |tc|
						tr do
							td tc.at_xpath("@name").value
							if tc.at_xpath("failure")
								td do
									img :src => "data:image/gif;base64,R0lGODlhEAAQANUAAPvq6vnh4eBhYc0yMf78/NIaGfrk5P75+dEXFvTJydMgH9tGRsyvr8zKys0JCPrn59UsK/K+vczFxfvt7dYyMdQmJe+sq8yTk8UKDtg4N/fY2OqUk88LCs0ODdk+PfXMzOJqasyJic1AP80aGeygn8kGBuNzc/ne3s1OTc0cG+JtbdMjItYvLttJSdIdHOV5ecwDA8yoqOV8fM0CAczMzP///2Zmmf///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAADcALAAAAAAQABAAAAaFwJtwSCwaj4DMYqiazQTGRQFAJJWetqzNBItkiQnFs1azzGRkG9H2GMxQMcegQauph7baATTjIAJkdms1NAwdMykMNHV3QnknLjNiBQlpawEjMwMSIjMOIYJDBiszf3otThuNNxVOF4t2Wo0QTi+BdpZCLE4edLB5jRROGA+3sUc3slpEQQA7"
								end
							else
								td do
									img :src => "data:image/gif;base64,R0lGODlhEAAQANUAAPX589bo0LLUpoi+d1iiP2SqTimJCrTWqTuTH/r8+SaFCNvr1iaHBmeiVPf79iyKDcHduHSyYHGmYK3RoUiaLX64a5jGiYu/etjq05GzhUyWM0ubMJvHjKrQnjaNGSeHB+Xx4eDu3EWZKi6KEPz+/E2dMySGBMzMzGZmmf///////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAACoALAAAAAAQABAAAAZ5QJVwSBQeKsWkMGAYKJMihBJFpaYiJkGKSkSlvqmJiQBGdVOn0+LBCKS355SDYhqA4UNvqmHyANIncBwdKl4HJll3cAWJISMmGmiAiyYGECUmHwGKeBeIiBJoW1VmKgkbiAgAZV+lQhgKJhmSW3hEFmR3XEogo1VEQQA7"
								end
							end
							if tc.at_xpath("failure")
								verdict = false
								msg = ""
								tc.xpath("failure").each { |failure|
									msg+=failure.inner_text
								}
								td msg
							else
								td ""
							end
						end
					}
    			end
    			# print mab.to_s

    			# create verdict
    			tcr = @rally.create("testcaseresults", {
    				"Build" => @build,
    				"Verdict" => (verdict ? "Pass" : "Fail"),
    				"TestCase" => rally_tc,
    				"Notes" => mab.to_s,
    				# "Date" => "2008-01-29T23:29:19.000Z"
    				"Date" => timestamp
    			})

				# ts.xpath("testcase").each { |tc|
				# 	print tc.at_xpath("@name"),"\n"

				# 	if tc.at_xpath("failure")
				# 		puts tc.children.size
				# 	end
				# }

			}
	end

	def run
		# iterate the xml files
		# Dir.glob('Sample/junit/*.xml') do |rb_file|
		# print "looking for xml files in : ", @resultsPath,"\n"
		# Dir.glob(@resultsPath+"/*.xml") do |rb_file|
		Dir.glob(@resultsPath+"/**/*.xml") do |rb_file|
			print "\nProcessing:",rb_file,"\n"
			process_file (rb_file)
		end
	end

	def create_defect

		user = find_user("test@rallydev.com")

		print ("user:#{user}\n")

		tcr = @rally.create("defect", {
    				"Name" => "My Defect with no permission user",
    				"Project" => @project,
    				"Workspace" => @workspace,
    				"Owner" => user
		})

		print ("defect:#{tcr["FormattedID"]}\n")

	end

	def find_and_update_testset

		ts = find_test_set("Firefox Browser Tests")

		print "TestSet:#{ts["FormattedID"]} #{ts["TestCases"].length}\n"

		tc = @rally.create("testcase", {
    				"Name" => "TestCase #{ts["TestCases"].length+1}",
    				"Project" => @project,
    				"Workspace" => @workspace
		})

		print "TestSet:#{tc["FormattedID"]} #{tc["Name"]}\n"

		ts["TestCases"].push(tc)

		ts.update( {
			"TestCases" => ts["TestCases"]
		})
		

	end


end

rtr = RallyTestResults.new ARGV[0],ARGV[1]

rtr.today8601
rtr.run



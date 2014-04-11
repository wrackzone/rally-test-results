require 'rubygems'
require 'nokogiri'
require 'rally_api'
require 'markaby'

class RallyTestResults 

	def initialize build

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

		config = {:base_url => "https://demo01.rallydev.com/slm"}
		config[:username]   = ""
		config[:password]   = ""
		config[:workspace]  = ""
		config[:project]    = ""
		config[:headers]    = headers #from RallyAPI::CustomHttpHeader.new()

		@rally = RallyAPI::RallyRestJson.new(config)

		@project = find_project(config[:project])
		@workspace = find_workspace(config[:workspace])
		@build = build

		print "Project:#{@project["Name"]}\n"

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

	def process_file rb_file

			xmldoc = Nokogiri::XML(File.open(rb_file))
		
			xp = "//testsuite"


			xmldoc.xpath(xp).each { |ts| 
				verdict = true
				tc_name =  ts.at_xpath("@name").value

				rally_tc = find_test_case(tc_name)
				if (rally_tc)
					print "#{rally_tc["FormattedID"]}:#{rally_tc["Name"]}\n"
				else
					print "Not found:#{tc_name}\ncreating...\n"
					rally_tc = @rally.create("testcase", {
						"Workspace" => @workspace,
						"Project" => @project,
						"Name" => tc_name	
					})
					print "Created:#{rally_tc["FormattedID"]}\n"
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
    			#print mab.to_s

    			# create verdict
    			tcr = @rally.create("testcaseresults", {
    				"Build" => @build,
    				"Verdict" => (verdict ? "Pass" : "Fail"),
    				"TestCase" => rally_tc,
    				"Notes" => mab.to_s,
    				"Date" => "2008-01-29T23:29:19.000Z"
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
		Dir.glob('Sample/junit/*.xml') do |rb_file|
			print rb_file,"\n"
			process_file (rb_file)
		end
	end


end

rtr = RallyTestResults.new ARGV[0]
rtr.run


require 'nokogiri' 

class SofortDetail
	include PayDetailable
	attr_accessor :country,:amount,:description,:currency,:order_no,:success_url

	SPEC_PARAMS_COUNTRY=%w(de nl)
	#PAY_SOFORT_PARAMS=%w{country currency order_no amount success_url notification_url abort_url timeout_url}
	def initialize(online_pay)
		if !payparams_valid("sofort",online_pay) ||  !spec_payparams_valid(online_pay)
			raise "sofort payparams valid failure!!"
		end

		define_var("sofort",online_pay)
	end

	def submit
		xbuilder = Builder::XmlMarkup.new(:target => xstr = "<?xml version='1.0' encoding='UTF-8'?>\n", :indent =>1)

		xbuilder.multipay {
			if @country == "de" 
				xbuilder.project_id Settings.sofort.project_id_de
			elsif @country == "nl"
				xbuilder.project_id Settings.sofort.project_id_nl
			end

			xbuilder.amount @amount
			xbuilder.currency_code @currency
			xbuilder.reasons {
				xbuilder.reason @order_no
			}
			#sofort success url  redirect_to   self.webpage
			#xbuilder.success_url Settings.sofort.success_url
			xbuilder.success_url @success_url
			xbuilder.success_link_redirect "true"
			xbuilder.abort_url Settings.sofort.abort_url
			xbuilder.timeout_url Settings.sofort.timeout_url
			if !Settings.sofort.notification_url.blank?
				xbuilder.notification_urls {
					xbuilder.notification_url Settings.sofort.notification_url
				}
			end
			if !Settings.sofort.notification_email.blank?
				xbuilder.notification_emails {
					xbuilder.notification_email Settings.sofort.notification_email
				}
			end
			xbuilder.su {
				xbuilder.customer_protection "0"
			}
		}
		Rails.logger.info "request xml: " + xstr
		http,req = httpinit(@country)
		req.body = xstr
		begin
			Rails.logger.info("request sofort pay!")
			res = http.request(req)
		rescue => e
			["failure","","","","request sofort pay failure:#{e.message}"]
		end

		redirect_url=''
		trade_no=''
		message=''
		if res.code == "200"
			doc = Nokogiri::XML(res.body.force_encoding("UTF-8"))
			if (doc.xpath("//errors/error").size == 0)
				redirect_url=doc.xpath("//new_transaction/payment_url").text
				trade_no=doc.xpath("//new_transaction/transaction").text
			else
				message=doc.xpath("//errors/error/message").first.text+":"+doc.xpath("//errors/error/field").first.text 
				Rails.logger.info ("Response.body:#{res.body.force_encoding("UTF-8")}")
			end
		else
			Rails.logger.info ("Response.body:#{res.body.force_encoding("UTF-8")}")
			message="request sofort pay failure:#{res.code}"
		end

		unless(redirect_url.blank?)
			["success",redirect_url,trade_no,"false",message]
		else
			["failure","","","",message]
		end
	end

	def identify_transaction(trade_no,country)
		identify_status=""
		identify_status_reason=""
		xbuilder = Builder::XmlMarkup.new(:target => xstr = "<?xml version='1.0' encoding='UTF-8'?>\n", :indent =>1)

		xbuilder.transaction_request("version" => "2") {
			xbuilder.transaction trade_no
		}

		http,req = httpinit(country)
		req.body = xstr
		begin
			res = http.request(req)
		rescue => e
			identify_status_reason=e.message
			[identify_status,identify_status_reason] and return
		end

		if res.code == "200"
			doc = Nokogiri::XML(res.body.force_encoding("UTF-8"))
			if doc.xpath("//errors/error").size == 0
				transaction_no = doc.xpath("//transactions/transaction_details/transaction").text
				test_mode = doc.xpath("//transactions/transaction_details/test").text
				status = doc.xpath("//transactions/transaction_details/status").text
				status_reason = doc.xpath("//transactions/transaction_details/status_reason").text
				amount = doc.xpath("//transactions/transaction_details/amount").text

				if(trade_no==transaction_no)
					identify_status=status
					identify_status_reason=status_reason
				else
					identify_status_reason="not match:online_pay.#{trade_no} <=> response.#{transaction_no}"
				end
			else
				identify_status_reason=doc.xpath("//errors/error/message").first.text + doc.xpath("//errors/error/field").first.text
			end
		else
			identify_status_reason="identify sofort pay failure:#{res.code}"
		end

		[identify_status,identify_status_reason] 
	end

	private 
		def spec_payparams_valid(online_pay)
			errmsg=''
			if(online_pay['currency']!="EUR")
				errmsg="sofort.currency must be 'EUR'"
				Rails.logger.info(errmsg)
			elsif( !SPEC_PARAMS_COUNTRY.include?(online_pay['country']) )
				errmsg="sofort.country must in #{SPEC_PARAMS_COUNTRY}"
				Rails.logger.info(errmsg)
			end

			if errmsg.blank?
				true
			else
				false
			end
		end


		def httpinit(country)
			uri = URI.parse(Settings.sofort.sofort_api_uri)

			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl =  uri.scheme == 'https'
			req = Net::HTTP::Post.new(uri.path)
			req.content_type = "application/xml; charset=UTF-8"
			if country == "de"
				req.basic_auth Settings.sofort.customer_number_de,Settings.sofort.api_key_de
			elsif country == "nl"
				req.basic_auth Settings.sofort.customer_number_nl,Settings.sofort.api_key_nl
			end
			[http,req]
		end
end
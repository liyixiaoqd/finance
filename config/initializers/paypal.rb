ActiveMerchant::Billing::Base.mode = Settings.paypal.mode
paypal_options_de = {
  :login => Settings.paypal.login_de,
  :password => Settings.paypal.password_de,
  :signature => Settings.paypal.signature_de
}
paypal_options_nl = {
  :login => Settings.paypal.login_nl,
  :password => Settings.paypal.password_nl,
  :signature => Settings.paypal.signature_nl
}
paypal_options_gb = {
  :login => Settings.paypal.login_gb,
  :password => Settings.paypal.password_gb,
  :signature => Settings.paypal.signature_gb
}
paypal_options_at = {
  :login => Settings.paypal.login_at,
  :password => Settings.paypal.password_at,
  :signature => Settings.paypal.signature_at
}
paypal_options_de_pm = {
  :login => Settings.paypal.login_de_pm,
  :password => Settings.paypal.password_de_pm,
  :signature => Settings.paypal.signature_de_pm
}
paypal_options_nl_pm = {
  :login => Settings.paypal.login_nl_pm,
  :password => Settings.paypal.password_nl_pm,
  :signature => Settings.paypal.signature_nl_pm
}
#::STANDARD_GATEWAY_DE = ActiveMerchant::Billing::PaypalGateway.new(paypal_options_de)
::EXPRESS_GATEWAY_DE = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_de)

#::STANDARD_GATEWAY_NL = ActiveMerchant::Billing::PaypalGateway.new(paypal_options_nl)
::EXPRESS_GATEWAY_NL = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_nl)

#::STANDARD_GATEWAY_GB = ActiveMerchant::Billing::PaypalGateway.new(paypal_options_gb)
::EXPRESS_GATEWAY_GB = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_gb)

#::STANDARD_GATEWAY_GB = ActiveMerchant::Billing::PaypalGateway.new(paypal_options_gb)
::EXPRESS_GATEWAY_AT = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_at)

#DE -  Package material 
::EXPRESS_GATEWAY_DE_PM = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_de_pm)

#NL -  Package material 
::EXPRESS_GATEWAY_NL_PM = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options_nl_pm)
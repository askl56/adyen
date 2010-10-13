require 'adyen/api/simple_soap_client'
require 'adyen/api/payment_service'
require 'adyen/api/recurring_service'

module Adyen
  # The API module contains classes that interact with the Adyen SOAP API.
  #
  # You'll need to provide a username and password to interact with Adyen:
  #
  #     Adyen::API.username = 'ws@Company.MyAccount'
  #     Adyen::API.password = 'secret'
  #
  # Furthermore, you can setup default parameters, that will be used by every
  # API call, by using {Adyen::API.default_arguments}.
  #
  # The following classes, which handle the SOAP services, are available:
  #
  # * {PaymentService}   - for authorisation of, and modification to, payments.
  # * {RecurringService} - for handling recurring contract details.
  #
  # *However*, direct use of these classes is discouraged in favor of the
  # shortcut methods defined on the API module. These methods do expect that you set the :merchant_account as a :default_param.
  #
  # Note that you'll need an Adyen notification PSP reference for some of the
  # calls. Because of this, store all notifications that Adyen sends to you.
  # (e.g. using the {Adyen::Notification} ActiveRecord class). Moreover, these
  # calls do *not* tell you whether or not the requested action was successful.
  # For this you will have to check the notification that will be sent.
  #
  # = Authorising payments
  #
  # To authorise payments, not recurring ones, the customers payment details
  # will have to pass through your application and infrastucture. Because of
  # this you will have to contact Adyen and provide the necessary paperwork
  # which says that you’re PCI DSS compliant.
  #
  # Unless you are going to process over twenty thousand payments anually, the
  # PCI DSS Self-Assessment Questionnaire (SAQ) type A will probably suffice.
  #
  # @see http://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard
  # @see https://www.pcisecuritystandards.org/saq/instructions_dss.shtml
  # @see http://usa.visa.com/merchants/risk_management/cisp_merchants.html
  module API
    class << self
      # The username that’s used to authenticate for the Adyen SOAP services.
      # It should look something like +ws@Company.MyAccount+
      # @return [String]
      attr_accessor :username

      # The password that’s used to authenticate for the Adyen SOAP services.
      # You can configure it in the user management tool of the merchant area.
      # @return [String]
      attr_accessor :password

      # Default arguments that will be used for every API call. You can override these default
      # values by passing a diffferent value to the service class’s constructor.
      #
      # @example
      #   Adyen::API.default_arguments[:merchant_account] = 'MyMerchant'
      #
      # @return [Hash]
      attr_accessor :default_params
      @default_params = {}

      # Authorise a new (regular) creditcard payment.
      #
      # Of all arguments, only the shopper’s IP address is optional. But since it’s used in
      # various risk checks, it’s a good idea to supply it anyway.
      #
      # @example
      #   response = Adyen::API.authorise_payment(
      #     invoice.id,
      #     { :currency => 'EUR', :value => invoice.amount },
      #     { :reference => user.id, :email => user.email, :ip => '8.8.8.8' },
      #     { :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737', :expiry_month => 12, :expiry_year => 2012 }
      #   )
      #   response.authorised? # => true
      #
      # @param          [Numeric,String] reference      Your reference (ID) for this payment.
      # @param          [Hash]           amount         A hash describing the money to charge.
      # @param          [Hash]           shopper        A hash describing the shopper.
      # @param          [Hash]           card           A hash describing the creditcard details.
      #
      # @option amount  [String]         :currency      The ISO currency code (EUR, GBP, USD, etc).
      # @option amount  [Integer]        :value         The value of the payment in discrete cents,
      #                                                 unless the currency does not have cents.
      #
      # @option shopper [Numeric,String] :reference     The shopper’s reference (ID).
      # @option shopper [String]         :email         The shopper’s email address.
      # @option shopper [String]         :ip            The shopper’s IP address.
      #
      # @option card    [String]         :holder_name   The full name on the card.
      # @option card    [String]         :number        The card number.
      # @option card    [String]         :cvc           The card’s verification code.
      # @option card    [Numeric,String] :expiry_month  The month in which the card expires.
      # @option card    [Numeric,String] :expiry_year   The year in which the card expires.
      #
      # @param [Boolean] enable_recurring_contract      Store the payment details at Adyen for
      #                                                 future recurring or one-click payments.
      #
      # @return [PaymentService::AuthorizationResponse] The response object which holds the
      #                                                 authorisation status.
      def authorise_payment(reference, amount, shopper, card, enable_recurring_contract = false)
        PaymentService.new(
          :reference => reference,
          :amount    => amount,
          :shopper   => shopper,
          :card      => card,
          :recurring => enable_recurring_contract
        ).authorise_payment
      end

      def authorise_recurring_payment(reference, amount, shopper, recurring_detail_reference = nil)
        PaymentService.new(
          :reference => reference,
          :amount    => amount,
          :shopper   => shopper,
          :recurring_detail_reference => recurring_detail_reference
        ).authorise_recurring_payment
      end

      def authorise_one_click_payment(reference, amount, shopper, card_cvc, recurring_detail_reference = nil)
        PaymentService.new(
          :reference => reference,
          :amount    => amount,
          :shopper   => shopper,
          :card      => { :cvc => card_cvc },
          :recurring_detail_reference => recurring_detail_reference
        ).authorise_one_click_payment
      end

      # Capture an authorised payment.
      #
      # Note that the response of this request will only indicate whether or
      # not the request has been successfuly received. Check the notitification
      # for the actual mutation status.
      #
      # @param [String] psp_reference  The PSP reference, from Adyen, of the
      #                                previously authorised request.
      # @param [String] currency       The ISO currency code. E.g. ‘EUR’.
      # @param [Numeric, String] value The value of the payment in cents, if
      #                                the currency type has cents.
      #
      # @return [PaymentService::CaptureResponse] The response object.
      def capture_payment(psp_reference, amount)
        PaymentService.new(:psp_reference => psp_reference, :amount => amount).capture
      end

      # Refund a payment.
      #
      # Note that the response of this request will only indicate whether or
      # not the request has been successfuly received. Check the notitification
      # for the actual mutation status.
      #
      # @param [String] psp_reference  The PSP reference, from Adyen, of the
      #                                previously authorised request.
      # @param [String] currency       The ISO currency code. E.g. ‘EUR’.
      # @param [Numeric, String] value The value of the payment in cents, if
      #                                the currency type has cents.
      #
      # @return [PaymentService::RefundResponse] The response object.
      def refund_payment(psp_reference, amount)
        PaymentService.new(:psp_reference => psp_reference, :amount => amount).refund
      end

      # Cancel or refund a payment. Use this if you wnat to cancel or refund
      # the payment, but are unsure what the current status is.
      #
      # Note that the response of this request will only indicate whether or
      # not the request has been successfuly received. Check the notitification
      # for the actual mutation status.
      #
      # @param [String] psp_reference  The PSP reference, from Adyen, of the
      #                                previously authorised request.
      # @param [String] currency       The ISO currency code. E.g. ‘EUR’.
      # @param [Numeric, String] value The value of the payment in cents, if
      #                                the currency type has cents.
      #
      # @return [PaymentService::CancelOrRefundResponse] The response object.
      def cancel_or_refund_payment(psp_reference)
        PaymentService.new(:psp_reference => psp_reference).cancel_or_refund
      end

      # Cancel an authorised payment.
      #
      # Note that the response of this request will only indicate whether or
      # not the request has been successfuly received. Check the notitification
      # for the actual mutation status.
      #
      # @param [String] psp_reference  The PSP reference, from Adyen, of the
      #                                previously authorised request.
      # @param [String] currency       The ISO currency code. E.g. ‘EUR’.
      # @param [Numeric, String] value The value of the payment in cents, if
      #                                the currency type has cents.
      #
      # @return [PaymentService::CancelResponse] The response object.
      def cancel_payment(psp_reference)
        PaymentService.new(:psp_reference => psp_reference).cancel
      end

      # Retrieve the recurring contract details for a shopper.
      #
      # @param [String] shopper_reference The ID used to store payment details
      #                                   for this shopper.
      #
      # @return [RecurringService::ListResponse] The response object.
      def list_recurring_details(shopper_reference)
        RecurringService.new(:shopper => { :reference => shopper_reference }).list
      end

      # Disable the recurring contract details for a shopper.
      #
      # @param [String] shopper_reference     The ID used to store payment
      #                                       details for this shopper.
      # @param [String, nil] detail_reference The ID of a specific recurring
      #                                       contract. Defaults to all.
      #
      # @return [RecurringService::DisableResponse] The response object.
      def disable_recurring_contract(shopper_reference, detail_reference = nil)
        RecurringService.new({
          :shopper => { :reference => shopper_reference },
          :recurring_detail_reference => detail_reference
        }).disable
      end
    end
  end
end

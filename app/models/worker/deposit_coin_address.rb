module Worker
  class DepositCoinAddress

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      payment_address = PaymentAddress.find payload[:payment_address_id]
      return if payment_address.address.present?
      address = ""
      private_key = ""
      currency = payload[:currency]
      if currency == 'eth'
        address, private_key = Web3T.get_new_address
      else
        address  = CoinRPC[currency].getnewaddress("payment")
      end

      if payment_address.update_attributes("address": address, "private_key": private_key)
        ::Pusher["private-#{payment_address.account.member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: payment_address.as_json})
      end
    end

  end
end

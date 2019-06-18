class Web3T
    @currency = Currency.find_by_code("eth")
    @web3 = Web3::Eth::Rpc.new host: @currency.rpc,
      port: 443,
      connect_options: {
        open_timeout: 20,
        read_timeout: 140,
        use_ssl: true,
        rpc_path: @currency.rpc_key
      }
    def self.get_new_address
        key = Eth::Key.new
        [key.address, key.private_hex]
    end
    def self.get_balance(address)
        @web3.eth.getBalance(address)
    end

    def self.get_block_number
        @web3.eth.blockNumber
    end
    
    def self.get_block_by_number(block_number)
        @web3.eth.getBlockByNumber(block_number)
    end

    def self.get_transaction_by_hash(txid)
        @web3.eth.getTransactionByHash(txid)
    end
    # def self.send_token(address, amount)
    #   key = Eth::Key.new priv: ENV['ETHEREUM_WALLET_PRIVATEKEY']
    #   pending_cnt = @web3.eth.getTransactionCount([key.address,"pending"]).to_i(16)
    #   data = abi_encode \
    #       'transfer(address,uint256)',
    #       address.downcase,
    #       '0x' + (amount * 10 ** ENV['AIBE_DECIMAL'].to_i).to_i.to_s(16)
    #   tx = Eth::Tx.new({
    #       value: 0,
    #       gas_limit: 100_000,
    #       gas_price: 10_000_000_000,
    #       nonce: pending_cnt,
    #       to: ENV['AIBE_TOKEN_CONTRACT_ADDRESS'],
    #       data: data
    #     })
    #   tx.sign key
    #   @web3.eth.sendRawTransaction([tx.hex])
    #   tx.hash
    # end
  
    def self.abi_encode(method, *args)
      '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
        data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
      end
    end
  
    def self.send_eth(sender_private_key, receiver_address, amount, internal = false)
      key = Eth::Key.new priv: sender_private_key
      pending_cnt = @web3.eth.getTransactionCount([key.address,"pending"]).to_i(16)
      gas_limit = 21_000
      gas_price = 10_000_000_000
      if internal 
        wei_amount = (amount * 10 ** 18).to_i - gas_limit * gas_price
      else
        wei_amount = (amount * 10 ** 18).to_i
      end
      tx = Eth::Tx.new({
          value: wei_amount,
          gas_limit: gas_limit,
          gas_price: gas_price,
          nonce: pending_cnt,
          to: receiver_address,
          data:""
        })
      tx.sign key
      @web3.eth.sendRawTransaction([tx.hex])
      return tx.hash
    end
  end
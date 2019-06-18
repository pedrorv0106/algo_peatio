
class Blockchain < ActiveRecord::Base
    # has_many :currencies, foreign_key: :blockchain_key, primary_key: :key
    # has_many :wallets, foreign_key: :blockchain_key, primary_key: :key
    def process_blockchain(blocks_limit: 250, force: false)
    
    latest_block = Web3T.get_block_number
    Rails.logger.info { "Latest Block: #{latest_block}, #{latest_block.to_i}"}
    if self.height >= latest_block.to_i && !force
        Rails.logger.info { "Skip synchronization. No new blocks detected height: #{self.height}, latest_block: #{latest_block}" }
        return
    end
    from_block   = self.height || 0
    to_block     = [latest_block.to_i, from_block + blocks_limit].min
    c = Currency.find_by_code('eth')
    payment_addresses = PaymentAddress.where('currency = ?', c.id)
    (from_block..to_block).each do |block_id|
        block_json = Web3T.get_block_by_number(block_id)
        next if block_json.blank? || block_json.transactions.blank?
        deposit_txids = build_deposits(block_json, payment_addresses, c)
        deposit_txids.each do |txid|
            AMQPQueue.enqueue(:deposit_coin, txid: txid, channel_key: "ether")
        end

        Rails.logger.info { "Finished processing in block number #{block_id}." }
    end
    self.update(height: to_block + 1)
    
    end
    def build_deposits(block_json, payment_addresses, c)
        deposit_txids = Array[]
        block_json.transactions.each do |block_txn|
            payment_addresses.each do |payment_address|
                if payment_address.address.present? && block_txn.to.present? && block_txn.to.downcase == payment_address.address.downcase && block_txn.to.downcase != c.main_address
                    deposit_txids.push(block_txn.hash)
                end
            end
        end
        deposit_txids
    end
end
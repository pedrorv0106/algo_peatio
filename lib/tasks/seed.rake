# encoding: UTF-8
# frozen_string_literal: true
require 'yaml'

namespace :seed do
  task blockchains: :environment do  
    Blockchain.transaction do
      blockchain = Blockchain.find_by_key("eth")
      if blockchain.blank?
        blockchain = Blockchain.create!("key":"eth", "status":"active", "height":5817659)
      else
        blockchain.key = "eth"
        blockchain.status = "active"
        blockchain.height = 5817659
        blockchain.save!
      end
    end
  end
end

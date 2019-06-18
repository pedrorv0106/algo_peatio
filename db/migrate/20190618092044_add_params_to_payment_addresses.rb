class AddParamsToPaymentAddresses < ActiveRecord::Migration
  def change
    add_column :payment_addresses, :private_key, :string
  end
end

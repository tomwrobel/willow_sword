module WillowSword
  module FetchData
    extend ActiveSupport::Concern
    include WillowSword::MultipartDeposit
    include WillowSword::AtomEntryDeposit
    include WillowSword::BinaryDeposit
    include WillowSword::ProcessDeposit
    include WillowSword::SaveData
  end
end

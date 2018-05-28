module WillowSword
  module AtomEntryDeposit

    private
    def atom_entry_not_supported
      message = 'Server does not support atom entry content types'
      @error = WillowSword::Error.new(message, type = :method_not_allowed)
      false
    end

    def validate_atom_entry
      puts 'atom-entry'
      true
    end

  end
end

module ModsToModel
  def assign_mods_to_model
    # deep copy metadata
    @mapped_metadata = Marshal.load(Marshal.dump(@metadata))
  end
end

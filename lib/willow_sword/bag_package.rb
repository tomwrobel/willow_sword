require 'bagit'
require 'pathname'

module WillowSword
  class BagPackage
    # Class to create a bag for a given source and at the given destination,
    # if the source isn't already a bag.

    attr_reader :package

    def initialize(src, dst)
      @src = src
      @dst = dst
      @src = File.join(src, '/') if File.directory?(src)
      @dst = File.join(dst, '/') if File.directory?(dst)
      @package = nil
      assign_package
    end

    def create_bag
      source_path = Pathname.new(@src)
      source_path.find.each do |file_path|
        next if file_path.directory?
        relative_path = file_path.relative_path_from(source_path)
        @package.add_file(relative_path, src_path=file_path.to_path)
      end
      @package.manifest!
    end

    def assign_package
      if File.exist?(File.join(@src, 'bagit.txt')) &&
        File.exist?(File.join(@src, 'bag-info.txt'))
        @package = ::BagIt::Bag.new(@src)
      else
        @package = ::BagIt::Bag.new(@dst)
        create_bag unless @package.valid?
      end
    end
  end
end


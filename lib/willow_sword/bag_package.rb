require 'bagit'
require 'pathname'

module WillowSword
  class BagPackage

    attr_reader :package

    def initialize(src, dst)
      @src = src
      @dst = dst
      @src = File.join(src, '/') if File.directory?(src)
      @dst = File.join(dst, '/') if File.directory?(dst)
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
      src_package = ::BagIt::Bag.new(@src)
      dst_package = ::BagIt::Bag.new(@dst)
      if src_package.valid?
        @package = src_package
      else
        @package = dst_package
        create_bag unless @package.valid?
      end
    end
  end
end


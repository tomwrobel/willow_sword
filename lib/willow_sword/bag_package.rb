require 'bagit'
require 'pathname'

module WillowSword
  class BagPackage

    attr_reader :package

    def initialize(src, dst)
      @src = src
      @dst = dst
      @package = ::BagIt::Bag.new(@dst)
      @src = File.join(src, '/') if File.directory?(src)
      @dst = File.join(dst, '/') if File.directory?(dst)

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
  end
end


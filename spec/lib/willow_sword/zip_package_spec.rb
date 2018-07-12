require 'spec_helper'
require 'sandbox'
require 'willow_sword/zip_package'
RSpec.describe WillowSword::ZipPackage do
  describe 'unzip_file' do
    before(:each) do
      @sandbox = Sandbox.new
      @zip_src = File.join(ENGINE_RAILS_ROOT, 'spec', 'fixtures', 'testPackage.zip')
      @src = File.join(ENGINE_RAILS_ROOT, 'spec', 'fixtures', 'testPackage')
    end

    after(:each) do
      @sandbox.cleanup!
    end

    it "should unzip the file containing files and dir" do
      dst = @sandbox.to_s
      zp = WillowSword::ZipPackage.new(@zip_src, dst)
      zp.unzip_file
      expect(list_dir(dst)).to match_array(list_dir(@src))
    end

    it "should zip the source containing files and dir" do
      dst = File.join @sandbox.to_s, 'zip_file.zip'
      zp = WillowSword::ZipPackage.new(@src, dst)
      zp.create_zip
      # md5 does not match due to different compression mechanisms
      # src_md5 = get_md5(@zip_src)
      expect(File.exist?(dst)).to be true
      expect(test_zip(dst)).to include('Noerrors')
    end
  end
end

def list_dir(dir_name)
  entries = []
  Dir.chdir(dir_name) do
    entries = Dir.glob("**/*")
  end
  entries
end

def get_md5(src_file)
  `md5sum "#{src_file}" | awk '{ print $1 }'`.strip
end

def test_zip(zip_file)
  `unzip -t /tmp/sandbox20180712-18403-1iwsqff/zip_file.zip | awk '{w=$1 $2} END{print w}'`
end

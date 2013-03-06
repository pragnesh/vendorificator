require 'spec_helper'

module Vendorificator
  class Vendor::Categorized < Vendor
    @category = :test
  end

  class Vendor::Custom < Vendor
    @method_name = :whatever
  end

  describe Vendor do
    describe '.category' do
      it 'defaults to nil' do
        assert { Vendor.category == nil }
      end

      it 'can be overridden in a subclass' do
        assert { Vendor::Categorized.category == :test }
      end
    end

    describe '.install!' do
      it "creates a method inside Vendorificator::Config" do
        deny { conf.respond_to?(:categorized) }

        Vendor::Categorized.install!(conf)
        assert { conf.respond_to?(:categorized) }
      end

      it "uses @method_name for method's name if set" do
        deny { conf.respond_to?(:custom) }
        deny { conf.respond_to?(:whatever) }

        Vendor::Custom.install!(conf)
        deny   { conf.respond_to?(:custom) }
        assert { conf.respond_to?(:whatever) }
      end
    end

    describe '#category' do
      it 'defaults to class attribute' do
        assert { Vendor.new(nil, 'test').category == nil }
        assert { Vendor::Categorized.new(nil, 'test').category == :test }
      end

      it 'can be overriden by option' do
        assert { Vendor.new(nil, 'test', :category => :foo).category == :foo }
        assert { Vendor::Categorized.new(nil, 'test', :category => :foo).category == :foo }
      end

      it 'can be reset to nil by option' do
        assert { Vendor::Categorized.new(nil, 'test', :category => nil).category == nil }
      end

      it 'is inserted into paths and other names' do
        env = stub(
          :git => stub(
            :capturing => stub(
              :rev_parse => 'cafe',
              :merge_base => 'cafe',
              :describe => '')),
          :config => Vendorificator::Config.new)

        uncategorized = Vendor.new(env, 'test')
        categorized   = Vendor.new(env, 'test', :category => :cat)

        deny { uncategorized.branch_name.include? 'cat' }
        assert { categorized.branch_name.include? 'cat' }

        deny { uncategorized.path.include? 'cat' }
        assert { categorized.path.include? 'cat' }

        deny { uncategorized.tag_name.include? 'cat' }
        assert { categorized.tag_name.include? 'cat' }
      end
    end
  end
end

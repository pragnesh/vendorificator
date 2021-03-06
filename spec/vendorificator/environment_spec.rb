require 'spec_helper'

module Vendorificator
  describe Environment do
    before do
      MiniGit.any_instance.stubs(:fetch)
    end
    let(:environment){ Environment.new 'spec/vendorificator/fixtures/vendorfiles/vendor.rb' }

    describe '#clean' do
      it 'returns false for dirty repo' do
        git_error = MiniGit::GitError.new(['command'], 'status')
        environment.git.expects(:update_index).raises(git_error)

        assert { environment.clean? == false }
      end

      it 'returns true for a clean repo' do
        environment.git.expects(:update_index)
        environment.git.expects(:diff_files)
        environment.git.expects(:diff_index)

        assert { environment.clean? == true }
      end
    end

    describe '#pull_all' do
      it 'aborts on a dirty repo' do
        environment.expects(:clean?).returns(false)

        assert { rescuing { environment.pull_all }.is_a? DirtyRepoError }
      end

      it 'pulls multiple remotes if specified' do
        environment.stubs(:clean?).returns(true)
        environment.expects(:pull).with('origin_1', anything)
        environment.expects(:pull).with('origin_2', anything)

        environment.pull_all(:remote => 'origin_1,origin_2')
      end
    end

    describe '#pull' do
      it "creates a branch if it doesn't exist" do
        Environment.any_instance.unstub(:git)
        environment.git.capturing.stubs(:show_ref).
          returns("602315 refs/remotes/origin/vendor/test")
        environment.vendor_instances = [ stub(:branch_name => 'vendor/test', :head => nil)]

        environment.git.expects(:branch).with({:track => true}, 'vendor/test', '602315')
        environment.pull('origin')
      end

      it "handles fast forwardable branches" do
        Environment.any_instance.unstub(:git)
        environment.git.capturing.stubs(:show_ref).
          returns("602315 refs/remotes/origin/vendor/test")
        environment.vendor_instances = [stub(
          :branch_name => 'vendor/test', :head => '123456', :in_branch => true, :name => 'test'
        )]

        environment.expects(:fast_forwardable?).returns(true)
        environment.pull('origin')
      end
    end

    describe '#vendor_instances' do
      let(:environment){ Environment.new 'spec/vendorificator/fixtures/vendorfiles/empty_vendor.rb' }

      it 'is initialized on a new environment' do
        assert { environment.vendor_instances == [] }
      end

      it 'allows to add/read instances' do
        environment.vendor_instances << :foo
        assert { environment.vendor_instances == [:foo] }
      end
    end

  end
end

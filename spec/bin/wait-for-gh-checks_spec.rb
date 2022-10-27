# frozen_string_literal: true

# Run these tests with:
#     rspec spec/bin/wait-for-gh-checks_spec.rb

load File.expand_path('../../bin/wait-for-gh-checks', __dir__)

RSpec.describe(WaitForChecksRunner) do # rubocop:disable RSpec/FilePath
  subject(:runner) { WaitForChecksRunner.new }

  describe '#repo' do
    subject(:repo) { runner.repo }

    context 'when in the david_runger repo' do
      before { expect(Dir).to receive(:pwd).and_return('/Users/david/code/david_runger') }

      it 'returns "david_runger"' do
        expect(repo).to eq('david_runger')
      end
    end
  end

  describe WaitForChecksRunner::LoopRunner do
    subject(:loop_runner) { WaitForChecksRunner::LoopRunner.new(runner:, start_time: Time.now) }

    let(:runner) { WaitForChecksRunner.new }

    describe '#fail_exit_reason' do
      subject(:fail_exit_reason) { loop_runner.fail_exit_reason }

      context 'when the test output indicates that the test suite has failed' do
        before do
          expect(loop_runner).to receive(:checks_output).and_return(<<~OUTPUT)
            test  fail  3m3s  https://github.com/davidrunger/david_runger/actions/runs/3137993451/jobs/5096817061
            deploy-and-prerender  skipping  0 https://github.com/davidrunger/david_runger/actions/runs/3137993451/jobs/5096859848
            percy/david_runger  pass  0 https://percy.io/David-Runger/david_runger/builds/21769344?utm_campaign=David-Runger&utm_content=david_runger&utm_source=github_status_private
          OUTPUT
        end

        it 'returns "tests failed"' do
          expect(fail_exit_reason).to eq('tests failed')
        end
      end
    end

    describe '#num_passing_checks' do
      subject(:num_passing_checks) { loop_runner.num_passing_checks }

      context 'when the test output indicates that there are 2 passing checks' do
        before do
          expect(loop_runner).to receive(:checks_output).and_return(<<~OUTPUT)
            test  pass  3m3s  https://github.com/davidrunger/david_runger/actions/runs/3137993451/jobs/5096817061
            deploy-and-prerender  skipping  0 https://github.com/davidrunger/david_runger/actions/runs/3137993451/jobs/5096859848
            percy/david_runger  pass  0 https://percy.io/David-Runger/david_runger/builds/21769344?utm_campaign=David-Runger&utm_content=david_runger&utm_source=github_status_private
          OUTPUT
        end

        it 'returns 2' do
          expect(num_passing_checks).to eq(2)
        end
      end
    end
  end
end

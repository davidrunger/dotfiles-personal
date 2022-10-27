# frozen_string_literal: true

# Run these tests with:
#     rspec spec/bin/open-gh-pr_spec.rb

load File.expand_path('../../bin/open-gh-pr', __dir__)

RSpec.describe(OpenPullRequestRunner) do # rubocop:disable RSpec/FilePath
  subject(:runner) { OpenPullRequestRunner.new(create_pr_command_output) }

  describe '#pr_link' do
    subject(:pr_link) { runner.pr_link }

    context 'when the output includes a PR link' do
      let(:create_pr_command_output) do
        'content https://github.com/davidrunger/runger_style/pull/198 more content'
      end

      it 'returns the PR link' do
        expect(pr_link).to eq('https://github.com/davidrunger/runger_style/pull/198')
      end
    end

    context 'when the output does not include a PR link' do
      let(:create_pr_command_output) do
        'All cruelty springs from weakness.'
      end

      it 'returns nil' do
        expect(pr_link).to eq(nil)
      end
    end
  end
end

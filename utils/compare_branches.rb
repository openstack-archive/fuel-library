require 'rubygems'
require 'open3'
require 'set'

class GitCompare
  DEFAULT_BRANCHES = %w(origin/stable/mitaka origin/stable/newton origin/master)
  EXCLUDE = [/^Merge /, /^Revert "Merge/]

  # The list of branches to compare
  # @return [Array<String>]
  def branches
    return ARGV if ARGV.any?
    DEFAULT_BRANCHES
  end

  # Path to the repo root
  # @return [String]
  def repo
    return @repo if @repo
    @repo = File.expand_path File.dirname File.dirname __FILE__
  end

  # Call git to sync the repo
  def sync
    Dir.chdir(repo) do
      system 'git', 'fetch', '--all'
      fail 'Git sync have failed!' unless $?.exitstatus == 0
    end
  end

  # Call the git command and capture the output
  # @param [Array<String>] args
  # @return [String]
  def git(*args)
    Dir.chdir(repo) do
      command = ['git'] + args.flatten
      Open3.capture2 *command
    end
  end

  # Get the list of commits in the git log
  # The key is the commit subject and the value
  # is the array of hashes of the commits with this
  # subject found in this branch.
  # @param [String] branch
  # @return [Hash<String => Array>]
  def get_commits(branch='origin/master')
    data, status = git 'log', '--pretty=%H|%s', branch
    fail 'Git log failed!' if status.exitstatus != 0
    commits = {}
    data.split("\n").each do |commit|
      hash, subject = commit.split('|')
      fail "Commit: #{hash}|#{subject} did not parse!" unless hash and subject
      next if EXCLUDE.any? do |exclude|
        subject =~ exclude
      end
      subject = subject.chomp.strip
      commits[subject] = [] unless commits[subject]
      commits[subject] << hash
    end
    commits
  end

  # Commits for all branches
  # @return [Hash<String => Hash>]
  def commits
    return @branch_commits if @branch_commits
    @branch_commits = {}
    branches.each do |branch|
      @branch_commits[branch] = get_commits branch
    end
    @branch_commits
  end

  # List of branch comparisons
  # @return [Array<String>]
  def comparisons
    branches.permutation 2
  end

  # Output a line
  # @param [String] message
  # @param [Integer] offset
  def output(message, offset=0)
    puts '  ' * offset.to_i + message
  end

  # Print the commit count
  def stats
    output red '=> Stats'
    commits.each do |branch, commits|
      output "Branch: '#{branch}' has: #{commits.keys.count} commits"
    end
  end

  # Show the commit difference between branches
  def show_commits_diff(branch1, branch2)
    # output "Call: show_commits_diff #{branch1} #{branch2}"
    branch1_set = Set.new commits[branch1].keys
    branch2_set = Set.new commits[branch2].keys
    diff = branch1_set - branch2_set
    output "\n"
    output red('=> Commits present in the branch ') + green(branch1) + red(' and missing from the branch ') + green(branch2)
    longest_commit_string = diff.to_a.max_by { |s| s.length }.length
    diff.to_a.sort.each do |commit|
      hashes = commits[branch1][commit]
      output "#{commit.ljust longest_commit_string} #{green hashes.join ' '}"
    end
  end

  # Print commit report for all branches
  def report
    comparisons.each do |branch1, branch2|
      show_commits_diff branch1, branch2
    end
  end

  def red(message)
    "\033[31m#{message}\033[0m"
  end

  def green(message)
    "\033[32m#{message}\033[0m"
  end

  def main
    sync
    stats
    report
  end

end

if $0 == __FILE__
  gc = GitCompare.new
  gc.main
end

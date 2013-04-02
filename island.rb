require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'pry'
require 'rugged'

module Island
  extend self

  def perform
    return if not repo = Rugged::Repository.new(path)
    ref = repo.head.name if not ref
    master = Rugged::Reference.lookup(repo, ref)

    visit repo, repo.lookup(master.target).tree
  end

  private
  def yml
    YAML::load_file(
      File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml')
    )
  end

  def path
    yml['repository']['path']
  end

  def ref
    yml['repository']['ref']
  end

  def visit repo, tree
    tree.each do |t|
      if t[:type] == :blob
        # p File.basename(repo.path, '.git') if not repo.workdir
        p t[:name]
      else
        visit repo, repo.lookup(t[:oid])
      end
    end
  end
end

Island.perform

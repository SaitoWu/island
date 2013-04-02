require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'rugged'
require 'linguist'
require 'tempfile'

module Island
  extend self

  def perform
    return if not repo = Rugged::Repository.new(path)
    ref = repo.head.name if not ref
    master = Rugged::Reference.lookup(repo, ref)

    visit repo, File.basename(ref), repo.lookup(master.target).tree, ""
  end

  private
  def yml
    YAML::load_file(
      File.join(
        File.dirname(
          File.expand_path(__FILE__)
        ), 'config.yml'))
  end

  def path
    yml['repository']['path']
  end

  def ref
    yml['repository']['ref']
  end

  def visit repo, ref, tree, path
    tree.each do |t|
      if t[:type] == :blob
        filepath = File.join(ref, path, t[:name])
        blob = repo.lookup(t[:oid])

        # create a tempfile for linguist
        tempfile = Tempfile.new([t[:name], File.extname(t[:name])])
        tempfile.write(blob.content)
        tempfile.close

        fileblob = Linguist::FileBlob.new(tempfile.path)
        if fileblob.indexable? and language = fileblob.language
          p Hash[%w[name size path encoding language content].zip(
            [t[:name], blob.size, filepath, fileblob.encoding, language.name, fileblob.data]
          )]
        end

        # unlink tempfile
        tempfile.unlink
      else
        visit repo, ref, repo.lookup(t[:oid]), "#{t[:name]}"
      end
    end
  end
end

Island.perform

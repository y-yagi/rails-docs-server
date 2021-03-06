require 'fileutils'
require 'version_number'
require 'generators/base'
require 'generators/config/release'

module Generators
  class Release < Base
    include Config::Release

    def initialize(tag, basedir)
      super(tag, basedir)
      @version_number = VersionNumber.new(tag)
    end

    def before_generation
      if version_number == '4.0.0'
        patch 'railties/lib/rails/api/task.rb' do |contents|
          # This was a bug.
          contents.sub(%q(ENV['HORO_PROJECT_VERSION'] = rails_version), "ENV['HORO_PROJECT_VERSION'] ||= rails_version")
        end
      elsif version_number == '4.2.0'
        patch 'Gemfile' do |contents|
          # This dependency could not be satisfied.
          contents.sub(/^.*delayed_job_active_record.*$/, '')
        end
      elsif version_number >= '4.2.8'
        # The Nokogiri dependency fixed in Gemfile.lock errs with
        #
        #   nokogiri-1.7.0 requires ruby version >= 2.1.0, which is incompatible with the current version, ruby 2.0.0p598
        FileUtils.rm_f('Gemfile.lock')
      elsif version_number == '4.2.9'
        # bundle install errs, it says "You have requested: nokogiri ~> 1.6.0. The bundle currently has nokogiri locked at 1.8.0.
        FileUtils.rm_f('Gemfile.lock')
      end

      patch 'Gemfile' do |contents|
        # kindlerb didn't have a version constraint in some early Gemfiles, and
        # the current one is no longer compatible.
        contents.sub(/gem ["']kindlerb["']$/, "gem 'kindlerb', '0.1.1'")
      end
    end

    def generate_api
      if version_number < '4.0.1'
        rake 'rdoc', 'HORO_PROJECT_NAME' => 'Ruby on Rails', 'HORO_PROJECT_VERSION' => target
      else
        rake 'rdoc'
      end
    end

    def generate_guides
      if version_number < '4.0.0'
        Dir.chdir('railties') do
          rake 'generate_guides', 'RAILS_VERSION' => target
          rake 'generate_guides', 'KINDLE' => '1', 'RAILS_VERSION' => target
        end
      else
        Dir.chdir('guides') do
          rake 'guides:generate:html',   'RAILS_VERSION' => target
          rake 'guides:generate:kindle', 'RAILS_VERSION' => target
        end
      end
    end

    private

    def version_number
      @version_number
    end
  end
end

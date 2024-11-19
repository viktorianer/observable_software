namespace :version do
  desc "Bump version, create git tag, and update changelog"
  task :bump, [ :type ] => :environment do |_, args|
    type = args[:type] || "patch"

    # Run bump command
    sh "bundle exec bump #{type} --tag"

    # Get new version
    version = YourAppName::VERSION

    # Update CHANGELOG.md if it exists
    if File.exist?("CHANGELOG.md")
      timestamp = Time.current.strftime("%Y-%m-%d")
      sh %(echo "## [#{version}] - #{timestamp}\n\n" >> CHANGELOG.md)
    end

    # Commit changelog if modified
    sh "git add CHANGELOG.md" if File.exist?("CHANGELOG.md")
    sh "git commit --amend --no-edit" if File.exist?("CHANGELOG.md")

    puts "Successfully bumped to version #{version}"
  end
end

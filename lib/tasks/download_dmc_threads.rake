require "open-uri"
require "fileutils"

namespace :dmc do
  desc "Download DMC thread images"
  task download_threads: :environment do
    base_url = "https://flosscross.com/public/images/floss/dmc/32/cr/"
    output_dir = Rails.root.join("data", "threads")
    FileUtils.mkdir_p(output_dir)

    dmc_colors = File.readlines(Rails.root.join("data", "dmc_colours.txt")).map(&:strip)

    dmc_colors.each_with_index do |color, index|
      url = "#{base_url}#{color}.png"
      output_file = output_dir.join("#{color}.png")

      begin
        URI.open(url) do |image|
          File.open(output_file, "wb") do |file|
            file.write(image.read)
          end
        end
        puts "Downloaded #{color}.png (#{index + 1}/#{dmc_colors.size})"
      rescue OpenURI::HTTPError => e
        puts "Error downloading #{color}.png: #{e.message}"
      end
    end

    puts "Download complete. Images saved in #{output_dir}"
  end
end

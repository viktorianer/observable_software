require "debug"
require "ferrum"
require "pathname"

namespace :pdf do
  desc "Download a PDF from FlossCross"
  task download: :environment do
    browser_options = {
      browser_path: Rails.env.production? ? "/usr/bin/google-chrome" : "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
      headless: true,
      timeout: 20,
      window_size: [ 1200, 800 ],
      save_path: Rails.root.join("data/downloads"),
      browser_options: {
        "download.default_directory" => Rails.root.join("data/downloads"),
        "download.prompt_for_download" => false
      }
    }

    browser = Ferrum::Browser.new(browser_options)

    begin
      browser.goto("https://flosscross.com/designer/")

      browser.network.wait_for_idle
      sleep 2

      file_input = browser.css('input[type="file"]').first
      raise "Could not find file input" unless file_input

      file_input.select_file(Rails.root.join("data/uploads/Puffins.fcjson"))
      sleep 2

      browser.goto("https://flosscross.com/designer/slot/1/pdf")
      browser.network.wait_for_idle
      sleep 2

      save_button = browser.css("button").find { |button| button.text.strip == "Save To PDF" }
      raise "Could not find Save to PDF button" unless save_button
      save_button.click

      ok_button = browser.css(".q-btn__content").find { |button| button.text.strip == "OK" }
      raise "Could not find OK button" unless ok_button
      ok_button.click

      sleep 2

      browser.downloads.wait

      file = File.open(Rails.root.join("data/downloads/#{browser.downloads.files.first['suggestedFilename']}"))
      puts "Downloaded file to: #{file.path}"

    rescue StandardError => e
      puts "Error: #{e.message}"
    ensure
      browser.quit
    end
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require "capybara"
# require "capybara/playwright/driver"

class DownloadPdfWithPlaywright
  def initialize(host:, token: ENV.fetch("BROWSERLESS_TOKEN"))
    @host = host
    @path = "/playwright/chromium?token=#{token}"
    configure_capybara
    @session = Capybara::Session.new(:playwright)
  end

  def call
    begin
      setup_browser
      navigate_and_upload_file
      download_pdf_file
    rescue StandardError => e
      puts "Error: #{e.message}"
    ensure
      cleanup
    end
  end

  private

  def configure_capybara
    Capybara.default_driver = :playwright
    Capybara.register_driver :playwright do |app|
      # We need to implement our own driver that connects to the browser URL
      # This is just a placeholder - we'll need to implement the actual driver
      CustomPlaywrightDriver.new(app,
        url: @host + @path,
        options: playwright_options)
    end
  end

  def playwright_options
    options = {
      viewport: { width: 1200, height: 800 },
      accept_downloads: true
    }

    if ENV["USE_BROWSERLESS"]
      options[:browser_ws_endpoint] = ENV["BROWSERLESS_URL"] || "ws://chrome-accessory:3000"
    end

    options
  end

  def setup_browser
    puts "Setting up browser session"
    @session.driver.browser.pages.first
  end

  def navigate_and_upload_file
    puts "Navigating to https://flosscross.com/designer/"
    @session.visit("https://flosscross.com/designer/")
    wait_for_network_idle

    puts "Selecting file"
    @session.attach_file('input[type="file"]', "data/uploads/Puffins.fcjson", make_visible: true)
    wait_for_network_idle
  end

  def download_pdf_file
    puts "Navigating to PDF page"
    @session.visit("https://flosscross.com/designer/slot/1/pdf")
    wait_for_network_idle

    puts "Waiting for Save To PDF button"
    @session.click("button", text: "Save To PDF")

    puts "Waiting for OK button"
    @session.click(".q-btn__content", text: "OK")

    # Handle download
    download_path = ENV["DOWNLOAD_PATH"] || "/rails/storage/downloads"
    @session.driver.browser.on("download") do |download|
      filename = download.suggested_filename
      full_path = File.join(download_path, filename)
      download.save_as(full_path)
      puts "Downloaded file to: #{full_path}"
    end
  end

  def wait_for_network_idle
    @session.driver.browser.pages.first.wait_for_load_state("networkidle")
    puts "Network is idle"
  end

  def cleanup
    @session&.driver&.quit
  end
end

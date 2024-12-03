require "google/apis/drive_v3"
# require "google/auth"
require "stringio"
require_relative "../models/drive_file"
require "ostruct"

module Repos
  class GoogleDrive
    FOLDER_ID = "1-3lHCbsr0tmvGwpkxqcfYqaS_WOrfP-M"

    def initialize
      key_file = StringIO.new(ENV.fetch("GOOGLE_KEY_FILE"))
      # key_file = File.open("/Users/johngallagher/Downloads/softwaredesignsimplified-d65fec64fbfa.json")

      @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: key_file,
        scope: Google::Apis::DriveV3::AUTH_DRIVE,
      )
    end

    def list
      drive = Google::Apis::DriveV3::DriveService.new
      drive.authorization = @credentials
      drive
        .list_files(fields: "nextPageToken, files(trashed,id, name, mime_type, parents)")
        .files
        .reject { |file| (file.parents || []).include?("0AJgZg4xHqkfQUk9PVA") }
        .map { |file| OpenStruct.new(id: file.id, name: file.name, mime_type: file.mime_type, contents: file.mime_type == "application/vnd.google-apps.folder" ? "" : download(file.id)) }
        .map { |drive_file| DriveFile.from_api(drive_file) }
    end

    def download(file_id)
      drive = Google::Apis::DriveV3::DriveService.new
      drive.authorization = @credentials
      drive.get_file(file_id, download_dest: StringIO.new)
    end

    def create(filename:, content:)
      file = Google::Apis::DriveV3::File.new
      file.name = filename
      file.parents = [ FOLDER_ID ]

      drive = Google::Apis::DriveV3::DriveService.new
      drive.authorization = @credentials
      drive.create_file(
        file,
        upload_source: StringIO.new(content),
        content_type: "text/plain"
      )
    end
  end
end

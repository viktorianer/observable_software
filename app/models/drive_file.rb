DriveFile = Data.define(:type, :id, :name, :contents, :mime_type) do
  def self.from_api(api_file)
    if api_file.mime_type == "application/vnd.google-apps.folder"
      new(
        id: api_file.id,
        name: api_file.name,
        contents: "",
        mime_type: api_file.mime_type,
        type: :folder,
      )
    else
      new(
        id: api_file.id,
        name: api_file.name,
        contents: api_file.contents,
        mime_type: api_file.mime_type,
        type: :file,
      )
    end
  end

  def read
    @contents.string
  end
end

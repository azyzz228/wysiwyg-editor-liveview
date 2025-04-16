defmodule Editor.S3Config do
  def bucket() do
    Application.get_env(:mgc, :s3_bucket_name)
  end

  def region() do
    Application.get_env(:mgc, :s3_bucket_region)
  end

  def cdn_host() do
    "https://#{bucket()}.#{region()}.cdn.digitaloceanspaces.com/"
  end

  def host() do
    "https://#{bucket()}.#{region()}.digitaloceanspaces.com/"
  end

  def folder() do
    "test"
  end
end

#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'fileutils'

class AssetDownloader
  ARCHIVE_BASE = 'http://web.archive.org/web/20250804195450id_/http://skinbyhaxton.com/'
  
  def initialize(html_file, output_dir)
    @html_file = html_file
    @output_dir = output_dir
    @assets_dir = File.join(@output_dir, 'image')
    @scripts_dir = File.join(@output_dir, 'scripts')
    FileUtils.mkdir_p(@assets_dir)
    FileUtils.mkdir_p(@scripts_dir)
  end

  def download_all_assets
    content = File.read(@html_file)
    
    # Extract all image references (both src and background-image CSS)
    image_urls = content.scan(/src=["|']image\/([^"|']+)["|']/).flatten
    css_images = content.scan(/url\(image\/([^)]+)\)/).flatten
    script_urls = content.scan(/src=["|']scripts\/([^"|']+)["|']/).flatten
    
    # Combine and deduplicate image URLs
    all_images = (image_urls + css_images).uniq
    
    puts "🖼️  Found #{all_images.length} images to download"
    puts "📜 Found #{script_urls.length} scripts to download"
    
    # Download images
    all_images.each do |image_path|
      download_asset("image/#{image_path}", File.join(@assets_dir, image_path))
      sleep(1) # Rate limiting
    end
    
    # Download scripts
    script_urls.each do |script_path|
      download_asset("scripts/#{script_path}", File.join(@scripts_dir, script_path))
      sleep(1) # Rate limiting
    end
    
    puts "✅ Asset download complete!"
  end

  private

  def download_asset(relative_path, local_path)
    url = ARCHIVE_BASE + relative_path
    puts "📥 Downloading: #{relative_path}"
    
    begin
      # Use curl to follow redirects and download the file
      FileUtils.mkdir_p(File.dirname(local_path))
      cmd = "curl -L -s '#{url}' -o '#{local_path}'"
      
      if system(cmd)
        if File.exist?(local_path) && File.size(local_path) > 0
          puts "✅ Saved: #{local_path}"
        else
          puts "❌ Downloaded empty file: #{relative_path}"
        end
      else
        puts "❌ Failed to download #{relative_path}"
      end
    rescue => e
      puts "❌ Error downloading #{relative_path}: #{e.message}"
    end
  end
end

# Run if script is executed directly
if __FILE__ == $0
  html_file = ARGV[0] || '/Users/matthewmengerink/Projects/skinbyhaxton/website/index.html'
  output_dir = File.dirname(html_file)
  
  downloader = AssetDownloader.new(html_file, output_dir)
  downloader.download_all_assets
end
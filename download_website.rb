#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'fileutils'
require 'uri'

class SkinByHaxtonDownloader
  DOMAIN = 'skinbyhaxton.com'
  ARCHIVE_URL_BASE = 'https://web.archive.org'
  WAYBACK_API = 'https://archive.org/wayback/available'
  
  def initialize
    @output_dir = File.join(Dir.pwd, 'website')
    @assets_dir = File.join(@output_dir, 'assets')
  end

  def download_website
    puts "🔍 Finding latest snapshot of #{DOMAIN}..."
    
    # Get the latest available snapshot
    latest_snapshot = get_latest_snapshot
    unless latest_snapshot
      puts "❌ No snapshots found for #{DOMAIN}"
      return false
    end
    
    puts "📅 Latest snapshot: #{latest_snapshot[:timestamp]}"
    puts "🔗 URL: #{latest_snapshot[:url]}"
    
    # Create output directories
    FileUtils.mkdir_p(@output_dir)
    FileUtils.mkdir_p(@assets_dir)
    
    # Use wayback_machine_downloader gem if available, otherwise use wget
    if system('which wayback_machine_downloader > /dev/null 2>&1')
      use_wayback_downloader
    else
      puts "📦 Installing wayback_machine_downloader gem..."
      system('gem install wayback_machine_downloader')
      use_wayback_downloader
    end
    
    # Post-process files for GitHub Pages and GoDaddy hosting
    post_process_files
    
    puts "✅ Website download complete!"
    puts "📁 Files saved to: #{@output_dir}"
    puts "🔗 To preview: Open #{File.join(@output_dir, 'index.html')} in your browser"
  end

  private

  def get_latest_snapshot
    uri = URI("#{WAYBACK_API}?url=#{DOMAIN}")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      if data['archived_snapshots'] && data['archived_snapshots']['closest']
        snapshot = data['archived_snapshots']['closest']
        {
          timestamp: snapshot['timestamp'],
          url: snapshot['url']
        }
      end
    end
  rescue => e
    puts "❌ Error fetching snapshot info: #{e.message}"
    nil
  end

  def use_wayback_downloader
    puts "📥 Downloading website using wayback_machine_downloader..."
    
    # Download to a temporary directory first
    temp_dir = File.join(Dir.pwd, 'temp_download')
    
    # Run wayback_machine_downloader
    cmd = "wayback_machine_downloader #{DOMAIN} --directory #{temp_dir} --concurrency 5"
    puts "Running: #{cmd}"
    
    unless system(cmd)
      puts "❌ Download failed. Trying alternative method..."
      use_wget_method
      return
    end
    
    # Move files from temp directory to our target directory
    downloaded_path = File.join(temp_dir, 'websites', DOMAIN)
    if Dir.exist?(downloaded_path)
      FileUtils.cp_r(Dir.glob("#{downloaded_path}/*"), @output_dir)
      FileUtils.rm_rf(temp_dir)
    else
      puts "❌ Expected download directory not found"
    end
  end

  def use_wget_method
    puts "📥 Using wget as fallback method..."
    
    # Get latest snapshot URL
    latest_snapshot = get_latest_snapshot
    return unless latest_snapshot
    
    base_url = latest_snapshot[:url].gsub(/\/[^\/]*$/, '/')
    
    # Use wget to download the site
    cmd = [
      'wget',
      '--recursive',
      '--level=3',
      '--no-clobber',
      '--page-requisites',
      '--html-extension',
      '--convert-links',
      '--restrict-file-names=windows',
      '--domains=web.archive.org',
      '--no-parent',
      '--directory-prefix=' + @output_dir,
      '--wait=4',  # Rate limiting for archive.org
      base_url
    ].join(' ')
    
    puts "Running: #{cmd}"
    system(cmd)
  end

  def post_process_files
    puts "🔧 Post-processing files for hosting..."
    
    # Find all HTML files
    html_files = Dir.glob(File.join(@output_dir, '**', '*.html'))
    
    html_files.each do |file|
      process_html_file(file)
    end
    
    # Create GitHub Pages configuration
    create_github_pages_config
    
    # Create hosting instructions
    create_hosting_instructions
  end

  def process_html_file(file_path)
    content = File.read(file_path)
    
    # Remove Wayback Machine toolbar and navigation
    content.gsub!(/<div id="wm-ipp-base".*?<\/div>/m, '')
    content.gsub!(/<script.*?\/\/web\.archive\.org.*?<\/script>/m, '')
    content.gsub!(/<link.*?\/\/web\.archive\.org.*?>/m, '')
    
    # Fix asset URLs - remove Wayback Machine prefixes
    content.gsub!(/https?:\/\/web\.archive\.org\/web\/\d+[^\/]*\//, '')
    
    # Convert absolute URLs to relative for local hosting
    content.gsub!(/https?:\/\/#{Regexp.escape(DOMAIN)}\//, './')
    
    File.write(file_path, content)
  end

  def create_github_pages_config
    # Create _config.yml for GitHub Pages
    config_content = <<~YAML
      # GitHub Pages configuration for skinbyhaxton.com
      title: "Skin by Haxton"
      description: "Archived website from #{DOMAIN}"
      baseurl: "/skinbyhaxton"
      url: "https://yourusername.github.io"
      
      # GitHub Pages settings
      markdown: kramdown
      highlighter: rouge
      theme: minima
      
      plugins:
        - jekyll-feed
        - jekyll-sitemap
    YAML
    
    File.write(File.join(@output_dir, '_config.yml'), config_content)
  end

  def create_hosting_instructions
    instructions = <<~MD
      # Hosting Instructions for skinbyhaxton.com

      ## GitHub Pages Preview
      1. Push this repository to GitHub
      2. Go to repository Settings > Pages
      3. Set source to "Deploy from a branch"
      4. Select "main" branch and "/website" folder
      5. Your site will be available at: https://yourusername.github.io/skinbyhaxton

      ## GoDaddy Hosting Deployment
      1. Log into your GoDaddy hosting control panel
      2. Navigate to File Manager or use FTP
      3. Upload all files from the `website/` directory to your domain's public_html folder
      4. Ensure the main page is named `index.html`
      5. Update any remaining absolute URLs to use your domain name

      ## Files Structure
      ```
      website/
      ├── index.html          # Main homepage
      ├── assets/            # Images, CSS, JS files
      ├── _config.yml        # GitHub Pages configuration
      └── [other pages]      # Additional HTML pages
      ```

      ## Notes
      - All Wayback Machine navigation has been removed
      - URLs have been converted to relative paths for local hosting
      - Images and assets should be properly linked
      - The site is ready for both GitHub Pages and traditional hosting
    MD
    
    File.write(File.join(Dir.pwd, 'HOSTING_INSTRUCTIONS.md'), instructions)
  end
end

# Run the downloader if this script is executed directly
if __FILE__ == $0
  downloader = SkinByHaxtonDownloader.new
  downloader.download_website
end
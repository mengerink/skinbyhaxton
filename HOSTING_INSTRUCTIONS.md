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
├── about-us.html       # About page
├── facials.html        # Treatments page  
├── Blog.html          # Blog page
├── reviews.html       # Press/reviews page
├── image/             # All website images
├── scripts/           # JavaScript files
├── _config.yml        # GitHub Pages configuration
├── .nojekyll         # Tells GitHub Pages to serve static files
└── README.md         # Site documentation
```

## Notes
- All Wayback Machine navigation has been removed
- URLs have been converted to relative paths for local hosting
- Images and assets should be properly linked
- The site is ready for both GitHub Pages and traditional hosting

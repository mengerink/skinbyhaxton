#!/bin/bash

# Deploy script for GoDaddy hosting
# This script prepares the website files for upload to GoDaddy

echo "🚀 Preparing skinbyhaxton.com for GoDaddy deployment..."

# Create deployment directory
DEPLOY_DIR="./godaddy_deploy"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Copy all website files
echo "📁 Copying website files..."
cp -r website/* "$DEPLOY_DIR/"

# Remove GitHub Pages specific files
echo "🧹 Removing GitHub Pages files..."
rm -f "$DEPLOY_DIR/_config.yml"
rm -f "$DEPLOY_DIR/.nojekyll"
rm -f "$DEPLOY_DIR/README.md"

# Clean up HTML files for production hosting
echo "🔧 Cleaning HTML files for production..."

for html_file in "$DEPLOY_DIR"/*.html; do
    if [ -f "$html_file" ]; then
        # Remove any remaining development/tracking scripts
        sed -i '' '/scorecard\.wspisp\.net/d' "$html_file"
        sed -i '' '/myregisteredsite\.com/d' "$html_file"
        
        # Update any localhost references to use relative paths
        sed -i '' 's|http://localhost|.|g' "$html_file"
        sed -i '' 's|https://localhost|.|g' "$html_file"
        
        echo "✅ Cleaned: $(basename "$html_file")"
    fi
done

# Create .htaccess for proper redirects and caching
echo "📄 Creating .htaccess file..."
cat > "$DEPLOY_DIR/.htaccess" << 'EOF'
# Cache images, CSS, and JS for better performance
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType text/css "access plus 1 week"
    ExpiresByType application/javascript "access plus 1 week"
    ExpiresByType text/javascript "access plus 1 week"
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Redirect www to non-www or vice versa if needed
# RewriteEngine On
# RewriteCond %{HTTP_HOST} ^www\.skinbyhaxton\.com [NC]
# RewriteRule ^(.*)$ http://skinbyhaxton.com/$1 [R=301,L]
EOF

# Create deployment summary
echo "📋 Creating deployment summary..."
cat > "$DEPLOY_DIR/DEPLOYMENT_INFO.txt" << EOF
SKIN BY HAXTON - GODADDY DEPLOYMENT PACKAGE
==========================================

Deployment Date: $(date)
Source: Internet Archive (snapshot from 2025-08-04)

FILES TO UPLOAD:
- All HTML files (index.html, about-us.html, etc.)
- image/ directory with all images
- scripts/ directory with JavaScript files  
- .htaccess file for server configuration

DEPLOYMENT STEPS:
1. Log into your GoDaddy hosting control panel
2. Navigate to File Manager (or use FTP client)
3. Upload ALL files from this directory to public_html/
4. Verify index.html loads correctly
5. Test all navigation links

CONTACT INFO ON SITE:
Phone: 650-815-9976
Address: 745 Distel Dr, Suite 201, Los Altos, CA 94022
Hours: Tuesday - Saturday, 11:00 am to 7:00 pm

Social Media Links:
- Facebook: https://www.facebook.com/SkinByHaxton/
- Twitter: https://twitter.com/ByHaxton  
- Instagram: https://instagram.com/richard_haxton
- Pinterest: https://www.pinterest.com/haxton10
- LinkedIn: https://www.linkedin.com/in/skinbyhaxton/
EOF

echo ""
echo "✅ GoDaddy deployment package ready!"
echo "📁 Files prepared in: $DEPLOY_DIR"
echo "📄 See DEPLOYMENT_INFO.txt for upload instructions"
echo ""
echo "📊 File count summary:"
echo "   HTML pages: $(find "$DEPLOY_DIR" -name "*.html" | wc -l)"
echo "   Images: $(find "$DEPLOY_DIR/image" -type f | wc -l 2>/dev/null || echo 0)"
echo "   Scripts: $(find "$DEPLOY_DIR/scripts" -type f | wc -l 2>/dev/null || echo 0)"